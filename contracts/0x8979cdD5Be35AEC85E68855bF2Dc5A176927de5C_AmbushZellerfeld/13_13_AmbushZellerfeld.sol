// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AmbushZellerfeld is ERC1155, Ownable, ReentrancyGuard {
    string public name = "Ambush Zellerfeld";
    string public symbol = "AZ";

    uint256 private currentTokenId = 0;
    uint8[] private supplies;
    string private baseURI =
        "https://gateway.pinata.cloud/ipfs/QmdPmYrcWh6WtCN79DR1EEn2dFDoPfmzrKQLnxSKcsFJEu";
    mapping(address => uint256) private holdCount;

    constructor(
        string memory _baseURI,
        address[] memory _individuals,
        address _another
    ) ERC1155(string(abi.encodePacked(_baseURI, "{id}"))) {
        supplies = new uint8[](10);
        for (uint256 i = 0; i < 10; i++) {
            supplies[i] = 0;
        }
        baseURI = _baseURI;

        require(_individuals.length == 3, "Individuals length is 3.");

        for (uint256 index = 0; index < _individuals.length; index++) {
            mint(_individuals[index]);
        }
        for (uint256 index = 0; index < 7; index++) {
            mint(_another);
        }
    }

    function setBaseUri(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function totalSupply() public view returns (uint256) {
        return currentTokenId;
    }

    function currentHoldCount() public view returns (uint256) {
        return holdCount[msg.sender];
    }

    function mint(address _receiver) internal {
        require(currentTokenId <= supplies.length - 1, "NFT is sold out.");

        require(supplies[currentTokenId] == 0, "NFT is already minted.");

        _mint(_receiver, currentTokenId, 1, "");

        supplies[currentTokenId] += 1;
        currentTokenId += 1;
        holdCount[_receiver] += 1;
    }

    // For putting NFT on Opensea
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId <= supplies.length - 1, "NFT does not exist");
        return baseURI;
    }
}