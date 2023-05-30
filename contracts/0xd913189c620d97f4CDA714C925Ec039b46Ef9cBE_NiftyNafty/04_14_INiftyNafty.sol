// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INiftyNafty {
    function updateOwnersList(address[] calldata addresses) external;

    function onOwnersList(address addr) external returns (bool);

    function addToAllowList(address[] calldata addresses) external;

    function onAllowList(address addr) external returns (bool);

    function removeFromAllowList(address[] calldata addresses) external;

    function claimedBy(address owner) external returns (uint256);

    function purchase(uint256 numberOfTokens) external payable;

    function gift(address[] calldata to) external;

    function setIsActive(bool isActive) external;

    function setPrice(uint256 newPrice) external;

    //function setMaxTotalSupply(uint256 newCount) external;

    function setStartDate(uint256 newDate) external;

    function setIsAllowListActive(bool isAllowListActive) external;

    function setAllowListMaxMint(uint256 maxMint) external;

    function setProof(string memory proofString) external;

    function withdraw() external;
}