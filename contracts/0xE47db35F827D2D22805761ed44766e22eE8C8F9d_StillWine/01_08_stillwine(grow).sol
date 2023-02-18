// SPDX-License-Identifier: UNLICENSED
// https://ipfs.io/ipfs/bafkreibywctgivmooiqjshbqmygakegu4wa3psvolqcft5f5y7dzmdggi4/
// https://twitter.com/DaChugger
//🍷
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract StillWine is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint64 public PRICE = 0.001 ether; 
    uint16 public MAX_SUPPLY = 25000; 
    uint8 public FREE_MINT_LIMIT_PER_WALLET = 10; // 10 Max free mints per wallet allowed
    uint8 public MAX_MINT_AMOUNT_PER_TX = 100; 
    uint64 public FREE_MINT_IS_ALLOWED_UNTIL = 2500; // Free Mints 10% of collection, then 0.001 eth
    uint16 internal currentIndex;

    bool public revealed = true;
    bool public IS_SALE_ACTIVE = true; 
    
    string public BASE_URI = "https://still-wine.nyc3.digitaloceanspaces.com/metadata/";
    string public notRevealedUri = "https://ipfs.io/ipfs/bafkreih7v3kcyzx2dwxjdjia4yjuuozzn6tcni6p24cjg23ogwwhboerpy/" ; 
    
    mapping(address => uint256) private freeMintCountMap;

    constructor() ERC721A("Still Wine.", "RED") {}

    function updateFreeMintCount(address minter, uint256 count) private {
        freeMintCountMap[minter] += count;
    }
    
    function freeMintCount(address addr) public view returns (uint256) {
        return freeMintCountMap[addr];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }
    
    function setPrice(uint64 customPrice) external onlyOwner {
        PRICE = customPrice;
    }

    function lowerMaxSupply(uint16 newMaxSupply) external onlyOwner {
        require(newMaxSupply < MAX_SUPPLY, "Invalid new max supply");
        require(newMaxSupply >= currentIndex, "Invalid new max supply");
        MAX_SUPPLY = newMaxSupply;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        
        BASE_URI = customBaseURI_;
    }

    function setFreeMintAllowance(uint8 freeMintAllowance) external onlyOwner {
        FREE_MINT_LIMIT_PER_WALLET = freeMintAllowance;
    }

    function setMaxMintPerTx(uint8 maxMintPerTx) external onlyOwner {
        MAX_MINT_AMOUNT_PER_TX = maxMintPerTx;
    }

    function setSaleActive(bool saleIsActive) external onlyOwner {
        IS_SALE_ACTIVE = saleIsActive;
    }
    
    function setRevealed(bool _revealed) public onlyOwner {
      revealed = _revealed;
    }

    function setFreeMintAllowedUntil(uint64 freeMintIsAllowedUntil) external onlyOwner {
        FREE_MINT_IS_ALLOWED_UNTIL = freeMintIsAllowedUntil;
    }
    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
  }

    modifier mintCompliance(uint128 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= MAX_MINT_AMOUNT_PER_TX, "Invalid mint amount!");
        require(currentIndex + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
        _;
    }

    function mint(uint128 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(IS_SALE_ACTIVE, "Sale is not active!");

        uint256 price = PRICE * _mintAmount;

        if (currentIndex < FREE_MINT_IS_ALLOWED_UNTIL) {
            uint256 remainingFreeMint = FREE_MINT_LIMIT_PER_WALLET - freeMintCountMap[msg.sender];
            if (remainingFreeMint > 0) {
                if (_mintAmount >= remainingFreeMint) {
                    price -= remainingFreeMint * PRICE;
                    updateFreeMintCount(msg.sender, remainingFreeMint);
                } else {
                    price -= _mintAmount * PRICE;
                    updateFreeMintCount(msg.sender, _mintAmount);
                }
            }
        }

        require(msg.value >= price, "Insufficient funds!");

        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint128 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    // withdraw address
  address t1 = 0x694aAA8Fe91411f7B11ba7F9f77d0B64E08dF719; 

     /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        
        payable(t1).transfer((balance * 100)/100);
    }

       function withdrawToThisAddress() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    
  }
}