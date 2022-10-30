//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./PlaygroundPair.sol";

contract PlaygroundFactory {
    address public feeTo;
    address public feeToSetter;

    bytes32 public constant INIT_CODE_PAIR_HASH =
        keccak256(abi.encodePacked(type(PlaygroundPair).creationCode));

    mapping(address => mapping(address => address)) public getPair;
    mapping(address => bool) public validPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
        feeTo = msg.sender;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB,
        address router
    ) external returns (address pair) {
        require(tokenA != tokenB, "Playground: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Playground: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Playground: PAIR_EXISTS"); // check once
        bytes memory bytecode = type(PlaygroundPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IPlaygroundPair(pair).initialize(token0, token1, router);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        validPair[pair] = true;
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "Playground: NOT_AUTHORIZED");
        feeToSetter = _feeToSetter;
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "Playground: NOT_AUTHORIZED");
        feeTo = _feeTo;
    }
}