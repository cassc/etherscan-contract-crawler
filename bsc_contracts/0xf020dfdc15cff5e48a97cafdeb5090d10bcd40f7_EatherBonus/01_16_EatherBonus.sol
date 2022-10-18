// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "./libs/fota/Auth.sol";
import "./libs/fota/Math.sol";
import "./libs/fota/MerkelProof.sol";
import "./interfaces/IGameNFT.sol";
import "./interfaces/IRewardManager.sol";
import "./interfaces/ILPToken.sol";
import "./interfaces/IItemNFT.sol";

contract EatherBonus is Auth, EIP712Upgradeable {

  IItemNFT public itemNFT;
  ILPToken public lpToken;
  IRewardManager public rewardManager;
  mapping (address => mapping(uint => bool)) public claimMarker;
  uint public signatureTimeOut;
  uint public maxEatherPerTurn;
  mapping(uint => bytes32) public rootHashes;
  mapping(uint => uint) private rates;

  event BonusResult(address indexed user, bool success, uint quantity, uint quantitySent, uint index);

  function initialize(
    string memory _name,
    string memory _version,
    address _itemNFT,
    address _rewardManager,
    address _lpToken
  ) public initializer {
    Auth.initialize(msg.sender);
    EIP712Upgradeable.__EIP712_init(_name, _version);
    itemNFT = IItemNFT(_itemNFT);
    rewardManager = IRewardManager(_rewardManager);
    lpToken = ILPToken(_lpToken);
    signatureTimeOut = 300;
    maxEatherPerTurn = 2;
  }

  function getBonus(bytes calldata _signature, uint _timestamp, uint _quantity, bytes32[] calldata _path, uint _index) external {
    require(!claimMarker[msg.sender][rewardManager.getDaysPassed()], "EatherBonus: see you tomorrow");
    claimMarker[msg.sender][rewardManager.getDaysPassed()] = true;
    _validateSignature(_signature, _timestamp, _quantity);
    if (_index > 0) {
      _validateWhiteList(_path, _index);
    }
    bool success = _haveBonus(_signature, _index);
    uint quantity = _quantity > maxEatherPerTurn ? maxEatherPerTurn : _quantity;
    if (success) {
      _giveReward(quantity);
    }
    emit BonusResult(msg.sender, success, _quantity, quantity, _index);
  }

  function _validateSignature(bytes calldata _signature, uint _timestamp, uint _quantity) private view {
    require(_timestamp + signatureTimeOut >= block.timestamp, "EatherBonus: signature time out");
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
      keccak256("GetBonus(address user,uint256 timestamp,uint256 quantity)"),
      msg.sender,
      _timestamp,
      _quantity
    )));
    address signer = ECDSAUpgradeable.recover(digest, _signature);
    require(signer == contractAdmin, "MessageVerifier: invalid signature");
    require(signer != address(0), "ECDSAUpgradeable: invalid signature");
  }

  function _haveBonus(bytes calldata _signature, uint _index) private view returns (bool) {
    (uint r0, uint r1) = lpToken.getReserves();
    uint randomNumber = Math.genRandomNumber(string(_signature), r0 + r1 + rates[_index]);
    return randomNumber < rates[_index];
  }

  function _validateWhiteList(bytes32[] calldata _path, uint _index) private view {
    bytes32 hash = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_path, rootHashes[_index], hash), "EatherBonus: index invalid");
  }

  function _giveReward(uint _quantity) private {
    itemNFT.mintItems(msg.sender, 0, 1, 5 ether, _quantity);
  }

  function setRootHashes(uint _index, bytes32 _rootHash) onlyMainAdmin external {
    require(_index > 0, "EatherBonus: invalid index");
    rootHashes[_index] = _rootHash;
  }

  function setRates(uint _index, uint _rate) onlyMainAdmin external {
    require(_rate >= 1 && _rate <= 100, "EatherBonus: invalid rate");
    rates[_index] = _rate;
  }

  function setMaxEatherPerTurn(uint _maxEatherPerTurn) onlyMainAdmin external {
    require(_maxEatherPerTurn > 0, "EatherBonus: invalid value");
    maxEatherPerTurn = _maxEatherPerTurn;
  }
}