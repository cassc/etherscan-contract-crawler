pragma solidity 0.8.15;

//SPDX-License-Identifier: MIT

import "./Common.sol";

interface IORCPassRender is CommonTypes {
    function getSVGContent(
        uint256 tokenID,
        address owner,
        PassType passType
    ) external view returns (string memory);
}