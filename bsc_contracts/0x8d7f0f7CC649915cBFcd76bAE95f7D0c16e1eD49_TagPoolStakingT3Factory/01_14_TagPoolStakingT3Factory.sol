// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "../../../interfaces/iTagToken.sol";

import "./TagPoolStakingT3.sol";

contract TagPoolStakingT3Factory is AccessControl {
    using SafeCast for *;
    using SafeMath for uint256;
    using Address for address;

    iTagToken FT;

    uint256 private ctr;

    mapping(address => address) private P2C;

    mapping(uint256 => address) private PoolStakingAddress;

    event create(address indexed _POOLSTAKINGCONTRACT);

    constructor(address _FTAddress) public AccessControl() {
        FT = iTagToken(_FTAddress);

        ctr = 0;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //Factory Fx
    function createPool(
        address _PT,
        string memory _name,
        string memory _symbol
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ctr = ctr.add(1);
        TagPoolStakingT3 TPool = new TagPoolStakingT3(address(FT), _PT, msg.sender);
        address TPA = address(TPool);
        P2C[TPA] = _PT;
        PoolStakingAddress[ctr] = TPA;
        emit create(TPA);
    }

    //Factory Fx

    function getP2C(address _addr) public view returns (address) {
        return P2C[_addr];
    }

    function getPoolStakingCtr(uint256 _ctr) public view returns (address) {
        return PoolStakingAddress[_ctr];
    }

    function getCtr() public view returns (uint256) {
        return ctr;
    }
}