pragma solidity >=0.5.0;

interface IRegiment {
    function IsRegimentMember(
        bytes32 regimentId,
        address memberAddress
    ) external view returns (bool);

    function IsRegimentManager(
        bytes32 regimentId,
        address managerAddress
    ) external view returns (bool);

    function IsRegimentAdmin(
        bytes32 regimentId,
        address adminAddress
    ) external view returns (bool);

    function IsRegimentMembers(
        bytes32 regimentId,
        address[] memory memberAddress
    ) external view returns (bool);
}