// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./src/ERC721A.sol";
import "./src/DefaultOperatorFilterer.sol";

error MaxMintExceeded();
error InsufficientFunds();
error NotLive();
error SoldOut();
error InvalidAmount();

contract murafuka is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    uint64 public price = 0.002 ether;
    uint64 public constant maxSupply = 3333; 
    uint64 public constant free = 1;
    uint64 public constant maxPerWallet = 10;
    string public uri = "ipfs://QmTrttPGhiwQjw4qt9toRBBCi9esKkjBJVEtpCtqfTVmwQ/meta/";
    bool public sale = false;

    constructor() ERC721A("Murafuka", "MRFK") {
        setRoyaltyInfo(500);
        _mint(msg.sender, 1);
    }

    function mint(uint64 amount) external payable {
        if(!sale) revert NotLive();
        if(!(maxSupply >= _totalMinted() + amount)) revert SoldOut();
        if(amount == 0) revert InvalidAmount();    
        if(_numberMinted(msg.sender) + amount > maxPerWallet) revert MaxMintExceeded();
        if(_numberMinted(msg.sender) >= free){
            if(msg.value < amount * price) revert InsufficientFunds();
        }else{
            if(msg.value < (amount - free) * price) revert InsufficientFunds();
        }
        _mint(msg.sender, amount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from){
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setRoyaltyInfo(uint96 royalty) public onlyOwner {
        _setDefaultRoyalty(msg.sender, royalty);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setUri(string calldata i) public onlyOwner {
        uri = i;
    }

    function setPrice(uint64 p) public onlyOwner {
        price = p;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(uri, _toString(tokenId), ".json"));
    }

    function toggleSale() external onlyOwner {
        sale = !sale;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}