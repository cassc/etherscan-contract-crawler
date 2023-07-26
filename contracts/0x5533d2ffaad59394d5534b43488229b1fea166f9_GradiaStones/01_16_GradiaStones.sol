// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGradiaStonesMetadata.sol";
import "./Whitelist.sol";
import "./ERC721A.sol";

contract GradiaStones is ERC721A, Whitelist {

    event NewComment(uint256 indexed tokenId, string content);
    event Redeem(uint256 indexed tokenId);
    
    using Strings for uint256;
    
    mapping(uint256 => string) private batchURI;
    mapping(uint256 => string) private comments;
    mapping(uint256 => bool) private redeemed;

    address public metadataProvider;
    bool public allowRedeem = false;

    constructor(address _metadataProvider) ERC721A("Gradia Stones", "STONE", 1000) {
        metadataProvider = _metadataProvider;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return IGradiaStonesMetadata(metadataProvider).getMetadata(tokenId);
    }

    function batchMint(address recipient, uint128 quantity) external onlyWhitelisted {
        _safeMint(recipient, quantity);
    }

    function batchTransfer(address from, address to, uint256 startTokenId, uint128 quantity) public override {
        super.batchTransfer(from, to, startTokenId, quantity);
    }

    function setMetadataProvider(address _address) external onlyWhitelisted {
        metadataProvider = _address;
    }

    function addComment(uint256 tokenId, string calldata comment) external {
        require(isApprovedOrOwner(tokenId, _msgSender()) || owner() == _msgSender(), "caller is not owner nor approved");
        comments[tokenId] = comment;
        emit NewComment(tokenId, comment);
    }

    function getComment(uint256 tokenId) public view returns (string memory) {
        return comments[tokenId];
    }

    function redeemMulti(uint256 [] calldata tokenIds) external {
        require(allowRedeem == true, "Redeem is currently disabled.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!redeemed[tokenIds[i]], "Stone is redeemed");
            require(isApprovedOrOwner(tokenIds[i], _msgSender()) || owner() == _msgSender(), "caller is not owner nor approved");
            redeemed[tokenIds[i]] = true;
            emit Redeem(tokenIds[i]);
        }
    }

    function setRedeemState(uint256 tokenId, bool state) external onlyWhitelisted {
        require(redeemed[tokenId] != state, "Stone is already in that state.");
        redeemed[tokenId] = state;
    }

    function getRedeemState(uint256 tokenId) public view returns (bool) {
        return redeemed[tokenId];
    }

    function setAllowRedeem(bool state) external onlyWhitelisted {
        allowRedeem = state;
    }


    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint128 quantity) internal virtual override {
        for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; tokenId++) {
            require(!redeemed[tokenId], "Stone is redeemed");
        }
    }
}