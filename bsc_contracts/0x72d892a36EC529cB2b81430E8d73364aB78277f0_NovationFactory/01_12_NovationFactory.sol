// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;

import "./libraries/EnumerableSet.sol";
import './interfaces/INovationFactory.sol';
import './NovationPair.sol';

contract NovationFactory is INovationFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(NovationPair).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    EnumerableSet.AddressSet tokens;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, address _WETH) public {
        feeToSetter = _feeToSetter;
        tokens.add(_WETH);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Novation: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Novation: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Novation: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(NovationPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        INovationPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Novation: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Novation: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function addToken(address _token) external {
        require(msg.sender == feeToSetter, 'Novation: FORBIDDEN');
        require(!tokens.contains(_token), 'Novation: FORBIDDEN');
        tokens.add(_token);
    }

    function removeToken(address _token) external {
        require(msg.sender == feeToSetter, 'Novation: FORBIDDEN');
        require(tokens.contains(_token), 'Novation: FORBIDDEN');
        tokens.remove(_token);
    }

    function existToken(address _token) external view returns (bool) {
        return tokens.contains(_token);
    }

    function getAllTokens() external view returns (address[] memory) {
        return tokens.values();
    }
}