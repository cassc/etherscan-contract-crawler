// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMIDI {
    function mint(
        address to,
        uint256 amount,
        string memory tokenURI,
        bytes memory data
    ) external;

    function currentTokenId() external view returns (uint256);
}