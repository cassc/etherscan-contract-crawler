// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './interfaces/IArborSwapFactory.sol';
import './ArborSwapPair.sol';

contract ArborSwapFactory is IArborSwapFactory {
  address public override feeTo;
  address public override feeToSetter;
  address public override migrator;

  mapping(address => mapping(address => address)) public override getPair;
  address[] public override allPairs;

  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  constructor(address _feeToSetter, address _feeTo) public {
    feeToSetter = _feeToSetter;
    feeTo = _feeTo;
  }

  function allPairsLength() external view override returns (uint256) {
    return allPairs.length;
  }

  function pairCodeHash() external pure returns (bytes32) {
    return keccak256(type(ArborSwapPair).creationCode);
  }

  function createPair(address tokenA, address tokenB) external override returns (address pair) {
    require(tokenA != tokenB, 'ArborSwapV2: IDENTICAL_ADDRESSES');
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'ArborSwap: ZERO_ADDRESS');
    require(getPair[token0][token1] == address(0), 'ArborSwap: PAIR_EXISTS'); // single check is sufficient
    bytes memory bytecode = type(ArborSwapPair).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(token0, token1));
    assembly {
      pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    ArborSwapPair(pair).initialize(token0, token1);
    getPair[token0][token1] = pair;
    getPair[token1][token0] = pair; // populate mapping in the reverse direction
    allPairs.push(pair);
    emit PairCreated(token0, token1, pair, allPairs.length);
  }

  function setFeeTo(address _feeTo) external override {
    require(msg.sender == feeToSetter, 'ArborSwap: FORBIDDEN');
    feeTo = _feeTo;
  }

  function setMigrator(address _migrator) external override {
    require(msg.sender == feeToSetter, 'ArborSwap: FORBIDDEN');
    migrator = _migrator;
  }

  function setFeeToSetter(address _feeToSetter) external override {
    require(msg.sender == feeToSetter, 'ArborSwap: FORBIDDEN');
    feeToSetter = _feeToSetter;
  }
}