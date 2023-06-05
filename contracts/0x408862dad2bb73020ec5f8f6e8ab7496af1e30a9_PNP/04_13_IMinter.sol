//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMinter {
    event SignerChanged(address signer);


    event PublicMintPriceChanged(uint256 price);

    function togglePublicMintStatus() external;

    function devMint(uint16 quantity, address to) external;

    function devMintToMultiAddr(uint16 quantity, address[] calldata addresses)
        external;


    function withdraw() external;
}