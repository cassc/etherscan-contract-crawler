// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import 'openzeppelin-contracts/security/ReentrancyGuard.sol';
import 'operator-filter-registry/DefaultOperatorFilterer.sol';
import 'openzeppelin-contracts/access/Ownable.sol';
import 'openzeppelin-contracts/utils/Strings.sol';
import 'ERC721A/ERC721A.sol';

import './INFT2.sol';

contract NFT is
ERC721A,
ReentrancyGuard,
DefaultOperatorFilterer,
Ownable {
  using Strings for uint256;

/******************** Variables ***********************/
  //##### State Variables #####
  bool public publicSale = false;
  bool public revealed = false;

  //##### Minting Variables #####
  uint256 public price = 0.025 ether;
  uint256 public supplyLimit = 10000;
  uint256 public maxTokensPerWallet = 50;
  // Does not include bonus
  uint256 public maxMintAmountPerTx = 20;

  //##### Metadata Variables #####
  string internal uri;
  string public uriSuffix = ".json";
  string public hiddenMetadataUri = "https://philaladys.com/hidden.json";

  //##### Royalty Variables #####
  address internal _royaltyReceiver;
  uint256 internal _royaltyBps = 500;


/******************** End of Variables***********************/
  
  constructor() 
  ERC721A("PhilaLadys", "PLADY") {
    // Royalty Receiver defaults to contract creator
    uri = "https://meta.philaladys.com/";
    setRoyaltyReceiver(msg.sender);
    setRevealed(true);

  }


/******************** Modifiers ***********************/
  function _checkPublicSale() internal view {
    require(publicSale == true, 'Public sale is not active');
  }

  function _checkReveal() internal view {
    require(revealed == true, 'Not revealed yet');
  }

  function _checkMaxMintAmount(uint256 _mintAmount) internal view {
    require(_mintAmount <= maxMintAmountPerTx, 'Max mint amount per tx exceeded');
  }

  function _checkMaxTokensPerWallet(uint256 _mintAmount, address _receiver) internal view {
    require(balanceOf(_receiver) + _mintAmount <= maxTokensPerWallet, 'Max tokens per wallet exceeded');
  }

  function _checkPrice(uint256 _mintAmount) internal view {
    require(msg.value >= price * _mintAmount, 'Ether value sent is not correct');
  }

  function _checkSupply(uint256 _mintAmount) internal view {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded');
  }



/******************** End of Modifiers ***********************/

/******************** Minting Functions ***********************/

  function remainingSupply() public view returns (uint256) {
    return supplyLimit - totalMinted();
  }

  function calcBonus(uint256 _mintAmount) public pure returns (uint256) {
    if (_mintAmount >= 10) {
      return 2;
    } else if (_mintAmount >= 5) {
      return 1;
    }
    else {
      return 0;
    }
  }

  function totalToMint(uint256 _mintAmount) public view returns (uint256) {
    uint256 _total = _mintAmount + calcBonus(_mintAmount);
    uint256 _remaining = remainingSupply();
    _checkSupply(_mintAmount);

    if (_total <= _mintAmount) {
      return _mintAmount;
    } else if (_total <= _remaining) {
      return _total;
    } else {
      while (_total > _mintAmount) {
        _total -= 1;
        if (_total <= _remaining) {
          return _total;
        } else if (_total <= _mintAmount) {
          return _mintAmount;
        }
      }
    }

   
    
  }

  function totalMinted() public view returns (uint256) {
    return _totalMinted();
  }




  function mint(uint256 _mintAmount, address _receiver) public payable nonReentrant {
    _checkPublicSale();
    //_checkReveal();
    require(_mintAmount > 0, 'Mint amount must be greater than 0');
    require(_receiver != address(0), 'Receiver cannot be the zero address');
    _checkMaxMintAmount(_mintAmount);
    _checkMaxTokensPerWallet(_mintAmount, _receiver);
    _checkPrice(_mintAmount);
    _checkSupply(_mintAmount);
    uint256 _total = totalToMint(_mintAmount);

    _safeMint(_receiver, _total);
  }

  function OwnerMint(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

/******************** End of Minting Functions ***********************/



/******************** Setter Functions ***********************/
/******************** State Toggle Functions ***********************/
  function setPublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }
  
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }
/******************** End of State Toggle Functions ***********************/

/******************** Metadata Functions ***********************/
//##### Metadata View Functions #####
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

//##### Metadata Setter Functions #####
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }
  
/******************** End of Metadata Functions ***********************/

/******************** Minting Config Functions ***********************/
//##### Minting Config Setter Functions #####
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxTokensPerWallet(uint256 _maxTokensPerWallet) public onlyOwner {
    maxTokensPerWallet = _maxTokensPerWallet;
  }

  function setSupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

//##### Minting Config View Functions #####

/******************** End of Minting Config Functions ***********************/




/******************** Admin Functions ***********************/


  //##### Withdraw Function #####

  function withdraw() public onlyOwner nonReentrant {
    // This will pay ReservedSnow 2% of the initial sale.
    //(bool rs, ) = payable(0xd4578a6692ED53A6A507254f83984B2Ca393b513).call{value: address(this).balance * 2 / 100}('');
    //require(rs);

    //owner withdraw
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

/******************** End of Admin Functions ***********************/

// ================== Read Functions Start =======================

  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
}


/******************** Transfer Functions ***********************/

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }  

/******************** End of Transfer Functions ***********************/


/******************** Operator Functions ***********************/
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

/******************** End of Operator Functions ***********************/


  //##### Functions #####
/******************** Functions ***********************/
/******************** End of  Functions ***********************/





/******************** ERC2981 Royalty Functions ***********************/
  //##### View Functions #####
  function royaltyReceiver() external view returns (address) {
    return _royaltyReceiver;
  }

  function royaltyBps() public view returns (uint256) {
    return _royaltyBps;
  }

  //##### Setter Functions #####
  function setRoyaltyReceiver(address receiver) public onlyOwner {
    _royaltyReceiver = receiver;
  }

  function setRoyaltyBps(uint256 bps) public onlyOwner {
    require(bps <= 10000, "Royalty bps should be less than 10000");
    _royaltyBps = bps;
  }

//##### Royalty Functions #####
  function _calcRoyaltyFee(uint256 salePrice) internal view returns (uint256) {
    return (salePrice * _royaltyBps) / 10000;
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    return (_royaltyReceiver, _calcRoyaltyFee(salePrice));
  }


/******************** End of ERC2981 Functions ***********************/

/******************** ERC165 Functions ***********************/
function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
    return
      // Supports ERC721
      interfaceId == 0x80ac58cd ||
      // Supports ERC721 Metadata
      interfaceId == 0x5b5e139f ||
      // Supports ERC721 Enumerable
      interfaceId == 0x780e9d63 ||
      // Supports ERC2981
      interfaceId == 0x2a55205a ||
      // Supports ERC165
      interfaceId == 0x01FFC9A7;
}
/******************** End of ERC165 Functions ***********************/

}