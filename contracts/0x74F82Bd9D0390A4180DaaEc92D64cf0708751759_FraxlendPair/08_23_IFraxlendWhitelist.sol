// SPDX-License-Identifier: ISC
pragma solidity >=0.8.17;

interface IFraxlendWhitelist {
    function fraxlendDeployerWhitelist(address) external view returns (bool);

    function oracleContractWhitelist(address) external view returns (bool);

    function owner() external view returns (address);

    function rateContractWhitelist(address) external view returns (bool);

    function renounceOwnership() external;

    function setFraxlendDeployerWhitelist(address[] calldata _addresses, bool _bool) external;

    function setOracleContractWhitelist(address[] calldata _addresses, bool _bool) external;

    function setRateContractWhitelist(address[] calldata _addresses, bool _bool) external;

    function transferOwnership(address newOwner) external;
}