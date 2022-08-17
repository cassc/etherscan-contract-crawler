// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ISilo.sol";

import "./lib/EasyMath.sol";
import "./BaseSilo.sol";

/// @title Silo
/// @notice Silo is the main component of the protocol. It implements lending logic, manages and isolates
/// risk, acts as a vault for assets, and performs liquidations. Each Silo is composed of the unique asset
/// for which it was created (ie. UNI) and bridge assets (ie. ETH and SiloDollar). There may be multiple
/// bridge assets at any given time.
/// @dev Main Silo contact that inherits from Base contract. It implements all user/UI facing methods.
/// @custom:security-contact [email protected]
contract Silo is ISilo, BaseSilo {
    using SafeERC20 for ERC20;
    using EasyMath for uint256;

    constructor (ISiloRepository _repository, address _siloAsset, uint128 _version)
        BaseSilo(_repository, _siloAsset, _version)
    {
        // initial setup is done in BaseSilo, nothing to do here
    }

    /// @inheritdoc ISilo
    function deposit(address _asset, uint256 _amount, bool _collateralOnly)
        external
        override
        returns (uint256 collateralAmount, uint256 collateralShare)
    {
        return _deposit(_asset, msg.sender, msg.sender, _amount, _collateralOnly);
    }

    /// @inheritdoc ISilo
    function depositFor(
        address _asset,
        address _depositor,
        uint256 _amount,
        bool _collateralOnly
    )
        external
        override
        returns (uint256 collateralAmount, uint256 collateralShare)
    {
        return _deposit(_asset, msg.sender, _depositor, _amount, _collateralOnly);
    }

    /// @inheritdoc ISilo
    function withdraw(address _asset, uint256 _amount, bool _collateralOnly)
        external
        override
        returns (uint256 withdrawnAmount, uint256 withdrawnShare)
    {
        return _withdraw(_asset, msg.sender, msg.sender, _amount, _collateralOnly);
    }

    /// @inheritdoc ISilo
    function withdrawFor(address _asset, address _depositor, address _receiver, uint256 _amount, bool _collateralOnly)
        external
        override
        onlyRouter
        returns (uint256 withdrawnAmount, uint256 withdrawnShare)
    {
        return _withdraw(_asset, _depositor, _receiver, _amount, _collateralOnly);
    }

    /// @inheritdoc ISilo
    function borrow(address _asset, uint256 _amount) external override returns (uint256 debtAmount, uint256 debtShare) {
        return _borrow(_asset, msg.sender, msg.sender, _amount);
    }

    /// @inheritdoc ISilo
    function borrowFor(address _asset, address _borrower, address _receiver, uint256 _amount)
        external
        override
        onlyRouter
        returns (uint256 debtAmount, uint256 debtShare)
    {
        return _borrow(_asset, _borrower, _receiver, _amount);
    }

    /// @inheritdoc ISilo
    function repay(address _asset, uint256 _amount)
        external
        override
        returns (uint256 repaidAmount, uint256 repaidShare)
    {
        return _repay(_asset, msg.sender, msg.sender, _amount);
    }

    /// @inheritdoc ISilo
    function repayFor(address _asset, address _borrower, uint256 _amount)
        external
        override
        returns (uint256 repaidAmount, uint256 repaidShare)
    {
        return _repay(_asset, _borrower, msg.sender, _amount);
    }

    /// @inheritdoc ISilo
    function flashLiquidate(address[] memory _users, bytes memory _flashReceiverData)
        external
        override
        returns (
            address[] memory assets,
            uint256[][] memory receivedCollaterals,
            uint256[][] memory shareAmountsToRepay
        )
    {
        assets = getAssets();
        uint256 usersLength = _users.length;
        receivedCollaterals = new uint256[][](usersLength);
        shareAmountsToRepay = new uint256[][](usersLength);

        for (uint256 i = 0; i < usersLength; i++) {
            (
                receivedCollaterals[i],
                shareAmountsToRepay[i]
            ) = _userLiquidation(assets, _users[i], IFlashLiquidationReceiver(msg.sender), _flashReceiverData);
        }
    }

    /// @inheritdoc ISilo
    function harvestProtocolFees() external override returns (uint256[] memory harvestedAmounts) {
        address[] memory assets = getAssets();
        harvestedAmounts = new uint256[](assets.length);

        address repositoryOwner = siloRepository.owner();

        for (uint256 i; i < assets.length;) {
            unchecked {
                // it will not overflow because fee is much lower than any other amounts
                harvestedAmounts[i] = _harvestProtocolFees(assets[i], repositoryOwner);
                // we run out of gas before we overflow i
                i++;
            }
        }
    }

    /// @inheritdoc ISilo
    function accrueInterest(address _asset) public override returns (uint256 interest) {
        return _accrueInterest(_asset);
    }
}