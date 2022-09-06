// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IBNFT is IERC721, IERC721Receiver {
    function mint(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function underlyingAsset() external view returns (address);
}