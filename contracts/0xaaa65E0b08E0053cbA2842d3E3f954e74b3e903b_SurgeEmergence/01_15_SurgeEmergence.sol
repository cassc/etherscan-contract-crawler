// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./SurgeGenesis.sol";

contract SurgeEmergence is ERC721Enumerable, Ownable {
    // Surge contract
    SurgeGenesis private immutable surge;

    // Token metadata uri
    string public baseURI;
    // Contract metadata uri
    string public metadataURI;
    // Is the airdrop active
    bool public airdropActive = false;

    constructor(
        address surgeAddress,
        string memory tokenBaseURI,
        string memory tokenMetadataURI
    ) ERC721("SurgeEmergence", "surge-emergence") {
        surge = SurgeGenesis(surgeAddress);
        setBaseURI(tokenBaseURI);
        setMetadataURI(tokenMetadataURI);
    }

    function mint(uint256[] calldata surgeIds) public {
        require(airdropActive, "Airdrop is not active");
        for (uint256 i = 0; i < surgeIds.length; i++) {
            require(
                surge.ownerOf(surgeIds[i]) == msg.sender,
                "Must own the surge you're attempting to get the banner for"
            );
            _safeMint(msg.sender, surgeIds[i]);
        }
    }

    // For OpenSea
    function contractURI() public view returns (string memory) {
        return metadataURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Owner only
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setMetadataURI(string memory _newMetadataURI) public onlyOwner {
        metadataURI = _newMetadataURI;
    }

    function toggleAirdropActive() external onlyOwner {
        airdropActive = !airdropActive;
    }

    function withdraw(address payable _to, uint256 _amount) public onlyOwner {
        _to.transfer(_amount);
    }
}