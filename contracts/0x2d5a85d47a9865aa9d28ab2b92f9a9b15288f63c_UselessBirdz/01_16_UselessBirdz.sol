// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'hardhat/console.sol';
import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';

contract UselessBirdz is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {
  /****************************************************
    VARIABLES
  /****************************************************/
  using Strings for uint256;
  using Counters for Counters.Counter;

  bytes32 public root;
  uint256 public constant maxSupply = 5555;

  string public baseURI;

  bool public paused = false;
  bool public presaleM = false;

  uint256 public publicSaleStartTimestamp;

  uint256 TransactionAmountLimit = 55;

  mapping(address => uint256) public _presaleClaimed;
  mapping(address => uint256) public _publicsaleClaimed;

  uint256 _price = 2000000000000000;

  Counters.Counter private _tokenIds;

  uint256[] private _teamShares = [25, 25, 25, 25];

  /****************************************************
    CONSTRUCTOR
  /****************************************************/
  constructor(
    string memory uri,
    bytes32 merkleroot,
    address[] memory _team,
    uint256 _publicSaleStartTimestamp
  )
    ERC721A('UselessBirdz', 'UBirdz')
    PaymentSplitter(_team, _teamShares)
    ReentrancyGuard()
  {
    root = merkleroot;

    setBaseURI(uri);

    publicSaleStartTimestamp = _publicSaleStartTimestamp;
  }

  /****************************************************
    URI
  /****************************************************/
  function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
    baseURI = _tokenBaseURI;
  }

  /****************************************************
    HELPERS
  /****************************************************/
  modifier onlyAccounts() {
    require(msg.sender == tx.origin, 'Not allowed origin');
    _;
  }

  function togglePause() public onlyOwner {
    paused = !paused;
  }

  function togglePresale() public onlyOwner {
    presaleM = !presaleM;
  }

  /****************************************************
     MERKELROOT
  /****************************************************/
  function setMerkleRoot(bytes32 merkleroot) public onlyOwner {
    root = merkleroot;
  }

  modifier isValidMerkleProof(bytes32[] calldata _proof) {
    require(
      MerkleProof.verify(
        _proof,
        root,
        keccak256(abi.encodePacked(msg.sender))
      ) == true,
      'Not allowed origin'
    );
    _;
  }

  /****************************************************
    MINT HELPER
  /****************************************************/
  function mintInternal(uint256 _amount) internal nonReentrant {
    require(_amount > 0, 'Amount cannot be 0');
    require(_amount + totalSupply() <= maxSupply, 'Sold out');

    _safeMint(msg.sender, _amount);
  }

  /****************************************************
    MINT TO EXTERNAL ADDRESS
  /****************************************************/
  function mintToAddress(address to, uint256 _amount) public onlyOwner {
    uint256 current = _tokenIds.current();

    require(_amount > 0, 'Amount cannot be 0');
    require(_amount <= TransactionAmountLimit, "You can't mint so much tokens");
    require(current + _amount <= maxSupply, 'max supply exceeded');
    require(_amount + totalSupply() <= maxSupply, 'Sold out');

    _safeMint(to, _amount);
  }

  /****************************************************
    MINT
  /****************************************************/
  function presaleMint(
    address account,
    uint256 _amount,
    bytes32[] calldata _proof
  ) external payable isValidMerkleProof(_proof) onlyAccounts {
    require(msg.sender == account, 'Not allowed');
    require(presaleM, 'Presale is OFF');
    require(!paused, 'Contract is paused');
    require(_amount > 0, 'Amount cannot be 0');
    require(_amount <= TransactionAmountLimit, "You can't mint so much tokens");
    require(
      _presaleClaimed[msg.sender] + _amount <= TransactionAmountLimit,
      "You can't mint so much tokens"
    );

    uint256 current = _tokenIds.current();

    require(current + _amount <= maxSupply, 'max supply exceeded');
    require(_price * _amount <= msg.value, 'Not enough ethers sent');

    _presaleClaimed[msg.sender] += _amount;

    mintInternal(_amount);
  }

  function publicSaleMint(uint256 _amount) external payable onlyAccounts {
    require(
      block.timestamp >= publicSaleStartTimestamp,
      'Sale has not started yet'
    );
    require(!paused, 'Contract is paused');
    require(_amount > 0, 'Amount cannot be 0');
    require(_amount <= TransactionAmountLimit, "You can't mint so much tokens");
    require(
      _publicsaleClaimed[msg.sender] + _amount <= TransactionAmountLimit,
      "You can't mint so much tokens"
    );

    uint256 current = _tokenIds.current();

    require(current + _amount <= maxSupply, 'Max supply exceeded');
    require(_price * _amount <= msg.value, 'Not enough ethers sent');

    _publicsaleClaimed[msg.sender] += _amount;

    mintInternal(_amount);
  }

  /****************************************************
    BURN
  /****************************************************/
  function burnToken(uint256 tokenId) public onlyOwner {
    _burn(tokenId);
  }

  /****************************************************
    FUNCTION OVERRIDES
  /****************************************************/
  //tokenURI
  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString(), '.json'))
        : baseURI;
  }
}