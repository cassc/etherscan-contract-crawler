// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

// Errors

error MustMintMoreThanZero();
error ExceedsMaxPerTxn();
error PublicSaleIsNotActive();
error MintingTooMany();
error SoldOut();
error NotEnoughETH();
error WhitelistSaleIsNotActive();
error WhitelistAlreadyClaimed();
error InvalidMerkleProof();
error URIQueryForNonexistentToken();
error NewSupplyCannotBeSmallerThanCurrentSupply();
error SupplyCannotBeIncreased();


contract TheAussies is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(uint256 => bool) public isAShitCarnt;
  mapping(uint256 => bool) public isUpShitCreek;
  mapping(uint256 => bool) public isFarked;


  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.000 ether;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
 

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;
    setHiddenMetadataUri(_hiddenMetadataUri);
    //to mint at contract deployment. Enter address and qty to mint 
    _mint(address(0x08934Ff21956ed802873151F94cEdc2706c51C43), 50);
    
  }


  modifier onlyApprovedOrOwner(uint256 tokenId) {
    require(
         _ownershipOf(tokenId).addr == _msgSender() || 
             owner() == _msgSender(),
                
        "Not approved nor owner"
    );
        
     _;
  }

  //Checks for correct mint data being passed through
  modifier mintCheck(uint256 _mintAmount) {
    if (_mintAmount == 0) revert MustMintMoreThanZero();
    if (_mintAmount > maxMintAmountPerTx) revert ExceedsMaxPerTxn();
    if (totalSupply() + _mintAmount > maxSupply) revert SoldOut();
    _;
  }

  //Checks for correct mint pricing data being passed through
  modifier mintPriceCheck(uint256 _mintAmount) {
    if (msg.value < cost * _mintAmount) revert NotEnoughETH();
    _;
  }
  //Whitelist minting function
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCheck(_mintAmount) mintPriceCheck(_mintAmount) {
    // Checks whether the mint is open, whether an address has already claimed, and that they are on the WL
    if (!whitelistMintEnabled) revert WhitelistSaleIsNotActive();
    if (whitelistClaimed[_msgSender()]) revert WhitelistAlreadyClaimed();
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert InvalidMerkleProof();

    whitelistClaimed[_msgSender()] = true;
    _mint(_msgSender(), _mintAmount);
  }

  //Public minting function
  function mint(uint256 _mintAmount) public payable mintCheck(_mintAmount) mintPriceCheck(_mintAmount) {
    if(paused) revert PublicSaleIsNotActive();

    _mint(_msgSender(), _mintAmount);
  }
  
  //Airdrop function - sends enetered number of NFTs to an address for free. Can only be called by Owner
  function airdrop(uint256 _mintAmount, address _receiver) public mintCheck(_mintAmount) onlyOwner {
    _mint(_receiver, _mintAmount);
  }

  //Set token starting ID to 1
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  
  //return URI for a token based on whether collection is revealed or not
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }
  

  //Reveal Collection  -true or false
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  //Change token cost
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  //Someone is a shit carnt.
  function setIsAShitCarnt(uint256 _tokenId, bool _state) public onlyOwner {
    isAShitCarnt[_tokenId] = true;
  }

  //Someone is up shit creek.
  function setIsUpShitCreek(uint256 _tokenId, bool _state) public onlyOwner {
    isUpShitCreek[_tokenId] = true;
  }

  //Someone is farked.
  function setIsFarked(uint256 _tokenId, bool _state) public onlyOwner {
    isFarked[_tokenId] = true;
  }

  //Change max amount of tokens per txn
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }


  //set hidden metadata URI
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  //set revealed URI prefix 
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
  uriPrefix = _uriPrefix;
  }

  //set revealed URI suffix eg. .json
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  //Function to pause the contract
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  //Function to set the Merkleroot hash
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  //Function to set the WL state
  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  //burn function
  function bonfire(uint256 tokenId) public onlyOwner {   
        _burn(tokenId);
    }

  //Withdraw function
  function withdraw() public onlyOwner nonReentrant {
    
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  //update maxsupply to decrease colecton size if needed
  function updateMaxSupply(uint256 _newSupply) external onlyOwner {
        if (_newSupply < totalSupply()) revert NewSupplyCannotBeSmallerThanCurrentSupply();
        if (_newSupply > maxSupply) revert SupplyCannotBeIncreased();
        maxSupply = _newSupply;
  }

  function _baseURI() internal view virtual override returns (string memory) {
  return uriPrefix;
  }


    // -- The Pub --
    

    bool public isThePubOpen = false;

    // At The Pub
    mapping(uint256 => uint256) private whatTimeDidYouGetToThePub; // tokenId -> what time did you get to the Pub (0 = not there yet).
    mapping(uint256 => uint256) private totalTimeYouHaveBeenAtThePub; // tokenId -> cumulative time at the Pub, does not include current time at the Pub
    
    uint256 private constant NO_BEER = 0;
    event EventAtThePub(uint256 indexed tokenId);
    event EventLeftThePub(uint256 indexed tokenId);

    /// @notice retrieve Pub visit status
    /// @return atThePubNow current Pub visit time in secs
    /// @return totalTimeAtThePubNow total time at the Pub (in secs)
    /// @return atThePub having a beer or nah?
    function getPubVisitInfoforAussie(uint256 tokenId) external view returns ( uint256 atThePubNow, uint256 totalTimeAtThePubNow, bool atThePub )
    {
        atThePubNow = 0;
        uint256 startTimestamp = whatTimeDidYouGetToThePub[tokenId];

        if (startTimestamp != NO_BEER) {  // atThePub
            atThePubNow = block.timestamp - startTimestamp;
        }

        totalTimeAtThePubNow = atThePubNow + totalTimeYouHaveBeenAtThePub[tokenId];
        atThePub = startTimestamp != NO_BEER;
    }

    function canYouGoToThePub(bool allowed) external onlyOwner {
        require(allowed != isThePubOpen, "Already set");
        isThePubOpen = allowed;
    }

    function _haveABeer(uint256 tokenId) private onlyApprovedOrOwner(tokenId)
    {
        uint256 startTimestamp = whatTimeDidYouGetToThePub[tokenId];

        if (startTimestamp == NO_BEER) { 
            // have a beer
            require(isThePubOpen, "Pub closed");
            whatTimeDidYouGetToThePub[tokenId] = block.timestamp;

            emit EventAtThePub(tokenId);
        } else { 
            // stop drinking
            totalTimeYouHaveBeenAtThePub[tokenId] += block.timestamp - startTimestamp;
            whatTimeDidYouGetToThePub[tokenId] = NO_BEER;

            emit EventLeftThePub(tokenId);
        }
    }

    /// @notice have a beer with multiple Aussies
    /// @param tokenIds Array of tokenIds to toggle
    function haveABeer(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _haveABeer(tokenId);
        }
    }
}