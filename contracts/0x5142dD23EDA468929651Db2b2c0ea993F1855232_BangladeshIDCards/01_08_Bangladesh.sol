// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Base64.sol";


contract BangladeshIDCards is ERC721A, Ownable {
    event MetadataUpdate(uint256 indexed tokenId);

    mapping(uint256 => uint256) public transfers;
    uint256 public cost = 0.0049 ether;
    uint256 public maxPerTx = 3;
    uint256 maxSupply = 1069;
    bool isSaleActive = false;

    constructor() ERC721A("Bangladesh ID Cards", "BID") {
        _safeMint(msg.sender, 1);
    }

    function mint(uint256 amount) external payable {
        require(totalSupply() + amount <= maxSupply, "All NFTs have been minted");
        require(isSaleActive, "Sale isn't active");
        require(msg.value >= cost * amount, "insufficient amount");
        require(amount > 0 && amount <= maxPerTx, "wrong amount");

        _safeMint(msg.sender, amount);
    }

    function ownerMint(uint256 count) external onlyOwner {
        _safeMint(msg.sender, count);
    }

    function withdrawMoney() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        payable(msg.sender).transfer(contractBalance);
    }

    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://bangladeshid.xyz/metadata/";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        address ownerAddress = ownerOf(tokenId);
        uint256 countTransfers = transfers[tokenId];

        return string(abi.encodePacked(_baseURI(), _toString(tokenId), "?wallet_address=", addressToString(ownerAddress), "&", "count_transfers=", _toString(countTransfers)));
    }

    function addressToString(address _address) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override {
        transfers[tokenId] += 1;
        emit MetadataUpdate(tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override {
        transfers[tokenId] += 1;
        emit MetadataUpdate(tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

}