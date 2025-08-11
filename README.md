# 🤖 AI Training Dataset Tokenization

🎯 **Democratizing AI training data through blockchain-based licensing and access control**

[![Clarity](https://img.shields.io/badge/Clarity-3.0-blue.svg)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Bitcoin_L2-orange.svg)](https://stacks.co/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🌟 Overview

Transform how AI training datasets are shared, licensed, and monetized! This smart contract enables dataset creators to tokenize their data assets and control access through flexible licensing mechanisms.

### ✨ Key Features

- 📦 **Dataset Tokenization**: Mint unique tokens representing AI training datasets
- 💰 **Flexible Licensing**: Commercial and research license tiers with custom pricing
- 🔐 **Access Control**: Time-based licenses with usage quotas
- 💸 **Revenue Sharing**: Automatic earnings distribution to dataset creators
- 📊 **Usage Tracking**: Monitor dataset access and download statistics
- ⏰ **License Extensions**: Extend existing licenses with prorated pricing

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) installed
- [Stacks wallet](https://www.hiro.so/wallet) for testing

### Installation

```bash
git clone <your-repo>
cd ai-training-dataset-tokenization
clarinet check
```

### 🔧 Deploy Contract

```bash
clarinet deploy --network=testnet
```

## 📖 Usage Guide

### 🏗️ For Dataset Creators

#### 1. Mint a Dataset Token

```clarity
(contract-call? .ai-training-dataset-tokenization mint-dataset
  "ImageNet-2024"
  "High-quality labeled images for computer vision training"
  u50000  ;; 50GB dataset
  0x1234567890abcdef...  ;; Dataset hash
  u1000000  ;; Commercial price (10 STX)
  u100000)  ;; Research price (1 STX)
```

#### 2. Monitor Earnings

```clarity
(contract-call? .ai-training-dataset-tokenization get-creator-earnings tx-sender)
```

#### 3. Withdraw Earnings

```clarity
(contract-call? .ai-training-dataset-tokenization withdraw-earnings)
```

### 🎓 For Researchers & Companies

#### 1. Purchase a License

```clarity
;; Research license for 30 days (4320 blocks ≈ 30 days)
(contract-call? .ai-training-dataset-tokenization purchase-license
  u1  ;; Dataset ID
  "research"
  u4320)  ;; Duration in blocks

;; Commercial license
(contract-call? .ai-training-dataset-tokenization purchase-license
  u1
  "commercial"
  u4320)
```

#### 2. Access Dataset

```clarity
(contract-call? .ai-training-dataset-tokenization access-dataset u1)
```

#### 3. Extend License

```clarity
(contract-call? .ai-training-dataset-tokenization extend-license
  u1      ;; Dataset ID
  u2160)  ;; Additional 15 days
```

## 🔍 Smart Contract Functions

### 📝 Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `mint-dataset` | 🎨 Create new dataset token | name, description, size, hash, commercial-price, research-price |
| `purchase-license` | 💳 Buy access license | dataset-id, license-type, duration-blocks |
| `access-dataset` | 📁 Download/access dataset | dataset-id |
| `extend-license` | ⏱️ Extend existing license | dataset-id, additional-blocks |
| `withdraw-earnings` | 💰 Withdraw creator earnings | none |

### 👀 Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-dataset` | 📋 Get dataset details | Dataset info |
| `get-license` | 🎫 Get license details | License info |
| `get-user-licenses` | 📑 Get user's licenses | List of dataset IDs |
| `check-license-validity` | ✅ Check if license is active | Boolean |
| `get-creator-earnings` | 💵 Get creator's earnings | Amount in microSTX |

## 💡 License Types

### 🔬 Research License
- ✅ Academic and non-commercial use
- 📊 Limited usage quota (100 accesses)
- 💰 Lower pricing tier
- 🎓 Perfect for universities and researchers

### 🏢 Commercial License
- ✅ Full commercial rights
- 📈 Higher usage quota (1000 accesses)
- 💼 Enterprise pricing
- 🚀 Ideal for AI companies and startups

## 📊 Economics

### 💰 Platform Fee
- **2.5%** platform fee on all transactions
- Supports platform development and maintenance
- Transparent fee structure

### 🔄 Revenue Distribution
- **97.5%** to dataset creators
- **2.5%** platform fee
- Automatic distribution on purchase

## 🛡️ Security Features

- ✅ **Access Control**: Only licensed users can access datasets
- ⏰ **Time-based Expiry**: Licenses automatically expire
- 📊 **Usage Quotas**: Prevent abuse with download limits
- 🔐 **Hash Verification**: Ensure data integrity
- 💳 **Secure Payments**: STX-based transactions

## 🧪 Testing

```bash
# Run all tests
clarinet test

# Check contract syntax
clarinet check

# Interactive console
clarinet console
```

### 🔬 Example Test Scenarios

```clarity
;; Test dataset creation
(contract-call? .ai-training-dataset-tokenization mint-dataset 
  "Test Dataset" "Description" u1000 0x1234 u500000 u50000)

;; Test license purchase
(contract-call? .ai-training-dataset-tokenization purchase-license u1 "research" u4320)

;; Test access
(contract-call? .ai-training-dataset-tokenization access-dataset u1)
```

## 🎯 Use Cases

### 🎓 Academic Research
- Share research datasets with proper attribution
- Control access to sensitive research data
- Generate funding for dataset maintenance

### 🏢 Commercial AI Training
- Monetize proprietary training datasets
- License data for specific use cases
- Track dataset usage and ROI

### 🤝 Data Collaboratives
- Create shared data pools for industry
- Implement fair usage policies
- Distribute revenue among contributors

## 🔮 Future Enhancements

- 📊 **Analytics Dashboard**: Detailed usage analytics
- 🎨 **NFT Integration**: Visual dataset representations
- 🔗 **Cross-chain Support**: Multi-blockchain compatibility
- 🤖 **AI Model Licensing**: Extend to trained model licensing
- 📱 **Mobile SDK**: Easy integration for mobile apps

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♀️ Support

- 📧 **Email**: support@ai-dataset-token.com
- 💬 **Discord**: [Join our community](https://discord.gg/example)
- 📖 **Docs**: [Full Documentation](https://docs.ai-dataset-token.com)
- 🐛 **Issues**: [GitHub Issues](https://github.com/your-repo/issues)

---

<div align="center">

**🌟 Star this repo if you found it helpful! 🌟**

*Built with ❤️ for the AI community*

</div>
