// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShiniki {
    function preSaleMint(
        address receiver,
        bytes32[] memory typeMints,
        uint256[] memory quantities,
        uint256 amountAllowce,
        uint256 nonce,
        bytes memory signature
    ) external;

    function publicSaleMint(
        bytes32[] memory typeMints,
        uint256[] memory quantities
    ) external payable;

    function privateMint(
        address receiver,
        uint256 quantityType1,
        uint256 quantityType2
    ) external;

    function lock(uint256[] memory tokenIds) external;

    function unlock(uint256[] memory tokenIds) external;

    function withdraw(address receiver, uint256 amount) external;

    function withdrawAll(address receiver) external;

    function safeTransferWhileStaking(
        address from,
        address to,
        uint256 tokenId
    ) external;
}