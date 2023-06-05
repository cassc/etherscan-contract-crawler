// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHUB {
    
    function emergencyRescueAlpha(uint16 _id, address _account) external;

    function setGenesis(address _genesis) external;

    function setTopia(address _topia) external;

    function batchSetGenesisIdentifier(uint16[] calldata _idNumbers, uint8[] calldata _types) external;

    function setRescueEnabled(bool _flag) external;

    function setDevRescueEnabled(bool _flag) external;

    function setGameContract(address _contract, bool flag) external;

    function transferOwnership(address newOwner) external;

    function getUserStakedAlphaGame(address owner, uint8 game) external view returns (uint16[] memory stakedAlphas);

    function devRescueEnabled() external view returns (bool);

}