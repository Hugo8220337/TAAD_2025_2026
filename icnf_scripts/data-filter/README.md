# Data Filter SSIS Project

This project provides a set of Python scripts designed to filter CSV files containing fire detection data. The main script, `apply_filters.py`, processes the data through a series of filters to clean and refine the dataset.

## Project Structure

```
data-filter-ssis
├── src
│   ├── apply_filters.py
│   ├── filters
│   │   ├── Abstract_Filter.py
│   │   ├── Area_Threshold_Filter.py
│   │   ├── Custom_Filter.py
│   │   ├── False_Alarm_Filter.py
│   │   ├── Filter_Pipeline.py
│   │   ├── Missing_Coordinates_Filter.py
│   │   ├── Not_Incendio_Filter.py
│   │   └── Queimada_Filter.py
│   └── utils
│       └── file_utils.py
├── requirements.txt
├── pyinstaller.spec
├── build_exe.bat
├── build_exe.sh
├── .gitignore
└── README.md
```

## Installation

To set up the project, ensure you have Python installed on your system. Then, install the required dependencies listed in `requirements.txt`:

```bash
pip install -r requirements.txt
```

## Building the Executable

To create an executable that can be run in SQL Server Integration Services (SSIS), you can use PyInstaller. The project includes scripts for building the executable:

- For Windows, run:
  ```bash
  build_exe.bat
  ```

- For Unix-based systems, run:
  ```bash
  bash build_exe.sh
  ```

The executable will be generated based on the configuration specified in `pyinstaller.spec`.

## Usage

Once the executable is built, you can run it to process CSV files. The main script `apply_filters.py` will apply a series of filters to the input data, which can be specified through command-line arguments.

## Contributing

Contributions to the project are welcome. Please feel free to submit issues or pull requests.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.