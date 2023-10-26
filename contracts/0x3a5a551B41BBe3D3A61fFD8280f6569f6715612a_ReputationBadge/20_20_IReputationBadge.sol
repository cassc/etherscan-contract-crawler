// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IReputationBadge is IERC1155 {
    // ========= Structs =========

    struct ClaimData {
        uint256 mintPrice;
        bytes32 claimRoot;
        uint48 claimExpiration;
    }

    // ========= Badge Operations =========

    function mint(
        address recipient,
        uint256 tokenId,
        uint256 amount,
        uint256 totalClaimable,
        bytes32[] calldata merkleProof
    ) external payable;

    function uri(uint256 tokenId) external view returns (string memory);

    function publishRoots(uint256[] calldata tokenIds, ClaimData[] calldata _claimData) external;

    function withdrawFees(address recipient) external;

    function setDescriptor(address _descriptor) external;

    function amountClaimed(address, bytes32) external view returns (uint256);
}