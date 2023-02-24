/*

https://baseayc.com

                    ___           ___           ___     
     _____         /  /\         /  /\         /  /\    
    /  /::\       /  /::\       /  /:/_       /  /:/_   
   /  /:/\:\     /  /:/\:\     /  /:/ /\     /  /:/ /\  
  /  /:/~/::\   /  /:/~/::\   /  /:/ /::\   /  /:/ /:/_ 
 /__/:/ /:/\:| /__/:/ /:/\:\ /__/:/ /:/\:\ /__/:/ /:/ /\
 \  \:\/:/~/:/ \  \:\/:/__\/ \  \:\/:/~/:/ \  \:\/:/ /:/
  \  \::/ /:/   \  \::/       \  \::/ /:/   \  \::/ /:/ 
   \  \:\/:/     \  \:\        \__\/ /:/     \  \:\/:/  
    \  \::/       \  \:\         /__/:/       \  \::/   
     \__\/         \__\/         \__\/         \__\/    


*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BaseAYC is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using Strings for uint256;
  uint256 public maxMintAmountPerWallet; 
  uint256 public teamSupply;
  
  string public uriPrefix;
  string public hiddenMetadataUri = 'https://baseayc.com/metadata.json';
  string public uriSuffix = '.json';

  uint256 public whitelistMintCost;

  bool public paused = true;
  bool public revealed = false;

  constructor() ERC721A(
        "BaseAYC",
        "BAYC"
    ) {
    _safeMint(msg.sender, 1);
  }

  /**
  @dev Gets price based on current supply
    // tokens 0 - 1000 ~~~~~~~~~~~~~ free
    // tokens 1001 - 2000 ~~~~~~~~~~ .004 eth
    // tokens 2001 - 3000 ~~~~~~~~~~ .008 eth
  */
  function getPrice() public view returns (uint256) {
    uint256 minted = totalSupply();
    uint256 cost = 0;
    if (minted < 1000) {
        cost = 0;
    } else if (minted < 2000) {
        cost = 0.004 ether;
    } else if (minted < 3000) {
        cost = 0.008 ether;
    } else {
        cost = 0.008 ether;
    }
    return cost;
  }

  function mint(uint256 _mintAmount) public payable nonReentrant {
    require(!paused, 'Mint has not started.');
    uint256 price = getPrice();


    uint256 _maxPerWallet = 10; // 10 per transaction
    if (price == 0) {
      _maxPerWallet = 1;
    }

    if ((msg.value >= _mintAmount * price) && price != 0) {
    } else {
      require(
        _numberMinted(msg.sender) + _mintAmount <= _maxPerWallet,
        "Free mint claimed!"
      );
    }

    require(msg.value >= _mintAmount * price, 'Insufficient Funds!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function teamMint(address[] memory _staff_address) public onlyOwner payable {
    require(_staff_address.length <= teamSupply, '');
    for (uint256 i = 0; i < _staff_address.length; i ++) {
      _safeMint(_staff_address[i], 1);
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }


  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, "/", _tokenId.toString(), uriSuffix))
    : '';
  }

  /**
  @dev Set revealed
  */
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  /**
  @dev Unrevealed metadata url
  */
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  /**
  @dev Set the uri suffix
  */
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  /**
  @dev Set the uri suffix (i.e .json)
  */
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  /**
  @dev Set mint price
  */
  function setMintCost(uint256 _wlCost) public onlyOwner {
      whitelistMintCost = _wlCost;
  }

  /**
  @dev Set sale is active (paused / unpaused)
  */
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }


  /**
  @dev Sets the amount allocated for team members
  */
  function setTeamAmount(uint256 _teamSupply) public onlyOwner {
    teamSupply = _teamSupply;
  }

  /**
  @dev Withdraw function
  */
  function withdraw() public onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  /**
  @dev OpenSea
  */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
  public payable
  override
  onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}