# Getting started

Open this folder in MATLAB and run:

```matlab
SolarTrackerLab
```

Start with the default clear-sky experiment. Move the time slider through morning, noon and evening, then open **Energy & Control** to compare power and net energy. Switch to **Overcast**, click **Run Experiment** and compare the result. Try a slower slew rate or a longer command interval to see the effect on tracking.

Use **Export CSV + plots** to save the current run. Copy `results/` before exporting again if you want to keep the previous run. **Open Simulink model** builds and opens the block model for the selected settings.

See [README.md](README.md) for setup, example results and the file guide. [docs/MODEL.md](docs/MODEL.md) contains the equations and assumptions. [docs/VALIDATION.md](docs/VALIDATION.md) explains the checks.
