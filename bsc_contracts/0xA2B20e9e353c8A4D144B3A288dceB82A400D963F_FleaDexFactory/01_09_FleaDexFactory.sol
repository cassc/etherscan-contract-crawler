// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './interfaces/IFleaDexFactory.sol';
import './FleaDexPair.sol';

contract FleaDexFactory is IFleaDexFactory {
 address public override feeTo ;
 address public override feeToManager;

 mapping(address => mapping(address => address)) public override getPair;
 address[] public override allPairs;

 bool public paused = false;

 event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

 event Pause();
 event Unpause();

 /**
  * @dev Modifier to make a function callable only when the contract is not paused.
  */
 modifier whenNotPaused() {
  require(!paused);
  _;
 }

 /**
  * @dev Modifier to make a function callable only when the contract is paused.
  */
 modifier whenPaused() {
  require(paused);
  _;
 }

 constructor(address _feeToManager, address _feeTo) public {
  require(_feeToManager != address(0), '_feeToManager cannot be zero address');
  require(_feeTo != address(0), '_feeTo cannot be zero address');
  feeToManager = _feeToManager;
  feeTo = _feeTo;
 }
 
 function allPairsLength() external view override returns (uint256) {
  return allPairs.length;
 }

 function pairCodeHash() external pure returns (bytes32) {
  return keccak256(type(FleaDexPair).creationCode);
 }

 function createPair(address tokenA, address tokenB) external override whenNotPaused returns (address pair) {
  require(tokenA != tokenB, 'FleaDexv2: IDENTICAL_ADDRESSES');
  (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  require(token0 != address(0), 'FleaDexv2: ZERO_ADDRESS');
  require(getPair[token0][token1] == address(0), 'FleaDexv2: PAIR_EXISTS'); // single check is sufficient
  bytes memory bytecode = type(FleaDexPair).creationCode;
  bytes32 salt = keccak256(abi.encodePacked(token0, token1));
  assembly {
pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
  }
  FleaDexPair(pair).initialize(token0, token1);
  getPair[token0][token1] = pair;
  getPair[token1][token0] = pair; // populate mapping in the reverse direction
  allPairs.push(pair);
  emit PairCreated(token0, token1, pair, allPairs.length);
 }

 function setFeeTo(address _feeTo) external override {
  require(msg.sender == feeToManager, 'Only FeeToManager can change the feeTo address');
  feeTo = _feeTo;
 }

 function setFeeToManager(address _feeToManager) external override {
  require(msg.sender == feeToManager, 'FleaDexV2: FORBIDDEN');
  require(_feeToManager != address(0), '_feeToManager cannot be zero address');
  feeToManager = _feeToManager;
 }

 /**
  * @dev called by the owner to pause, triggers stopped state
  */
 function pause() public whenNotPaused {
  require(msg.sender == feeToManager, 'FleaDexV2: FORBIDDEN');
  paused = true;
  emit Pause();
 }

 /**
  * @dev called by the owner to unpause, returns to normal state
  */
 function unpause() public whenPaused {
  require(msg.sender == feeToManager, 'FleaDexV2: FORBIDDEN');
  paused = false;
  emit Unpause();
 }

 function isPaused() external view override returns (bool) {
  return paused;
 }
}