// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./IMintableBurnableERC20.sol";

interface IVaultFactory {
    function collateral() external view returns (IERC20);
    function token() external view returns (IMintableBurnableERC20);

    function protocolFeeTo() external view returns (address);
    function maxProtocolFee() external view returns (uint);
    function redemptionFeeTo() external view returns (address);
    function minRedemptionFee() external view returns (uint);
    function maxRedemptionAdjustment() external view returns (uint);
    function PRECISION() external view returns (uint);

    function createVault(address) external returns (address);
    function getVault(address) external view returns (address);
    function allVaults(uint) external view returns (address);
    function isVaultManager(address) external view returns (bool);
    function vaultsLength() external view returns (uint);

    function setVaultManager(address _manager, bool _status) external ;
    function setMaxProtocolFee(uint) external;
    function setProtocolFeeTo(address) external;
    function setMinRedemptionFee(uint) external;
    function setMaxRedemptionAdjustment(uint) external;
    function setRedemptionFeeTo(address) external;
}