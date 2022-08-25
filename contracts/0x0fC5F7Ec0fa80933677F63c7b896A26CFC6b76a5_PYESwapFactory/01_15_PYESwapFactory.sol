// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './interfaces/IPYESwapFactory.sol';
import './interfaces/IPYESwapPair.sol';
import './libraries/ReentrancyGuard.sol';
import './PYESwapPair.sol';

contract PYESwapFactory is IPYESwapFactory, ReentrancyGuard {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(PYESwapPair).creationCode));

    address public override feeTo;
    address public override feeToSetter;
    address public override routerAddress;
    bool public routerInit;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    mapping (address => bool) public override pairExist;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event FeeToUpdate(address feeTo);
    event FeeToSetterUpdate(address feeToSetter);

    constructor() {
        feeToSetter = msg.sender;
        feeTo = msg.sender;
    }

    function routerInitialize(address _router) external override {
        require(msg.sender == feeToSetter, "PYESwap: FORBIDDEN");
        require(!routerInit, "PYESwap: INITIALIZED_ALREADY");
        require(_router != address(0), "PYESwap: INVALID_ADDRESS");
        routerAddress = _router;
        routerInit = true;
    }
    
    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB, bool supportsTokenFee, address feeTaker) external override nonReentrant returns (address pair) {
        require(tokenA != tokenB, 'PYESwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PYESwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'PYESwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(PYESwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IPYESwapPair(pair).initialize(token0, token1, supportsTokenFee);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        if(supportsTokenFee) {
            IPYESwapPair(pair).setBaseToken(tokenB);
            IPYESwapPair(pair).setFeeTaker(feeTaker);

            uint32 size;
            assembly {
                size := extcodesize(tokenA)
            }
            if(size > 0) {
                IToken(tokenA).addPair(pair, tokenB);
            }
        }
        pairExist[pair] = true;
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'PYESwap: FORBIDDEN');
        require(_feeTo != address(0), "PYESwap: INVALID_ADDRESS");
        feeTo = _feeTo;
        emit FeeToUpdate(feeTo);
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'PYESwap: FORBIDDEN');
        require(_feeToSetter != address(0), "PYESwap: INVALID_ADDRESS");
        feeToSetter = _feeToSetter;
        emit FeeToSetterUpdate(feeToSetter);
    }
}