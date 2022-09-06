// SPDX-License-Identifier: MIT
/*

   $$\   $$\ $$$$$$$\         $$$$$$\  $$\   $$\ $$\   $$\     $$\ 
   $$ |  $$ |$$  __$$\       $$  __$$\ $$$\  $$ |$$ |  \$$\   $$  |
   $$ |  $$ |$$ |  $$ |      $$ /  $$ |$$$$\ $$ |$$ |   \$$\ $$  / 
   $$ |  $$ |$$$$$$$  |      $$ |  $$ |$$ $$\$$ |$$ |    \$$$$  /  
   $$ |  $$ |$$  ____/       $$ |  $$ |$$ \$$$$ |$$ |     \$$  /   
   $$ |  $$ |$$ |            $$ |  $$ |$$ |\$$$ |$$ |      $$ |    
   \$$$$$$  |$$ |             $$$$$$  |$$ | \$$ |$$$$$$$$\ $$ |    
    \______/ \__|             \______/ \__|  \__|\________|\__|    

        (for art lovers and degens only)
 
 --
 Up Only NFTs are a unique class of curated NFTs for artists:
 * Each NFT may only be listed at a higher price than previously sold
 * Transfer functions disabled: use list/buy functions
 * Approve functions disabled: avoids gas wasting accidents
 * No burn function
 --

*/
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct UpOnlyToken {
    address artist;
    uint256 listPrice;
    uint256 lastSalePrice;
    string  tokenURI;
}

contract UpOnly is ERC721, Ownable, ReentrancyGuard {

    uint256 constant private ARTIST_FEE = 5;
    uint256 constant private CONTRACT_FEE = 1;
    uint256 constant private MAX_INT = 2**256 - 1;

    uint256 public supply;

    mapping(uint256 => UpOnlyToken) public tokens;

    event Mint(address indexed artist, uint256 indexed tokenId);
    event List(address indexed seller, uint256 indexed listPrice);
    event Delist(address indexed seller);
    event Sale(address indexed buyer, uint256 indexed salePrice);
    
    constructor() ERC721("UpOnly", "UPONLY") {}

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(supply > 0, "No items minted yet");
        require(tokens[tokenId].artist != address(0x0), "Token does not exist");
        require(bytes(tokens[tokenId].tokenURI).length > 0, "Metadata is empty");

        return tokens[tokenId].tokenURI;
    }
    
    //
    // owner functions ↓
    //

    function mint(address artist, string calldata tokenURI, uint256 listPrice) external onlyOwner nonReentrant {
        _mint(artist, tokenURI, listPrice);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    //
    // list functions ↓
    //
    // tip: listPrice denominated in wei
    //

    function list(uint256 tokenId, uint256 listPrice) external nonReentrant {
        _list(tokenId, listPrice);
    }

    function delist(uint256 tokenId) external nonReentrant {
        _delist(tokenId);
    }

    //
    // buy functions ↓
    //
    function buy(uint256 tokenId) external nonReentrant payable {
        _buy(tokenId);
    }

    function flip(uint256 tokenId, uint256 listPrice) external nonReentrant payable {
        _buy(tokenId);
        _list(tokenId, listPrice);
    }

    // (f your chad self intends to never sell
    function neverGonnaGiveYouUp(uint256 tokenId) external nonReentrant payable {
        _buy(tokenId);
        tokens[tokenId].lastSalePrice = MAX_INT;
    }

    //
    // Disabled Transfer/Approve functions ↓
    //

    error TransferDisabled();
    error ApproveDisabled();

    function transferFrom(address, address, uint256) public override {
        revert TransferDisabled();
    }

    function safeTransferFrom(address, address, uint256) public override {
        revert TransferDisabled();
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public override { 
        revert TransferDisabled();
    }

    function approve(address, uint256) public override {
        revert ApproveDisabled();
    }

    function setApprovalForAll(address, bool) public override {
        revert ApproveDisabled();
    }

    //
    // Internal functions ↓
    //

    function _mint(address artist, string memory tokenURI, uint256 listPrice) internal {
        require(artist != address(0x0), "Artist address must not be 0x0");
        uint256 tokenId = supply;
        
        _safeMint(artist, tokenId);
        tokens[tokenId] = UpOnlyToken(artist, listPrice, 0, tokenURI);

        unchecked {
            ++supply;
        }

        emit Mint(artist, tokenId);
    }

    function _list(uint256 tokenId, uint256 listPrice) internal {
        require(ownerOf(tokenId) == msg.sender, "you don't own that token.");
        require(listPrice > tokens[tokenId].lastSalePrice, "ser, this is an Up Only.");

        tokens[tokenId].listPrice = listPrice;

        emit List(msg.sender, listPrice);
    }

    function _delist(uint256 tokenId) internal {
        require(ownerOf(tokenId) == msg.sender, "you don't own that token.");

        tokens[tokenId].listPrice = 0;

        emit Delist(msg.sender);
    }

    function _buy(uint256 tokenId) internal {
        UpOnlyToken memory token = tokens[tokenId];
        address seller = ownerOf(tokenId);

        require(seller != address(0));
        require(token.artist != address(0));
        require(token.listPrice > 0, "uh that's not for sale");
        require(seller != msg.sender, "you already own that");
        require(msg.value == token.listPrice, "incorrect amount");
        require(token.listPrice > token.lastSalePrice, "ser, this is an Up Only");
        
        tokens[tokenId].lastSalePrice = token.listPrice;
        delete tokens[tokenId].listPrice;

        _transfer(seller, msg.sender, tokenId);

        (bool success, ) = token.artist.call{value: msg.value * ARTIST_FEE / 100 }("");
        require(success, "Artist fee payment failed.");

        (success, ) = seller.call{value: msg.value * (100 - CONTRACT_FEE - ARTIST_FEE) / 100}("");
        require(success, "Seller payment failed.");

        emit Sale(msg.sender, msg.value);
    }
}