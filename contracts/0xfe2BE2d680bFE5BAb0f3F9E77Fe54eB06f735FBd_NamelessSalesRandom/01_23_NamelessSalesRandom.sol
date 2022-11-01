// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import '../nameless/NamelessToken.sol';
import '../utils/LazyShoeDistribution.sol';

error SaleNotStarted(string);
error InvalidTicket(string);
error TotalSupplyLimit(string);
error WrongPrice(string);
error InvalidQuantity(string);

contract NamelessSalesRandom is EIP712, AccessControl, Initializable  {
  using LazyShoeDistribution for LazyShoeDistribution.Shoe;

  address payable public benefactor;
  string public name;

  event TokenPurchased(uint index, address buyer);

  bool public saleActive;
  address public ticketSigner;
  uint256 public collectionSize;
  uint256 public totalMinted;

  LazyShoeDistribution.Shoe private shoe;
  uint firstTokenId;
  uint maxQuantity;

  function initialize(string memory _name, uint size, uint firstId, uint _maxQuantity, address _ticketSigner, address initialAdmin, address _benefactor) public initializer {
    name = _name;
    benefactor = payable(_benefactor);
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);

    saleActive = false;
    ticketSigner = _ticketSigner;

    collectionSize = size;
    shoe.size = size;

    totalMinted = 0;
    firstTokenId = firstId;
    maxQuantity = _maxQuantity;
  }

  constructor(string memory _name, string memory _domain, string memory _version, uint size, uint firstId, uint _maxQuantity, address _ticketSigner, address _benefactor) EIP712(_domain, _version) {
    initialize(_name, size, firstId, _maxQuantity, _ticketSigner, msg.sender, _benefactor);
  }

  function pickTokenId() internal returns (uint) {
    uint random = uint256(keccak256(abi.encodePacked(msg.sender, shoe.size, block.difficulty, block.timestamp, block.number, blockhash(block.number - 1))));
    uint result = shoe.pop(random);
    return firstTokenId + result - 1;
  }

  function purchase(uint quantity, uint price, NamelessToken _tokenContract, string calldata ticket, bytes calldata signature) external payable {
    if (!saleActive) { revert SaleNotStarted('Sales not started'); }
    if (SafeMath.add(totalMinted, quantity) > collectionSize) { revert TotalSupplyLimit('Sold out'); }
    if (SafeMath.mul(price, quantity) != msg.value) { revert WrongPrice('Incorrect price'); }
    if (quantity > maxQuantity || quantity <= 0) { revert InvalidQuantity('Invalid quantity'); }

    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        keccak256("SalesTicket(address wallet,string ticket,uint price,uint quantity)"),
        msg.sender,
        keccak256(bytes(ticket)),
        price,
        quantity
    )));
    address signer = ECDSA.recover(digest, signature);
    if (signer != ticketSigner) { revert InvalidTicket(string(abi.encodePacked(Strings.toHexString(uint160(signer))))); }

    NamelessToken token = _tokenContract;
    for (uint i = 0; i < quantity; i++) {
      uint tokenId = pickTokenId();
      token.mint(msg.sender, tokenId);
      totalMinted++;
      emit TokenPurchased(tokenId, msg.sender);
    }
  }

  function setPubsaleActive(bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    saleActive = active;
  }

  function withdraw() public {
    require(msg.sender == benefactor || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not authorized');
    uint amount = address(this).balance;
    require(amount > 0, 'no balance');

    Address.sendValue(benefactor, amount);
  }

  function setBenefactor(address payable newBenefactor, bool sendBalance) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(benefactor != newBenefactor, 'already set');
    uint amount = address(this).balance;
    address payable oldBenefactor = benefactor;
    benefactor = newBenefactor;

    if (sendBalance && amount > 0) {
      Address.sendValue(oldBenefactor, amount);
    }
  }
}