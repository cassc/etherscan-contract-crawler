// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "../Interfaces/IBondNFT.sol";


interface IBondNFTArtwork {
    function tokenURI(uint256 _tokenID, IBondNFT.BondExtraData calldata _bondExtraData) external view returns (string memory);
}