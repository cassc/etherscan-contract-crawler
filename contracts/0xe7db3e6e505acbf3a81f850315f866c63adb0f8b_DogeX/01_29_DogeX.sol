// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// Custom errors
error ExceedsFeesLimit();
error AlreadyExcludedFee(address, bool);
error AlreadyBlacklisted(address, bool);
error AlreadyWalletLimitUnlimited(address, bool);
error AlreadyWalletsLimitEnabled(bool);
error WalletLimitZero();
error AlreadyWalletLimit(uint256);
error AlreadyAPairAddress(address, bool);
error AlreadyTxTrigger(uint256);
error InvalidArrayLength();
error ExceedsArrayLimit();
error InsufficientAirdropTokens();
error InsufficientBalance(uint256);
error BlacklistedAddress();
error ExceedsWalletLimit();
error InsufficientTokenBalanceForApplyingFees();

/**
 * @title DogeX Coin (DOGX) Granny said "Don't you dare GO to the Moon!
 * @author Shiba$hip (aka Shiba__Ship, ∞ba_ship; ∞ba_8hip; 8ba_Ship) with the assistance of the OpenAI gpt-4 model
 * @notice [email protected] Websites www.DogeX.ai https://github.com/8baShip/dogex.ai Social Networks Telegram https://t.me/+S8_jaol3wvtlYzU0 Discord https://discord.gg/k3Z25ynY (Admin will NEVER Direct Message (DM) You). Legal disclaimer The information and content provided on this solidity script are intended for informational purposes only and do not constitute financial, investment, or other professional advice. Investing in cryptocurrencies, such as DOGX, carries inherent risks, and users should conduct their own research and consult professional advisors before making any decisions. DOGX and its team members disclaim any liability for any direct or indirect losses, damages, or consequences that may arise from the use of the information provided on this script. This disclaimer is governed by and construed in accordance with international law, and any disputes relating to this disclaimer shall be subject to the jurisdiction of the courts within which the offense was made.
 * @dev DogeX Coin is an upgradeable ERC20 token utilizing access control mechanism, reentrancy protection, and other features.
 */

