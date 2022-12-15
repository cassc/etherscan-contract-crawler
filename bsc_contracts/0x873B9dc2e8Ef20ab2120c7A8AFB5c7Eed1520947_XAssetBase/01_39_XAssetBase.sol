// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@prb/proxy/contracts/IPRBProxyRegistry.sol";
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import "./IXAsset.sol";
import "../strategies/IXStrategy.sol";
import "./XAssetShareToken.sol";
import "../farms/FarmXYZBase.sol";
import "hardhat/console.sol";

// todo #1: events
// todo #2: bridge
// todo #3: strategy
// todo #4: base-token
// todo #5: shares
// todo #6: share value conversion in x-base-token
// zapper - conversie automata

contract XAssetBase is IXAsset, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, ERC2771Recipient, UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * The name of this XASSET
     */
    string public name;

    /**
     * The base token that all investments are denominated in.
     */
    address public baseToken;

    /**
     * The share token emitted by the XASSET
     */
    address public override shareToken;

    address public proxyRegistry;

    bool public strategyIsInitialized;

    bool public initialInvestmentDone;

    /**
     * The strategy used to manage actions between investment assets.
     */
//    IXStrategy private _strategy;
    address private strategy;

    /**
     * The power of ten used to calculate share tokens number
     */
    uint256 private shareTokenDenominator;

    /**
     * The denominator for the base token
     */
    uint256 private baseTokenDenominator;

    uint256 public acceptedPriceDifference;

    /**
     * @dev Emitted when `value` tokens are invested into an XAsset
     */
    event Invest(address indexed from, uint256 amount);

    /**
     * @dev Emitted when `value` tokens are withdrawn from an XAsset
     */
    event Withdraw(address indexed to, uint256 amount);

    /**
     * @dev Emitted when the xAsset is initialized & first investment is done
     */
    event XAssetInitialized();

    /**
     * @param name_ The name of this XASSET
     * @param baseToken_ The token in which conversions are made by default
     * @param shareToken_ The contract which holds the shares
     */
    function initialize(
        string calldata name_,
        address baseToken_,
        address shareToken_,
        address proxyRegistry_
    ) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        name = name_;
        baseToken = baseToken_;
        baseTokenDenominator = 10 ** IERC20Metadata(baseToken).decimals();
        shareToken = shareToken_;
        shareTokenDenominator = 10 ** IERC20Metadata(shareToken).decimals();
        strategyIsInitialized = false;
        initialInvestmentDone = false;
        acceptedPriceDifference = 1000;
        proxyRegistry = proxyRegistry_; // address(0x43fA1CFCacAe71492A36198EDAE602Fe80DdcA63);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setTrustedForwarder(address forwarder) public onlyOwner {
        _setTrustedForwarder(forwarder);
    }

    function setAcceptedPriceDifference(uint256 priceDifference) public onlyOwner {
        acceptedPriceDifference = priceDifference;
    }

    function setStrategy(address strategy_) public onlyOwner {
        require(!strategyIsInitialized, "Strategy is already initialized");
        strategyIsInitialized = true;
        strategy = strategy_;
    }

    function executeInitialInvestment() external onlyOwner {
        require(!initialInvestmentDone, "Initial investment is already done");

        uint256 totalAssetValueBeforeInvest = IXStrategy(strategy).getTotalAssetValue();
        require(
            totalAssetValueBeforeInvest == 0,
            "Strategy should have no assets since no shares have been issued"
        );

        // We start with a share value of $10, and 1 share
        uint256 amount = 10 * baseTokenDenominator;
        IERC20Upgradeable(baseToken).safeIncreaseAllowance(address(strategy), amount);
        IXStrategy(strategy).invest(baseToken, amount, 0);
        XAssetShareToken(shareToken).mint(address(this), 1 * shareTokenDenominator);
        initialInvestmentDone = true;
        emit Invest(address(this), amount);
        emit XAssetInitialized();

//        uint256 totalAssetValueAfterInvest = _strategy.getTotalAssetValue();
//
//        uint256 pricePerShareAfterInvest = _sharePrice();
    }

    function _sharePrice() internal view returns (uint256) {
        if (!initialInvestmentDone) {
            return 0;
        }
        uint256 totalAssetsValue = IXStrategy(strategy).getTotalAssetValue();
        uint256 sharePrice = (totalAssetsValue * shareTokenDenominator) / IERC20(shareToken).totalSupply();
        return sharePrice;
    }

    /**
     * @return The price per one share of the XASSET
     */
    function getSharePrice() external view override returns (uint256) {
        return _sharePrice();
    }

    function _checkPriceDifference(
        uint256 priceBefore,
        uint256 priceAfter
    ) internal view returns (uint256) {
        if (priceBefore > priceAfter) {
            require(
                (priceBefore - priceAfter) < acceptedPriceDifference,
                "Price per share can not change more than accepted price difference after any operation"
            );
            return priceBefore - priceAfter;
        } else {
            require(
                (priceAfter - priceBefore) < acceptedPriceDifference,
                "Price per share can not change more than accepted price difference after any operation"
            );
            return priceAfter - priceBefore;
        }
    }

    function _invest(
        address token,
        uint256 amount,
        uint256 minAmount
    ) internal returns (uint256) {
        require(IERC20(shareToken).totalSupply() > 0, "Initial investment is not done yet");

        // Transfer tokens from the user to the XAsset
        IERC20Upgradeable(token).safeTransferFrom(_msgSender(), address(this), amount);

        // Approve the strategy to spend the tokens
        if (IERC20(token).allowance(address(this), address(strategy)) < amount) {
            IERC20Upgradeable(token).safeIncreaseAllowance(address(strategy), type(uint256).max);
        }

        uint256 newShares = 0;

        // Compound the earnings of the strategy
        IXStrategy(strategy).compound();

        // Save the total asset value before the investment
        uint256 totalAssetValueBeforeInvest = IXStrategy(strategy).getTotalAssetValue();
        //        console.log("[xasset][invest] totalAssetValueBeforeInvest: %s", totalAssetValueBeforeInvest);

        // Save the price per share before the investment
        uint256 pricePerShareBeforeInvest = _sharePrice();
        // Invest using the strategy
        IXStrategy(strategy).invest(token, amount, minAmount);

        uint256 totalAssetValueAfterInvest = IXStrategy(strategy).getTotalAssetValue();
        uint256 totalAssetValueInvested = totalAssetValueAfterInvest - totalAssetValueBeforeInvest;
        console.log("[xasset][invest] totalAssetValueAfterInvest: %s", totalAssetValueAfterInvest);

        // Calculate the number of shares to mint
        newShares = (totalAssetValueInvested * shareTokenDenominator) / pricePerShareBeforeInvest;

        console.log("[xasset][invest] newShares: %s", newShares);
        // Mint the shares
        XAssetShareToken(shareToken).mint(_msgSender(), newShares);

        // Calculate the price per share after the investment
        uint256 pricePerShareAfterInvest = _sharePrice();

        console.log("[xasset][invest] pricePerShareBeforeInvest", pricePerShareBeforeInvest);
        console.log("[xasset][invest] pricePerShareAfterInvest", pricePerShareAfterInvest);

        // Make sure the price per share did not change more than the accepted price difference
        _checkPriceDifference(
            pricePerShareBeforeInvest,
            pricePerShareAfterInvest
        );

        emit Invest(_msgSender(), amount);
        return newShares;
    }

    function invest(
        address token,
        uint256 amount
    ) nonReentrant whenNotPaused external override returns (uint256) {
        return _invest(token, amount, 0);
    }

    function estimateSharesForInvestmentAmount(
        address token,
        uint256 amount
    ) external view returns (uint256) {
        uint256 pricePerShare = _sharePrice();
        uint256 baseTokenAmount = IXStrategy(strategy).convert(token, amount);
        uint256 shares = (baseTokenAmount * shareTokenDenominator) / pricePerShare;
        return shares;
    }

    function _withdrawFrom(address owner, uint256 shares) private returns (uint256) {
        if (_msgSender() != owner) {
            // We'll allow the proxy to withdraw on behalf of the owner
            require(
                address(IPRBProxyRegistry(proxyRegistry).getCurrentProxy(owner)) == _msgSender(),
                "Only owner or proxy can withdraw"
            );
            require(
                IERC20(shareToken).balanceOf(owner) >= shares,
                "You don't own enough shares"
            );
        } else {
            require(
                IERC20(shareToken).balanceOf(_msgSender()) >= shares,
                "You don't own enough shares"
            );
        }
//        uint256 totalAssetValueBeforeWithdraw = _strategy.getTotalAssetValue();
//        console.log("[xasset][withdraw] totalAssetValueBeforeWithdraw: %s", totalAssetValueBeforeWithdraw);
        uint256 pricePerShareBeforeWithdraw = _sharePrice();
        console.log("[xasset][withdraw] pricePerShareBeforeWithdraw: %s", pricePerShareBeforeWithdraw);
        uint256 amountToWithdraw = (shares * pricePerShareBeforeWithdraw) / shareTokenDenominator;
//        console.log("[xasset][withdraw] amountToWithdraw: %s", amountToWithdraw);

        uint256 withdrawn = IXStrategy(strategy).withdraw(
            amountToWithdraw,
            0
        );
        XAssetShareToken(shareToken).burn(owner, shares);

        uint256 pricePerShareAfterWithdraw = _sharePrice();
        console.log("[xasset][withdraw] pricePerShareAfterWithdraw: %s", pricePerShareAfterWithdraw);
        console.log("[xasset][withdraw] amountToWithdraw: %s", amountToWithdraw);
        console.log("[xasset][withdraw] withdrawn: %s", withdrawn);
        // calculate the difference between the withdrawn amount and the amount to withdraw
        uint256 difference = withdrawn - amountToWithdraw;
        console.log("[xasset][withdraw] difference: %s", difference);

        IERC20Upgradeable(baseToken).safeTransfer(owner, withdrawn);

//        _checkPriceDifference(
//            pricePerShareBeforeWithdraw,
//            pricePerShareAfterWithdraw
//        );
        emit Withdraw(owner, withdrawn);
        return withdrawn;
    }

    function withdrawFrom(
        address owner,
        uint256 shares
    ) nonReentrant whenNotPaused external override returns (uint256) {
        return _withdrawFrom(owner, shares);
    }

    function withdraw(
        uint256 shares
    ) nonReentrant whenNotPaused external override returns (uint256) {
        return _withdrawFrom(_msgSender(), shares);
    }

    function getBaseToken() override external view returns (address) {
        return baseToken;
    }

    /**
     * @param amount - The amount of shares to calculate the value of
     * @return The value of amount shares in baseToken
     */
    function getValueForShares(
        uint256 amount
    ) external view override returns (uint256) {
        return _sharePrice() * amount;
    }

    /**
     * @return Returns the total amount of baseTokens that are invested in this XASSET
     */
    function getTVL() external view override returns (uint256) {
        return IXStrategy(strategy).getTotalAssetValue();
    }

    /**
     * @return Total shares owned by address in this xAsset
     */
    function getTotalSharesOwnedBy(
        address account
    ) external view override returns (uint256) {
        return IERC20(shareToken).balanceOf(account);
    }

    /**
     * @return Total value invested by address in this xAsset, in baseToken
     */
    function getTotalValueOwnedBy(
        address account
    ) external view override returns (uint256) {
        uint256 sharePrice = _sharePrice();
        uint256 accountShares = this.getTotalSharesOwnedBy(account);
        uint256 totalValue = (accountShares * sharePrice) /
        shareTokenDenominator;
        return totalValue;
    }

    function _msgSender()
    internal view virtual override(ERC2771Recipient, ContextUpgradeable) returns (address ret)
    {
        return ERC2771Recipient._msgSender();
    }

    function _msgData()
    internal view virtual override(ERC2771Recipient, ContextUpgradeable) returns (bytes calldata ret)
    {
        return ERC2771Recipient._msgData();
    }

    /**
    * @notice pause xasset, restricting certain operations
     */
    function pause() external nonReentrant onlyOwner {
        _pause();
    }

    /**
     * @notice unpause xasset, enabling certain operations
     */
    function unpause() external nonReentrant onlyOwner {
        _unpause();
    }

    //    function logTokenValue(string memory message, uint256 amount) internal view {
    //        log.value(message, amount, _baseTokenDenominator);
    //    }
    //
    //    function logShareValue(string memory message, uint256 amount) internal view {
    //        log.value(message, amount, _shareTokenDenominator);
    //    }
}