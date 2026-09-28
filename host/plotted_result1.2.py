import serial
import threading
import queue
import matplotlib.pyplot as plt
import matplotlib.animation as animation

plt.rcParams['path.simplify'] = False

PORT = "COM4"
BAUD = 115200
NUM_SAMPLES = 4096
SYNC_SEQ = bytes([0xAA, 0x55, 0xAA, 0x55])

data_queue = queue.Queue(maxsize=2)
stop_event = threading.Event()
batch_count = 0


def wait_for_sync(ser):
    window = bytearray()
    while not stop_event.is_set():
        b = ser.read(1)
        if len(b) == 0:
            continue
        window.append(b[0])
        if len(window) > 4:
            window.pop(0)
        if bytes(window) == SYNC_SEQ:
            return


def reader_thread():
    global batch_count
    ser = serial.Serial(PORT, BAUD, timeout=1)
    print("Waiting for sync marker...")

    while not stop_event.is_set():
        wait_for_sync(ser)

        samples = []
        while len(samples) < NUM_SAMPLES and not stop_event.is_set():
            hi = ser.read(1)
            lo = ser.read(1)
            if len(hi) == 0 or len(lo) == 0:
                continue
            word = (hi[0] << 8) | lo[0]
            samples.append(word)

        if len(samples) == NUM_SAMPLES:
            batch_count += 1
            try:
                data_queue.put(samples, timeout=1)
            except queue.Full:
                pass

    ser.close()


def main():
    thread = threading.Thread(target=reader_thread, daemon=True)
    thread.start()

    Y_MAX = 4095
    Y_MARGIN = 200
    INITIAL_X_WINDOW = 200  # only show first 200 samples by default; zoom/pan freely from there

    fig, ax = plt.subplots(figsize=(12, 5))
    line, = ax.plot([], [], drawstyle='steps-post', linewidth=1.0, color='tab:blue') 
    bad_scatter = ax.scatter([], [], color='red', s=20, zorder=5, label='out-of-range (corrupt)')

    ax.set_xlim(0, INITIAL_X_WINDOW)   # small default window -- user can zoom/pan out from here
    ax.set_ylim(0, Y_MAX + Y_MARGIN)   # y stays locked, protects against corrupt-sample spikes
    ax.set_xlabel("Sample Index")
    ax.set_ylabel("Value")
    ax.grid(True, alpha=0.4)
    ax.legend(loc='upper right')

    def update(frame):
        try:
            samples = data_queue.get_nowait()
        except queue.Empty:
            return line, bad_scatter

        x = list(range(len(samples)))
        clipped = [min(v, Y_MAX) for v in samples]
        line.set_data(x, clipped)

        bad_x = [i for i, v in enumerate(samples) if v > Y_MAX]
        bad_y = [Y_MAX + Y_MARGIN * 0.6 for _ in bad_x]
        if bad_x:
            bad_scatter.set_offsets(list(zip(bad_x, bad_y)))
        else:
            bad_scatter.set_offsets([[None, None]][:0])

        # Only re-lock the Y-axis every frame -- leave X alone so zoom/pan persists
        ax.set_ylim(0, Y_MAX + Y_MARGIN)

        n_bad = len(bad_x)
        good_samples = [v for v in samples if v <= Y_MAX]
        data_min = min(good_samples) if good_samples else 0
        data_max = max(good_samples) if good_samples else 0

        ax.set_title(
            f"Live Captured Samples  |  batch #{batch_count}  |  "
            f"min={data_min}  max={data_max}  |  corrupt samples: {n_bad}"
        )

        return line, bad_scatter

    ani = animation.FuncAnimation(fig, update, interval=50, blit=False, cache_frame_data=False)
    plt.show()

    stop_event.set()
    thread.join(timeout=2)


if __name__ == "__main__":
    main()