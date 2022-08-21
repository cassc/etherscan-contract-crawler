// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/Strings.sol";


interface IContractWhiteList {
  function ownerOf(uint256 tockenId) external view returns (address);
}

contract InfraRethAuctionV02 is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(uint256 => bool) public whiteListParentTokenIdClaimed;
  mapping(address => bool) public premintlistClaimed;
  mapping(uint256 => uint256) public whiteListParentTokenIdMintCount;
  mapping(address => uint256) public whiteListAddressMintCount;
  mapping(address => uint256) public utilityEarnedForAddress;
  mapping(address => uint256) public utilityClaimedForAddress;
  
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintPerWhiteListTokenId = 1;
  uint256 public maxMintPerWhiteListAddress = 1; 
  uint256 public maxTokenIdWhitelisted = 0;
  
  
  bool public claimUtilityOpen = false;
  bool public allowMultipleWhitelistMints = false;
  bool public allowMultiplePremintlistMints = false;
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public premintlistMintEnabled = false;
  bool public revealed = false;

  address public contractWhiteListAddress = address(0);
  address public adminClaimAddress = address(0);
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    setMaxSupply(_maxSupply);
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function verifyAvailableNftTokenIdKongZToClaim() internal view virtual returns (uint256) {
    uint256 nftTokenIdKongZToClaim = 0;

    /**
    * get the CYBER KONG Z GENESIS Token IDs owned by message sender address
    */

    // interface

    /**
    * Check wich of the tokens hasn't yet claimed
    */

    return nftTokenIdKongZToClaim;
  }

  function whitelistMint(uint256 _mintAmount, uint256 nftTokenIdWhitelisted, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    if (nftTokenIdWhitelisted > 0) {
      require(allowMultipleWhitelistMints || whiteListParentTokenIdMintCount[nftTokenIdWhitelisted]<maxMintPerWhiteListTokenId, 'NFT whitelisted already claimed, you reached the maximum mints allowed!');
      require(nftTokenIdWhitelisted>0 && nftTokenIdWhitelisted <= maxTokenIdWhitelisted, 'NFT Token is not Whitelisted');
      require(contractWhiteListAddress != address(0), 'The contract to validate your whitelisted token id is not set');
      require(validateNftTokenIdWhitelistedByOwner(_msgSender(), nftTokenIdWhitelisted), 'You are not the owner of the NFT token id claimed');
    }
    else {
      require(maxMintPerWhiteListAddress>0, 'Whitelist by address mint is not enabled yet.');
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Your wallet address is not whitelisted');
      require(allowMultipleWhitelistMints || whiteListAddressMintCount[_msgSender()]<maxMintPerWhiteListAddress, 'You reached the maximum mints allowed per whitelist address!');
    }
    if (nftTokenIdWhitelisted > 0) {
      whiteListParentTokenIdMintCount[nftTokenIdWhitelisted] = whiteListParentTokenIdMintCount[nftTokenIdWhitelisted] + 1;
    }
    else {
      whiteListAddressMintCount[_msgSender()] = whiteListAddressMintCount[_msgSender()] + 1;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function premintlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify premintlist requirements
    require(premintlistMintEnabled, 'The premint list sale is not enabled!');

    require(allowMultiplePremintlistMints || !premintlistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    premintlistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function validateNftTokenIdWhitelistedByOwner(address _owner, uint256 tokenId) public view returns (bool) {
    
    if (contractWhiteListAddress == address(0)) {
      return false;
    }
    return (IContractWhiteList(contractWhiteListAddress).ownerOf(tokenId) == _owner);
    
  }

  function isSoldOut() public view returns (bool) {
    return (maxSupply == totalSupply());
  }

  function getUtilityEarnedForAddress(address _owner) public view returns (uint256) {
    return utilityEarnedForAddress[_owner];
  }
  function getUtilityClaimedForAddress(address _owner) public view returns (uint256) {
    return utilityClaimedForAddress[_owner];
  }
  function getBalanceToClaimForAddress(address _owner) public view returns (uint256) {
    if (utilityClaimedForAddress[_owner] > utilityEarnedForAddress[_owner]) {
      return 0;
    }
    return utilityEarnedForAddress[_owner] - utilityClaimedForAddress[_owner];
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      if (_exists(currentTokenId)) {
        TokenOwnership memory ownership = _ownerships[currentTokenId];

        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function addUtilityEarnedForAddresses(address[] memory addresses, uint256[] memory amount) public onlyOwner {
    for (uint i=0; i<addresses.length && i<amount.length; i++) {
      utilityEarnedForAddress[addresses[i]] = (utilityEarnedForAddress[addresses[i]] + amount[i]);
    } 
  }

  function setUtilityEarnedForAddresses(address[] memory addresses, uint256[] memory amount) public onlyOwner {
    for (uint i=0; i<addresses.length && i<amount.length; i++) {
      utilityEarnedForAddress[addresses[i]] = amount[i];
    } 
  }

  function setUtilityEarnedForAddressesByAdmin(address[] memory addresses, uint256[] memory amount) public {
    require(adminClaimAddress != address(0) && adminClaimAddress == _msgSender(), 'This method is only available by admin address');
    for (uint i=0; i<addresses.length && i<amount.length; i++) {
      utilityEarnedForAddress[addresses[i]] = amount[i];
    } 
  }

  function addUtilityEarnedForAddress(address _address, uint256 amount) public onlyOwner {
    utilityEarnedForAddress[_address] = (utilityEarnedForAddress[_address] + amount);
  }

  function setUtilityEarnedForAddress(address _address, uint256 amount) public onlyOwner {
    utilityEarnedForAddress[_address] = amount;
  }

  function setUtilityEarnedForAddressByAdmin(address _address, uint256 amount) public {
    require(adminClaimAddress != address(0) && adminClaimAddress == _msgSender(), 'This method is only available by admin address');
    utilityEarnedForAddress[_address] = amount;
  }

  function setContractWhiteListAddress(address _contractWhiteListAddress) public onlyOwner {
    contractWhiteListAddress = _contractWhiteListAddress;
  }

  function setAdminClaimAddress(address _address) public onlyOwner {
    adminClaimAddress = _address;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxTokenIdWhitelisted(uint256 _maxTokenIdWhitelisted) public onlyOwner {
    maxTokenIdWhitelisted = _maxTokenIdWhitelisted;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintPerWhiteListTokenId(uint256 _maxMintPerWhiteListTokenId) public onlyOwner {
    maxMintPerWhiteListTokenId = _maxMintPerWhiteListTokenId;
  }

  function setMaxMintPerWhiteListAddress(uint256 _maxMintPerWhiteListAddress) public onlyOwner {
    maxMintPerWhiteListAddress = _maxMintPerWhiteListAddress;
  }
  
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setAllowMultipleWhitelistMint(bool _state) public onlyOwner {
    allowMultipleWhitelistMints = _state;
  }

  function setAllowMultiplePremintlistMint(bool _state) public onlyOwner {
    allowMultiplePremintlistMints = _state;
  }

  function setClaimUtilityOpen(bool _state) public onlyOwner {
    claimUtilityOpen = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setPremintlistMintEnabled(bool _state) public onlyOwner {
    premintlistMintEnabled = _state;
  }

  function claimUtility(uint256 _mintAmount) public  {
    require(claimUtilityOpen, 'The claim utility process is temporary closed, come back later!');
    require(_mintAmount <= getBalanceToClaimForAddress(_msgSender()) , 'Amount exceedes the balance available to claim');
    utilityClaimedForAddress[_msgSender()] = utilityClaimedForAddress[_msgSender()] + _mintAmount;
    (bool os, ) = payable(_msgSender()).call{value: _mintAmount}('');
    require(os);
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}