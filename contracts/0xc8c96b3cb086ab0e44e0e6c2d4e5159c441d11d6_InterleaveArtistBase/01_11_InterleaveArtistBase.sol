// contracts/InterleaveArtistBase.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
  _____       _            _                     
  \_   \_ __ | |_ ___ _ __| | ___  __ ___   _____ 
   / /\/ '_ \| __/ _ \ '__| |/ _ \/ _` \ \ / / _ \
/\/ /_ | | | | ||  __/ |  | |  __/ (_| |\ V /  __/
\____/ |_| |_|\__\___|_|  |_|\___|\__,_| \_/ \___|

*/

/// @title The NFT contract used to claim Interleave SuperNFT 6 artist drops
/// @notice Contract representing the 6 different artist token types claimable by burning a Interleave SuperNFT
contract InterleaveArtistBase is ERC1155, ERC1155Burnable, Ownable {
    string public baseURI;
    string public artistName;

    mapping(uint256 => bool) public validId;

    address private interleaveClaimer;

    event SetURI(string baseURI);

    event SetClaimer(address interleaveClaimer);

    constructor(
        string memory _baseURI,
        string memory _artistName,
        address _sender
    ) ERC1155(_baseURI) {
        baseURI = _baseURI;
        artistName = _artistName;
        interleaveClaimer = _sender;
        validId[0] = true;
        transferOwnership(_sender);
    }

    modifier onlyAuthorised {
        require(msg.sender == interleaveClaimer || msg.sender == owner(), "Unauthorized minter");
        _;
    }

    function mint(
        address _account,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public onlyAuthorised returns (bool) {
        require(validId[_id], "Minting invalid id");
        _mint(_account, _id, _amount, _data);
        return true;
    }

    function setClaimer(address _interleaveClaimer) public onlyOwner {
        interleaveClaimer = _interleaveClaimer;
        emit SetClaimer(_interleaveClaimer);
    }

    function uri(uint256 _typeID) public view override returns (string memory) {
        require(validId[_typeID], "URI requested for invalid artist type");
        return baseURI;
    }

    function updateTokenURI(string memory _baseURI) external onlyOwner {
        require(bytes(_baseURI).length > 0, "invalid uri");
        baseURI = _baseURI;
        emit SetURI(_baseURI);
    }
}