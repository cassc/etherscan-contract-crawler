// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface MembersInterface {
    function setFactoryAdmin(address factoryAdmin) external returns (bool);

    function setCustodian(address custodian) external returns (bool);

    function addMerchant(address merchant) external returns (bool);

    function removeMerchant(address merchant) external returns (bool);

    function isFactoryAdmin(address addr) external view returns (bool);

    function isCustodian(address addr) external view returns (bool);

    function isMerchant(address addr) external view returns (bool);

    function getMerchants() external view returns (address[] memory);

    function merchantsLength() external view returns (uint256);
}