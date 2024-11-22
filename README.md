# ConSmax: Fully Parallelizable Softmax Alternative with Learnable Parameters

This repository contains the hardware implementation for ConSmax,
introduced in our work: "ConSmax: Hardware-Friendly Alternative Softmax with
Learnable Parameters," presented at ICCAD 2024.

In this research, we introduce **ConSmax**, an optimized softmax alternative
designed for efficient on-device use in transformer-based language models. By
implementing two differentiable normalization parameters, we eliminate the need
for maximum searching and denominator summation.

ConSmax achieves up to **7.5x power savings** and **13.75x area reduction** over
traditional softmax hardware in 16nm FinFET technology.

**ConSmax Key Features:**
1. **Hardware-Friendly Numerical Stability**: Fully-parallelizable numerical stability operation
2. **Hardware-Friendly Learned Normalization**: Fully-parallelizable, learned normalization operation
3. **Differentiable Parameters**: Learnable during training, fixed during inference for efficient decoding
4. **Bitwidth-Split LUT Design**: Enables scalability for non-linear operations
5. **Comparable Language Modeling Accuracy on Post-LN Networks**: Comparable Validation Loss with GPT-2 on WikiText103 dataset

---

## Publication Links

* [ICCAD 2024 Publication](paper/ICCAD_2024_ConSmax.pdf)
* Preprint Link: https://arxiv.org/abs/2402.10930

---

## Citation
If you find our code useful for your research, please consider citing:

```bibtex
@inproceedings{liu2024consmaxhardwarefriendlyalternativesoftmax,
      title={ConSmax: Hardware-Friendly Alternative Softmax with Learnable Parameters},
      author={Shiwei Liu and Guanchen Tao and Yifei Zou and Derek Chow and Zichen Fan and Kauna Lei and Bangfei Pan and Dennis Sylvester and Gregory Kielian and Mehdi Saligane},
      booktitle={Proceedings of the IEEE/ACM International Conference on Computer-Aided Design (ICCAD)},
      pages={1117},
      year={2024},
      eprint={2402.10930},
      archivePrefix={arXiv},
      primaryClass={cs.AR},
      url={https://arxiv.org/abs/2402.10930}
}
```


---

### Software Evaluation


Assuming PyTorch GPU training and NanoGPT dependencies are installed on your
enviroment:

```sh
git clone https://github.com/ReaLLMASIC/nanogpt.git
cd nanogpt/

cd data/wikitext103
python3 get_wikitext103.py
python3 prepare.py -t input.txt --method tiktoken

cd ../../

# Run with ConSmax
python3 train.py --softmax_variant_attn consmax_v2 --dataset wikitext103 --max_sample_tokens 256 --max_iters 30000 --use_post_ln

# Run Softmax for Reference
python3 train.py --dataset wikitext103 --max_sample_tokens 256 --max_iters 30000 --use_post_ln
```
