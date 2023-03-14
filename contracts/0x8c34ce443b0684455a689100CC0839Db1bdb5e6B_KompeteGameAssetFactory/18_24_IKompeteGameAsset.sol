// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMintableERC1155.sol";

interface IKompeteGameAsset is IMintableERC1155 {
    function registry() external view returns (address);

    function setMaxSupply(
        uint256 id,
        uint256 max,
        bool freeze
    ) external;
}