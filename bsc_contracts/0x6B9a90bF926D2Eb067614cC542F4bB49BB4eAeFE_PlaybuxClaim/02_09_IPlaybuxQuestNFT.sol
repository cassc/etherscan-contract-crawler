// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPlaybuxQuestNFT is IERC721 {
    function mintTo(address _to, uint256 _type) external;
}