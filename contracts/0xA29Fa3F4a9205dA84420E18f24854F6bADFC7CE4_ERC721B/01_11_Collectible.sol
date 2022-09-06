// SPDX-License-Identifier: MIT

/*
                                                                                                                            ||
                                                                                                                           ||||
                                                                                                                           |||
                   ||||                                                                                             |      ||
              ||||||||||||||                                                                                       |||  ||||||    |
            |||||||||||||||||                                                                                        || |||||||||||||
          ||||||||||||||||||||                                                                                        ||||||
         |||||||||||||||||||||                                                                                      ||||||
        |||||||||||||||||||||                                                                    |                  ||| ||||
       ||||||||||||||||||||||                                                                 |||||||                    |||
      ||||||||||||||||||||||                                                                ||||||||||
     |||||||||||||||||||||                                                                 |||||||||||
    |||||||||||||||||||||                                                                  ||||||||||||
   ||||||||||||||||||||                             ||||||             ||||                |||||||||||||
   ||||||||||||||||||            ||||             |||||||||           ||||||               |||||||||||||            |||||
  ||||||||||||||||             ||||||            |||||||||||         ||||||||              ||||||||||||||           |||||||
  ||||||||||||||              |||||||           ||||||||||||        |||||||||||           |||||||||||||||          |||||||||
  ||||||||||||||             ||||||||          ||||||||||||||       ||||||||||||          |||||||||||||||          ||||||||||
  |||||||||||||             |||||||||         ||||||||||||||||     ||||||||||||||         ||||||||||||||||        ||||||||||||
  |||||||||||||      |     ||||||||||        |||||||||||||||||     ||||||||||||||  |||||||||||||||||||||||        ||||||||||||
  |||||||||||||||||||||||  ||||||||||        ||||||||||||||||||   ||||||||||||||||||||||||||||||||||||||||||||||| |||||||||||||
   ||||||||||||||||||||||| ||||||||||       |||||||||||||||||||   ||||||||||||||||||||||||||||||||||||||||||||||| ||||||||||||||
   ||||||||||||||||||||||||||||||||||       |||||||||||||||||||  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
   ||||||||||||||||||||||||||||||||||      ||||||||||| ||||||||  ||||||||| ||||||||||||||||||||||||||||||||||||| ||||||||||||||||
   ||||||||||||||||||||   |||||||||||      ||||||||||  ||||||||  ||||||||  ||||||||||||||||||||||||||||||||||||  ||||||||||||||||
    |||||||||||||||      ||||||||||||     |||||||||||  |||||||| |||||||||||||||||||||  ||||||||||||||||||       ||||||||||||||||||
    |||||||||||||||      ||||||||||||     |||||||||||  |||||||||||||||||||||||||||||||     |||||||||||||||      ||||||||||||||||||
    |||||||||||||||      |||||||||||||    ||||||||||||||||||||||||||||||||||||||||||||     |||||||||||||||      ||||||||||||||||||
    ||||||||||||||||     |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||     |||||||||||||||      ||||||||||||||||||
     |||||||||||||||     ||||||||||||||||||||||||||||||||||||||||||||||||  |||||||||||      ||||||||||||||      ||||||||||||||||||
     |||||||||||||||     |||||||||||||||||||||||||||||||||||| |||||||||||  ||||||||||||     |||||||||||||||     |||||||||||||||||
      |||||||||||||||    |||||||||||||||||||||||||||||||||||| |||||||||||   ||||||||||      ||||||||||||||||||   |||||||||||||||
       ||||||||||||||     ||||||||||||||||||||||||||||||||||  ||||||||||      ||||||         |||||||||||||||||    |||||||||||||
         |||||||||||       ||||||||||||||||    ||||||||||      |||||                          |||||||||||||||       ||||||||||
             ||||                  ||||||         |||||                                          ||||||||
*/




pragma solidity >=0.8.9 <0.9.0;

import "ERC721AQueryable.sol";
import "ERC721ABurnable.sol";
import "Ownable.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";



