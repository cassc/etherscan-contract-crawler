// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./types/AccessControlled.sol";


contract KonduxFounders is ERC721, ERC721Enumerable, Pausable, ERC721Burnable, ERC721Royalty, AccessControlled {
    event BaseURIChanged(string baseURI);
    event Received(address sender, uint value);
    event DenominatorChanged(uint96 denominator);

    using Counters for Counters.Counter;

    bytes32 public MINTER_ROLE = keccak256("MINTER_ROLE");

    string public baseURI;
    uint96 public denominator;
    
    Counters.Counter private _tokenIdCounter;

    constructor(string memory _name, string memory _ticker, address _authority) 
        ERC721(_name, _ticker) 
        AccessControlled(IAuthority(_authority)) {
    }

    function changeDenominator(uint96 _denominator) public onlyGovernor returns (uint96) {
        denominator = _denominator;
        emit DenominatorChanged(denominator);
        return denominator;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyGovernor {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId,address receiver,uint96 feeNumerator) public onlyGovernor {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setBaseURI(string memory _newURI) external onlyGovernor returns (string memory) {
        baseURI = _newURI;
        emit BaseURIChanged(baseURI);
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }

    function pause() public onlyGovernor {
        _pause();
    }

    function unpause() public onlyGovernor {
        _unpause();
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        return tokenId;
    }

    // Internal functions //

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override (ERC721Royalty, ERC721) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}