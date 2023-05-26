// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT1155.sol";

/// @title EnigmaNFT1155
///
/// @dev This contract extends from BaseEnigmaNFT1155

contract EnigmaNFT1155 is BaseEnigmaNFT1155 {
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /**
     * @notice Internal function to verify a sign to mint tokens
     * Reverts if the sign verification fails.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param sign_ struct combination of uint8, bytes32, bytes32 are v, r, s.
     */
    function verifySign(string memory tokenURI_, Sign memory sign_) internal view {
        bytes32 hash = keccak256(abi.encodePacked(this, tokenURI_));
        require(
            owner() ==
                ecrecover(
                    keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                    sign_.v,
                    sign_.r,
                    sign_.s
                ),
            "Owner sign verification failed"
        );
    }

    /**
     * @notice public function to mint a new token.
     * @param uri_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     * @param sign_ struct combination of uint8, bytes32, bytes32 are v, r, s.
     */
    function mint(
        string memory uri_,
        uint256 supply_,
        uint256 fee_,
        Sign memory sign_
    ) external {
        uint256 tokenCounter = newItemId;
        verifySign(uri_, sign_);
        newItemId = newItemId + 1;
        _mint(tokenCounter, supply_, uri_, fee_);
    }
}