// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC721Initializable {
    function initialize(
        string calldata name,
        string calldata symbol,
        string calldata baseUri,
        uint256 maxCap,
        address admin,
        address minter
    ) external;
}