contract DogeX is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{

    // Custom events
    event ExcludeFee(address, bool);
    event Blacklisted(address, bool);
    event WalletLimitUnlimited(address, bool);
    event WalletsLimitEnabled(bool);
    event WalletLimit(uint256);
    event PairAddressCreated(address, bool);
    event TxTrigger(uint256);
    event Received(address, uint);

    /* ========== STATE VARIABLES ========== */

    address payable public ownerFeeRecipient;
    address payable public marketingFeeRecipient;
    address payable public devFeeRecipient;

    uint8 public ownerFeePercent;
    uint8 public marketingFeePercent;
    uint8 public devFeePercent;
    uint8 public liquidityFeePercent;
    uint8 public constant maxFees = 8;

    uint256 public totalOwnerAmount;
    uint256 public totalMarketingAmount;
    uint256 public totalDevAmount;
    uint256 public totalLiquidity;

    uint256 public airdropTokens;

    mapping(address => bool) private isExcludedFee;
    mapping(address => bool) private isBlacklisted;
    mapping(address => bool) private isWalletLimitUnlimited;

    uint8 public walletsLimit;
    bool public isWalletsLimitEnabled;

    IUniswapV2Router02 private uniswapV2Router;

    mapping(address => bool) public pairAddress;
    uint256 private txCounter;
    uint256 public txTrigger;

    /* ========== CONSTRUCTOR ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ========== OPENZEPPELIN WIZARD FUNCTIONS ========== */

    function initialize(
        address router_,
        address owner_
    ) initializer public {
        __ERC20_init("DogeX", "DOGEX");
        __ERC20Burnable_init();
        __Ownable_init();
        __ERC20Permit_init("DogeX");
        __UUPSUpgradeable_init();

        transferOwnership(owner_);

        _mint(owner(), 299792458 * 10 ** decimals());

        // to change after deployment
        ownerFeeRecipient = payable(owner());
        marketingFeeRecipient = payable(owner());
        devFeeRecipient = payable(owner());

        ownerFeePercent = 6;
        marketingFeePercent = 0;
        devFeePercent = 0;
        liquidityFeePercent = 2;

        totalOwnerAmount = 0;
        totalMarketingAmount = 0;
        totalDevAmount = 0;
        totalLiquidity = 0;

        airdropTokens = 0;

        isExcludedFee[owner()] = true;
        isExcludedFee[address(this)] = true;

        walletsLimit = 1;
        isWalletsLimitEnabled = true;

        // set up uniswap factory and router
        uniswapV2Router = IUniswapV2Router02(router_); 

        txCounter = 0;
        txTrigger = 5;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /* ========== VIEW FUNCTIONS ========== */

    function getIsExcludedFee(address account) external view returns (bool) {
        return isExcludedFee[account];
    }

    function getIsBlacklisted(address account) external view returns (bool) {
        return isBlacklisted[account];
    }

    function getIsWalletLimitUnlimited(address account) external view returns (bool) {
        return isWalletLimitUnlimited[account];
    }

    /* ========== SETTER FUNCTIONS ========== */

    /**
     * @notice Set the addresses of the owner, marketing and dev.
     * @param _ownerFeeRecipient The owner address.
     * @param _marketingFeeRecipient The marketing address.
     * @param _devFeeRecipient The dev address.
     */
    function bulkSetAddresses(
        address payable _ownerFeeRecipient,
        address payable _marketingFeeRecipient,
        address payable _devFeeRecipient
    ) public onlyOwner {
        ownerFeeRecipient = _ownerFeeRecipient;
        marketingFeeRecipient = _marketingFeeRecipient;
        devFeeRecipient = _devFeeRecipient;
    }

    /**
     * @notice Set the 4 fees percentages in this order: Owner, marketing, dev, auto lp.
     * @param _ownerFeePercent The percentage of the owner fee  //  on buys and sells.
     * @param _marketingFeePercent The percentage of the marketing fee  //  on buys and sells.
     * @param _devFeePercent The percentage of the dev fee  //  on buys and sells.
     * @param _liquidityFeePercent The percentage of the liquidity fee  //  only on sells.
     */
    function bulkSetFees(
        uint8 _ownerFeePercent,
        uint8 _marketingFeePercent,
        uint8 _devFeePercent,
        uint8 _liquidityFeePercent
    ) public onlyOwner {
        if (_ownerFeePercent + _marketingFeePercent + _devFeePercent + _liquidityFeePercent > maxFees)
            revert ExceedsFeesLimit();
        ownerFeePercent = _ownerFeePercent;
        marketingFeePercent = _marketingFeePercent;
        devFeePercent = _devFeePercent;
        liquidityFeePercent = _liquidityFeePercent;
    }

    /**
     * @notice Exclude or re-include an address from the fees. All ExcludedFee wallets are by default not subject to wallet limit.
     * @param account The address to exclude or re-include.
     * @param trueOrFalse True if the address should be excluded (not pay fees/taxes), false otherwise.
     * @dev all ExcludedFee wallets are by default not subject to wallet limit.
     */
    function setIsExcludedFee(address account, bool trueOrFalse) external onlyOwner {
        if (isExcludedFee[account] == trueOrFalse)
            revert AlreadyExcludedFee(account, trueOrFalse);
        isExcludedFee[account] = trueOrFalse;
        emit ExcludeFee(account, trueOrFalse);
    }

    /**
     * @notice Add or remove an address from the blacklist.
     * @param account: The address to blacklist or un-blacklist.
     * @param trueOrFalse: True if the address should be blacklisted, false otherwise.
     */
    function setIsBlacklisted(address account, bool trueOrFalse) external onlyOwner {
        if (isBlacklisted[account] == trueOrFalse)
            revert AlreadyBlacklisted(account, trueOrFalse);
        isBlacklisted[account] = trueOrFalse;
        emit Blacklisted(account, trueOrFalse);
    }

    /**
     * @notice Add or remove addresses from the blacklist.
     * @param account: The addresses to blacklist or un-blacklist.
     * @param trueOrFalse: True if the addresses should be blacklisted, false otherwise.
     */
    function bulkSetIsBlacklisted(address[] memory account, bool trueOrFalse) external onlyOwner {
        for (uint256 i = 0; i < account.length; i++) {
            isBlacklisted[account[i]] = trueOrFalse;
        }
    }

    /**
     * @notice Exclude or re-include an address from the wallet limit.
     * @param account: The address to exclude or re-include.
     * @param trueOrFalse: True if the address should be excluded (not subject to wallet limit), false otherwise.
     * @dev all ExcludedFee wallets are by default not subject to wallet limit.
     */
    function setIsWalletLimitUnlimited(address account, bool trueOrFalse) external onlyOwner {
        if (isWalletLimitUnlimited[account] == trueOrFalse)
            revert AlreadyWalletLimitUnlimited(account, trueOrFalse);
        isWalletLimitUnlimited[account] = trueOrFalse;
        emit WalletLimitUnlimited(account, trueOrFalse);
    }

    /**
     * @notice Turn ON or OFF the wallets limit.
     * @param trueOrFalse True if the wallets limit should be enabled, false otherwise.
     * @dev Having isWalletsLimitEnabled to 'true' will apply the % limit defined with setWalletsLimit(). Having isWalletsLimitEnabled to 'false' disable wallets limit.
     */
    function setIsWalletsLimitEnabled(bool trueOrFalse) external onlyOwner {
        if (isWalletsLimitEnabled == trueOrFalse)
            revert AlreadyWalletsLimitEnabled(trueOrFalse);
        isWalletsLimitEnabled = trueOrFalse;
        emit WalletsLimitEnabled(trueOrFalse);
    }

    /**
     * @notice Set the wallets limit in percentage. Which represent percentage of the total supply.
     * @param _walletsLimit The wallets limit. Only accept an integer (no decimals).
     */
    function setWalletsLimit(uint8 _walletsLimit) external onlyOwner {
        if (_walletsLimit == 0)
            revert WalletLimitZero();
        if (_walletsLimit == walletsLimit)
            revert AlreadyWalletLimit(_walletsLimit);
        walletsLimit = _walletsLimit;
        emit WalletLimit(_walletsLimit);
    }

    /**
     * @notice Set or unset a pair address.
     * @param _pairAddress The address of the pair.
     * @param trueOrFalse True if the address is a pair, false otherwise (to remove a pair).
     * @dev Every pair address should be set to true in order to apply taxes and fees.
     */
    function setPairAddress(address _pairAddress, bool trueOrFalse) external onlyOwner {
        if (pairAddress[_pairAddress] == trueOrFalse)
            revert AlreadyAPairAddress(_pairAddress, trueOrFalse);
        pairAddress[_pairAddress] = trueOrFalse;
        emit PairAddressCreated(_pairAddress, trueOrFalse);
    }

    /**
     * @notice Define the number of tx that will trigger the fees distribution.
     * @param _txTrigger The number of tx that will trigger the fees distribution.
     */
    function setTxTrigger(uint256 _txTrigger) external onlyOwner {
        if (_txTrigger == txTrigger)
            revert AlreadyTxTrigger(_txTrigger);
        txTrigger = _txTrigger;
        emit TxTrigger(_txTrigger);
    }

    /* ========== AIRDROP FUNCTION ========== */

    /**
     * @notice Deposit tokens to be airdropped
     * @param amount: The amount of tokens to be deposited
     */
    function depositAirdropTokens(uint256 amount) public onlyOwner {
        super._transfer(_msgSender(), address(this), amount);
        airdropTokens += amount;
    }

    /**
     * @notice Airdrop tokens to multiple addresses
     * @param _recipients: The addresses of the recipients
     * @param _values: The amounts of tokens to be airdropped
     */
    function bulkAirdrop(address[] memory _recipients, uint256[] memory _values) public onlyOwner {
        uint256 totalValues = 0;
        
        if (_recipients.length != _values.length)
            revert InvalidArrayLength();
        if (_recipients.length > 100)
            revert ExceedsArrayLimit();
        for (uint256 i = 0; i < _values.length; i++) {
            totalValues += _values[i];
        }
        if (totalValues > airdropTokens)
            revert InsufficientAirdropTokens();
        for (uint256 i = 0; i < _recipients.length; i++) {
            airdropTokens -= _values[i];
            super._transfer(address(this), _recipients[i], _values[i]);
        }
    }

    /**
     * @notice withdrawToken to be use only if owner sends tokens to the contract by mistake. Tokens goes back to the owner.
     * @param amount: The amount of tokens to be withdrawn
     * @dev It shouldn't be possible to withdraw tokens that are reserved for fees and airdrop.
     */
    function withdrawToken(uint256 amount) public onlyOwner {
        if (balanceOf(address(this)) < totalOwnerAmount + totalMarketingAmount + totalDevAmount + totalLiquidity + airdropTokens + amount)
            revert InsufficientBalance(amount);
        super._transfer(address(this), _msgSender(), amount);
    }

    /* ========== FEES MECHANISM ========== */

    function _transfer (address sender, address recipient, uint256 amount) internal virtual override {
        if (isBlacklisted[sender] || isBlacklisted[recipient])
            revert BlacklistedAddress();

        if (isExcludedFee[sender] || isExcludedFee[recipient]) {
            super._transfer(sender, recipient, amount);
            return;
        }

        if (isWalletsLimitEnabled == true && isWalletLimitUnlimited[recipient] == false && balanceOf(recipient) + amount > (totalSupply() / 100) * walletsLimit)
            revert ExceedsWalletLimit();
        
        uint256 transferAmount = amount;

        // If listing on another DEX, need to add to the pairAddress mapping and fees will be collected
        if (pairAddress[sender] == true || pairAddress[recipient] == true) {      // buy or sell
            txCounter++;

            // Store cumulative fees
            uint256 ownerFeeAmount = (amount / 100) * ownerFeePercent;
            uint256 marketingFeeAmount = (amount / 100) * marketingFeePercent;
            uint256 devFeeAmount = (amount / 100) * devFeePercent;
            transferAmount = transferAmount - devFeeAmount - marketingFeeAmount - ownerFeeAmount;

            totalOwnerAmount += ownerFeeAmount;
            totalMarketingAmount += marketingFeeAmount;
            totalDevAmount += devFeeAmount;

            if (pairAddress[recipient] == true) { // sell
                // get liquidity fee and store the cumulative amount
                uint256 liquidityFeeAmount = (amount / 100) * liquidityFeePercent;
                transferAmount -= liquidityFeeAmount;

                totalLiquidity += liquidityFeeAmount;
            }

            super._transfer(sender, address(this), amount - transferAmount);
                
            if (txCounter >= txTrigger && pairAddress[recipient] == true) {
                _distributeFee();
                txCounter = 0;
            }
        }

        // send the rest of the tokens to the recipient
        super._transfer(sender, recipient, transferAmount);
    }

    function _distributeFee() internal nonReentrant {
        // swap tokens for ETH
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance < totalOwnerAmount + totalMarketingAmount + totalDevAmount + totalLiquidity)
            revert InsufficientTokenBalanceForApplyingFees();
        
        if ((totalOwnerAmount + totalMarketingAmount + totalDevAmount + totalLiquidity) > 0)
            swapTokensForETH(totalOwnerAmount + totalMarketingAmount + totalDevAmount + (totalLiquidity / 2));

        // reset total fees
        totalOwnerAmount = 0;
        totalMarketingAmount = 0;
        totalDevAmount = 0;

        uint256 swapEthBalance = address(this).balance;

        if (totalLiquidity > 0) {
            addLiquidity((totalLiquidity / 2), swapEthBalance);
            totalLiquidity = 0;
        }

        swapEthBalance = address(this).balance;

        // send fees to their recipients
        if (swapEthBalance > 0) {
            if (ownerFeePercent > 0) {
                uint256 ownerFeeETHAmount = swapEthBalance / (devFeePercent + marketingFeePercent + ownerFeePercent) * (ownerFeePercent);
                payable(ownerFeeRecipient).transfer(ownerFeeETHAmount);
            }
            if (marketingFeePercent > 0) {
                uint256 marketingFeeETHAmount = swapEthBalance / (devFeePercent + marketingFeePercent + ownerFeePercent) * (marketingFeePercent);
                payable(marketingFeeRecipient).transfer(marketingFeeETHAmount);
            }
            if (devFeePercent > 0) {
                uint256 devFeeETHAmount = swapEthBalance / (devFeePercent + marketingFeePercent + ownerFeePercent) * (devFeePercent);
                payable(devFeeRecipient).transfer(devFeeETHAmount);
            }
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Swapping tokens for ETH using Uniswap 
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0), // send LP token to burn address
            block.timestamp
        );
    }
}