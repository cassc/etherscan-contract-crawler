// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721AUpgradeable} from "@erc721a-upgradable/extensions/ERC721AQueryableUpgradeable.sol";
import {IERC4906} from "../interfaces/IERC4906.sol";

interface IBeepBoopBotzV2 is IERC721AUpgradeable, IERC4906 {
    event Evolve(uint256 botId, uint256 buildId);
    event CancelEvolve(uint256 botId, uint256 buildId);

    function getBotEvolvedBuild(uint256 tokenId) external view returns (uint256);
}