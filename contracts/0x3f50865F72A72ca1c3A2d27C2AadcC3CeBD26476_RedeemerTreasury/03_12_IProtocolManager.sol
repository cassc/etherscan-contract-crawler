// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IProtocolManager {
    event NewRedeemerCreated(
        address indexed fedMember,
        address indexed newRedeemer,
        address indexed redeemerTreasury
    );
    event RedeemerStatusChanged(address indexed redeemer, bool status);

    function initialize(
        address _fluentUSPlusAddress,
        address _USPlusMinterAddr,
        address _USPlusBurnerAddr,
        address _redeemerBookkeeper,
        address _redeemerFactory,
        address _complianceManager
    ) external;

    function setUSPlusMinterAddress(address _USPlusMinterAddr) external;

    function setUSPlusBurnerAddress(address _USPlusBurnerAddr) external;

    function createNewRedeemer(address fedMemberId) external returns (address);

    function setRedeemerStatus(address redeemer, bool status) external;

    function getRedeemerStatus(
        address redeemer
    ) external view returns (bool isActive);

    function getRedeemers(
        address fedMemberId
    ) external view returns (address[] memory);

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external;
}