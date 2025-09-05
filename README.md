# ♻️ Recycling Rewards DApp

A blockchain-based incentive system that rewards users for verified recycling actions using Clarity smart contracts on the Stacks blockchain.

## 🌟 Features

- 📝 **User Registration**: Register as a recycling participant
- 🏢 **Recycling Centers**: Authorized centers can verify recycling actions
- 🎯 **Action Submission**: Submit recycling actions with material type and weight
- ✅ **Verification System**: Centers verify submitted recycling actions
- 💰 **Automatic Rewards**: Verified actions trigger automatic STX rewards
- 🏆 **Reputation System**: Build reputation through consistent recycling
- 📊 **Material-based Rewards**: Different materials have different reward multipliers

## 🚀 Getting Started

### Prerequisites

- Clarinet CLI installed
- Stacks wallet for testing

### Installation

```bash
clarinet new recycling-rewards-project
cd recycling-rewards-project
```

Copy the contract code to `contracts/recycling-rewards.clar`

### Testing

```bash
clarinet console
```

## 📋 Usage Instructions

### For Users

1. **Register as User**
```clarity
(contract-call? .recycling-rewards register-user)
```

2. **Submit Recycling Action**
```clarity
(contract-call? .recycling-rewards submit-recycling-action "plastic" u500 "hash123abc")
```

3. **Check Your Profile**
```clarity
(contract-call? .recycling-rewards get-user-profile tx-sender)
```

### For Contract Owner

1. **Register Recycling Center**
```clarity
(contract-call? .recycling-rewards register-recycling-center "EcoCenter Downtown" "123 Green St")
```

2. **Fund Contract**
```clarity
(contract-call? .recycling-rewards fund-contract)
```

3. **Update Reward Rate**
```clarity
(contract-call? .recycling-rewards update-reward-rate u15)
```

### For Recycling Centers

1. **Verify Actions**
```clarity
(contract-call? .recycling-rewards verify-recycling-action u1)
```

## 🎁 Reward System

### Material Multipliers
- 📄 **Paper**: 1x base reward
- 🥤 **Plastic**: 2x base reward  
- 🍶 **Glass**: 3x base reward
- 🔩 **Metal**: 4x base reward

### Reputation Levels
- 🥉 **Bronze**: 100+ reputation points
- 🥈 **Silver**: 500+ reputation points
- 🥇 **Gold**: 1000+ reputation points

## 🔧 Contract Functions

### Public Functions
- `register-user()` - Register as a new user
- `register-recycling-center()` - Register authorized recycling center
- `submit-recycling-action()` - Submit new recycling action
- `verify-recycling-action()` - Verify submitted action
- `distribute-reward()` - Distribute STX rewards
- `update-reward-rate()` - Update base reward rate
- `fund-contract()` - Add funds to contract

### Read-Only Functions
- `get-user-profile()` - Get user statistics
- `get-recycling-action()` - Get action details
- `get-contract-stats()` - Get overall contract statistics
- `calculate-reward()` - Calculate reward for given weight/material
- `get-user-reputation()` - Get user reputation score

## 🌍 Environmental Impact

This DApp encourages recycling by:
- 💚 Providing financial incentives for recycling
- 📈 Tracking recycling metrics transparently
- 🏅 Gamifying environmental responsibility
- 🤝 Building community around sustainability

## 🛠️ Development

### Contract Structure
- User profiles with reputation tracking
- Recycling center authorization system
- Action verification workflow
- Automated reward distribution
- Material-based reward calculation

### Security Features
- Owner-only administrative functions
- Center authorization requirements
- Action verification before rewards
- Input validation and error handling

## 📊 Statistics Tracking

The contract tracks:
- Total recycling actions submitted
- Total rewards distributed
- Individual user statistics
- Recycling center performance
- Material type distributions

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Test thoroughly with Clarinet
4. Submit pull request

## 📄 License

MIT License - Feel free to use and modify for environmental good! 🌱
```

**Git Commit Message:**
```
feat: implement recycling rewards MVP with user registration, action verification, and STX incentives
```

**GitHub Pull Request Title:**
```
🚀 Add Recycling Rewards DApp MVP - Blockchain Incentives for Environmental Action
```

**GitHub Pull Request Description:**
```
## 🌟 What's Added

This PR introduces a complete Minimum Viable Product for the Recycling Rewards DApp - a blockchain-based system that incentivizes recycling through verified smart contract rewards.

### ✨ Key Features Implemented

- **User Management System**: Registration and profile tracking with reputation scores
- **Recycling Center Authorization**: Admin-controlled center registration and verification rights  
- **Action Submission Workflow**: Users can submit recycling actions with material type and weight
- **Verification & Rewards**: Authorized centers verify actions triggering automatic STX rewards
- **Material-Based Incentives**: Different reward multipliers for plastic, glass, metal, and paper
- **Reputation System**: Gamified experience with Bronze/Silver/Gold levels
- **Contract Statistics**: Comprehensive tracking of all recycling metrics

### 🔧 Technical Implementation

- **150+ lines** of clean, production-ready Clarity code
- **Comprehensive error handling** with descriptive error codes
- **Gas-optimized** map structures for efficient data storage
- **Role-based access control** for administrative functions
- **Input validation** and security checks throughout

### 📋 Files Added

- `contracts/recycling-rewards.clar` - Main smart contract implementation
- `README.md` - Complete documentation with usage examples and emoji-enhanced formatting

### 🧪 Ready for Testing

The contract is fully functional and ready for Clarinet testing. All core recycling reward workflows are implemented and can be tested immediately.

This MVP provides a solid foundation for incentivizing real-world environmental action through blockchain technology! ♻️
