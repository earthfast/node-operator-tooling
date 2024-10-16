from setuptools import setup, find_packages

setup(
    name="earthfast-node-cli",
    version="0.1",
    packages=find_packages(),
    entry_points={
        'console_scripts': [
            'earthfast-node-cli=earthfast_node_cli:main',
        ],
    },
    install_requires=[
    ],
)