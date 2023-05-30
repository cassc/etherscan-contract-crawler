// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./DevWallet.sol";
import "./ERC721A.sol";


interface IMoonToken {
  function burn(address _from, uint256 _amount) external;
  function updateRewardOnMint(address _user, uint256 _amount) external;
  function updateReward(address _from, address _to) external;
  function balanceOf(address account) external view returns(uint256);
}

contract AlphieWhales is Ownable, ERC721A, ReentrancyGuard {
  using ECDSA for bytes32;

  IMoonToken public MoonToken;
  DevWallet private _devWalletContract;
  address private _devMultiSigWalletAddress;

  address public validator;

  modifier whaleOwner(uint256 whaleId) {
    require(ownerOf(whaleId) == msg.sender, "Cannot interact with a Whale you do not own");
    _;
  }

  struct WhitelistedUser
  {
    address walletAddress; 
    uint256 mintAmount;
  }

  uint256 public GENESIS_PRICE = 0.077 ether;
  uint256 public MAX_TOTAL_SUPPLY = 7777;

  uint256 public PUBLICSALE_MAX_TOKENS_PER_PURCHASE = 5;

  uint256 public GENESIS_RESERVE = 277;

  uint256 public genesisCount = 0;

  uint256 public constant NAME_CHANGE_PRICE = 100 ether;

  bool public preMintActive = false;
  bool public publicMintActive = false;

  mapping(address => WhitelistedUser) public whitelisted;
  mapping(address => bool) public _addressExist;

  mapping (address => uint256) public balanceGenesisWhales;
  mapping(uint256 => string) public whaleNames;

  string private baseURI;

  /***************/
  /*** EVENTS ****/
  /***************/

  event ValidatorSet(address validator);
  event WhalesMinted(address _owner, uint256 amount, uint256 startTokenId);
  event NameChanged(uint256 whaleId, string whaleName);


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    address _validator,
    address payable _devWalletAddress,
    address devMultiSigWallet
  ) ERC721A(_name, _symbol, 5) {
    _devWalletContract = DevWallet(_devWalletAddress);
    _devMultiSigWalletAddress = devMultiSigWallet;
    setValidator(_validator);
    setBaseURI(_initBaseURI);
  }

  function setValidator(address validator_) public onlyOwner {
    require(validator_ != address(0), "validator cannot be 0x0");
    validator = validator_;
    emit ValidatorSet(validator);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setGenesisPrice(uint256 _newPrice) public onlyOwner {
    GENESIS_PRICE = _newPrice;
  }

  function setNewSupply(uint256 _maxGenesisQuantity) public onlyOwner {
    MAX_TOTAL_SUPPLY = _maxGenesisQuantity;
  }
  
  function setMaxTokensPerPurchasePublicsale(uint256 _maxTokensPerPurchase) public onlyOwner {
    PUBLICSALE_MAX_TOKENS_PER_PURCHASE = _maxTokensPerPurchase;
  }

  function reserveGenesisTokens(uint256 _quantity) public {
    require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
    require(_quantity <= GENESIS_RESERVE, "The quantity exceeds the reserve.");
    require(genesisCount + _quantity <= MAX_TOTAL_SUPPLY, "Exceeds maximum tokens available for purchase");
    GENESIS_RESERVE -= _quantity; // TODO * discuss about how many to reserve for marketing and team and where keep these tokens.

    uint256 remainder = _quantity % maxBatchSize;

    require(
      (_quantity - remainder) % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );

    uint256 numChunks = (_quantity - remainder) / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(_devMultiSigWalletAddress, maxBatchSize);
    }

    if (remainder > 0) {
      _safeMint(_devMultiSigWalletAddress, remainder);
    }

    genesisCount += _quantity;

    emit WhalesMinted(_devMultiSigWalletAddress, _quantity, genesisCount);
    MoonToken.updateRewardOnMint(_devMultiSigWalletAddress, _quantity);
  }

  function changeName(uint256 whaleId, string memory newName) external whaleOwner(whaleId) {
    bytes memory n = bytes(newName);
    require(n.length > 0 && n.length < 25, "Invalid name length");
    require(sha256(n) != sha256(bytes(whaleNames[whaleId])),    "New name is same as current name");
    
    MoonToken.burn(msg.sender, NAME_CHANGE_PRICE);
    whaleNames[whaleId] = newName;
    emit NameChanged(whaleId, newName);
  }

  function setMoonToken(address moonTokenAddress) external onlyOwner {    
    MoonToken = IMoonToken(moonTokenAddress);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  /**
    OVERRIDE FUNCTIONS
   */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721A)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) 
    internal
    override(ERC721A)
  {
    MoonToken.updateReward(from, to);

    if (from != 0x0000000000000000000000000000000000000000) {
      balanceGenesisWhales[from] -= quantity;
    }
    balanceGenesisWhales[to] += quantity;
  }

  function togglePreMintActive() public onlyOwner {
    preMintActive = !preMintActive;
  }

  function togglePublicMintActive() public onlyOwner {
    publicMintActive = !publicMintActive;
  }

  function toggleBetweenPreAndPublicActive() public onlyOwner {
    // pre and public will always be oppsite
    preMintActive = !preMintActive; 
    publicMintActive = !preMintActive;
  }

  function pauseAllMint() public onlyOwner {
    // pause everything
    preMintActive = false; 
    publicMintActive = false;
  }

  function isWhitelisted(uint256 _type, bytes calldata signature) 
    public
    view
    returns (bool, uint256)  
  {
    // check if this address is whitelisted or not
    uint256 mintAmount = 0;
    bool isWhitelistedBool;

    if (_verify(_hash(msg.sender, _type), signature)) {
      isWhitelistedBool = true;

      if (!_addressExist[msg.sender]) { // After verify the signature - check if address is already exist yet then create one
        mintAmount = _type == 300 ? 3 : 2; // 200 is 2 mints && 300 is 3 mints
      } else {
        mintAmount = whitelisted[msg.sender].mintAmount;
      }
    } else {
      isWhitelistedBool = false;
    }
    return (isWhitelistedBool, mintAmount);
  }

  function _hash(address account, uint256 _type)
    internal pure returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(account, _type)));
    }

  function _verify(bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
      return validator == ECDSA.recover(digest, signature);
    }

  // presale
  function mintPre(uint256 _mintAmount, uint256 _type, bytes calldata signature)
    public
    payable
  {
    require(preMintActive, "Must be active to mint");
    require(
      tx.origin == msg.sender,
      "Purchase cannot be called from another contract"
    );
    require(genesisCount + _mintAmount <= MAX_TOTAL_SUPPLY - GENESIS_RESERVE, "Exceeds maximum tokens available for purchase");
    require(_verify(_hash(msg.sender, _type), signature), "Invalid signature"); // check if this is a correct WL address 

    if (!_addressExist[msg.sender]) { // After verify the signature - check if address is already exist yet then create one
      uint256 initialMintAmount = _type == 300 ? 3 : 2; // 200 is 2 mints && 300 is 3 mints
      setWhitelistUser(msg.sender, initialMintAmount);
    }

    require(_mintAmount > 0 && _mintAmount <= whitelisted[msg.sender].mintAmount, "Exceeds maximum tokens you can purchase in a single transaction");
    require(whitelisted[msg.sender].mintAmount > 0, "There's no more you can mint, please wait for the public sale to mint more!");
    require(_mintAmount <= whitelisted[msg.sender].mintAmount, "You cannot mint more than that!");
    require(msg.value >= GENESIS_PRICE * _mintAmount, "ETH amount is not sufficient");

    _safeMint(msg.sender, _mintAmount);

    emit WhalesMinted(msg.sender, _mintAmount, genesisCount);

    genesisCount += _mintAmount;

    whitelisted[msg.sender].mintAmount -= _mintAmount;

    MoonToken.updateRewardOnMint(msg.sender, _mintAmount);
  }

  // publicsale 
  function mintPublic(uint256 _mintAmount)
    public
    payable
  {
    require(publicMintActive, "Must be active to mint");
    require(
      tx.origin == msg.sender,
      "Purchase cannot be called from another contract"
    );
    require(genesisCount + _mintAmount <= MAX_TOTAL_SUPPLY - GENESIS_RESERVE, "Exceeds maximum tokens available for purchase");
    require(_mintAmount > 0 && _mintAmount <= PUBLICSALE_MAX_TOKENS_PER_PURCHASE, "Exceeds maximum tokens you can purchase in a single transaction");
    require(msg.value >= GENESIS_PRICE * _mintAmount, "ETH amount is not sufficient");

    _safeMint(msg.sender, _mintAmount);

    emit WhalesMinted(msg.sender, _mintAmount, genesisCount);

    genesisCount += _mintAmount;

    MoonToken.updateRewardOnMint(msg.sender, _mintAmount);
  }

  function setWhitelistUser(address _walletAddress, uint256 _mintAmount) private {
    whitelisted[_walletAddress].walletAddress = _walletAddress;
    whitelisted[_walletAddress].mintAmount = _mintAmount;
    _addressExist[_walletAddress] = true; // winner address;
  }

  function removeWhitelistUser(address _user) public {
    require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
    delete whitelisted[_user];
    delete _addressExist[_user];
  }

  function withdrawTokensToDev(IERC20 token) public {
    require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
    uint256 funds = token.balanceOf(address(this));
    require(funds > 0, 'No token left');
    token.transfer(address(_devWalletContract), funds);
  }

  function withdrawBalanceToDev() public {
    require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
    require(address(this).balance > 0, 'No ETH left');

    (bool success,) = address(_devWalletContract).call{ value: address(this).balance }("");

    require(success, "Transfer failed.");
  }

  // DEV WALLET!
  function setDevWalletAddress(address payable _address) external {
    require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
    _devWalletContract = DevWallet(_address);
  }
}