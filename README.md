# Savings Account Smart Contract

A Clarity-based smart contract for the Stacks blockchain that enables users to deposit STX, earn interest, and withdraw their funds with accrued returns.

## Features

- **Deposit STX**: Store STX in the contract and begin earning interest immediately
- **Variable Interest Accrual**: Interest compounds based on block height (5% annualized)
- **Flexible Withdrawals**: Withdraw principal + interest or interest only
- **Principal Preservation**: `claim-interest()` lets you withdraw earnings while keeping your deposit intact
- **Real-time Queries**: Check deposit balance and accrued interest at any time

## Smart Contract Overview

| Function | Type | Description |
|----------|------|-------------|
| `deposit(amount)` | Public | Deposit STX and start earning interest |
| `withdraw(amount)` | Public | Withdraw STX (principal + interest combined) |
| `claim-interest()` | Public | Withdraw only earned interest, keep principal |
| `get-deposit(user)` | Read-only | View deposit amount and last update block |
| `get-accrued-interest(user)` | Read-only | Calculate current accrued interest |

## Interest Rate

- **Annual Rate**: 5% APY
- **Per-Block Rate**: 0.000238% (approximately 238 per 100,000,000)
- **Calculation**: `interest = blocks_passed × amount × rate / denominator`

## Error Codes

| Code | Constant | Reason |
|------|----------|--------|
| u100 | `ERR_INSUFFICIENT_BALANCE` | Withdrawal exceeds available balance |
| u101 | `ERR_ZERO_AMOUNT` | Invalid zero or negative amount |

