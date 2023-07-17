// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IDynamic {
    function renewSubscription(uint256 tokenid) external payable;

    function mintGenesis(
        address to,
        bytes32[] calldata _merkleProof,
        uint256 amount
    ) external payable;

    function mintGiftGenesis(address _to) external;

    function mintSubscription(
        address to,
        uint256 amount,
        uint256 code
    ) external payable;

    function setDistibuteGenesisTokensActive() external;

    function claimDistributedTokens(uint256 tokenId) external;

    function subscriptionExpiry(uint256 tokenId) external;

    function updateSubscriptionMintBalance(uint256 tokenId) external;

    function addApprovedProposal(
        string memory id,
        string memory title,
        address author
    ) external;

    function transferNft(address _to, uint256 _tokenId) external;

    function fundProposal(string memory id, uint256 amount) external;

    function getReferralCode(address referree) external view returns (uint256);
}