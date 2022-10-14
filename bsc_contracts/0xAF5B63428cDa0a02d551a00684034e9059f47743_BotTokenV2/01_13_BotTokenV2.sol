/************************************************************
 *
 * Autor: BotPlanet
 *
 * 446576656c6f7065723a20416e746f6e20506f6c656e79616b61 ****/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter02.sol";

contract BotTokenV2 is ERC20, Ownable {
    // Usings

    using Address for address;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Structs

    struct WalletConfig {
        bool isExcludedFromFee;
        bool isExcludedFromMaxWalletAmount;
        bool isExcludedFromMaxTxAmount;
    }

    // Constants

    address private INITIAL_TOKEN_OWNER =
        0xe919621cae4bE24eb2cA43E5D077816690D96767;
    uint256 private constant MAX = ~uint256(0);
    address public constant ROUTER_ADDRESS =
        0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC
    //address public ROUTER_ADDRESS = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC TestNet
    uint256 private constant DEFAULT_MAX_TX_PER = 100;
    uint256 private constant DEFAULT_MAX_WALLET_PER = 1;
    uint256 private MAX_SUPPLY = 1000000000 * 1e18;

    // Attributies

    mapping(address => WalletConfig) private _configs;
    // Addressed to ignore from holder list, because is used for other reasons and is not real holders
    mapping(address => bool) internal _excludedHolders;
    EnumerableSet.AddressSet internal _holderList; // All token holders
    EnumerableSet.AddressSet internal _excludedFromCirculationSupply;

    // Properties

    IPancakeRouter02 public pcsV2Router;
    address public dao;
    address public pcsV2Pair; // address of pair in PancakeSwap (BOT / WBNB)
    uint256 public maxTxAmount; // Max transaction amount
    uint256 public maxWalletAmount; // Max wallet balance
    uint256 public burnFee = 2; // Burn fee 2%
    bool public initialized; // Initialized or not pair in PancakeSwap

    // Modifiers

    modifier onlyOwnerOrDAO() {
        require(
            owner() == _msgSender() || dao == _msgSender(),
            "BotTokenV2: caller is not the owner or DAO"
        );
        _;
    }

    // Constructor

    constructor() ERC20("BOT", "BOT") {
        //transferOwnership(INITIAL_TOKEN_OWNER);
        // Owner wallet configuration
        _configs[owner()].isExcludedFromFee = true;
        _configs[owner()].isExcludedFromMaxWalletAmount = true;
        _configs[owner()].isExcludedFromMaxTxAmount = true;
        // Current contract configuration
        _configs[address(this)].isExcludedFromFee = true;
        _configs[address(this)].isExcludedFromMaxWalletAmount = true;
        _configs[address(this)].isExcludedFromMaxTxAmount = true;
        // Burn address configuration
        _configs[address(0)].isExcludedFromMaxWalletAmount = true;

        // We ignore holders, who is contracts/special address and is not real holder of tokens
        _excludedHolders[address(0)] = true;
        _excludedHolders[address(this)] = true;

        // Mint tokens to owner
        _mint(owner(), MAX_SUPPLY);

        // Set default max tx amount and max wallet balance
        maxTxAmount = (totalSupply() * DEFAULT_MAX_TX_PER) / 100; // setMaxTxPercent
        maxWalletAmount = (totalSupply() * DEFAULT_MAX_WALLET_PER) / 100; // setMaxWalletPercent
    }

    // Private/Internal Methods

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal view override {
        require(
            amount_ > 0,
            "BotTokenV2: Transfer amount must be greater than zero"
        );
        // Check if exceeds max transfer amount
        if (
            !_configs[from_].isExcludedFromMaxTxAmount &&
            !_configs[to_].isExcludedFromMaxTxAmount
        ) {
            require(
                amount_ <= maxTxAmount,
                "BotTokenV2: Transfer amount exceeds the max tx amount."
            );
        }
        // Check if exceeds new wallet amount
        if (!_configs[to_].isExcludedFromMaxWalletAmount) {
            uint256 contractBalanceRecepient = balanceOf(to_);
            require(
                contractBalanceRecepient + amount_ <= maxWalletAmount,
                "BotTokenV2: Exceeds maximum wallet amount"
            );
        }
    }

    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        // Check if apply fee or not
        if (
            _configs[from_].isExcludedFromFee || _configs[to_].isExcludedFromFee
        ) {
            // Don't take fee
            super._transfer(from_, to_, amount_);
        } else {
            // Take fee and burn it
            uint256 toBurnAmount = (amount_ * burnFee) / 100;
            _burn(from_, toBurnAmount);
            super._transfer(from_, to_, amount_ - toBurnAmount);
        }
    }

    // With this function, after tokens is transfer, we review holder list to remove 0 balance holders,
    // and add new holders with new balance
    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        // Step 0: Check if amount is to change anything. If is 0, we don't change any list of holders,
        // because really we don't have any change in amounts
        if (amount_ > 0) {
            // Step 1: Check from account (not accept mint case)
            if (
                from_ != address(0) &&
                balanceOf(from_) == 0 &&
                !_excludedHolders[from_]
            ) {
                // This address not has any balance
                require(
                    _holderList.remove(from_),
                    "BotTokenV2: cannot remove holder"
                );
            }
            // Step 2: Check to account && Check if holder is allowed
            if (
                to_ != address(0) &&
                !_holderList.contains(to_) &&
                !_excludedHolders[to_]
            ) {
                // Is not burn case. Add holder to list
                require(
                    _holderList.add(to_),
                    "BotTokenV2: cannot add new holder"
                );
            }
        }
    }

    // Public/External Methods
    function init(address dao_) external onlyOwnerOrDAO {
        require(!initialized, "BotTokenV2: already initialized!");

        setDAO(dao_);

        // Create a PancakeSwap pair for this new token
        IPancakeRouter02 pcsV2Router_ = IPancakeRouter02(ROUTER_ADDRESS);
        pcsV2Pair = IPancakeFactory(pcsV2Router_.factory()).createPair(
            address(this),
            pcsV2Router_.WETH()
        );
        pcsV2Router = pcsV2Router_;

        // Pancake pair configuration
        _configs[pcsV2Pair].isExcludedFromFee = false;
        _configs[pcsV2Pair].isExcludedFromMaxWalletAmount = true;
        _configs[pcsV2Pair].isExcludedFromMaxTxAmount = true;

        initialized = true;
    }

    function setDAO(address dao_) public onlyOwnerOrDAO {
        require(
            dao_ != address(0),
            "BotTokenV2: for DAO is not accepted 0 address!"
        );
        dao = dao_;
    }

    function setBurnFee(uint256 burnFee_) external onlyOwnerOrDAO {
        require(
            burnFee_ >= 1 && burnFee_ <= 100,
            "BotTokenV2: set bern fee percent"
        );
        burnFee = burnFee_;
    }

    function setMaxTxPercent(uint256 maxTxPercent_) public onlyOwnerOrDAO {
        require(
            maxTxPercent_ >= 1 && maxTxPercent_ <= 100,
            "BotTokenV2: set max tx percent"
        );
        maxTxAmount = (totalSupply() * maxTxPercent_) / 100;
    }

    function setMaxWalletPercent(uint256 maxWalletPercent_)
        public
        onlyOwnerOrDAO
    {
        require(
            maxWalletPercent_ >= 1 && maxWalletPercent_ <= 100,
            "BotTokenV2: set max wallet percent"
        );
        maxWalletAmount = (totalSupply() * maxWalletPercent_) / 100;
    }

    function setExcludedHolder(address account_, bool isExcluded_)
        external
        onlyOwnerOrDAO
    {
        _excludedHolders[account_] = isExcluded_;
    }

    function isExcludedHolder(address account_) external view returns (bool) {
        return _excludedHolders[account_];
    }

    function setIsExcludedFromFee(address account_, bool value_)
        external
        onlyOwnerOrDAO
    {
        _configs[account_].isExcludedFromFee = value_;
    }

    function setIsExcludedFromMaxWalletAmount(address account_, bool value_)
        external
        onlyOwnerOrDAO
    {
        _configs[account_].isExcludedFromMaxWalletAmount = value_;
    }

    function setIsExcludedFromMaxTxAmount(address account_, bool value_)
        external
        onlyOwnerOrDAO
    {
        _configs[account_].isExcludedFromMaxTxAmount = value_;
    }

    function setIsExcludedFromCirculationSupply(address account_, bool value_)
        external
        onlyOwnerOrDAO
    {
        if (_excludedFromCirculationSupply.contains(account_)) {
            // Now is excluded address
            require(
                !value_,
                "BotTokenV2: already excluded from circulation supply"
            );
            _excludedFromCirculationSupply.remove(account_);
        } else {
            // Address is not excluded
            require(
                value_,
                "BotTokenV2: is not excluded from circulation supply"
            );
            _excludedFromCirculationSupply.add(account_);
        }
    }

    function isExcludedFromCirculationSupply(address account_)
        external
        view
        returns (bool)
    {
        return _excludedFromCirculationSupply.contains(account_);
    }

    function burn(uint256 amount_) external {
        _burn(msg.sender, amount_);
    }

    function holder(uint256 index_) external view returns (address) {
        return _holderList.at(index_);
    }

    function walletConfig(address account_)
        external
        view
        returns (WalletConfig memory)
    {
        return _configs[account_];
    }

    function numberOfHolders() external view returns (uint256) {
        return _holderList.length();
    }

    function numberTokensBurned() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function maxSupply() external view returns (uint256) {
        return MAX_SUPPLY;
    }

    function circulationSupply() external view returns (uint256) {
        uint256 result = totalSupply();
        uint256 excludedLenght = _excludedFromCirculationSupply.length();
        for (uint256 i = 0; i < excludedLenght; i++) {
            address excluded = _excludedFromCirculationSupply.at(i);
            result -= balanceOf(excluded);
        }
        return result;
    }

    // To recieve ETH from pcsV2Router when swaping
    receive() external payable {}
}