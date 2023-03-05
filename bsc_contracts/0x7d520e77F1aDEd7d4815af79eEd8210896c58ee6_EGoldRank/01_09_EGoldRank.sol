//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../library/EGoldUtils.sol";

contract EGoldRank is AccessControl {
    using SafeMath for uint256;

    mapping(uint256 => EGoldUtils.Ranks) private Rank;

    event addRank( uint256 indexed _rank , EGoldUtils.Ranks miner );

    constructor() AccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setRank( uint256 _rank , EGoldUtils.Ranks memory _rankDetails ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Rank[_rank] = _rankDetails;
        emit addRank( _rank , _rankDetails);
    }

    function fetchRank(  uint256 _rank ) external view returns ( EGoldUtils.Ranks memory ) {
        return Rank[_rank];
    }

}