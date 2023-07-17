// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WhiteRock is ERC20, Ownable {
 
    bool private _construction;
    uint256 private TEAM_PERCENTAGE = 35;
    uint256 private MARKET_PERCENTAGE = 35;
    uint256 private TOTAL_SUPPLY = 235_200_000_000 ether; 
    bool private _limitBuyEnabled = true;
    uint256 private _maxWalletPercentage = 5;
    uint256 private _maxTransferPercentage = 5;
    address private _uniswapPair;
    address private _teamAddress;
    address private _marketingAddress;      

    constructor(address teamAddress, address marketAddress) ERC20("WhiteRock", "WHITEROCK") {

        _construction = true;
        uint256 devFee = (TOTAL_SUPPLY * TEAM_PERCENTAGE) / 1000;
        uint256 marketingFee = (TOTAL_SUPPLY * MARKET_PERCENTAGE) / 1000;
        _marketingAddress = marketAddress;
        _teamAddress = teamAddress;
        _mint(teamAddress, devFee);
        _mint(marketAddress, marketingFee);
        _mint(msg.sender, TOTAL_SUPPLY - devFee - marketingFee);
        _construction = false;
    }    

    function _isUniswap(address pair) private view returns (bool) {
        return pair == _uniswapPair;
    }

    function _isOwnerAddress(address from, address to) private view returns (bool) {
        return from == owner() || to == owner() || from == _marketingAddress || to == _marketingAddress || from == _teamAddress || to == _teamAddress;
    }

    function _beforeTokenTransfer(
            address from,
            address to,
            uint256 amount
        ) override internal virtual {

        if(_construction){
            return;
        }

        if(_isOwnerAddress(from, to)){
            return;
        }

        if (_uniswapPair == address(0)) {
            require(_isOwnerAddress(from, to), "Trading not activated, please stand by");
            return;
        }

        bool buy = _isUniswap(from);
        bool sell = _isUniswap(to);

        if (_limitBuyEnabled && (buy || sell)){
            uint256 maxWhaleTransferAllowance = (TOTAL_SUPPLY * _maxTransferPercentage) / 100;
            require(amount <= maxWhaleTransferAllowance, "Cannot buy or sell that many tokens in one go");
        }
        
        if(_limitBuyEnabled && buy){
            uint256 whaleMaxWalletAllowance = (TOTAL_SUPPLY * _maxWalletPercentage) / 100;
            require(super.balanceOf(to) + amount <= whaleMaxWalletAllowance, "Cannot buy more WHITEROCK tokens with address");
        }
    }

    function disableLimitBuy() external onlyOwner {
        _limitBuyEnabled = false;
    }

    function setMaxBuyAndSell(uint256 maxWalletPercentage, uint256 maxTransferPercentage) external onlyOwner {
        _maxTransferPercentage = maxTransferPercentage;
        _maxWalletPercentage = maxWalletPercentage;
    }

    function setUniswapPair(address uniswapPair) external onlyOwner {
        _uniswapPair = uniswapPair;
    }
}