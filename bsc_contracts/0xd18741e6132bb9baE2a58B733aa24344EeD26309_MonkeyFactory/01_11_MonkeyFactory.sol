// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;

import "./interfaces/IMonkeyFactory.sol";
import "./MonkeyPair.sol";

contract MonkeyFactory is IMonkeyFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(MonkeyPair).creationCode));

    address public feeTo;
    address public treasurer;
    address public admin;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(address _admin) public {
        admin = _admin;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Monkey: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Monkey: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Monkey: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(MonkeyPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IMonkeyPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == admin, "Monkey: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setTreasurer(address _treasurer) external {
        require(msg.sender == admin, "Monkey: FORBIDDEN");
        treasurer = _treasurer;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "Monkey: FORBIDDEN");
        admin = _admin;
    }
}