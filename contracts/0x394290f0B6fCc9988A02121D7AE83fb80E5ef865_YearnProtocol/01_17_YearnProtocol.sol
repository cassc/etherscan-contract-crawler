// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./imports/IVault.sol";

import "../../interfaces/IContractsRegistry.sol";
import "../../interfaces/IReinsurancePool.sol";
import "../../interfaces/IDefiProtocol.sol";

import "../../abstract/AbstractDependant.sol";
import "../../Globals.sol";

contract YearnProtocol is IDefiProtocol, OwnableUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public totalDeposit;
    uint256 public totalRewards;

    ERC20 public override stablecoin;
    IVault public vault;

    uint256 public constant YEARN_PRECESSION = 10**6;

    IReinsurancePool public reinsurancePool;

    address public yieldGeneratorAddress;
    address public capitalPoolAddress;

    uint256 public lastPricePerShare;
    uint256 public lastUpdateBlock;

    modifier onlyYieldGenerator() {
        require(_msgSender() == yieldGeneratorAddress, "YP: Not a yield generator contract");
        _;
    }

    function __YearnProtocol_init() external initializer {
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stablecoin = ERC20(_contractsRegistry.getUSDTContract());
        vault = IVault(_contractsRegistry.getYearnVaultContract());
        yieldGeneratorAddress = _contractsRegistry.getYieldGeneratorContract();
        capitalPoolAddress = _contractsRegistry.getCapitalPoolContract();
        reinsurancePool = IReinsurancePool(_contractsRegistry.getReinsurancePoolContract());
    }

    /**
    @notice Deposit an amount of stablecoin in defi protocol in exchange of shares.
    @dev
        We deposit in the Vault an amount of stablecoin.
        This amount is registered in totalDeposit (as an investment).
        The Vault gives shares in return.
        Shares are the representation of the underlying stablecoin in Vault, their price may change.
    @param amount uint256 the amount of stablecoin deposited
    */
    function deposit(uint256 amount) external override onlyYieldGenerator {
        // approve amount of stablecoin to Vault
        stablecoin.safeApprove(address(vault), 0);
        stablecoin.safeApprove(address(vault), amount);
        // deposit amount of stablecoin to Vault, returns the amount of shares issued
        vault.deposit(amount);
        totalDeposit = totalDeposit.add(amount);
        _updatePriceAndBlock();
    }

    /**
    @notice Withdraw an amount of stablecoin in defi protocol in exchange of shares.
    @dev 
        The withdraw function is called with an amount of underlying stablecoin.
        This amount should be inferior to the totalDeposit to ensure that we don't withdraw yield but only investment.
        Then this amount is converted to shares thanks to pricePerShare() function in Vault.
        The amount in shares is sent to the Vault in exchange of an amount of underlying stablecoin sent directly to the capitalPool.
        This amount of stablecoin should equals amountInUnderlying.
    @param amountInUnderlying uint256 the amount of underlying token to withdraw the deposited stable coin
    @return actualAmountWithdrawn : The amount of underlying stablecoin withdrawn (sould equals amountInUnderlying) 
    */
    function withdraw(uint256 amountInUnderlying)
        external
        override
        onlyYieldGenerator
        returns (uint256 actualAmountWithdrawn)
    {
        // we ensure that we withdraw stablecoin from investment (not yield), which is represented by totalDeposit
        if (totalDeposit >= amountInUnderlying) {
            // get the price for a single share
            uint256 sharePrice = vault.pricePerShare();
            // convert amountInUnderlying to withdraw in shares
            uint256 amountInShares = amountInUnderlying.mul(YEARN_PRECESSION).div(sharePrice);
            // withdraw the underlying stablecoin and send it to the capitalPool
            if (amountInShares > 0) {
                actualAmountWithdrawn = vault.withdraw(amountInShares, capitalPoolAddress);
                totalDeposit = totalDeposit.sub(actualAmountWithdrawn);
            }
        }
        _updatePriceAndBlock();
    }

    function withdrawAll()
        external
        override
        onlyYieldGenerator
        returns (uint256 actualAmountWithdrawn, uint256 accumaltedAmount)
    {
        uint256 yTokenBalance = vault.balanceOf(address(this));
        if (yTokenBalance > 0) {
            actualAmountWithdrawn = vault.withdraw();

            stablecoin.safeTransfer(capitalPoolAddress, actualAmountWithdrawn);

            accumaltedAmount = actualAmountWithdrawn.sub(totalDeposit);
            actualAmountWithdrawn = actualAmountWithdrawn.sub(accumaltedAmount);
            totalRewards = totalRewards.add(accumaltedAmount);

            totalDeposit = 0;
        }
    }

    /** 
    @notice Claim rewards and send it to reinsurance pool
    @dev 
        We want to withdraw only the yield. 
        First, we compare the amount totalValue (see totalValue()) and the totalDeposit.
        The reward is the difference between totalValue and totalDeposit.
        The rewards is converted in shares thanks to pricePerShare() function in Vault.
        The reward in shares is sent to the Vault in exchange of an amount of underlying stablecoin sent directly to the reinsurancePool.
    */
    function claimRewards() external override onlyYieldGenerator {
        uint256 _totalStblValue = _totalValue();
        // the gain is the difference between the totalValue and the totalDeposit
        if (_totalStblValue > totalDeposit) {
            uint256 _accumaltedAmount = _totalStblValue.sub(totalDeposit);
            // get the price for a single share
            uint256 sharePrice = vault.pricePerShare();
            // convert rewards in share value
            uint256 rewardsInShares = _accumaltedAmount.mul(YEARN_PRECESSION).div(sharePrice);
            // withdraw the reward and send it to the reinsurancePool
            if (rewardsInShares > 0) {
                uint256 _amountInUnderlying = vault.withdraw(rewardsInShares, capitalPoolAddress);
                reinsurancePool.addInterestFromDefiProtocols(_amountInUnderlying);
                totalRewards = totalRewards.add(_amountInUnderlying);
            }
        }
        _updatePriceAndBlock();
    }

    /** 
@notice The totalValue represent the amount of stablecoin locked in the Vault.
    @dev 
        We want to know how much underlying stablecoin is locked in the Vault.
        First we get the balance of this contract to get the quantity of shares.
        Then we get the price of a share (which is evolving).
        The total amount of stablecoin we could withdraw is the quatity of shares * the unit price.
        @return uint256 the total value locked in the defi protocol, in terms of stablecoin
    */
    function totalValue() external view override returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256) {
        // get balance of shares in Vault
        uint256 balanceShares = vault.balanceOf(address(this));
        // get the price for a single share
        uint256 sharePrice = vault.pricePerShare();
        // total value is the balance of shares multiplied by the price
        return balanceShares.mul(sharePrice).div(YEARN_PRECESSION);
    }

    function setRewards(address newValue) external override onlyYieldGenerator {}

    function _updatePriceAndBlock() internal {
        lastPricePerShare = vault.pricePerShare();
        lastUpdateBlock = block.number;
    }

    function getOneDayGain() external view override returns (uint256 oneDayGain) {
        uint256 newPricePerShare = vault.pricePerShare();
        if (newPricePerShare > lastPricePerShare) {
            uint256 priceChange = (newPricePerShare.sub(lastPricePerShare)).mul(PRECISION);
            uint256 nbDay = (block.number.sub(lastUpdateBlock)).div(BLOCKS_PER_DAY);

            if (nbDay > 0) {
                oneDayGain = priceChange.div(YEARN_PRECESSION).div(nbDay);
            } else {
                oneDayGain = priceChange.div(YEARN_PRECESSION);
            }
        } else {
            oneDayGain = 0;
        }
    }

    function updateTotalValue() external override onlyYieldGenerator returns (uint256) {}

    function updateTotalDeposit(uint256 _lostAmount) external override onlyYieldGenerator {
        totalDeposit = totalDeposit.sub(_lostAmount);
    }
}