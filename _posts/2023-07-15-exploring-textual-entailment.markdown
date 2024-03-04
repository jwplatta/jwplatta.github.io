---
layout: post
title:  "Exploring Textual Entailment: Naive Bayes, Neural Network, and Text-Davinci"
date:   2023-07-15 10:00:00 -0500
categories: [machine-learning]
tags: [nlp, supervised-learning, pytorch, transformers, bert, openai, gpt-3, snli, textual-entailment]
math: true
toc: true
img_path: /assets/img/posts/
---
During my time at Georgia Tech, one of the datasets I found most interesting for projects was the Stanford Natural Language Inference (SNLI) dataset[^1]. This particular dataset consists of 570k sentence pairs, each labeled with an inferential relationship: neutral, contradiction, or entailment.

Although we may often take for granted our own ability to recognize these inferential connections (even when our judgment fails us), the task of enabling computers to discern such relationships is challenging. For instance, any proficient English speaker would intuitively recognizes that "A man inspects the uniform of a figure in some East Asian country." contradicts "The man is sleeping". Yet training a computer to do the same requires significant effort.

Since this task is so fundamental to using language, the capacity for NLP systems to accurately identify inferential relationships is highly valuable and has widespread application in many domains and more complex NLP tasks. The below experiments compare OpenAI's `text-davinci-002` performance on the textual entailment task with Naive Bayes classifier and a simple neural network with one hidden layer.

## Model Design

Training the Naive Bayes classifier requires vectorizing the sentence pairs, i.e. turning the text into a vector real numbers. A commonly used method of vectorizing text for classification tasks is TF-IDF (term frequency-inverse document frequency). TF-IDF is better than using a straightforward bag-of-words, i.e. word frequency, because the combination of the word frequency and its inverse frequency across all documents allows TF-IDF to identify those words that best discriminate amongst the documents.

The underlying assumption of the Naive Bayes model is that each pair of words in the TF-IDF vectorization is conditionally independent given the inferential relationship.  Although this assumption may oversimplify the textual entailment task, the model is a good benchmark to compare OpenAI and the neural network agaisnt. I only kept the most significant 2000 features identified by the TF-IDF. Limiting the feature set helps reduce noise and emphasizes the most important features.

The neural network model is more complex. It consists of an input layer, one hidden layer, and an output layer, each separated by a Rectified Linear Unit (ReLU) activation function:

```python
self.module_list = [
	nn.Linear(768, 50),
	nn.ReLU(),
	nn.Linear(50, 50),
	nn.ReLU(),
	nn.Linear(50, 3)
]
```

I used the BERT model to generate word embeddings for vectorizing the text for the neural network.

Preprocessing the text had several steps. First, the text is tokenized, i.e. broken into an array of subwords for the BERT model. Next, token type IDs are created to differentiate between the two sentences. Then, I retrieved the token IDs, or unique identifiers, from the BERT model's vocabulary to numerically represent the text. Finally, an attention mask is created to indicate which tokens the model should focus on. Also, sequences longer than the specified maximum length of 128 were truncated, while shorter sequences were padded with zeros.

Here is an example preprocessing a sentence pair from the training dataset:
```
# sentence pair sequence after tokenization
['[CLS]', 'this', 'church', 'choir', 'sings', 'to', 'the', 'masses', 'as', 'they', 'sing', 'joy', '##ous', 'songs', 'from', 'the', 'book', 'at', 'a', 'church', '.', '[SEP]', 'the', 'church', 'has', 'cracks', 'in', 'the', 'ceiling', '.', '[SEP]']

# token ids
[101, 101, 2023, 2277, 6596, 10955, 2000, 1996, 11678, 2004, 2027, 6170, 6569, 3560, 2774, 2013, 1996, 2338, 2012, 1037, 2277, 1012, 102, 1996, 2277, 2038, 15288, 1999, 1996, 5894, 1012, 102, 102, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# attention  mask
[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

# token type ids
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

The token IDs, attention mask, and token type IDs are fed into the BERT model to get the word embeddings. These embeddings are extracted from the last hidden state of the output returned by the BERT model. However, this last hidden state is a tensor with the shape `[batch_size, sequence_length, hidden_size]` and we need a single embedding for each sentence pair. I used average pooling to find the mean score for each pair of sentences over the sequence length to produce this single embedding. Ultimately, the size of the embedding for each pair of sentences is 768.

Here is an example of generating the embedding. We use `no_grad` because the weights of the network are not going to get updated and computation graph does not need to be stored:
```python
with torch.no_grad():
	outputs = self.model(
	  input_ids=input_tensor,
	  attention_mask=attn_mask,
	  token_type_ids=tkn_type
	)

