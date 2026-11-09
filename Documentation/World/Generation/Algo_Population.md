

This document describes the algorithm for Victoria's population generation.

## 1. Set Minimum Population Size

The population of Victoria has a baseline of 1000 people it cannot go under.

## 2. Determine Social Class Distribution

The social class distribution is done by assigning statuses to people by using the population composition rules found in **"Population Composition.md".

## 3. Determine Family Demography 

Use the probability table's data found in **"Community Profiles",** To group families with sizes respecting their social class's date on family size.

## 4. Generate Family Dynamics

Allocate family surnames by using the pool of available surnames per class to name the generated families.

## 5. Generate Citizens within family

- Generate individual profiles within the families.
- Allocate 2 family authorities. 1 male, 1 female. 
- Determine the utmost family authority through a 7/10 weight for males and 3/10 weight for females.
- For oligarchs assign the title to the utmost family authority.

## 6.Generate Solitary Citizens

Generate individual profiles for the individuals in Victoria without families.

## 7. Generate a Validation Report

verify population distribution, family structure, titles and IDs.
