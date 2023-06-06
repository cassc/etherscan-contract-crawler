/**
YUNA TOKEN

https://t.me/yuna_eth
https://yunatoken.io

**/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YunaToken is Ownable, ERC20 {
    // Anti Bear settings
    bool private antiBear = true;
    uint256 public antiBearThreshold = 25; // bips
    uint256 public antiBearInterval = 86400; // 1 day
    mapping(address => uint256) public sellTime;
    mapping(address => uint256) public soldAmount;
    mapping(address => bool) public isAmm;
    address public uniswapPool;

    // Anti MEV settings
    bool paused = true;
    uint256 public minHoldingAmount;

    // Admin settings
    mapping(address => bool) public whitelist;

    constructor(
        uint256 _totalSupply
    ) ERC20("Yuna Token (YunaToken.io)", "YUNA") {
        whitelistAddr(msg.sender, true);
        _mint(msg.sender, _totalSupply);
    }

    function whitelistAddr(
        address _address,
        bool _isWhitelisted
    ) public onlyOwner {
        whitelist[_address] = _isWhitelisted;
    }

    function setUniswap(
        address _uniswapPool,
        bool _isAmm
    ) public onlyOwner {
        uniswapPool = _uniswapPool;
        isAmm[_uniswapPool] = _isAmm;
    }

    function setBearRules(
        bool _isAntiBear,
        uint256 _antiBearThreshold,
        uint256 _antiBearInterval
    ) external onlyOwner {
        antiBear = _isAntiBear;
        antiBearThreshold = _antiBearThreshold;
        antiBearInterval = _antiBearInterval;
    }

    function setMevRules(
        bool _paused,
        uint256 _minHoldingAmount
    ) public onlyOwner {
        paused = _paused;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Alow owner / whitelisted addresses to add liquidity
        if (whitelist[from] || whitelist[to]){
            return;
        }

        // prevent MEV
        require(
            super.balanceOf(from) - amount >= minHoldingAmount,
            "Forbidden"
        );
        require(!paused, "Trading Paused");

        // prevent anti-bear
        // if not AMM (ie. not a buy)
        if (!(isAmm[from])) {
            if (antiBear) {

                // 24h elapsed since last sell
                if (sellTime[from] < block.timestamp - antiBearInterval) {
                    require(
                        amount <= _antiBearLimit(),
                        "YunaToken: Transfer exceeds antiBear limit"
                    );
                    sellTime[from] = block.timestamp;
                    soldAmount[from] = amount;
                } else {
                    // enforce 24h limit
                    soldAmount[from] = amount + soldAmount[from];
                    require(
                        soldAmount[from] <= _antiBearLimit(),
                        "YunaToken: Transfer exceeds 24h limit"
                    );
                }
            }
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function _antiBearLimit() internal view returns (uint256) {
        /** using simple balanceOf to get balance from one pool **/
        uint256 poolBalance = super.balanceOf(uniswapPool);
        return (antiBearThreshold * poolBalance) / 10000;
    }
}