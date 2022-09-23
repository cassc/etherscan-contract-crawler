// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IFiat24Account is IERC721Enumerable {
    enum Status { Na, SoftBlocked, Tourist, Blocked, Closed, Live }
    function historicOwnership(address) external view returns(uint256);
    function exists(uint256 tokenId) external view returns(bool);
    function nickNames(uint256) external view returns(string memory);
    function isMerchant(uint256) external view returns(bool);
    function merchantRate(uint256) external view returns(uint256);
    function status(uint256) external view returns(uint256);
    function checkLimit(uint256, uint256) external view returns(bool);
    function updateLimit(uint256 tokenId, uint256 amount) external;
}