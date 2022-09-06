// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IDynamic {
    function renewSubscription(uint256 tokenid) external payable;

    function mintGenesis(address to, bytes32[] calldata _merkleProof, uint256 amount) external payable;

    function mintSubscription(address to, uint256 amount) external payable;

    function refund(bool state) external;

    function subscriptionExpiry(uint256 tokenId) external;

    function updateSubscriptionMintBalance(uint256 tokenId) external;

    function addApprovedProposal(
        string memory id,
        string memory title,
        address author,
        uint256 funds
    ) external;

    function transferNft(address _to, uint256 _tokenId) external;

    function fundProposal(string memory id, uint256 amount) external;
}