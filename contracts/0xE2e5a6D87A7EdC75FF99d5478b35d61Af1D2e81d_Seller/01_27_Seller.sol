// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Collection.sol";
import "./Store.sol";
import "./utils/Structs.sol";

contract Seller is Stoppable {
  Store store;

  mapping(address => mapping(uint256 => mapping(address => uint256)))
    public presaleTokens;

  mapping(address => uint256) balance;
  mapping(address => uint256) lastTokenId;
  mapping(address => mapping(uint256 => uint256)) public sold;

  event Withdraw(address collection, address owner, uint256 balance);

  event PaymentReceived(
    address indexed payer,
    address collection,
    uint256 saleId,
    uint256 quantity,
    uint256 payment
  );

  event RequestForMint(
    address indexed payer,
    address indexed to,
    address collection,
    uint256 nonce,
    uint256 quantity
  );

  modifier validCollection(address _collection) {
    store.validateCollection(_collection);
    _;
  }

  modifier storeOrCollectionAuthorized(address _collection) {
    require(
      store.isAuthorized(msg.sender, _collection),
      "UNAUTHORIZED: Sender is not authorized"
    );
    _;
  }

  constructor(address _store) {
    store = Store(_store);
  }

  function buy(
    address _collection,
    uint256 _saleId,
    address _to,
    uint256 _qtyAllowed,
    uint256 _qtyToBuy,
    bytes32[] calldata _proof,
    bool _mintL1
  ) external payable nonStopped validCollection(_collection) {
    (bytes32 whitelistRoot, , , uint256 price) = store.sales(
      _collection,
      _saleId
    );
    if (whitelistRoot != bytes32(0)) {
      _verifyPresaleBuy(_collection, _saleId, _qtyToBuy, _qtyAllowed, _proof);
      presaleTokens[_collection][_saleId][msg.sender] += _qtyToBuy;
    }
    require(msg.value >= price * _qtyToBuy, "PAYMENT: Insufficient funds");
    balance[_collection] += msg.value;
    _mintRequest(_collection, _saleId, _to, _qtyToBuy, _mintL1);
    emit PaymentReceived(
      msg.sender,
      _collection,
      _saleId,
      _qtyToBuy,
      msg.value
    );
  }

  function reserve(
    address _collection,
    uint256 _saleId,
    address[] memory _to,
    uint256[] memory _qty,
    bool _mintL1
  )
    external
    nonStopped
    validCollection(_collection)
    storeOrCollectionAuthorized(_collection)
  {
    require(
      _to.length == _qty.length,
      "A quantity must be set for each benefited"
    );
    for (uint256 i = 0; i < _to.length; i++) {
      _mintRequest(_collection, _saleId, _to[i], _qty[i], _mintL1);
    }
  }

  function withdraw(address _collection, address receiver)
    external
    nonStopped
    validCollection(_collection)
  {
    require(
      Collection(_collection).owner() == msg.sender,
      "Sender is not the owner of the collection"
    );
    uint256 balanceToWithdraw = balance[_collection];
    balance[_collection] = 0;
    payable(receiver).transfer(balanceToWithdraw);
    emit Withdraw(_collection, msg.sender, balanceToWithdraw);
  }

  function verifyPresale(
    address _collection,
    uint256 _saleId,
    address account,
    uint256 qty,
    bytes32[] memory proof
  ) public view nonStopped validCollection(_collection) returns (bool) {
    return _verify(_collection, _saleId, _leaf(account, qty), proof);
  }

  function _mintRequest(
    address _collection,
    uint256 _saleId,
    address _to,
    uint256 _qty,
    bool _mintL1
  ) internal {
    _verifyMintRequest(_collection, _saleId, _qty, _mintL1);
    uint256 initialTokenId = lastTokenId[_collection] + 1;
    sold[_collection][_saleId] += _qty;
    lastTokenId[_collection] += _qty;

    if (_mintL1) {
      for (uint256 i = initialTokenId; i <= lastTokenId[_collection]; i++) {
        Collection(_collection).mint(_to, i);
      }
    } else {
      emit RequestForMint(msg.sender, _to, _collection, initialTokenId, _qty);
    }
  }

  function _verify(
    address _collection,
    uint256 _saleId,
    bytes32 leaf,
    bytes32[] memory proof
  ) internal view returns (bool) {
    (bytes32 whitelistRoot, , , ) = store.sales(_collection, _saleId);
    return MerkleProof.verify(proof, whitelistRoot, leaf);
  }

  function _verifyMintRequest(
    address _collection,
    uint256 _saleId,
    uint256 _qtyToBuy,
    bool _mintL1
  ) internal view {
    (, bool mintL1Authorized) = store.collection(_collection);
    (, bool active, uint256 supply, ) = store.sales(_collection, _saleId);
    require(!_mintL1 || mintL1Authorized, "Minting to L1 is not authorized");
    require(
      active || Collection(_collection).owner() == msg.sender,
      "TRANSACTION: Sale is not active"
    );

    require(
      _qtyToBuy + sold[_collection][_saleId] <= supply,
      "SUPPLY: Value exceeds supply"
    );
  }

  function _verifyPresaleBuy(
    address _collection,
    uint256 _saleId,
    uint256 _qtyToBuy,
    uint256 _qtyAllowed,
    bytes32[] calldata _proof
  ) internal view {
    require(
      verifyPresale(_collection, _saleId, msg.sender, _qtyAllowed, _proof),
      "TRANSACTION: Invalid proof"
    );
    require(
      presaleTokens[_collection][_saleId][msg.sender] + _qtyToBuy <=
        _qtyAllowed,
      "TRANSACTION: More than allowed"
    );
  }

  function _leaf(address account, uint256 qty) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(account, qty));
  }
}