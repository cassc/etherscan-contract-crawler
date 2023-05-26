// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// All Smilesss LLC (www.smilesss.com)

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ShiestySmilesss is ERC1155, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 private _counter = 0;

  mapping(address => bool) public firstTwenty;
  uint256 public firstTwentyCounter = 0;

  // Smart contract status
  enum MintStatus {
    CLOSED,
    PRESALE,
    PUBLIC
  }
  MintStatus public status = MintStatus.CLOSED;

  // Collection info
  string private _uri = "https://smilesssvrs.mypinata.cloud/ipfs/Qmag96HBhnp6EWzzNJkqi3hv7SDEbC3WM6331D5ULNrBY7/";
  string private _suffix = ".json";
  uint256 public price = 0.1 ether;
  uint256[3] public maxPerStatus = [0, 1, 4];
  uint256 private publicSupply = 1000;

  // Presale
  bytes32 public merkleRoot = 0xf4673a559825e70d5678bc571b3f84dcde0f4302ca3e5e046a3422eaf70b678a;
  mapping(address => bool) private _hasMinted;

  // Event declaration
  event ChangedStatusEvent(uint256 newStatus);

  constructor() ERC1155(_uri) {
    // Token zero has only 1 edition and it will be put on auction
    _mint(msg.sender, 0, 1, "");
  }

  // To be used to mint id 1,2,3 and 4
  function mint(
    uint256 _qty,
    bytes32[] calldata _proof
  ) external payable nonReentrant presaleValidation(_proof){
    uint256 __counter = _counter;
    require(msg.sender == tx.origin, "You cannot mint from a smart contract");
    require(status != MintStatus.CLOSED, "Minting is closed");
    require(msg.value >= price * _qty, "Ether sent is not correct");
    require(_qty <= maxPerStatus[uint256(status)], "Exceeded the max amount of NFTs");
    require(__counter < publicSupply, "Amount not available");

    _counter += _qty;
    for (uint i = 0; i < _qty; ++i){
      uint256 tokenId = (__counter % 4) + 1;
      ++__counter;
      _mint(msg.sender, tokenId, 1, "");
    }

    if(firstTwentyCounter < 20 && !firstTwenty[msg.sender]){
        isSetCompleted(msg.sender);
    }
  }

  modifier presaleValidation(bytes32[] calldata _proof) {
    if (status == MintStatus.PRESALE) {
      require(
        MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
        "You are not in presale"
      );
      require(!_hasMinted[msg.sender], "Already minted");
      _hasMinted[msg.sender] = true;
    }
    _;
  }

  // Getters
  function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
    return string(abi.encodePacked(super.uri(_id), _id.toString(), _suffix));
  }

  function totalSupply() public view returns (uint256) {
    return _counter;
  }

  function getStatus(address _address) public view returns (uint256 mintStatus, uint256 minted, bool presaleMinted){
    return (uint256(status), _counter, _hasMinted[_address]);
  }

  // Setters
  function setURI(string memory newuri, string memory suffix) public onlyOwner {
      _suffix = suffix;
      _setURI(newuri);
  }

  function setStatus(uint256 _status) external onlyOwner {
    // _status -> 0: CLOSED, 1: PRESALE, 2: PUBLIC
    require(_status >= 0 && _status <= 2, "Mint status must be between 0 and 2");
    status = MintStatus(_status);
    emit ChangedStatusEvent(_status);
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  // Withdraw function
  function withdraw(address payable withdraw_address) external payable nonReentrant onlyOwner {
    require(withdraw_address != address(0), "Withdraw address cannot be zero");
    require(address(this).balance != 0, "Balance is zero");
    payable(withdraw_address).transfer(address(this).balance);
  }


  // FirstTwenty
  function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
      super._safeTransferFrom(from, to, id, amount, data);

      if(firstTwentyCounter < 20 && !firstTwenty[to]){
        isSetCompleted(to);
      }
    }
  
  function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
      super._safeBatchTransferFrom(from, to, ids, amounts, data);

      if(firstTwentyCounter < 20 && !firstTwenty[to]){
        isSetCompleted(to);
      }
    }

  function isSetCompleted(address _address) internal {
    if(balanceOf(_address, 1) > 0 && balanceOf(_address, 2) > 0 && balanceOf(_address, 3) > 0 && balanceOf(_address, 4) > 0){
      firstTwenty[_address] = true;
      ++ firstTwentyCounter;
    }
  }

  function isInFirstTwenty(address _address) public view returns(bool){
    return(firstTwenty[_address]);
  }
}