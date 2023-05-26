// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface IBabyBirdez is IERC721Enumerable {
    function setBreeder(address _newBreeder) external;
    function owner() external view returns (address);
    function mintTo(address _to, uint256 _numberOfTokens) external;
    function hatch(uint256 _tokenId) external;
    function isHatch(uint256 _tokenId) external view returns (bool);
}