// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IFactoryERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**v
 * @title TooneyLootBox
 *
 * TooneyLootBox - a tradeable loot box of Tooney.
 */
contract TooneyLootBox is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    /** counter */
    Counters.Counter private _nextTokenId;

    /** token uri */
    string internal baseTokenURI;
    
    /** factory */
    address factoryAddress;
    uint256 constant UNPACK_FACTORY_OPTION = 3;

    /** number of items */
    uint256 numberOfItemsPerBox = 5;

    /** discount */
    uint256 public price = 0.25 ether; 
    uint256 public discount = 10;
    uint256 internal constant HUNDRED_PERCENT = 100;

    mapping(uint256 => uint256) internal prices;
    uint256[] public tokenIds;

    constructor(address _factoryAddress, string memory _baseTokenURI, address _ownerAddress) 
        ERC721("TooneyLootBox", "TOONCLBX")
    {
        factoryAddress = _factoryAddress;
        setBaseURI(_baseTokenURI);
        transferOwnership(_ownerAddress);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

     /** 
     * Set number of items per lootbox
     */
    function setItemsPerLootBox(uint256 newNumber) external virtual onlyOwner {
        numberOfItemsPerBox = newNumber;
    }

    function itemsPerLootBox() public view returns (uint256) {
        return numberOfItemsPerBox;
    }

    /** 
     * Set price of a lootbox
     */
    function setPrice(uint256 newPrice) public virtual onlyOwner {
        price = newPrice;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    /**
     * @notice Set discount for each purchase.
     * @param _percent Bonus percent.
     */
    function setDiscount(uint256 _percent) external onlyOwner {
        require(_percent <= HUNDRED_PERCENT, "Discount cannot be more than 100%");
        
        discount = _percent;
    }

    function getDiscount() public view returns (uint256) {
        return discount;
    }
    
    function preSale(address _to, uint256 _count, bytes32 hash, bytes memory signature) external payable nonReentrant {
        require(
            recoverSigner(hash, signature) == owner(),
            "PreSale. Address is not allowlisted."
        );

        uint256 _price = price - (price * discount / HUNDRED_PERCENT);        
        require(msg.value >= _price * _count, "PreSale. Lootboxes mint value is smaller than the minimum mint price.");   

        for (uint256 i = 0; i < _count; i++) {
            uint256 tokenId = mintTo(_to);
            setLootBoxPrice(tokenId, _price);
        }
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        public
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function purchase(address _to, uint256 _count) external payable nonReentrant {
        uint256 _price = price - (price * discount / HUNDRED_PERCENT);        
        require(msg.value >= _price * _count, "Lootboxes mint value is smaller than the minimum mint price");   

        for (uint256 i = 0; i < _count; i++) {
            uint256 tokenId = mintTo(_to);
            setLootBoxPrice(tokenId, _price);
        }
    }

    function mintTo(address _to) virtual internal returns(uint256) {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
        return currentTokenId;
    }

    function unpack() external payable nonReentrant {
        uint256 balance = balanceOf(_msgSender());
        require(balance > 0, "You don't have any item");
        
        for (uint256 i = 0; i < balance; i++) {
            tokenIds.push(tokenOfOwnerByIndex(_msgSender(), i) );
        }
        
        uint256 _tokenId = tokenIds[tokenIds.length - 1];
        FactoryERC721 factory = FactoryERC721(factoryAddress);
        uint256 savedPrice = getLootBoxPrice(_tokenId);
        factory.mint{value: savedPrice}(UNPACK_FACTORY_OPTION, _msgSender(), itemsPerLootBox());

        // Burn the lootbox.
        _burn(_tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }
    
    function setLootBoxPrice(uint256 _tokenId, uint256 _price) private {
        prices[_tokenId] = _price;
    }

    function getLootBoxPrice(uint256 _tokenId) private view  returns (uint256) {
        return prices[_tokenId];
    }
}