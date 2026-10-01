"""Execute the notebook in a fresh kernel using this Python environment."""
from pathlib import Path
import os
import sys
import nbformat
from nbclient import NotebookClient
from jupyter_client import KernelManager

root = Path(__file__).resolve().parent
os.environ.setdefault("MPLBACKEND", "Agg")
ipython_dir = root / ".local" / "ipython"
ipython_dir.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("IPYTHONDIR", str(ipython_dir))
notebook = nbformat.read(root / "NBA_code.ipynb", as_version=4)
for cell in notebook.cells:
    if cell.cell_type == "code":
        cell.outputs = []
        cell.execution_count = None
manager = KernelManager(kernel_name="python3")
manager.kernel_spec.argv = [sys.executable, "-m", "ipykernel_launcher", "-f", "{connection_file}"]
client = NotebookClient(notebook, km=manager, timeout=300, resources={"metadata": {"path": str(root)}})
client.execute()
nbformat.write(notebook, root / "NBA_code.ipynb")
print("Fresh-kernel execution succeeded.")
