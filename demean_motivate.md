---
title: "Motivating Demeaning Approach"
author: "Ragip Gurlek"
date: "11/2/2020"
output:
  bookdown::pdf_document2:
    keep_md: true
---



This document analytically motivates demeaning of variables in the Yelp dataset that I use for my *Price Placebo Effect* project. The project investigates if consumers' experience with a more expensive restaurant is better even if the restaurant is similar to its competitors in other dimensions. To address the inherent endogeneity in the problem, I use Tax as an instrumental variable (IV). I also demean the variables by their *local means*^[Local in geographical proximity.] to eliminate the bias introduces by location. I assume the Directed Acyclic  Graph (DAG) in Figure \@ref(fig:dag1) captures the causal relationship.

\begin{figure}
\includegraphics[width=5.14in]{dag1} \caption{Causal Relationship of Variables}(\#fig:dag1)
\end{figure}

This graph implies the following structural equation model

\begin{align*}
\text { Tax } &=f(\text { Location }) \\
U &= m(\text { Location }) +\varepsilon_{1} \\
\text { Price } &= g(\text { Location }) + \alpha_1 \text { Tax } + \gamma_{1} U+\varepsilon_{2} \\
&=g(\text { Location }) + \alpha_1 f(\text { Location }) + \gamma_{1} m(\text { Location }) + \gamma_1 \varepsilon_1 + \varepsilon_{2} \\
\text { Satistaction }&=\alpha_2 \text { price } + h(\text { Location }) +\gamma_{2} U + \varepsilon_{3} \\
&=\alpha_2 g(\text { Location }) + \alpha_2\alpha_1 f(\text { Location }) + \alpha_2 \gamma_{1} m(\text { Location }) + \alpha_2 \gamma_1  \varepsilon_1 + \alpha_2 \varepsilon_{2} \\
 &+h(\text { Location }) + \gamma_{2} m(\text { Location }) + \gamma_2 \varepsilon_1 + \varepsilon_{3}
\end{align*}

Let
\begin{align*}
\overline{\text {Satistaction}_i} &= E[\text {Satistaction} | \text {Location} \in \ell_i(\epsilon)] \\
&= \left(\alpha_2\alpha_1\alpha_3+\alpha_2\alpha_4+\alpha_5\right) E[\text {Location}| \text {Location} \in \ell_i(\epsilon)] + \left(\alpha_2 \gamma_{1}+\gamma_{2}\right) E[U| \text {Location} \in \ell_i(\epsilon)] \\
\widetilde{\text {Satistaction}}_i &= \text {Satistaction}_i -  \overline{\text {Satistaction}_i}\\
&\approx \alpha_2 \alpha_1 \varepsilon_{1}+\left(\alpha_2 \gamma_{1}+\gamma_{2}\right) \tilde{U}+\alpha_2 \varepsilon_{2}+\varepsilon_{3}
\end{align*}
where $\ell_i$ is the $\epsilon$-ball around the actual location of the observation. Therefore, the approximation gets better for smaller $\epsilon$.

Similarly,
\begin{align*}
\widetilde{\text {Tax}}_i &= \text {Tax}_i -  \overline{\text {Tax}_i}\\
&\approx \varepsilon_{1} \\
\widetilde{\text {Price}}_i &= \text {Price}_i -  \overline{\text {Price}_i}\\
&\approx \alpha_1 \varepsilon_{1}+ \gamma_{1} \tilde{U}+\varepsilon_{2}
\end{align*}

Therefore, we can approximate the DAG in Figure \@ref(fig:dag1) with the one in Figure \@ref(fig:dag2).
\begin{figure}
\includegraphics[width=4.9in]{dag2} \caption{Alternative Causal Relationship}(\#fig:dag2)
\end{figure}

This analysis implies we can employ two approaches. First, we can use the DAG in Figure \@ref(fig:dag2) and estimate a weighted local average for each variable to demean it. Then, we can estimate the effect with 2SLS.

Alternatively, we can directly estimate a 2SLS where we use cluster fixed-effects as an approximation to Location to control it. The DAG in Figure \@ref(fig:dag1) shows that Location is the sufficient set to identify the effects of Tax on both Price and Satisfaction.
