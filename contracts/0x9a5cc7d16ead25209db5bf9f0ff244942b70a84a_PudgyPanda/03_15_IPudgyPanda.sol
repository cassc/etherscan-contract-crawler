// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPudgyPanda {
    function addToAllowList(address[] calldata addresses) external;

    function onAllowList(address addr) external returns (bool);

    function removeFromAllowList(address[] calldata addresses) external;

    function allowListClaimedBy(address owner) external returns (uint256);

    function purchase(uint256 numberOfTokens) external payable;

    function purchaseAllowList(uint256 numberOfTokens) external payable;

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function ownerMint(uint256 quantity) external;

    function gift(address[] calldata to) external;

    function setIsActive(bool isActive) external;

    function setIsAllowListActive(bool isAllowListActive) external;

    function setAllowListMaxMint(uint256 maxMint) external;

    function setPublicMaxMint(uint256 maxMint) external;

    function setProof(string memory proofString) external;

    function lock() external;

    function emergencyWithdraw() external payable;

    function withdrawAll() external payable;

    function setMintPrice(uint256 price) external;
}