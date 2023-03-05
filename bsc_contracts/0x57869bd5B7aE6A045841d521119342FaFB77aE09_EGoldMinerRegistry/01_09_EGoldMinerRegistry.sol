//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../library/EGoldUtils.sol";

contract EGoldMinerRegistry is AccessControl {
    using SafeMath for uint256;

    mapping ( uint256 => EGoldUtils.minerStruct ) private miner;

    event addMiner( uint256 indexed _type , EGoldUtils.minerStruct miner );

    constructor() AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setMiner( uint256 _type , EGoldUtils.minerStruct memory _miner) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        miner[_type] = _miner;
        emit addMiner( _type , _miner );
    }

    function fetchMinerInfo( uint256 _type ) external view returns ( EGoldUtils.minerStruct memory ){
        return miner[_type];
    }

}