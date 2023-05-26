//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAcorneCommon} from "./IAcorneCommon.sol";

interface IAcorneRenderer is IAcorneCommon {
    function setBaseURI(string memory _baseURI) external;

    function setAnimationURI(string memory _animationURI) external;

    function tokenURI(
        uint256 _tokenId,
        uint256 _commission
    ) external view returns (string memory);
}