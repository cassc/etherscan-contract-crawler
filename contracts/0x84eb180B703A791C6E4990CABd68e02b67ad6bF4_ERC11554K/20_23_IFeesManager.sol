// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IGuardians.sol";
import "./IERC11554KController.sol";

/**
 * @dev {IFeesManager} interface:
 */
interface IFeesManager {
    function receiveFees(
        IERC11554K erc11554k,
        uint256 id,
        IERC20Upgradeable asset,
        uint256 _salePrice
    ) external;

    function calculateTotalFee(
        IERC11554K erc11554k,
        uint256 id,
        uint256 _salePrice
    ) external returns (uint256);

    function payGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address payer,
        IERC20Upgradeable paymentAsset
    ) external;

    function refundGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address recipient,
        IERC20Upgradeable paymentAsset
    ) external;

    function moveFeesBetweenGuardians(
        address guardianFrom,
        address guardianTo,
        IERC20Upgradeable asset
    ) external;

    function setGuardians(IGuardians guardians_) external;

    function setController(IERC11554KController controller_) external;

    function setGlobalTradingFee(uint256 globalTradingFee_) external;

    function setTradingFeeSplit(
        uint256 protocolSplit,
        uint256 guardianSplit
    ) external;

    function setExchange(address exchange_) external;

    function setVersion(bytes32 version_) external;

    function transferOwnership(address newOwner) external;
}