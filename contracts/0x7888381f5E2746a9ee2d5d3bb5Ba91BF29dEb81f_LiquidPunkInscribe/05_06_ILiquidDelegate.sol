// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./INFTFlashBorrower.sol";

/**
 * @title Interface to Liquid Delegate
 */

struct Rights {
    address depositor;
    uint96 expiration;
    address contract_;
    uint256 tokenId;
}

interface ILiquidDelegate {
    function idsToRights(uint256 rightsId) external view returns(Rights memory);
    function creationFee() external view returns(uint256);
    function nextRightsId() external view returns(uint256);
    function create(address contract_, uint256 tokenId, uint96 expiration, address payable referrer) external payable;
    function burn(uint256 rightsId) external;
    function transferFrom(address from, address to, uint256 id) external;
    function flashLoan(uint256 rightsId, INFTFlashBorrower receiver, bytes calldata data) external;
}