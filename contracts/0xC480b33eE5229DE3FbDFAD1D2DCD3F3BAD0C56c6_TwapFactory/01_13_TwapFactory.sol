// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import './interfaces/ITwapFactory.sol';
import './TwapPair.sol';

contract TwapFactory is ITwapFactory {
    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    address public override owner;

    constructor() {
        owner = msg.sender;

        emit OwnerSet(msg.sender);
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external override returns (address pair) {
        require(msg.sender == owner, 'TF00');
        require(tokenA != tokenB, 'TF3B');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TF02');
        require(getPair[token0][token1] == address(0), 'TF18'); // single check is sufficient
        bytes memory bytecode = type(TwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ITwapPair(pair).initialize(token0, token1, oracle, trader);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TF00');
        require(_owner != owner, 'TF01');
        require(_owner != address(0), 'TF02');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'TF00');
        _getPair(tokenA, tokenB).setMintFee(fee);
    }

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'TF00');
        _getPair(tokenA, tokenB).setBurnFee(fee);
    }

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external override {
        require(msg.sender == owner, 'TF00');
        _getPair(tokenA, tokenB).setSwapFee(fee);
    }

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external override {
        require(msg.sender == owner, 'TF00');
        _getPair(tokenA, tokenB).setOracle(oracle);
    }

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external override {
        require(msg.sender == owner, 'TF00');
        _getPair(tokenA, tokenB).setTrader(trader);
    }

    function collect(
        address tokenA,
        address tokenB,
        address to
    ) external override {
        require(msg.sender == owner, 'TF00');
        _getPair(tokenA, tokenB).collect(to);
    }

    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external override {
        require(msg.sender == owner, 'TF00');
        ITwapPair pair = _getPair(tokenA, tokenB);
        pair.transfer(address(pair), amount);
        pair.burn(to);
    }

    function _getPair(address tokenA, address tokenB) internal view returns (ITwapPair pair) {
        pair = ITwapPair(getPair[tokenA][tokenB]);
        require(address(pair) != address(0), 'TF19');
    }
}