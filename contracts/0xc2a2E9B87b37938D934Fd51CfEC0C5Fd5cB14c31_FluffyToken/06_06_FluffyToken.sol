// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract FluffyToken is ERC20, Ownable {
    uint256 public immutable percentageBase;
    address public taxReceiver;
    address public rewardsPool;

    mapping(address => bool) public blacklisted;
    mapping(address => bool) public isDexPair;
    mapping(address => bool) public isFluffyContract;
    mapping(address => bool) public disabledFluffyAllowance;
    mapping(address => uint256) public lastSwap;

    bool public holdersPurchaseEnabled;

    uint256 public sellTax;
    uint256 public maxTx;
    uint256 public cooldown;
    uint256 public maxWallet;

    uint256 public sellTaxUpperLimit;
    uint256 public maxTxLowerLimit;
    uint256 public cooldownUpperLimit;
    uint256 public maxWalletLowerLimit;


    modifier notBlacklisted(address _address) {
        require(!blacklisted[_address], "BLACKLISTED");
        _;
    }

    constructor(
        address _rewardsPool,
        address _teamWallet,
        address _taxReceiver,
        uint256 _totalSupply,
        uint256 _sellTaxUpperLimit,
        uint256 _maxTxLowerLimit,
        uint256 _cooldownUpperLimit,
        uint256 _maxWalletLowerLimit
    ) ERC20("FLUFFY TOKEN", "$FLUFFY") Ownable() {
        isFluffyContract[_rewardsPool] = true;
        isFluffyContract[_teamWallet] = true;
        isFluffyContract[_taxReceiver] = true;

        uint256 teamWalletAlloc = 504300 ether;
        uint256 rewardsPoolAlloc = _totalSupply - teamWalletAlloc;

        _mint(_teamWallet, teamWalletAlloc);
        _mint(_rewardsPool, rewardsPoolAlloc);

        percentageBase = 100_000;
        rewardsPool = _rewardsPool;
        taxReceiver = _taxReceiver;

        holdersPurchaseEnabled = true;

        sellTaxUpperLimit = _sellTaxUpperLimit;
        maxTxLowerLimit = _maxTxLowerLimit;
        cooldownUpperLimit = _cooldownUpperLimit;
        maxWalletLowerLimit = _maxWalletLowerLimit;
    }

    function enableFluffyAllowance() external {
        disabledFluffyAllowance[msg.sender] = false;
    }

    function disableFluffyAllowance() external {
        disabledFluffyAllowance[msg.sender] = true;
    }

    function increaseRewardsPoolBalance(uint256 _amount) external {
        require(msg.sender == rewardsPool, "FluffyToken: ONLY REWARDS POOL");
        _mint(msg.sender, _amount);
    }

    function blacklistWallet(address _address) external onlyOwner {
        blacklisted[_address] = true;
    }

    function unBlacklistWallet(address _address) external onlyOwner {
        blacklisted[_address] = false;
    }

    function setDexPair(address _dexPair) external onlyOwner {
        isDexPair[_dexPair] = true;
    }

    function removeDexPair(address _dexPair) external onlyOwner {
        isDexPair[_dexPair] = false;
    }

    function setFluffyContract(address _fluffyContract) external onlyOwner {
        isFluffyContract[_fluffyContract] = true;
    }

    function removeFluffyContract(address _fluffyContract) external onlyOwner {
        isFluffyContract[_fluffyContract] = false;
    }

    function disableHoldersPurchase() external onlyOwner {
        holdersPurchaseEnabled = false;
    }

    function setSellTax(uint256 _sellTax) external onlyOwner {
        require(_sellTax <= sellTaxUpperLimit, "FluffyToken: SELL TAX TOO HIGH");
        sellTax = _sellTax;
    }

    function setMaxTx(uint256 _maxTx) external onlyOwner {
        require(_maxTx >= maxTxLowerLimit, "FluffyToken: MAX TX TOO LOW");
        maxTx = _maxTx;
    }

    function setCooldown(uint256 _cooldown) external onlyOwner {
        require(_cooldown <= cooldownUpperLimit, "FluffyToken: COOLDOWN TOO HIGH");
        cooldown = _cooldown;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet >= maxWalletLowerLimit, "FluffyToken: MAX WALLET TOO LOW");
        maxWallet = _maxWallet;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            !isFluffyContract[from] && 
            !isFluffyContract[to] &&
            from != address(0) &&
            to != address(0)
        ) {
            require(amount <= maxTx, "FluffyToken: MAX TX AMOUNT EXCEEDED");
        }

        if (
            !isDexPair[to] &&
            !isFluffyContract[to]
        )
            require(balanceOf(to) + amount <= maxWallet, "FluffyToken: MAX WALLET AMOUNT EXCEEDED");

        if (
            isDexPair[from] &&
            !isDexPair[to] &&
            !isFluffyContract[to]
        ) {
            require(block.timestamp - lastSwap[to] >= cooldown, "FluffyToken: COOLDOWN NOT MET");
            lastSwap[to] = block.timestamp;
        } else if (
            isDexPair[to] &&
            !isDexPair[from] && 
            !isFluffyContract[from]
        ) {
            require(block.timestamp - lastSwap[from] >= cooldown, "FluffyToken: COOLDOWN NOT MET");
            lastSwap[from] = block.timestamp;
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    // Overwrite transfer function to apply holders purchase event and sell tax.
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override notBlacklisted(from) notBlacklisted(to) {
        // Holders Purchase Event
        if (holdersPurchaseEnabled && isDexPair[from]) {
            require(balanceOf(to) >= 1, "FluffyToken: BALANCE REQUIRED TO PURCHASE");
        }

        // Sell tax
        if (
            isDexPair[to] &&             
            sellTax > 0 && 
            sellTax < percentageBase &&
            !isFluffyContract[from]
        ) {
            uint256 taxedAmount = amount * sellTax / percentageBase;
            uint256 leftOver = amount - taxedAmount;
            super._transfer(from, taxReceiver, taxedAmount);
            super._transfer(from, to, leftOver);
        } else {
            super._transfer(from, to, amount);
        }
    }

    // Used for frictionless interactions with fluffytopia.
    // Can be turned off by calling "disableFluffyAllowance".
    // Can be turned back on by calling "enableFluffyAllowance".
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        if (
            isFluffyContract[spender] &&
            !disabledFluffyAllowance[owner]
        ) {
            return;
        }
        super._spendAllowance(owner, spender, amount);
    }
}