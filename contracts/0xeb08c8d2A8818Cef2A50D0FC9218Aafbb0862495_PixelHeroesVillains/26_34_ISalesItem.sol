// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ISalesItem is IERC165{
    function sellerMint(address to, uint256 quantity) external;
    function sellerBurn(uint256 tokenId) external;
    function burned() external view returns(uint256);
    function getConsumedAllocation(address _target, uint8 _currentSaleIndex) external view returns(uint16);
    function setConsumedAllocation(address _target, uint8 _currentSaleIndex, uint16 _consumed) external;
    function addConsumedAllocation(address _target, uint8 _currentSaleIndex, uint16 _consumed) external;
}