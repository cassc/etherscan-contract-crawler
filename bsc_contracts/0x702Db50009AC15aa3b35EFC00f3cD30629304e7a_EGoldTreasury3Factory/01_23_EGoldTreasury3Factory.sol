// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./EGoldTreasury3.sol";

contract EGoldTreasury3Factory is AccessControl {
    using SafeCast for *;
    using SafeMath for uint256;
    using Address for address;

    address public identity;
    address public minerReg;
    address public rank;
    address public master;
    uint256 public maxLevel;
    uint256 public burnRatio;
    address public burnerAddr;
    address public nft;
    address public cashback;


    event createInstance( address indexed _instance , address _identity , address _minerReg , address _rank ,  address _rate , address _master , uint256 _maxLevel , address _token , address _nft , uint256 _burnRatio  , address _burnerAddr , address _cashback ,address _DFA );

    constructor() AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setup( address _identity , address _minerReg , address _rank , address _master , uint256 _maxLevel , address _nft , uint256 _burnRatio , address _burnerAddr , address _cashback ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        identity = _identity;
        minerReg = _minerReg;
        rank = _rank;
        master = _master;
        maxLevel = _maxLevel;
        nft = _nft;
        burnRatio = _burnRatio;
        burnerAddr = _burnerAddr;
        cashback = _cashback;
    }

    //Factory Fx
    function create(
        address _token,
        address _rate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        EGoldTreasury3 instance = new EGoldTreasury3( identity , minerReg , rank , _rate , master , maxLevel , _token , nft , burnRatio , burnerAddr , cashback , msg.sender );
        emit createInstance( address(instance) , identity , minerReg , rank , _rate , master , maxLevel , _token , nft , burnRatio , burnerAddr , cashback , msg.sender );
    }
    //Factory Fx

}