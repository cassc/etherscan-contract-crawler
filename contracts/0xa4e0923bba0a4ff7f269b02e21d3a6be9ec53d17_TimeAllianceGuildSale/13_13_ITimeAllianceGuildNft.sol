// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITimeAllianceGuildNft {
    function mint(address account, uint256 id, uint256 amount) external;

    function burn(address account, uint256 id, uint256 amount) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}