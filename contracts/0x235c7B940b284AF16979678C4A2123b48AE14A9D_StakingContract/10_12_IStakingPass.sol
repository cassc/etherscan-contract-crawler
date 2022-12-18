//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IStakingPass is IERC721Upgradeable {
    function mint(address _to, uint256 _tokenId) external;
    function checkExistence(uint256 _tokenId) external view returns (bool);
}