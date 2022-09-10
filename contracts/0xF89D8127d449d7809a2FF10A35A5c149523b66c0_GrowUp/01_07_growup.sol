// SPDX-License-Identifier: UNLICENSED
//🅽🅾🅱🅾🅳🆈 🅺🅽🅾🆆🆂 🆆🅷🅰🆃 🅸🆃 🅸🆂 ...🅰🅽 🆄🅽🅺🅽🅾🆆🅽 🅻🅸🅵🅴 🅵🅾🆁🅼 ...🅱🅴 🅱🅾🆁🅽, 🅶🆁🅾🆆, 🅲🅷🅰🅽🅶🅴 🅰🅽🅳 🅳🅸🅴
//"🄽🄾🄱🄾🄳🅈 🄺🄽🄾🅆🅂 🅆🄷🄰🅃 🄸🅃 🄸🅂 ... 🄱🅄🅃 🄸🅃 🄻🄸🅅🄴🅂!"
//www.grow-up.wtf

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract GrowUp is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRICE = 0.01 ether; //  10000000000000000 wei price
    uint256 public MAX_SUPPLY = 3333; 
    uint256 public FREE_MINT_LIMIT_PER_WALLET = 2; // Max 2 free mints per wallet
    uint256 public MAX_MINT_AMOUNT_PER_TX = 10; 
    uint256 public FREE_MINT_IS_ALLOWED_UNTIL = 1000; // Free Mints until 1000 others 2333 at 0.01 eth
    uint256 internal currentIndex;

    bool public revealed = false;
    bool public IS_SALE_ACTIVE = true; 
    
    string public BASE_URI = "";
    string public notRevealedUri = "https://growup.sfo3.digitaloceanspaces.com/unrevealed.json" ; 
    
    mapping(address => uint256) private freeMintCountMap;

    constructor() ERC721A("GrowUp", "GRW") {}

    function updateFreeMintCount(address minter, uint256 count) private {
        freeMintCountMap[minter] += count;
    }
    
    function freeMintCount(address addr) public view returns (uint256) {
        return freeMintCountMap[addr];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }
    
    function setPrice(uint256 customPrice) external onlyOwner {
        PRICE = customPrice;
    }

    function lowerMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < MAX_SUPPLY, "Invalid new max supply");
        require(newMaxSupply >= currentIndex, "Invalid new max supply");
        MAX_SUPPLY = newMaxSupply;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        
        BASE_URI = customBaseURI_;
    }

    function setFreeMintAllowance(uint256 freeMintAllowance) external onlyOwner {
        FREE_MINT_LIMIT_PER_WALLET = freeMintAllowance;
    }

    function setMaxMintPerTx(uint256 maxMintPerTx) external onlyOwner {
        MAX_MINT_AMOUNT_PER_TX = maxMintPerTx;
    }

    function setSaleActive(bool saleIsActive) external onlyOwner {
        IS_SALE_ACTIVE = saleIsActive;
    }
    
    function setRevealed(bool _revealed) public onlyOwner {
      revealed = _revealed;
    }

    function setFreeMintAllowedUntil(uint256 freeMintIsAllowedUntil) external onlyOwner {
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

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= MAX_MINT_AMOUNT_PER_TX, "Invalid mint amount!");
        require(currentIndex + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
        _;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
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

    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    // withdraw address
  address t1 = 0xECFb040c27CfE97EE4bD804d56e7D487Ce979160; 

     /// @notice Withdraw contract balance
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance");
        
        payable(t1).transfer((balance * 100)/100);
    }
}