// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface iEGoldMinerNFT is IERC721 {

    struct MetaMinerStruct {
        string uri;
        string minerName;
        uint256 hashRate;
        uint256 powerFactor;
        bool status;
    }

    function pauseToken() external  returns (bool);

    function unpauseToken() external  returns (bool);

    function mint( address to, string memory uri, string memory minerName, uint256 hashRate, uint256 powerFactor) external returns (bool);

    function fetchMinerInfo( uint256 _id ) external view returns ( MetaMinerStruct memory );

    function fetchMinerhashRate( uint256 _id ) external view returns ( uint256 );

    function fetchMinerpowerFactor( uint256 _id ) external view returns ( uint256 );

    function totalSupply() external view returns ( uint256 );

}