// SPDX-License-Identifier: ISC
pragma solidity ^0.8.18;

interface IFraxlendPairRegistry {
    function addPair(address _pairAddress) external;

    function addSalt(address _pairAddress, bytes32 _salt) external;

    function deployedPairsArray(uint256) external view returns (address);

    function deployedPairsByName(string memory) external view returns (address);

    function deployedPairsBySalt(bytes32) external view returns (address);

    function deployedPairsLength() external view returns (uint256);

    function deployedSaltsArray(uint256) external view returns (address);

    function deployedSaltsLength() external view returns (uint256);

    function deployers(address) external view returns (bool);

    function getAllPairAddresses() external view returns (address[] memory _deployedPairsArray);

    function getAllPairSalts() external view returns (address[] memory _deployedSaltsArray);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setDeployers(address[] memory _deployers, bool _bool) external;

    function transferOwnership(address newOwner) external;
}