// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./libraries/UniswapV2Library.sol";
import './UniswapV2Pair.sol';

/// @custom:security-contact [email protected]
contract UniswapV2Factory is AccessControl {
    bytes32 public constant PAIR_CREATOR_ROLE = keccak256("PAIR_CREATOR_ROLE");

    address  public immutable template = address(new UniswapV2Pair());
    address  public feeTo;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function getPair(address tokenA, address tokenB) public view returns (address) {
        address pair = UniswapV2Library.pairFor(address(this), tokenA, tokenB);
        return pair.code.length > 0 ? pair : address(0);
    }

    function createPair(address tokenA, address tokenB) external onlyRoleOrOpenRole(PAIR_CREATOR_ROLE) returns (address pair) {
        (address token0, address token1) = UniswapV2Library.sortTokens(tokenA, tokenB);
        pair = Clones.cloneDeterministic(template, keccak256(abi.encodePacked(token0, token1)));
        UniswapV2Pair(pair).initialize(token0, token1);
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeTo = _feeTo;
    }
}