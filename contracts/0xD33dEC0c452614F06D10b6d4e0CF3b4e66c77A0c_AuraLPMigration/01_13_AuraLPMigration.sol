//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import '../interfaces/drops/IDropsCompoundingVault.sol';
import '../interfaces/drops/IDropsAuraMarket.sol';
import '../interfaces/aura/IAuraBaseRewardPool.sol';

/** @title AuraLPMigration: get balanceLP from Aura and supply
 */
contract AuraLPMigration is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice aura base reward pool
    IAuraBaseRewardPool public auraRewardPool;

    /// @notice auto compounding vault
    IDropsCompoundingVault public compoundingVault;

    /// @notice drops CToken for aura market
    IDropsAuraMarket public dropsAuraMarket;

    /// @notice balancer LP token
    IERC20Upgradeable public balancerLP;

    /// @notice emitted when withdraw happens
    event LogEmergencyWithdraw(address indexed from, address indexed asset, uint256 amount);

    function initialize(
        IAuraBaseRewardPool _auraRewardPool,
        IDropsCompoundingVault _compoundingVault,
        IDropsAuraMarket _dropsAuraMarket
    ) public payable initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _setAddresses(_auraRewardPool, _compoundingVault, _dropsAuraMarket);
    }

    function _setAddresses(
        IAuraBaseRewardPool _auraRewardPool,
        IDropsCompoundingVault _compoundingVault,
        IDropsAuraMarket _dropsAuraMarket
    ) internal {
        require(
            _auraRewardPool.asset() == address(_compoundingVault.want()),
            'aura asset are not same with compoundingVault want'
        );

        compoundingVault = _compoundingVault;
        auraRewardPool = _auraRewardPool;
        dropsAuraMarket = _dropsAuraMarket;
        balancerLP = IERC20Upgradeable(_auraRewardPool.asset());
    }

    /// @notice withdraw LP tokens from Aura and supply to market
    /// @dev caller should approve this contract before calling.
    ///      also enables supplied assets as collateral in the market
    /// @param amount of Aura pool tokens to withdraw
    function supplyToMarket(
        uint256 amount
    ) external whenNotPaused nonReentrant returns (uint256 shares) {
        address user = msg.sender;
        require(auraRewardPool.allowance(user, address(this)) >= amount, '!allowance');

        // withdraw from Aura
        auraRewardPool.withdraw(amount, address(this), user);
        require(balancerLP.balanceOf(address(this)) >= amount, '!assets');

        // deposit into compounding compoundingVault and get erc20
        balancerLP.safeApprove(address(compoundingVault), amount);
        shares = compoundingVault.deposit(amount);

        // supply to market
        uint256 err = dropsAuraMarket.mintTo(shares, user);
        require(err == 0, '!mint');

        // enable as collateral
        IDropsAuraComptroller comptroller = dropsAuraMarket.comptroller();
        address[] memory markets = new address[](1);
        markets[0] = address(dropsAuraMarket);
        comptroller.enterMarketsFrom(markets, user);
    }

    /// @notice market will call this function to withdraw balancer LP or restake to Aura
    /// the market should send vault erc20 tokens before call this function
    /// @param withdrawType 1 for withdraw balancer LP, 2 for restake
    function redeem(
        address reciver,
        uint256 amount,
        uint256 withdrawType
    ) external whenNotPaused nonReentrant {
        require(msg.sender == address(dropsAuraMarket), '!market');
        require(withdrawType == 1 || withdrawType == 2, '!withdrawType');
        require(
            IERC20Upgradeable(address(compoundingVault)).balanceOf(address(this)) >= amount,
            '!vaultAmount'
        );

        uint256 withdrawBalance = compoundingVault.withdraw(amount);
        require(withdrawBalance > 0, '!withdrawBalance');
        require(balancerLP.balanceOf(address(this)) >= withdrawBalance, '!lpBalance');

        if (withdrawType == 1) {
            balancerLP.safeTransfer(reciver, withdrawBalance);
        } else {
            balancerLP.safeApprove(address(auraRewardPool), withdrawBalance);
            auraRewardPool.stakeFor(reciver, withdrawBalance);
        }
    }

    /* ========== owner level functions ========== */

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function emergencyWithdraw(address asset, address receiver) external onlyOwner {
        uint256 assetBalance;
        if (asset == address(0)) {
            // ether
            assetBalance = (address(this)).balance;
            payable(receiver).transfer(assetBalance);
        } else {
            assetBalance = IERC20Upgradeable(asset).balanceOf(address(this));
            IERC20Upgradeable(asset).safeTransfer(receiver, assetBalance);
        }
        if (assetBalance > 0) {
            emit LogEmergencyWithdraw(receiver, asset, assetBalance);
        }
    }

    function setAddresses(
        IAuraBaseRewardPool _auraRewardPool,
        IDropsCompoundingVault _compoundingVault,
        IDropsAuraMarket _dropsAuraMarket
    ) external onlyOwner {
        _setAddresses(_auraRewardPool, _compoundingVault, _dropsAuraMarket);
    }
}