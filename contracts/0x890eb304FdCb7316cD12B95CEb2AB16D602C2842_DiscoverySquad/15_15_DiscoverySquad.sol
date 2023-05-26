// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface Contract1 {
    function reveal(uint256 token_id) external;
    function ownerOf(uint256 token_id) external view returns(address);
}

contract DiscoverySquad is ERC721Enumerable, Ownable, ReentrancyGuard {

    mapping(uint256 => uint256) public last_transfer;
    Contract1 nft1;
    string base_uri;
    uint256 max_token_id = 1000;
    uint256 counter = 1;

    constructor(address nft1_address) ERC721("Discovery Squad", "DSHOUSE") {
        nft1 = Contract1(nft1_address);
    }

    function set_nft1_address(address nft1_address) public onlyOwner {
        nft1 = Contract1(nft1_address);
    }

    function _baseURI() internal view override returns (string memory) {
        return base_uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return string(abi.encodePacked(uri, ".json"));
    }

    function get_nfts_by_address(
        address owner,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256 actualLimit = (balance < offset + limit)
            ? (balance - offset)
            : limit;

        uint256[] memory nfts = new uint256[](actualLimit);
        for (uint256 i = 0; i < actualLimit; i++) {
            nfts[i] = tokenOfOwnerByIndex(owner, offset + i);
        }
        return nfts;
    }

    function set_base_uri(string memory new_base_uri) public onlyOwner {
        base_uri = new_base_uri;
    }

    function set_max_token_id(uint256 new_max_token_id) public onlyOwner {
        max_token_id = new_max_token_id;
    }

    function mint(uint256 token_id
    ) external nonReentrant {
        require(token_id <= max_token_id, "Your NFT is outside the collection limit");
        require(
            nft1.ownerOf(token_id) == msg.sender,
            "You don't own this token"
        );
        nft1.reveal(token_id);
        _mint(msg.sender, counter);
        last_transfer[counter] = block.timestamp;
        counter++;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        last_transfer[tokenId] = block.timestamp;
        super._transfer(from, to, tokenId);
    }
}