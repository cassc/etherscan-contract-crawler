// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./configuration/UserConfiguration.sol";
import "./interfaces/ILedger.sol";
import "./interfaces/IUserData.sol";
import "./libraries/math/MathUtils.sol";
import "./libraries/helpers/Errors.sol";
import "./types/DataTypes.sol";

contract UserData is IUserData, Initializable, AccessControlUpgradeable {
    using MathUtils for uint256;
    using MathUtils for int256;
    using UserConfiguration for DataTypes.UserConfiguration;

    uint256 public constant VERSION = 3;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @dev Total reserve share supply, expressed in ray
    // pid => share supply
    mapping(uint256 => uint256) public totalReserveShareSupply;

    /// @dev Total collateral share supply, expressed in ray
    // pid => share supply
    mapping(uint256 => uint256) public totalCollateralShareSupply;

    // user => amount
    mapping(address => DataTypes.UserData) public userData;

    /// @dev Ledger
    ILedger public ledger;

    event SetLedger(address ledger);

    function initialize() external initializer onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), Errors.CALLER_NOT_OPERATOR);
        _;
    }

    function setLedger(address ledger_) external onlyOperator {
        require(address(ledger) == address(0), Errors.LEDGER_INITIALIZED);
        ledger = ILedger(ledger_);
        emit SetLedger(ledger_);
    }

    function depositReserve(address user, uint256 pid, uint256 amount, uint256 unit, uint256 currPoolSupply) external override onlyLedger {
        uint256 currTotalReserveShareSupply = totalReserveShareSupply[pid];

        if (userData[user].reserveShares[pid] == 0) {
            userData[user].configuration.setUsingReserve(pid, true);
        }

        uint256 shares = _toShare(
            amount.unitToRay(unit),
            currTotalReserveShareSupply,
            currPoolSupply.unitToRay(unit)
        );

        userData[user].reserveShares[pid] += shares;
        totalReserveShareSupply[pid] += shares;
    }

    function withdrawReserve(address user, uint256 pid, uint256 amount, uint256 unit, uint256 currPoolSupply) external override onlyLedger {
        uint256 currTotalReserveShareSupply = totalReserveShareSupply[pid];

        uint256 shares = _toShare(
            amount.unitToRay(unit),
            currTotalReserveShareSupply,
            currPoolSupply.unitToRay(unit)
        );

        require(shares <= userData[user].reserveShares[pid], Errors.NOT_ENOUGH_BALANCE);

        userData[user].reserveShares[pid] -= shares;
        totalReserveShareSupply[pid] -= shares;

        if (userData[user].reserveShares[pid] == 0) {
            userData[user].configuration.setUsingReserve(pid, false);
        }
    }

    function depositCollateral(address user, uint256 pid, uint256 amount, uint256 unit, uint256 currPoolSupply) external override onlyLedger {
        uint256 currTotalCollateralShareSupply = totalCollateralShareSupply[pid];

        if (userData[user].collateralShares[pid] == 0) {
            userData[user].configuration.setUsingCollateral(pid, true);
        }

        uint256 shares = _toShare(
            amount.unitToRay(unit),
            currTotalCollateralShareSupply,
            currPoolSupply.unitToRay(unit)
        );

        userData[user].collateralShares[pid] += shares;
        totalCollateralShareSupply[pid] += shares;
    }

    function withdrawCollateral(address user, uint256 pid, uint256 amount, uint256 currPoolSupply, uint256 unit) external override onlyLedger {
        uint256 currTotalCollateralShareSupply = totalCollateralShareSupply[pid];

        uint256 shares = _toShare(
            amount.unitToRay(unit),
            currTotalCollateralShareSupply,
            currPoolSupply.unitToRay(unit)
        );

        userData[user].collateralShares[pid] -= shares;
        totalCollateralShareSupply[pid] -= shares;

        if (userData[user].collateralShares[pid] == 0) {
            userData[user].configuration.setUsingCollateral(pid, false);
        }
    }

    // TODO: requires review
    function changePosition(address user, uint256 pid, int256 incomingPosition, uint256 borrowIndex, uint256 decimals) external override onlyLedger {
        int256 currNormalizedPositionRay = _normalizedPositionRay(userData[user].positions[pid], borrowIndex);

        int256 nextPositionRay = currNormalizedPositionRay + incomingPosition.unitToRay(decimals);

        userData[user].positions[pid] = _scaledPositionRay(nextPositionRay, borrowIndex);

        userData[user].configuration.setUsingPosition(pid, nextPositionRay != 0);
    }

    function getUserCollateralInternal(address user, uint256 pid, uint256 currPoolSupply, uint256 decimals) external view onlyLedger returns (uint256) {
        uint256 currUserCollateralShare = userData[user].collateralShares[pid];

        if (currUserCollateralShare == 0) {
            return 0;
        }

        uint256 currTotalShareSupply = totalCollateralShareSupply[pid];

        return _toAmount(
            currUserCollateralShare,
            currTotalShareSupply,
            currPoolSupply.unitToRay(decimals)
        ).rayToUnit(decimals);
    }

    function getUserPositionInternal(address user, uint256 pid, uint256 borrowIndex, uint256 decimals) external view override onlyLedger returns (int256) {
        return _normalizedPositionRay(userData[user].positions[pid], borrowIndex).rayToUnit(decimals);
    }

    function getUserConfiguration(address user) external view returns (DataTypes.UserConfiguration memory) {
        return userData[user].configuration;
    }

    function getUserReserve(address user, address asset, bool claimable) external view returns (uint256) {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        uint256 currUserReserveShare = userData[user].reserveShares[reserve.poolId];

        if (currUserReserveShare == 0) {
            return 0;
        }

        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);
        uint256 decimals = assetConfig.decimals;

        (uint256 currAvailableSupply,uint256 currPoolSupply,,,) = ledger.reserveSupplies(asset);

        uint256 currTotalShareSupply = totalReserveShareSupply[reserve.poolId];

        uint256 balance = _toAmount(
            currUserReserveShare,
            currTotalShareSupply,
            currPoolSupply.unitToRay(decimals)
        ).rayToUnit(decimals);

        if (claimable) {
            if (balance > currAvailableSupply) {
                balance = currAvailableSupply;
            }
        }

        return balance;
    }

    function getUserCollateral(address user, address asset_, address reinvestment, bool claimable) external override view returns (uint256) {
        // resolve stack too deep;
        address asset = asset_;
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);

        uint256 currUserCollateralShare = userData[user].collateralShares[collateral.poolId];

        if (currUserCollateralShare == 0) {
            return 0;
        }

        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);
        uint256 decimals = assetConfig.decimals;

        uint256 currPoolSupply = ledger.collateralTotalSupply(asset, reinvestment);
        uint256 currTotalShareSupply = totalCollateralShareSupply[collateral.poolId];

        uint256 balance = _toAmount(
            currUserCollateralShare,
            currTotalShareSupply,
            currPoolSupply.unitToRay(decimals)
        ).rayToUnit(decimals);

        if (claimable) {

            DataTypes.UserLiquidity memory currUserLiquidity = ledger.getUserLiquidity(user);

            if (currUserLiquidity.availableLeverageUsd <= 0) {
                return 0;
            }

            uint256 leverageFactor = ledger.getProtocolConfig().leverageFactor;

            (uint256 assetPrice, uint256 assetPriceUnit) = assetConfig.oracle.getAssetPrice(asset);

            uint256 ltvGwei = uint256(collateral.configuration.ltvGwei);

            uint256 maxAmount = uint256(currUserLiquidity.availableLeverageUsd)
            .wadDiv(leverageFactor)
            .wadDiv(ltvGwei.unitToWad(9))
            .wadDiv(assetPrice.unitToWad(assetPriceUnit))
            .wadToUnit(decimals);

            if (maxAmount < balance) {
                balance = maxAmount;
            }
        }

        return balance;
    }

    function getUserPosition(address user, address asset) external override view returns (int256) {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);

        (,,uint256 borrowIndex) = ledger.getReserveIndexes(asset);

        return _normalizedPositionRay(
            userData[user].positions[reserve.poolId],
            borrowIndex
        ).rayToUnit(assetConfig.decimals);
    }

    function _normalizedPositionRay(int256 scaledPosition, uint256 borrowIndex) internal pure returns (int256) {
        if (scaledPosition < 0) {
            uint256 absNormalizedPosition = scaledPosition.abs().rayMul(borrowIndex);
            return int256(absNormalizedPosition) * (- 1);
        } else {
            return scaledPosition;
        }
    }

    function _scaledPositionRay(int256 normalizedPosition, uint256 borrowIndex) internal pure returns (int256) {
        if (normalizedPosition < 0) {
            uint256 absScaledPosition = normalizedPosition.abs().rayDiv(borrowIndex);
            return int256(absScaledPosition) * (-1);
        } else {
            return normalizedPosition;
        }
    }

    function _toShare(uint256 amount, uint256 shareSupply, uint256 poolSupply) internal pure returns (uint256) {
        if (poolSupply == 0) {
            return amount;
        }
        return amount * shareSupply / poolSupply;
    }

    function _toAmount(uint256 share, uint256 shareSupply, uint256 poolSupply) internal pure returns (uint256) {
        if (shareSupply == 0) {
            return share;
        }
        return share * poolSupply / shareSupply;
    }

    modifier onlyLedger() {
        require(address(ledger) == msg.sender, Errors.CALLER_NOT_LEDGER);
        _;
    }
}