//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import './HashStore.sol';

contract OperatorHub is Ownable {
  bytes constant public ETH_PREFIX = "\x19Ethereum Signed Message:\n32";

  uint constant public MIN_REQUIRED_OPERATORS = 2;

  uint8 public requiredOperators;

  mapping(address => bool) public operators;

  mapping(address => string) public operatorLocation;

  address[] public operatorList;

  HashStore public immutable hashStore;

  constructor(HashStore _hashStore, uint8 _requiredOperators, address[] memory initialOperators) {
    require(_requiredOperators != 0, "should provide the number of required operators");
    require(initialOperators.length >= _requiredOperators, "should provide more operators");
    require(_requiredOperators >= MIN_REQUIRED_OPERATORS, "should be greater than the minimum number of required operators");

    for (uint i = 0; i < initialOperators.length; i++) {
      addOperator(initialOperators[i]);
    }

    if (_hashStore == HashStore(0x0)) {
      _hashStore = new HashStore();
    }

    hashStore = _hashStore;

    setRequiredOperators(_requiredOperators);
  }

  function addOperator(address operator) public onlyOwner {
    require(operator != address(0));
    require(!operators[operator], "cannot add the same operator twice");
    operators[operator] = true;
    operatorList.push(operator);

    emit OperatorAdded(operator);
  }

  /**
   * @dev Transfers ownership of the HashStore contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferHashStoreOwnership(address newOwner) public onlyOwner {
    hashStore.transferOwnership(newOwner);
  }

  function removeOperator(address operator) public onlyOwner {
    require(operators[operator], "cannot find this operator");

    require(operatorList.length > requiredOperators, "cannot remove more operators");
    delete operators[operator];
    delete operatorLocation[operator];

    emit OperatorRemoved(operator);

    for (uint256 i = 0; i < operatorList.length; i++) {
      if (operatorList[i] == operator) {
        operatorList[i] = operatorList[operatorList.length - 1];
        operatorList.pop();
        return;
      }
    }
  }

  function updateLocation(address operator, string memory location) public onlyOwner {
    require(operators[operator], "cannot find this operator");

    operatorLocation[operator] = location;

    emit LocationUpdated(operator, location);
  }

  function setRequiredOperators(uint8 requiredOperators_) public onlyOwner {
    require(requiredOperators_ > 0, "at least one operator is required");
    require(operatorList.length >= requiredOperators_, "cannot be more than the number of added operators");
    require(requiredOperators_ >= MIN_REQUIRED_OPERATORS, "should be greater than the minimum number of required operators");
    requiredOperators = requiredOperators_;
  }

  function isOperator(address operator) public view returns (bool) {
    return (operators[operator] == true);
  }

  function operatorCount() public view returns (uint) {
    return operatorList.length;
  }

  function operatorAddresses() public view returns (address[] memory) {
    return operatorList;
  }

  function checkSignatures(
    bytes32 hash,
    uint256 length,
    uint8[] memory v,
    bytes32[] memory r,
    bytes32[] memory s
  ) public view returns(uint8) {
    uint8 approvals = 0;

    address prevOperator = address(0x0);

    for (uint i = 0; i < length; ++i) {
      address operator = ecrecover(hash, v[i], r[i], s[i]);
      require(isOperator(operator), "should be an operator");
      require(prevOperator < operator, "signatures are out of order");
      prevOperator = operator;
      approvals ++;
    }

    return approvals;
  }

  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  event OperatorAdded(address operator);
  event OperatorRemoved(address operator);
  event LocationUpdated(address operator, string location);
}