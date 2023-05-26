// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CommunityStatementOnNFTArt is ERC721 {

    string public statementCid = "ipfs://Qmbuc7FMZ2qsUjSMtTG6FoD6sAigCzS9AyJUtQF2cMX4Qe";
    mapping(address => bool) public signedAddressMap;

    modifier disabled { revert("Disabled"); _; }

    event Sign(address indexed signer);

    constructor() ERC721("Community Statement on NFT art", "CSNA") {}

    function signToStatement() public {
        _signToStatement();
    }

    function signToStatementAndMintBadge() public {
        _signToStatement();
        _safeMint(msg.sender, uint256(uint160(msg.sender)));
    }

    function _signToStatement() internal {
        if (!signedAddressMap[msg.sender]) {
            signedAddressMap[msg.sender] = true;
            emit Sign(msg.sender);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "CommunityStatementOnNFTArt: URI query for nonexistent token");

        return "https://ipfs.io/ipfs/QmXtwT89TTySmJYpvU9mNWi46Ro44x3pT5yh9m6yFN7Uy4";
    }

    // Disabled ERC721 interfaces
    function approve(address to, uint256 tokenId) public virtual override disabled {}
    function setApprovalForAll(address operator, bool approved) public virtual override disabled {}
    function safeTransferFrom(address from, address to, uint256 tokenId) public override disabled {}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override disabled {}
    function transferFrom(address from, address to, uint256 tokenId) public virtual override disabled {}
}