embeddings = outputs.last_hidden_state
embeddings = torch.mean(embeddings, dim=1)
```

The setup for the last model, OpenAI's text-davinci-002, is straightforward. I wrote a simple prompt for the textual entailment task. The temperature, frequency penalty, and presence penalty are all set to zero.
```
Does the premise entail, contradict, or have no relationship to the hypothesis? Label the sentence pair as contradiction, entailment, or neutral.
###
premise: {premise}
hypothesis: {hypothesis}
###
Label:
```

## Results

The neural network model had the highest accuracy and outperformed the Naive Bayes classifier and the `text-davinci-002` model on most metrics with a few interesting exceptions. This outcome makes sense given a couple inherent disadvantages of the other models.

The Naive Bayes classifier relies on the assumption of conditional independence among features. This assumption oversimplifies the contextual information within each sentence pair by disregarding word relationships.

The `text-davinci-002` model does not make the same assumption because of the self-attention layers in its transformer architecture. These self-attention layers enable the model to consider word context and relationships of words across the sequence of words.

However, unlike the neural network, the `text-davinci-002` model was not trained on the SNLI dataset and did not have the opportunity to make weight updates to directly model the patterns within the data. Rather, it was simply used for inference by feeding it the prompt with the sentence pair.

The simple neural network, on the other hand, was trained on the SNLI dataset using the BERT-generated embeddings as features. This enabled the neural network to directly learn the intricate relationships among words in the sentence pairs.

|                  | Davinci |        |          | NN |        |          | NBayes  |        |          |         |
| ---------------- | ---------------- | ------ | -------- | -------------- | ------ | -------- | ------------ | ------ | -------- | ------- |
|                  | **precision**        | **recall** | **f1** | **precision**      | **recall** | **f1** | **precision**    | **recall** | **f1** | **support** |
| contradiction    | 0.9              | 0.42   | 0.57     | 0.75           | 0.72   | 0.74     | 0.51         | 0.46   | 0.48     | 3237    |
| entailment       | 0.6              | 0.84   | 0.7      | 0.69           | 0.83   | 0.76     | 0.48         | 0.58   | 0.52     | 3368    |
| neutral          | 0.35             | 0.39   | 0.37     | 0.73           | 0.6    | 0.66     | 0.52         | 0.46   | 0.49     | 3219    |
| accuracy         |                  |        | 0.55     |                |        | 0.72     |              |        | 0.5      | 9824    |
| macro avg        | 0.62             | 0.55   | 0.55     | 0.73           | 0.72   | 0.72     | 0.5          | 0.5    | 0.5      | 9824    |
| wghtd avg     | 0.62             | 0.55   | 0.55     | 0.73           | 0.72   | 0.72     | 0.5          | 0.5    | 0.5      | 9824    |

The Naive Bayes classifier scored an accuracy of 50% on the test dataset. This result isn't impressive, but beats a random classifier. A more interesting observation is the fact that it performs similarly on each the entailment labels. This result is due to the lack context modeling in the feature set generated by the TF-IDF scores.

The `text-davinci-002` scored a slightly higher accuracy of 55%, but its performance on each of the labels is much less balanced than the Naive Bayes classifier. The model scored very high accuracy when identifying positive instances of contradiction samples and outperformed the other models at identifying all the positive instances of entailment. However, the model struggled with neutral samples. Overall, the `text-davinci-002` model was extremely precise about labeling samples as contradictory while somewhat liberal in labeling samples as entailment.

Finally, the simple neural network scored the highest accuracy at 72%. The model's F1 scores show that neural network, with relatively little tuning, learned best how to correctly identify samples of each of the entailment types.


![confusion_matrices](confusion_matrices.png){: w="1000" }

## Final Thoughts

The performance of these toy models has some ground to cover in order to reach the state-of-the-art results on the SNLI dataset. Several models have achieved accuracy levels surpassing 90% on the test SNLI dataset for the textual entailment task.

Many of these high-performing models leverage a combination of foundational models like BERT along with additional features. Foundational language models such as BERT exhibit impressive performance on the SNLI dataset when fine-tuned. However, despite their ability to capture contextual word information, they may overlook other important linguistic features.

For instance, SemBERT combines the BERT model with contextual semantic information and achieves 91.1% accuracy on SNLI's test dataset[^2]. Likewise, other foundational models could be paired with additional feature engingeering or processing to enhance performance on the textual entailment task.

The code the experiments can be found [here](https://github.com/jwplatta/textual_entailment).

## References

[^1]: Bowman, Samuel R., et al. "A Large Annotated Corpus for Learning Natural Language Inference." ArXiv:1508.05326 [Cs], 21 Aug. 2015, arxiv.org/abs/1508.05326.
[^2]: Zhang, Zhuosheng, et al. "Semantics-Aware BERT for Language Understanding." ArXiv.org, 4 Feb. 2020, arxiv.org/abs/1909.02209. Accessed 15 July 2023.