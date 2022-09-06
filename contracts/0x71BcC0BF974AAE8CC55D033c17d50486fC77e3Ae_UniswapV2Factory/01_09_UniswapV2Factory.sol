// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;
    uint256 public defaultFee = 4;
    uint256 public constant MAX_FEE = 50;

    mapping(address => mapping(address => address)) public override getPair;
    mapping(address => uint) public override feeForPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2Pair(pair).initialize(token0, token1);
        feeForPair[pair] = defaultFee;
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setDefaultFee(uint _defaultFee) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        require(_defaultFee <= MAX_FEE, 'UniswapV2: INVALID_FEE');
        defaultFee = _defaultFee;
    }

    function setFeeForPair(address _pair, uint _fee) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        require(_fee <= MAX_FEE, 'UniswapV2: INVALID_FEE');
        feeForPair[_pair] = _fee;
    }

    function setFeeForPairs(address[] calldata _pair, uint[] calldata _fee) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        require(_pair.length == _fee.length);
        
        for (uint i; i < _pair.length; ++i) {
            uint fee = _fee[i];
            require(fee <= MAX_FEE, 'UniswapV2: INVALID_FEE');
            feeForPair[_pair[i]] = fee;
        }
    }

    function getFeeForPair(address _pair) external override view returns (uint) {
        return feeForPair[_pair];
    }
}