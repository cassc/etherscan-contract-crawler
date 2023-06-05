// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IURS {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract URSCompanions is ERC721Enumerable, Ownable {

    bool public g_claimOpen = false;

    uint256 private constant MAX_PER_TRANSACTION = 50;

    IURS private g_ursContract;
    string private g_baseUri = "";

    constructor(
        string memory _name, 
        string memory _symbol, 
        address ursContract
    ) ERC721 (_name, _symbol) {
        g_ursContract = IURS(ursContract);
    }

    modifier isClaimActive() {
        require(g_claimOpen, "Claiming window is not open.");
        _;
    }

    function toggleClaimOpen() external onlyOwner {
        g_claimOpen = !g_claimOpen;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        g_baseUri = _uri;
    }

    function claim(uint256[] calldata _ursIds) external isClaimActive {
        uint256 claimAmount = _ursIds.length;

        require(claimAmount <= MAX_PER_TRANSACTION, "Can not mint more than 50 at a time.");
        
        for (uint256 i = 0; i < claimAmount; i++) {
            require(!isURSUsed(_ursIds[i]), "One of the selected URS has already been used to claim a companion.");
            require(g_ursContract.ownerOf(_ursIds[i]) == msg.sender, "One of the selected URS does not belong to you.");
            _mint(msg.sender, _ursIds[i]);
        }
    }

    function isURSUsed(uint256 _ursId) public view returns (bool) {
        return _exists(_ursId);
    }

    function _baseURI() internal view override returns (string memory) {
        return g_baseUri;
    }


}