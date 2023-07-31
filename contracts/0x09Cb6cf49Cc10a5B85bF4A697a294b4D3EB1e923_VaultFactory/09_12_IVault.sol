// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./IVaultFactory.sol";

interface IVault {
    function initialize(address) external;

    function factory() external view returns (IVaultFactory);
    function owner() external view returns (address);
    function deposited() external view returns (uint);
    function minted() external view returns (uint);
    function availableBalance() external view returns (uint);
    function pendingYield() external view returns (uint);
    function mintRatio() external view returns (uint);
    function protocolFee() external view returns (uint);
    function redemptionFee() external view returns (uint);

    function deposit(uint) external returns (uint);
    function withdraw(uint) external;
    function mint(uint) external;
    function burn(uint) external;
    function redeem(uint) external;
    function claim() external;
}