// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

interface ISkebClaim {
    function claim(
        address signer,
        address user,
        uint256 amount,
        uint256 expiry,
        bytes memory sig
    ) external;

    function grantSigner(address newSigner) external;

    function revokeSigner(address oldSigner) external;

    function isSigner(address signer) external view returns (bool);

    function getTokenBalance() external view returns (uint256);

    function withdrawToken(uint256 amount) external;

    function incrementTermId() external;

    function changeTermId(uint256 newTermId) external;

    function createClaimMessage(
        address user,
        uint256 amount,
        uint256 expiry,
        uint256 termId
    ) external pure returns (bytes32);

    function validateSignature(
        address signer,
        address user,
        uint256 amount,
        uint256 expiry,
        bytes memory sig,
        uint256 termId
    ) external pure returns (bool);
}