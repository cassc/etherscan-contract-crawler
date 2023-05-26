pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


contract MekaY00ts is Ownable, ERC721A, ReentrancyGuard {
    string   public       baseURI;
    bool     public       publicSale                      = false;
    uint256  public       amountFree                      = 606;
    uint256  public       price                           = 0.002 ether;
    uint     public       maxFreePerWallet                = 2;
    uint     public       maxPerTx                        = 10;
    uint     public       maxSupply                       = 808;

    constructor() ERC721A ( "MekaY00ts", "MekaY00ts") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setFree(uint256 amount) external onlyOwner {
        amountFree = amount;
    }

    function freeMint(uint256 quantity) external callerIsUser {
        require(publicSale, "Public sale has not begun yet");
        require(totalSupply() + quantity <= amountFree, "Reached max free supply");
        require(numberMinted(msg.sender) + quantity <= maxFreePerWallet,"Too many free per wallet!");
        _safeMint(msg.sender, quantity);
    }


  function setMaxFreePerWallet(uint256 maxFreePerWallet_) external onlyOwner {
      maxFreePerWallet = maxFreePerWallet_;
  }

    function mint(uint256 quantity) external payable callerIsUser {
        require(publicSale, "Public sale has not begun yet");
        require(totalSupply() + quantity <= maxSupply,"Reached max supply");
        require(quantity <= maxPerTx, "can not mint this many at a time");
        require(msg.value >= price * quantity , "Ether value sent is not correct");

        _safeMint(msg.sender, quantity);
    }

  function ownerMint(uint256 quantity) external onlyOwner
  {
    require(totalSupply() + quantity < maxSupply + 1,"too many!");

    _safeMint(msg.sender, quantity);
  }


  function setmaxPerTx(uint256 maxPerTx_) external onlyOwner {
      maxPerTx = maxPerTx_;
  }

  function setmaxSupply(uint256 maxSupply_) external onlyOwner {
      maxSupply = maxSupply_;
  }


	function setprice(uint256 _newprice) public onlyOwner {
	    price = _newprice;
	}
    
    function setSaleState(bool state) external onlyOwner {
        publicSale = state;
    }


  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

}