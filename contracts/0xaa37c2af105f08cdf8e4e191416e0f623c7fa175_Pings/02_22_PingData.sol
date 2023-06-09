// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PingAtts.sol";

contract PingData is Ownable {
    mapping(uint256 => PingAtts) attsById;

    function getAtt(uint256 tokenId) external view virtual returns (PingAtts memory) {
        return attsById[tokenId];
    }

}