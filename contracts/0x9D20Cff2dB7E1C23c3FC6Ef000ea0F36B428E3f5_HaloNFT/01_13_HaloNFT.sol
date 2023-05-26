// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC721A.sol";
import "./INFT.sol";



contract HaloNFT is ERC721A, Ownable, INFT {
    /// @dev Library
    using Strings for uint256;
    /// @dev Event
    event PurchaseEvent(address purchaseWallet, uint256 nftID, uint256 purchaseTimestamp);
    ////////////////////////////////////////////

    /// @dev All constant defination
    ////////////////////////////////////////////
    uint256 public  INVENTORY = 5050;

    uint256 private W_PRICE;
    uint256 private N_PRICE;

    uint256 private MINT_LIMIT = 1;

    /// @dev public variable for business
    ////////////////////////////////////////////

    uint256 private _private_sell_start = 1650207737;
    uint256 private _public_sell_start = 0;

    bool private _is_revealed = false;

    string private _base_uri = "";

    string private _blindbox_uri = "https://ipfs.halonft.art/halo/token/";
  
    address private SIGNER = 0x7828570E9e8c468a213Dabb6C37dDAAdb5eF5F38;

    /// functions
    ////////////////////////////////////////////////////////////////////////

    /// Override
    function _baseURI() internal view override returns (string memory) {
        return _base_uri;
    }

    /// NFT Related
    ////////////////////////////////////////////////////////////////////////
    constructor() ERC721A("HALO NFT", "HALO") {
    }


    function purchaseWhitelist(uint256 amount, bytes memory sign) external payable {
        purchaseWhitelistValidator(msg.sender, sign, amount);
        mintTo(msg.sender, amount);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!_is_revealed) {
            return bytes(_blindbox_uri).length > 0 ? string(abi.encodePacked(_blindbox_uri, tokenId.toString(), ".json")) : "";
        }
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    /// @dev check if we have storage for the purchase
    function isEnough(uint256 amount) private view returns (bool enough) {
        uint256 solded = totalSupply();
        uint256 afterPurchased = solded + amount;
        enough = true;
        require(afterPurchased <= INVENTORY, "Max limit");
    }


    function querySellType() public view returns (uint256) {
        if (_public_sell_start > 0) {
            return 2;
        }
        if (block.timestamp > _private_sell_start ) {
            return 1;
        }
        return 0;
    }

    function purchaseWhitelistValidator(address purchaseUser, bytes memory sign, uint256 amount) private {
        // basic validate
        require(_private_sell_start > 0, "Not start selling yet(1)");
        require(block.timestamp >= _private_sell_start, "Not start selling yet(2)");
        require(_public_sell_start == 0, "Private sale is over");
        require(amount >= 1, "at least purchase 1");
        require((_numberMinted(purchaseUser) + amount) <= MINT_LIMIT, "purchase over limit");
        require(msg.value >= (W_PRICE * amount), "insufficient value");
        
        require(verify(purchaseUser, sign), "this sign is not valid");
    }

    /// @dev external method to verify the owner of the token
    function isOwner(uint256 nftID, address owner) external view returns(bool isNFTOwner) {
        address tokenOwner = ownerOf(nftID);
        isNFTOwner = (tokenOwner == owner);
    }

    function mintedNunber(address addr) external override view returns(uint256) {
        return _numberMinted(addr);
    }

    /// @dev show all purchased nfts by Arrays
    /// @return tokens nftID array
    function listMyNFT(address owner) external view returns (uint256[] memory tokens) {
        uint256 owned = balanceOf(owner);
        tokens = new uint256[](owned);
        uint256 start = 0;
        for (uint i=0; i<totalSupply(); i++) {
            if (ownerOf(i) == owner) {
                tokens[start] = i;
                start ++;
            }
        }
    }

    function purchaseValidator(address purchaseUser, uint256 amount) private {
        // basic validate
        require(_public_sell_start > 0, "Not start selling yet(21)");
 
        require(amount >= 1, "at least purchase 1");
        require(purchaseUser != address(0), "invalid address");
        require(msg.value >= (N_PRICE * amount), "insufficient value");

    }


    /// @dev user doing purchase
    /// @param amount how many
    function purchaseNFT(uint256 amount) external payable {
        address purchaseUser = msg.sender;
        purchaseValidator(purchaseUser, amount);
        mintTo(purchaseUser, amount);
    }


    /// @dev mint function
    function mintTo(address purchaseUser, uint256 amount) private {
        isEnough(amount);
        _safeMint(purchaseUser, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// Admin Functions
    //////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////
    function batchMint(address wallet, uint amount) external onlyOwner {
        mintTo(wallet, amount);
    }

    function setBaseData(bool isRevealed, string memory uri) external onlyOwner {
        _base_uri = uri;
        _is_revealed = isRevealed;
    }

    function setReveal(bool reveal_) external onlyOwner {
        _is_revealed = reveal_;
    }

    function withdrawETH(address wallet) external onlyOwner {
        payable(wallet).transfer(address(this).balance);
    }

    function withdrawTo(address wallet, uint256 amount) external onlyOwner {
        payable(wallet).transfer(amount);
    }

    function updateBlindboxURI(string memory url) external onlyOwner {
        _blindbox_uri = url;
    }

    function updatePriceW(uint256 price_) external onlyOwner {
        W_PRICE = price_;
    }

    function updatePriceN(uint256 price_) external onlyOwner {
        N_PRICE = price_;
    }

    function updateMintLimit(uint256 limit_) external onlyOwner {
        MINT_LIMIT = limit_;
    }
    
    function updatePrivateSale(uint256 time_) external onlyOwner {
        _private_sell_start = time_;
    }
    
    function updatePublicSale(uint256 time_) external onlyOwner {
        _public_sell_start = time_;
    }

    function updateSigner(address signer_) external onlyOwner {
        SIGNER = signer_;
    }

    function updateInventory(uint256 inventory_) external onlyOwner {
        INVENTORY = inventory_;
    }

    function parameters() external view returns (uint256 inventory, uint256 privatePrice, uint256 publicPrice, uint256 mintLimit, uint256 privateStart, uint256 publicStart, uint256 sellType) {
        inventory = INVENTORY;
        privatePrice = W_PRICE;
        publicPrice = N_PRICE; 
        mintLimit = MINT_LIMIT;
        privateStart = _private_sell_start;
        publicStart = _public_sell_start; 
        sellType = querySellType();
    }

    function verify(address _user, bytes memory _signatures) public view returns (bool) {
        bytes32 message = keccak256(abi.encodePacked(_user, address(this)));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        address[] memory signList = recoverAddresses(hash, _signatures);
        return signList[0] == SIGNER;
    }

    function recoverAddresses(bytes32 _hash, bytes memory _signatures) internal pure returns (address[] memory addresses) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint count = _countSignatures(_signatures);
        addresses = new address[](count);
        for (uint i = 0; i < count; i++) {
            (v, r, s) = _parseSignature(_signatures, i);
            addresses[i] = ecrecover(_hash, v, r, s);
        }
    }
    
    function _parseSignature(bytes memory _signatures, uint _pos) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        uint offset = _pos * 65;
        assembly {
            r := mload(add(_signatures, add(32, offset)))
            s := mload(add(_signatures, add(64, offset)))
            v := and(mload(add(_signatures, add(65, offset))), 0xff)
        }

        if (v < 27) v += 27;

        require(v == 27 || v == 28);
    }
    
    function _countSignatures(bytes memory _signatures) internal pure returns (uint) {
        return _signatures.length % 65 == 0 ? _signatures.length / 65 : 0;
    }

}