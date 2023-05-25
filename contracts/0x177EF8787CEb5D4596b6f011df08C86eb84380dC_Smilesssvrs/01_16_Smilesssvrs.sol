// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// All Smilesss LLC (www.smilesss.com)
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*********************************ALLSMILESSS**********************************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@&(**********/%@@@@@@@@@@@@@@*******************************&(@@@@@@@@@@/%*******************************@@@@@@@@@@@@@&(**********/%@@@@@@@@@@@@@@@@
// @@@@@@@@@@@(********************/&@@@@@@@@@@**************************(@@@@@@@@@@@@@@@@@@@@/&*************************@@@@@@@@@@(********************/&@@@@@@@@@@@
// @@@@@@@@%**************************/@@@@@@@@@**********************%@@@@@@@@@@@@@@@@@@@@@@@@@@/**********************@@@@@@@@%**************************/@@@@@@@@@
// @@@@@@&******************************(@@@@@@@@*******************&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(*******************@@@@@@@&******************************(@@@@@@@
// @@@@@#********************#(***********@@@@@@@@*****************#@@@@@@@@@@@@@@@@@@@@#(@@@@@@@@@@@*****************@@@@@@@#********************#(***********@@@@@@
// @@@@#********************/@@%***********@@@@@@@@***************#@@@@@@@@@@@@@@@@@@@@/**%@@@@@@@@@@@***************@@@@@@@#********************/@@%***********@@@@@
// @@@@/*****@@@@@/*@@@@@%***#@@#***********%@@@@@@@**************/@@@@@*****/@*****%@@@#**#@@@@@@@@@@@%************@@@@@@@@/*****@@@@@/*@@@@@%***#@@#***********%@@@
// @@@@******@@@@@/*@@@@@*****@@@**********#@@@@@@@@@*************@@@@@@*****/@*****@@@@@***@@@@@@@@@@#************@@@@@@@@@******@@@@@/*@@@@@*****@@@**********#@@@@
// @@@@/**********************@@@**********%@@@@@@@@@@************/@@@@@@@@@@@@@@@@@@@@@@***@@@@@@@@@@%***********@@@@@@@@@@/**********************@@@**********%@@@@
// @@@@%*****@@@@@/*@@@@@****#@@#*********(@@@@@@@@@@@@***********%@@@@@*****/@*****@@@@#**#@@@@@@@@@(***********@@@@@@@@@@@%*****@@@@@/*@@@@@****#@@#*********(@@@@@
// @@@@@&****@@@@@/*@@@@@***/@@%*********/@@@@@@@@@@@@@@***********&@@@@*****/@*****@@@/**%@@@@@@@@@/***********@@@@@@@@@@@@@&****@@@@@/*@@@@@***/@@%*********/@@@@@@
// @@@@@@@/******************#(*********%@@@@@@@@@@@@@@@@************/@@@@@@@@@@@@@@@@@@#(@@@@@@@@@%***********@@@@@@@@@@@@@@@@/******************#(*********%@@@@@@@
// @@@@@@@@@/*************************&@@@@@@@@@@@@@@@@@@@*************/@@@@@@@@@@@@@@@@@@@@@@@@@&************@@@@@@@@@@@@@@@@@@@/*************************&@@@@@@@@@
// @@@@@@@@@@@@(*******************%@@@@@@@@@@@@@@@@@@@@@@@***************(@@@@@@@@@@@@@@@@@@@%**************@@@@@@@@@@@@@@@@@@@@@@@(*******************%@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&%(//***/(#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@******************&%(//@@@/(#&******************@@@@@@@@@@@@@@@@@@@@@@@@@@@@&%(//***/(#&@@@@@@@@@@@@@@@@@
// @@[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@*O*************R*************C**************R*@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@

// Artist: Waheed Zai
// Project Manager: Giovanni
// Developer: SignorCrypto
// Strategy: Jake
// Community: Logan, Trish, 90u, Twoseven, Franklin
// Content creator: Verifryd
// Advisors: JRBlake, Jonah B, Josh

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract Smilesssvrs is ERC721Enumerable, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;
  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // Contract State
  enum MintStatus {
    CLOSED,
    ACT_I,
    ACT_II,
    ACT_III,
    ACT_IV,
    PUBLIC_I,
    PUBLIC_II
  }

  MintStatus public _mintStatus = MintStatus.CLOSED;
  bool public reveal = false;

  // ERC721 params
  string private tokenName = 'Smilesss';
  string private tokenId = 'SMLS';
  string private _baseTokenURI =
    'http://www.smilesss.com/api/metadata/';

  // Withdraw address
  address private withdraw_address = 0x10fD2b2E5a8E0fe05A018B2aE4BbEc4D725FF547;

  // ECDSA
  address private signer_address = 0xd31ADBC091A37cafE4c9Fd0426905E8256f1AaCc;
  mapping(string => bool) private _isNonceUsed;

  // Collection params
  uint256 public constant TOT = 8888;
  uint256 public constant GIVEAWAY = 502;
  uint256 public constant PUBLIC_II_MINT_LIMIT = 8;
  uint256 public constant PRICE = 0.1 ether;

  // Utils
  uint256 public currentTokenId;
  uint256 public giveawaySupply = GIVEAWAY;
  uint256 public mintableSupply = TOT - GIVEAWAY;

  // Premint list
  mapping(address => bool) private _premintList;
  mapping(address => uint256) private _premintClaimed;
  mapping(address => uint256) private _premintAvailable;
  mapping(address => MintStatus) private _premintTier;

  // CLOSED (0) | ACT_I (9 premint + 1 for free) | ACT_II (4 premint)
  // ACT_III (2 premint) | ACT_IV (1 premint) | PUBLIC_I (1)
  uint256[6] public TIER_LIMIT = [0, 9, 4, 2, 1, 1];

  // Event declaration
  event MintEvent(uint256 indexed id);

  // Modifiers
  modifier olnyIfAvailable(uint256 _amount) {
    require(_mintStatus != MintStatus.CLOSED, 'Minting is closed');
    require(_tokenIds.current() < TOT, 'Collection is sold out');
    require(_amount <= mintableSupply, 'Not enough NFTs available');
    require(_amount > 0, 'NFTs amount must be greater than zero');
    require(msg.value == PRICE * _amount, 'Ether sent is not correct');
    _;
  }

  // Signature verfification
  modifier onlySignedTx(
    uint256 _amount,
    string memory _nonce,
    bytes memory _signature
  ) {
    require(!_isNonceUsed[_nonce], 'Nonce already used');
    require(
      keccak256(abi.encodePacked(msg.sender, _amount, _nonce))
        .toEthSignedMessageHash()
        .recover(_signature) == signer_address,
      'Signature do not correspond'
    );

    // Save nonce as used
    _isNonceUsed[_nonce] = true;
    _;
  }

  // Constructor
  constructor() ERC721(tokenName, tokenId) {}

  // Private mint function
  function Enter(address _to, uint256 _amount) private {
    for (uint256 i; i < _amount; i++) {
      _tokenIds.increment();
      _safeMint(_to, _tokenIds.current());
      currentTokenId = _tokenIds.current();

      emit MintEvent(currentTokenId);
    }
  }

  // Private premint function for Act_I, Act_II, Act_III and Act_IV tiers
  function premint(uint256 _amount) private {
    require(_premintList[msg.sender], 'You need a premint');
    require(
      _mintStatus >= _premintTier[msg.sender],
      'Minting is still closed for your tier'
    );
    require(
      _premintClaimed[msg.sender] < _premintAvailable[msg.sender],
      'You already claimed your premint NFTs'
    );
    require(
      _amount <= _premintAvailable[msg.sender],
      'Exceeded the max amount of NFT mintable in your tier'
    );
    require(
      _amount + _premintClaimed[msg.sender] <= _premintAvailable[msg.sender],
      'You do not have enough premint available'
    );

    if (
      _premintTier[msg.sender] == MintStatus.ACT_I &&
      _premintClaimed[msg.sender] == 0
    ) {
      // Give one for free
      Enter(msg.sender, _amount + 1);
      mintableSupply -= (_amount + 1);
    } else {
      Enter(msg.sender, _amount);
      mintableSupply -= _amount;
    }
    _premintClaimed[msg.sender] += _amount;
  }

  // Private mint function for public mint
  function publicIIMint(uint256 _amount) private {
    require(_mintStatus == MintStatus.PUBLIC_II, 'Public II is closed');
    require(
      _amount <= PUBLIC_II_MINT_LIMIT,
      'Exceeded the max amount of NFT mintable in one transaction'
    );
    Enter(msg.sender, _amount);

    mintableSupply -= _amount;
  }

  // Private mint function for public I mint -> Only 1 NFT
  function publicIMint(uint256 _amount) private {
    require(_mintStatus == MintStatus.PUBLIC_I, 'Public I is closed');
    require(
      _amount <= TIER_LIMIT[uint256(_mintStatus)],
      'Exceeded the max amount of NFT mintable in Public I tier'
    );

    if (_premintList[msg.sender]) {
      require(
        _premintClaimed[msg.sender] == 0,
        'You already partecipated in the premint'
      );
    } 

	  _premintList[msg.sender] = true;
    _premintClaimed[msg.sender] += _amount;

    Enter(msg.sender, _amount);

    mintableSupply -= _amount;
  }

  // Public mint function to interact with the smart contract
  function mint(
    uint256 _amount,
    string memory _nonce,
    bytes memory _signature
  )
    external
    payable
    olnyIfAvailable(_amount)
    onlySignedTx(_amount, _nonce, _signature)
    nonReentrant
  {
    if (_mintStatus == MintStatus.PUBLIC_II) {
      publicIIMint(_amount);
    } else if (_mintStatus == MintStatus.PUBLIC_I) {
      publicIMint(_amount);
    } else {
      premint(_amount);
    }
  }

  // GIVEAWAY
  function giveaway(address _to, uint256 _amount) external onlyOwner {
    require(_amount <= giveawaySupply, 'Not enough giveaway available');
    Enter(_to, _amount);
    giveawaySupply -= _amount;
  }

  // Add users to premit list
  function addToPremintList(uint256 _tier, address[] calldata _addresses)
    external
    onlyOwner
  {
    require(_tier > 0, 'Tier cannot be zero');
    require(_tier < 5, 'Tier must be smaller than five');

    for (uint256 i = 0; i < _addresses.length; i++) {
      require(!_premintList[_addresses[i]], 'Already in premint list');
      _premintList[_addresses[i]] = true;
      _premintClaimed[_addresses[i]] = 0;
      _premintAvailable[_addresses[i]] = TIER_LIMIT[uint256(_tier)];
      _premintTier[_addresses[i]] = MintStatus(_tier);
    }
  }

  // Add single premint to contest winners
  function addPremint(address[] calldata _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      if (_premintList[_addresses[i]]) {
        _premintAvailable[_addresses[i]] += 1;
      } else {
        _premintList[_addresses[i]] = true;
        _premintClaimed[_addresses[i]] = 0;
        _premintAvailable[_addresses[i]] = 1;
        _premintTier[_addresses[i]] = MintStatus.ACT_IV;
      }
    }
  }

  // Setters
  function setStatus(uint8 _status) external onlyOwner {
    _mintStatus = MintStatus(_status);
  }

  function setReveal(bool _reveal) public onlyOwner {
    reveal = _reveal;
  }

  function setBaseURI(string memory _URI) public onlyOwner {
    _baseTokenURI = _URI;
  }

  function setSignerAddress(address _signer) external onlyOwner {
    signer_address = _signer;
  }

  function setWithdrawAddress(address _withdraw) external onlyOwner {
    withdraw_address = _withdraw;
  }

  // Contract state
  function getContractState()
    external
    view
    returns (
      MintStatus mintStatus_,
      uint256 tot_,
      uint256 price_,
      uint256 currentTokenId_,
      uint256 mintableSupply_
    )
  {
    return (_mintStatus, TOT, PRICE, currentTokenId, mintableSupply);
  }

  function isOnPremint(address _address)
    external
    view
    returns (
      MintStatus tier,
      uint256 claimed_,
      uint256 tierLimit_
    )
  {
    if (_premintList[_address]) {
      return (
        _premintTier[_address],
        _premintClaimed[_address],
        _premintAvailable[_address]
      );
    } else {
      return (MintStatus.CLOSED, 0, 0);
    }
  }

  function tokenExists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  // URI
  function tokenURI(uint256 _tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    require(_exists(_tokenId), 'Token does not exist');
    return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
  }

  // Withdraw function
  function withdrawAll() external payable onlyOwner {
    require(address(this).balance != 0, 'Balance is zero');
    require(payable(withdraw_address).send(address(this).balance));
  }
}