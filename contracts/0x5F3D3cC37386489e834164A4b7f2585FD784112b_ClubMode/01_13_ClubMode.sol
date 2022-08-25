// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ClubMode is ERC721, AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public baseTokenURI;
    string private _contractMetadataURI;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(uint256 mintCount) public onlyRole(MINTER_ROLE) {
        require(mintCount > 0, "Min 1 mint");
        uint256 currentId = _tokenIdCounter.current();
        for (uint256 i = 1; i <= mintCount; i++) {    
            _safeMint(msg.sender, currentId + i);
        }
        // Reduces gas cost for big bulk mints by avoiding calls to .increment()
        _tokenIdCounter._value += mintCount;

    }

    function airdropMint(address recipient) public onlyRole(MINTER_ROLE) {
        _tokenIdCounter.increment();
        _safeMint(recipient, _tokenIdCounter.current());
    }

    function setBaseTokenUri(string memory _newUri) public onlyRole(MINTER_ROLE) {
        baseTokenURI = _newUri;
    }

    function setContractMetadataUri(string memory _newUri) public onlyRole(MINTER_ROLE) {
        _contractMetadataURI = _newUri;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return bytes(baseTokenURI).length > 0
            ? baseTokenURI
            : "";
    }

    function contractURI() public view returns (string memory) {
        return bytes(_contractMetadataURI).length > 0
            ? _contractMetadataURI
            : "";
    }

}