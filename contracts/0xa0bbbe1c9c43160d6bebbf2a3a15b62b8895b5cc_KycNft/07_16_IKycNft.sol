// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

interface IKycNft {
    /**
     * @custom:deprecated In version v2.1
     */
    function mint(
        uint256 basicGene,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Allows anyone to claim (mint) anyone's NFT
     * @param to Address that will receive the claimed NFT
     */
    function claim(address to) external;

    /**
     * @dev Returns the domain separator used in the encoding of the signature for provider protected functions, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}