contract ERC721B is ERC721AQueryable, ERC721ABurnable, Ownable, ReentrancyGuard {
  using Strings for uint256;

// State variables
  string public metadataUri;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public reservedSupply;
  uint256 public freeSupply;
  bool public paused = true;
  uint256 public maxFree;
  uint256 public maxPaid;

  //mappings
  mapping(address => uint) public freeMintedByOwner;
  mapping(address => uint) public paidMintedByOwner;



// Constructor
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _reservedSupply,
    uint256 _maxSupply,
    uint256 _freeSupply,
    uint256 _maxFree,
    uint256 _maxPaid,
    string memory _MetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
      setCost(_cost);
      maxSupply = _maxSupply;
      freeSupply = _freeSupply;
      reservedSupply = _reservedSupply;
      setMaxMintAmountPerTx(_maxFree, _maxPaid);
      setMetadataUri(_MetadataUri);
      // mint(reservedSupply);
  }


//_______________________________________________________________________________
//
//Owner Control Methods
//_______________________________________________________________________________
// Sets the URI for a function
    function setMetadataUri(string memory _metadataUri) public onlyOwner {
      metadataUri = _metadataUri;
    }

// Controls Pausing and unpausing
    function setPaused(bool _state) public onlyOwner {
      paused = _state;
    }

// Controls the price of the paid NFTs
    function setCost(uint256 _cost) public onlyOwner {
      cost = _cost;
    }

// Controls the max amounts of mints a wallet can do.
    function setMaxMintAmountPerTx(uint256 _maxFree, uint256 _maxPaid) public onlyOwner {
      maxFree = _maxFree;
      maxPaid = _maxPaid;
    }

    //Only method withdrawing money restricted to owner wallet
    function withdraw() public onlyOwner nonReentrant {
      (bool os, ) = payable(owner()).call{value: address(this).balance}('');
      require(os);
    }

//_______________________________________________________________________________
//
// Start Drop Unpausing and Minting the reserved NFTs
//_______________________________________________________________________________
function start_drop() public onlyOwner empty {
    setPaused(false);
    mint(reservedSupply);
}


//_______________________________________________________________________________
//
//Mint Method
//_______________________________________________________________________________

function mint(uint256 _mintAmount) public payable enabled edge_check(_mintAmount) funded(_mintAmount) availible_mints(_mintAmount) {
   _safeMint(_msgSender(), _mintAmount);
 }


 //_______________________________________________________________________________
 //
 //Returning the NFT URI
 //_______________________________________________________________________________

 function _baseURI() internal view virtual override returns (string memory) {
     return metadataUri;
 }

//_______________________________________________________________________________
//
//Function Modifiers
//_______________________________________________________________________________


    modifier availible_mints(uint256 _mintAmount){
      uint256 transitionAmount = freeSupply + reservedSupply;
      if (totalSupply() < transitionAmount) {
        // Handles if free mint
        require(_mintAmount > 0 && (_mintAmount + freeMintedByOwner[msg.sender] <= maxFree || msg.sender == owner()),  'Invalid mint amount!');

      }
      else{
        // Handles if paid mint
        require(_mintAmount > 0 && (_mintAmount + paidMintedByOwner[msg.sender] <= maxPaid || msg.sender == owner()),  'Invalid mint amount!');

      }
      _;
      if (totalSupply() <= transitionAmount) {
        // Handles if free mint
        freeMintedByOwner[msg.sender] =  _mintAmount + freeMintedByOwner[msg.sender];

      }
      else{
        // Handles if paid mint
        paidMintedByOwner[msg.sender] = _mintAmount + paidMintedByOwner[msg.sender];

      }
    }





    // Checks if will be above max supply or if its going to cross an edge
    modifier edge_check(uint256 _mintAmount) {
      uint256 newSupply = totalSupply() + _mintAmount;
      uint256 currentSupply = totalSupply();
      uint256 transitionAmount = freeSupply + reservedSupply;

      require((currentSupply < transitionAmount && newSupply <= transitionAmount) || (currentSupply >= transitionAmount && newSupply > transitionAmount) ,  'Invalid: crosses an edge!');
      // check Max Supply
      require(newSupply <= maxSupply, 'Max supply exceeded!');
      _;
    }

    // Checks if needing funding and if so if it is funded
    modifier funded(uint256 _mintAmount) {
      require(((totalSupply() + _mintAmount) <= (freeSupply + reservedSupply)) || (msg.value >= cost * _mintAmount)  ||  msg.sender == owner(), 'Insufficient funds!');
      _;
    }

    modifier enabled() {
      require(!paused, 'The contract is paused!');
      _;
      if (totalSupply() == maxSupply) {
        paused = true;
      }
    }

    modifier empty() {
      require(totalSupply() == 0, 'The contract must be empty');
      _;
    }
}