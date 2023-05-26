// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IReverseRegistrar.sol";
import "./ERC721.sol";

/**
 * @title MasterchefMasatoshi
 * NFT + DAO = NEW META
 * Vitalik, remove contract size limit pls
 */
contract MasterchefMasatoshi is ERC721, Ownable {
  using ECDSA for bytes32;
  string public PROVENANCE;
  bool provenanceSet;

  uint256 public mintPrice;
  uint256 public maxPossibleSupply;
  uint256 public allowListMintPrice;
  uint256 public maxAllowedMints;

  address public immutable currency;
  address immutable wrappedNativeCoinAddress;

  address private signerAddress;
  address public daoDelegate;

  uint256 public percentToVote = 60;
  uint256 public votingDuration = 86400;

  bool public percentToVoteFrozen;
  bool public votingDurationFrozen;

  Voting[] public votings;

  bool public isDao;
  bool public paused;
  address immutable ENSReverseRegistrar = 0x084b1c3C81545d370f3634392De611CaaBFf8148;

  enum MintStatus {
    PreMint,
    AllowList,
    Public,
    Finished
  }

  MintStatus public mintStatus = MintStatus.PreMint;

  mapping (address => uint256) totalMintsPerAddress;

  struct Voting {
    address contractAddress;
    bytes data;
    uint256 value;
    string comment;
    uint256 index;
    uint256 timestamp;
    bool isActivated;
    address[] signers;
  }

  modifier onlyHoldersOrOwner {
    require((isDao && balanceOf(msg.sender) > 0) || msg.sender == owner());
    _;
  }

  modifier onlyContractOrOwner {
    require(msg.sender == address(this) || msg.sender == owner());
    _;
  }

  constructor(
      string memory _name,
      string memory _symbol,
      uint256 _maxPossibleSupply,
      uint256 _mintPrice,
      uint256 _allowListMintPrice,
      uint256 _maxAllowedMints,
      address _signerAddress,
      address _nftDaoAddress,
      address _currency,
      address _wrappedNativeCoinAddress
  ) ERC721(_name, _symbol, _maxAllowedMints) {
    maxPossibleSupply = _maxPossibleSupply;
    mintPrice = _mintPrice;
    allowListMintPrice = _allowListMintPrice;
    maxAllowedMints = _maxAllowedMints;
    signerAddress = _signerAddress;
    daoDelegate = _nftDaoAddress;
    currency = _currency;
    wrappedNativeCoinAddress = _wrappedNativeCoinAddress;
  }

  function permanentlyConvertToDao() external onlyOwner {
    isDao = true;
  }

  function flipPaused() external onlyOwner {
    paused = !paused;
  }

  function preMint(uint amount) public onlyContractOrOwner {
    require(mintStatus == MintStatus.PreMint, "s");
    require(totalSupply() + amount <= maxPossibleSupply, "m");  
    _safeMint(msg.sender, amount);
  }

  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    require(!provenanceSet);
    PROVENANCE = provenanceHash;
    provenanceSet = true;
  }

  // warning! don't call this function unless you know what you are doing
  function setDaoDelegate(address _daoDelegate) external onlyOwner {
    daoDelegate = _daoDelegate;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }
  
  function changeMintStatus(MintStatus _status) external onlyContractOrOwner {
    require(_status != MintStatus.PreMint);
    mintStatus = _status;
  }

  function mintAllowList(
    bytes32 messageHash,
    bytes calldata signature,
    uint amount
  ) public payable {
    require(hashMessage(msg.sender, address(this)) == messageHash, "i");
    require(verifyAddressSigner(messageHash, signature), "f");
    _mintWithChecks(amount, allowListMintPrice, MintStatus.AllowList);
  }

  function mintPublic(uint amount) public payable {
    _mintWithChecks(amount, mintPrice, MintStatus.Public);
  }

  function _mintWithChecks(uint amount, uint price, MintStatus status) private {
    require(mintStatus == status && !paused, "s");
    require(totalSupply() + amount <= maxPossibleSupply, "m");
    require(totalMintsPerAddress[msg.sender] + amount <= maxAllowedMints, "l");

    if (currency == wrappedNativeCoinAddress) {
        require(price * amount <= msg.value, "a");
    } else {
        IERC20 _currency = IERC20(currency);
        _currency.transferFrom(msg.sender, address(this), amount * price);    
    }

    totalMintsPerAddress[msg.sender] = totalMintsPerAddress[msg.sender] + amount;
    _safeMint(msg.sender, amount);

    if (totalSupply() == maxPossibleSupply) {
      mintStatus = MintStatus.Finished;
    }
  }

  receive() external payable {
    mintPublic(msg.value / mintPrice);
  }

  function addReverseENSRecord(string memory name) external onlyOwner {
    IReverseRegistrar(ENSReverseRegistrar).setName(name);
  }

  function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
    return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
  }

  function hashMessage(address sender, address thisContract) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(sender, thisContract));
  }

  function getAllVotings() external view returns (Voting[] memory) {
    return votings;
  }

  function withdraw() external onlyOwner() {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawTokens(address tokenAddress) external onlyOwner() {
    IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
  }

  fallback() external {
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), sload(daoDelegate.slot), ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)
      switch result
      case 0 {revert(ptr, size)}
      default {return (ptr, size)}
    }
  }
}

// The High Table