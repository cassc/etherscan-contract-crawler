// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import './DefaultOperatorFilterer.sol';

contract NoblyWorld is ERC721Enumerable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    using Strings for uint256;

    string baseURI;
    bool public _revealed = false;
    string private _notRevealedUri;
    string private _baseExtension = ".json";

    // Market and minting
    bool public mintingActive = false;
    uint256 public _maxSupply = 33;
    uint256 public _maxLimitPerMint = 33;
    uint _reservedTokens = 33;
    uint256 _mintPrice = 0;

    uint256 _totalClaimable = 0;
    uint256 _marketplaceVolume = 0;
    uint256 _minterFee = 3;
    uint256 _marketFee = 0;
    address _marketFeeAddress = address(0);

    // original minters
    mapping (uint256 => address) _minters;
    mapping (address => uint256) _claimable;
    mapping(address => uint) public _minted;

    // Buy and Sell
    struct Listing {
        uint256 price;
        TokenState state;
        address seller;
    }
    enum TokenState {
        Neutral,
        ForSale,
        Sold
    }
    mapping(uint256 => Listing) Marketplace;

    uint256[] ForSale;

    struct BuyInfo {
        address buyer;
        uint256 price;
        uint256 buyTime;
    }

    mapping(uint256 => BuyInfo[]) _buyers;
    
    /// @notice Event emitted when tokens are claimed by a recipient from a grant
    event AddClaim(address indexed recipient, uint256 indexed amountClaimable);
    
    /// @notice Event emitted when tokens are claimed by a recipient from a grant
    event Claimed(address indexed recipient, uint256 indexed amountClaimed);

    event NewBaseURI(string newURI, address updatedBy);
    event BoughtListing(uint256 tokenId, uint256 value);
    event SetListing(uint256 id, uint256 price);
    event CanceledListing(uint256 tokenId);

    constructor() ERC721("Nobly World", "NoblyWorld") {
        _notRevealedUri = "https://pink-lazy-jay-804.mypinata.cloud/ipfs/QmWJ3QAvR25RhCC1Bbkbg2am5QUNKuq1UW27Ug65kW29GP/24.json";
        baseURI = "https://pink-lazy-jay-804.mypinata.cloud/ipfs/QmWJ3QAvR25RhCC1Bbkbg2am5QUNKuq1UW27Ug65kW29GP";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;

        emit NewBaseURI(baseURI, msg.sender);
    }

    function setNotRevealedURI(string memory notRevealedURI) public onlyOwner {
        _notRevealedUri = notRevealedURI;
    }

    function reveal(bool show) public onlyOwner() {
        _revealed = show;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(_revealed == false && msg.sender != owner()) {
            return _notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, "/", tokenId.toString(), _baseExtension)) : "";
    }

    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        override(ERC721, IERC721) 
        onlyAllowedOperator(from) 
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public 
        override(ERC721, IERC721)  
        onlyAllowedOperator(from) 
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721) 
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Get token grant for recipient
     * @dev Returns 0 if `deadline` is reached
     * @param recipient The address that has a grant
     * @return The amount recipient can claim
     */
    function getClaimableRoyalties(address recipient) public view returns(uint256) {
        return _claimable[recipient];
    }

    /**
     * @notice Allows a recipient to claim their tokens
     * @dev Errors if no tokens are available
     */
    function claimRoyalties() external {
        uint256 availableToClaim = getClaimableRoyalties(_msgSender());
        require(availableToClaim > 0, "claim: availableToClaim is 0");

        _claimable[_msgSender()] = 0;
        _totalClaimable = _totalClaimable - availableToClaim;

        require(payable(_msgSender()).send(availableToClaim));

        emit Claimed(_msgSender(), availableToClaim);
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    function mintNoblyWorld(uint256 maxNFT) public payable nonReentrant {
        require(mintingActive == true, "Sale inactivate");
        require(
            maxNFT > 0 && maxNFT <= _maxLimitPerMint,
            "You must mint a minimum 1 and maximum of 3"
        );
        require(_minted[_msgSender()] + maxNFT <= _maxLimitPerMint, "Can't mint tokens anymore");
        require(totalSupply() + maxNFT + _reservedTokens <= _maxSupply, "Exceeds max supply");
        require(msg.value >= _mintPrice * maxNFT, "Value sent is below the price");

        for (uint256 i = 0; i < maxNFT; i++) {
            uint256 mintIndex = totalSupply() + 1;

            _safeMint(_msgSender(), mintIndex);

            _minters[mintIndex] = _msgSender();
            _minted[_msgSender()] ++;
        }
    }

    // ONLYOWNER FUNCTIONS
    
    function setMaxSupply(uint256 maxSupply) public onlyOwner {
        _maxSupply = maxSupply;
    }
    
    function setMinterFee(uint256 minterFee) public onlyOwner {
        _minterFee = minterFee;
    }

    function setMarketFee(uint256 marketFee) public onlyOwner {
        _marketFee = marketFee;
    }

    function setMarketFeeAddress(address marketFeeAddress) public onlyOwner {
        _marketFeeAddress = marketFeeAddress;
    }

    function reserve(uint256 maxNFT) external nonReentrant onlyOwner {
        require(maxNFT <= _reservedTokens, "Exceeds reserved token count");
        for (uint256 i = 0; i < maxNFT; i++) {
            uint256 mintIndex = totalSupply() + 1;

            _safeMint(_msgSender(), mintIndex);

            _minters[mintIndex] = _msgSender();

            _reservedTokens--;
        }
    }

    function startMint(bool start) external onlyOwner {
        mintingActive = start;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
    }

    // MARKET
    function setListing(uint256 tokenId, uint256 price) public {
        require(msg.sender == ownerOf(tokenId));

        bool found = false;
        for (uint256 i = 0; i < ForSale.length; i++) {
            if (ForSale[i] == tokenId) {
                found = true;
            }
        }
        if (found == false) {
            ForSale.push(tokenId);
        }
        Marketplace[tokenId].price = price;
        Marketplace[tokenId].state = TokenState.ForSale;
        Marketplace[tokenId].seller = msg.sender;

        emit SetListing(tokenId, price);
    }

    function cancelListing(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId));

        delete Marketplace[tokenId].price;
        delete Marketplace[tokenId].seller;

        Marketplace[tokenId].state = TokenState.Neutral;
        
        for(uint256 i = 0; i < ForSale.length; i++) {
            if (ForSale[i] == tokenId) {
                ForSale[i] = ForSale[ForSale.length - 1];
                ForSale.pop();
                break;
            }
        }

        emit CanceledListing(tokenId);
    }

    function buyListing(uint256 tokenId) public payable {
        address tokenOwner = ownerOf(tokenId);
        require(Marketplace[tokenId].seller == tokenOwner, "Seller is not owner of this item");
        require(msg.sender != tokenOwner, "msg.sender is the owner of this item");

        address payable seller = payable(tokenOwner);

        require(msg.value >= Marketplace[tokenId].price, "Incorrect amount");
        require(TokenState.ForSale == Marketplace[tokenId].state, "Not for sale");

        uint256 minterFee = 0;
        uint256 marketFee = 0;
        uint256 afterFee = 0;
        
        if (Marketplace[tokenId].price >= 0) {
            minterFee = royaltyOf(msg.value, _minterFee);
            marketFee = royaltyOf(msg.value, _marketFee);
            afterFee = msg.value - minterFee - marketFee;

            address minter = _minters[tokenId];

            seller.transfer(afterFee);

            // Make royalty fee claimable and add to total
            _claimable[minter] += minterFee;
            _totalClaimable += minterFee;

            // Make market fee claimable and add to total
            _claimable[_marketFeeAddress] += marketFee;
            _totalClaimable += marketFee;

            _marketplaceVolume += msg.value;

            _buyers[tokenId].push(BuyInfo({
                buyer: msg.sender,
                price: msg.value,
                buyTime: block.timestamp
            }));
            
            emit AddClaim(minter, minterFee);
        }

        // TRANSFER NFT
        _transfer(ownerOf(tokenId), msg.sender, tokenId);
        Marketplace[tokenId].state = TokenState.Sold;

        // MARK NFT AS SOLD
        for(uint256 i = 0; i < ForSale.length; i++) {
            if (ForSale[i] == tokenId) {
                ForSale[i] = ForSale[ForSale.length - 1];
                ForSale.pop();
                break;
            }
        }

        emit BoughtListing(tokenId, msg.value);
    }

    function reArrangeSetSellList() public onlyOwner {
        uint deleteItems;
        uint tokenId;
        for (uint256 i = 0; i < ForSale.length; i++) {
            address tokenOwner = ownerOf(ForSale[i]);
            tokenId = ForSale[i];
            if (Marketplace[tokenId].seller != tokenOwner) {
                delete Marketplace[tokenId].price;
                delete Marketplace[tokenId].seller;
                Marketplace[tokenId].state = TokenState.Neutral;

                ForSale[i] = ForSale[ForSale.length - 1 - deleteItems];
                deleteItems ++;
            }
        }

        for (uint256 j = 0; j < deleteItems; j++) {
            ForSale.pop();
        }
    }

    function getForSale() public view returns(uint256[] memory) {
        return ForSale;
    }

    // View function to see user's buyer info.
    function getBuyInfo(uint8 tokenId) public view returns (BuyInfo[] memory) {
        return _buyers[tokenId];
    }

    function getPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function getMarketVolume() public view returns (uint256) {
        return _marketplaceVolume;
    }
    
    function getMarketFee() public view returns (uint256) {
        return _marketFee;
    }

    function getMinterFee() public view returns (uint256) {
        return _minterFee;
    }

    function getReservedTokens() public view returns (uint256) {
        return _reservedTokens;
    }

    function getMarketplace(uint tokenId) public view returns (uint price, TokenState state, address seller) {
        address tokenOwner = ownerOf(tokenId);
        if (Marketplace[tokenId].seller != address(0) 
            && Marketplace[tokenId].seller != tokenOwner)
            return (0, TokenState.Neutral, address(0));
        else
            return (Marketplace[tokenId].price, Marketplace[tokenId].state, Marketplace[tokenId].seller);
    }

    function royaltyOf(uint256 amount, uint256 fee) internal pure returns (uint256) {
        uint256 toReceiver = amount * fee / 100;
        return toReceiver;
    }

    function minterOf(uint256 tokenId) public view returns (address) {
        return _minters[tokenId];
    }

    function withdraw(uint256 value) external payable nonReentrant onlyOwner  {
        require(payable(_msgSender()).send(value));
    }
    
    function withdrawAll() external payable nonReentrant onlyOwner {
        require(payable(_msgSender()).send(address(this).balance - _totalClaimable));
    }
}