// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IVotingEscrow {
    function create_lock(uint256 value, uint256 lock_duration)
        external
        returns (uint256);

    function increase_amount(uint256 tokenID, uint256 value) external;

    function increase_unlock_time(uint256 tokenID, uint256 duration) external;

    function merge(uint256 fromID, uint256 toID) external;

    function locked(uint256 tokenID)
        external
        view
        returns (uint256 amount, uint256 unlockTime);

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOfNFT(uint256 tokenId) external view returns (uint256);

    function split(uint256 from, uint256 amount) external returns (uint256);

    function attachments(uint256 tokenId) external view returns (uint256);

    function voted(uint256 tokenId) external view returns (bool isVoted);

    function ownerOf(uint256 tokenId) external view returns (address);

    // function isApprovedOrOwner(address, uint256) external view returns (bool);

    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenID
    // ) external;
}