# allrank-train

## About

Docker-based fork of [allegro/allRank](https://github.com/allegro/allRank), adapted to train and validate ListNet and ListMLE listwise learning-to-rank models for ranking senior men's and women's 100m sprint athletes using pre-event data.

This is **stage 1** of a three-repo pipeline:

1. **allrank-train** (this repo) — trains and validates ListNet and ListMLE via Docker, producing a `model.pkl` checkpoint per gender for each model in the output directory.

2. [**allrank-infer**](https://github.com/mphop-T/allrank-infer) — loads `model.pkl` from this repo and generates ListNet/ListMLE prediction scores for the men's and women's test sets. 

3. [**athletes-ranking**](https://github.com/mphop-T/athletes-ranking) — data preprocessing, LambdaRank and Random Forest training/evaluation, and the results and significance testing that combine outputs from all three repos.

## What this repo does

- Trains ListNet and ListMLE separately for men's and women's senior 100m sprint data, using allRank's listwise ranking objectives.
- Input: LibSVM-formatted ranking files, organized into gender-specific folders ( `athletes_women_data_combined/`, `athletes_men_data_combined/`), each containing `train.txt` and `vali.txt` — renamed from their original exported filenames to match allRank's expected convention (training data must be named `train.txt`; the validation filename is set in `config.json`). Each row contains a query ID (`qid`, one per athletic event), a relevance label, and indexed feature values.
- Relevance labels are derived as `Max_Rank − Normalized_Place + 1`, so the athlete with the best (lowest) finishing position in an event receives the highest relevance score. `Position`, `Normalized_Place`, and `Mark` are excluded from the feature set to prevent data leakage.
- Output: trained model checkpoints (`model.pkl`), one per gender per model, consumed downstream by `allrank-infer`.

## Requirements

- Base image: `python:3.9` (pulled automatically from Docker Hub during `docker build`; not stored in this repo)
- Additional dependencies layered on top by the Dockerfile: `torch==1.13.1`, `torchvision==0.14.1` (CPU or GPU build, selected via the `arch_version` build-arg), plus allRank's own Python dependencies (`requirements.txt`) are installed by the original, unmodified Dockerfile — no packages were added or changed for this project

## Usage

The Docker image only needs to be built once (or whenever the Dockerfile/dependencies change):

```
docker build --build-arg arch_version=cpu -t allrank-train .
```
Each training run is then launched from that already-built image, via a shell script that calls allRank's training entry point:

```
python allrank/main.py --config_file_name allrank/config.json --run_id <experiment_name> --job_dir <output_path>
```
- `output_path` contains output directory name which has the `model.pkl` file

The model type (ListNet vs. ListMLE), loss function, and other hyperparameters aren't CLI flags — they're set inside a config file, and the config also points at the correct gender folder's `train.txt`/`vali.txt`. A separate config file and shell script were used for each model/gender combination:

| Model | Gender | Config file | Training/testing script | Output directory |
|---|---|---|---|---|
| ListMLE | Men | `athletes_listmle_config_listmle_male_combined.json` | `run_listmle_male_combined_in_docker.sh` | `listmle-male-combined-test-data` |
| ListMLE | Women | `athletes_listmle_config_listmle_women_combined.json` | `run_listmle_women_combined_in_docker.sh` | `listmle-women-combined-test-data` |
| ListNet | Men | `athletes_listnet_men_combined_config.json` | `run_listnet_men_combined_in_docker.sh` | `listnet-men-combined-test-data` |
| ListNet | Women | `athletes_listnet_women_combined_config.json` | `run_listnet_women_combined_in_docker.sh` | `listnet-women-combined-test-data` |

## Data

Training and validation LibSVM files (`train.txt` / `vali.txt` per gender folder) are produced by the data-preprocessing notebook in [athletes-ranking](https://github.com//mphop-T/athletes-ranking). See that repo for the full data cleaning, feature engineering, and leakage-prevention steps that generate these files.

## Modifications from upstream

This repo is a fork of [allegro/allRank](https://github.com/allegro/allRank) (Pobrotyn et al., 2020, [arXiv:2005.10084](https://arxiv.org/abs/2005.10084)), used under its Apache 2.0 license.

*Note for completion: list the specific changes you made — e.g. new/edited config files for this dataset, any changes to data loading, changes to hyperparameters from the allRank defaults, etc.*

## License

Apache License 2.0, inherited from upstream allRank. See `LICENSE`.

---

allRank is a PyTorch-based framework for training neural Learning-to-Rank (LTR) models, featuring implementations of:
* common pointwise, pairwise and listwise loss functions
* fully connected and Transformer-like scoring functions
* commonly used evaluation metrics like Normalized Discounted Cumulative Gain (NDCG) and Mean Reciprocal Rank (MRR)
* click-models for experiments on simulated click-through data

### Motivation

allRank provides an easy and flexible way to experiment with various LTR neural network models and loss functions.
It is easy to add a custom loss, and to configure the model and the training procedure. 
We hope that allRank will facilitate both research in neural LTR and its industrial applications.

## Features

### Implemented loss functions:
 1. ListNet (for binary and graded relevance)
 2. ListMLE
 3. RankNet
 4. Ordinal loss
 5. LambdaRank
 6. LambdaLoss
 7. ApproxNDCG
 8. RMSE
 9. NeuralNDCG (introduced in https://arxiv.org/pdf/2102.07831)

### Getting started guide

To help you get started, we provide a ```run_example.sh``` script which generates dummy ranking data in libsvm format and trains
 a Transformer model on the data using provided example ```config.json``` config file. Once you run the script, the dummy data can be found in `dummy_data` directory
 and the results of the experiment in `test_run` directory. To run the example, Docker is required.

### Getting the right architecture version (GPU vs CPU-only)

Since torch binaries are different for GPU and CPU and GPU version doesn't work on CPU - one must select & build appropriate docker image version.

To do so pass `gpu` or `cpu` as `arch_version` build-arg in 

```docker build --build-arg arch_version=${ARCH_VERSION}```

When calling `run_example.sh` you can select the proper version by a first cmd line argument e.g. 

```run_example.sh gpu ...```

with `cpu` being the default if not specified.

### Configuring your model & training

To train your own model, configure your experiment in ```config.json``` file and run  

```python allrank/main.py --config_file_name allrank/config.json --run_id <the_name_of_your_experiment> --job_dir <the_place_to_save_results>```

All the hyperparameters of the training procedure: i.e. model defintion, data location, loss and metrics used, training hyperparametrs etc. are controlled
by the ```config.json``` file. We provide a template file ```config_template.json``` where supported attributes, their meaning and possible values are explained.
 Note that following MSLR-WEB30K convention, your libsvm file with training data should be named `train.txt`. You can specify the name of the validation dataset 
 (eg. valid or test) in the config. Results will be saved under the path ```<job_dir>/results/<run_id>```
 
Google Cloud Storage is supported in allRank as a place for data and job results.


### Implementing custom loss functions

To experiment with your own custom loss, you need to implement a function that takes two tensors (model prediction and ground truth) as input
 and put it in the `losses` package, making sure it is exposed on a package level.
To use it in training, simply pass the name (and args, if your loss method has some hyperparameters) of your function in the correct place in the config file:

```
"loss": {
    "name": "yourLoss",
    "args": {
        "arg1": val1,
        "arg2: val2
    }
  }
```

### Applying click-model

To apply a click model you need to first have an allRank model trained.
Next, run:

```python allrank/rank_and_click.py --input-model-path <path_to_the_model_weights_file> --roles <comma_separated_list_of_ds_roles_to_process e.g. train,valid> --config_file_name allrank/config.json --run_id <the_name_of_your_experiment> --job_dir <the_place_to_save_results>``` 

The model will be used to rank all slates from the dataset specified in config. Next - a click model configured in config will be applied and the resulting click-through dataset will be written under ```<job_dir>/results/<run_id>``` in a libSVM format.
The path to the results directory may then be used as an input for another allRank model training.

## Continuous integration

You should run `scripts/ci.sh` to verify that code passes style guidelines and unit tests.

## Research

This framework was developed to support the research project [Context-Aware Learning to Rank with Self-Attention](https://arxiv.org/abs/2005.10084). If you use allRank in your research, please cite:
```
@article{Pobrotyn2020ContextAwareLT,
  title={Context-Aware Learning to Rank with Self-Attention},
  author={Przemyslaw Pobrotyn and Tomasz Bartczak and Mikolaj Synowiec and Radoslaw Bialobrzeski and Jaroslaw Bojar},
  journal={ArXiv},
  year={2020},
  volume={abs/2005.10084}
}
```
Additionally, if you use the NeuralNDCG loss function, please cite the corresponding work, [NeuralNDCG: Direct Optimisation of a Ranking Metric via Differentiable Relaxation of Sorting](https://arxiv.org/abs/2102.07831):
```
@article{Pobrotyn2021NeuralNDCG,
  title={NeuralNDCG: Direct Optimisation of a Ranking Metric via Differentiable Relaxation of Sorting},
  author={Przemyslaw Pobrotyn and Radoslaw Bialobrzeski},
  journal={ArXiv},
  year={2021},
  volume={abs/2102.07831}
}
```

## License

Apache 2 License
