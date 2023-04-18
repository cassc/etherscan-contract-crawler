// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "./interfaces/IUniswapV2Pair.sol";
import { IWERC721 } from "./interfaces/IWERC721.sol";
import { UniswapV2Pair } from "./UniswapV2Pair.sol";
import { WERC721 } from "./WERC721.sol";
import { DELEGATE_FACTORY } from "./Delegation.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    mapping(address => address) public getCollection;
    mapping(address => address) public getWrapper;
    address[] public allWrappers;

    mapping(address => mapping(address => bool)) public delegates;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function allWrappersLength() external view returns (uint) {
        return allWrappers.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "SweepnFlip: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SweepnFlip: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "SweepnFlip: PAIR_EXISTS"); // single check is sufficient
        bool discrete0 = getCollection[token0] != address(0);
        bool discrete1 = getCollection[token1] != address(0);
        require(!(discrete0 && discrete1), "SweepnFlip: DISCRETE_CLASH");
        if (discrete0 || discrete1) {
            bytes32 salt = keccak256(abi.encodePacked(token0, token1));
            pair = address(new UniswapV2Pair{salt: salt}());
            IUniswapV2Pair(pair).initialize(token0, token1, discrete0, discrete1);
        } else {
            pair = IUniswapV2Factory(DELEGATE_FACTORY).getPair(tokenA, tokenB);
            if (pair == address(0)) {
                IUniswapV2Factory(DELEGATE_FACTORY).createPair(tokenA, tokenB);
            }
            delegates[token0][token1] = true;
        }
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function createWrapper(address collection) external returns (address wrapper) {
        require(collection != address(0), "SweepnFlip: ZERO_ADDRESS");
        require(getWrapper[collection] == address(0), "SweepnFlip: WRAPPER_EXISTS");
        bytes32 salt = keccak256(abi.encodePacked(collection));
        wrapper = address(new WERC721{salt: salt}());
        IWERC721(wrapper).initialize(collection);
        getCollection[wrapper] = collection;
        getWrapper[collection] = wrapper;
        allWrappers.push(wrapper);
        emit WrapperCreated(collection, wrapper, allWrappers.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "SweepnFlip: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "SweepnFlip: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function _initCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }
}