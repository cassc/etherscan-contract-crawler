//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IArtERC721.sol";

interface IArtTokenVault {
    function initialize(
        address sellerAddress,
        IArtERC721 nftToken,
        string memory ftName,
        string memory ftSymbol
    ) external;
}