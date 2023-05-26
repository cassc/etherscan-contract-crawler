// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import { IERC721 as ERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface EclipticInterface {
    function approve(address to, uint256 tokenId) external;
    function transferPoint(uint32 _point, address _target, bool _reset) external;
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
}

abstract contract Ecliptic is EclipticInterface {}