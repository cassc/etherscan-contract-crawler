/*
     ____.  _____ _____________________    _____  .___ 
    |    | /  _  \\______   \__    ___/   /  _  \ |   |
    |    |/  /_\  \|       _/ |    |     /  /_\  \|   |
/\__|    /    |    \    |   \ |    |    /    |    \   |
\________\____|__  /____|_  / |____| /\ \____|__  /___|
                 \/       \/         \/         \/     


Transform words into stunning art 

Website: https://jart.ai/
Twitter: https://twitter.com/jart_ai
Telegram: https://t.me/jart_ai

Total supply: 420,690,000 tokens
Tax: 4% (1% - LP, 1% - operational costs, 2% marketing)
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract JartAiConfig {
    mapping(address => bool) public isExcludedFromSwapFee;
    address public marketingWallet;
    address public owner;

    // initial values, sniper protection
    uint256 public marketingFee = 45;
    uint256 public liquidityFee = 45;
    uint256 public constant FEE_DENOMINATOR = 100;

    uint256 public minAmountForMarketing;
    uint256 public minAmountForLiquidity;

    constructor() {
        owner = msg.sender;
        marketingWallet = msg.sender;
    }

    function setExcludeFromSwapFee(
        address[] calldata users,
        bool excludedFromSwapFee
    ) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            isExcludedFromSwapFee[users[i]] = excludedFromSwapFee;
        }
    }

    function setMarketingWallet(address wallet) external onlyOwner {
        marketingWallet = wallet;
    }

    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
    }

    function setFees(uint256 _marketingFee, uint256 _liquidityFee)
        external
        onlyOwner
    {
        marketingFee = _marketingFee;
        liquidityFee = _liquidityFee;
    }

    function setMinAmounts(
        uint256 _minAmountForMarketing,
        uint256 _minAmountForLiquidity
    ) external onlyOwner {
        minAmountForMarketing = _minAmountForMarketing;
        minAmountForLiquidity = _minAmountForLiquidity;
    }

    // ACL

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}