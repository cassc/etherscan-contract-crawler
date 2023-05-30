// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Open Source Libraries See: https://github.com/NFTCulture/nftc-open-contracts
import {BooleanPacking} from "@nftculture/nftc-open-contracts/contracts/utility/BooleanPacking.sol";

// OZ Libraries
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Two Phase Mint Implementation
 * @author @NiftyMike, NFT Culture
 * @dev All the code needed to support a Two Phase mint in a standard way.
 *
 * Phase 1 - Claiming
 * Phase 2 - Public Mint
 *
 * Phases are independent and can be run concurrently or exclusively.
 */
contract TwoPhaseMint is Ownable {
    using BooleanPacking for uint256;

    uint256 private constant CLAIMING_PHASE = 1;
    uint256 private constant PUBLIC_MINT_PHASE = 2;

    // BooleanPacking used on mintControlFlags
    uint256 private mintControlFlags;

    uint256 public claimPricePerNft;
    uint256 public publicMintPricePerNft;

    modifier isClaiming() {
        require(mintControlFlags.getBoolean(CLAIMING_PHASE), 'Claiming stopped');
        _;
    }

    modifier isPublicMinting() {
        require(mintControlFlags.getBoolean(PUBLIC_MINT_PHASE), 'Minting stopped');
        _;
    }

    constructor(
        uint256 __claimPricePerNft,
        uint256 __publicMintPricePerNft
    ) {
        claimPricePerNft = __claimPricePerNft;
        publicMintPricePerNft = __publicMintPricePerNft;
    }

    function setMintingState(
        bool __claimingActive,
        bool __publicMintingActive,
        uint256 __claimPricePerNft,
        uint256 __publicMintPricePerNft
    ) external onlyOwner {
        uint256 tempControlFlags;

        tempControlFlags = tempControlFlags.setBoolean(
            CLAIMING_PHASE,
            __claimingActive
        );
        tempControlFlags = tempControlFlags.setBoolean(
            PUBLIC_MINT_PHASE,
            __publicMintingActive
        );

        mintControlFlags = tempControlFlags;

        if (__claimPricePerNft > 0) {
            claimPricePerNft = __claimPricePerNft;
        }

        if (__publicMintPricePerNft > 0) {
            publicMintPricePerNft = __publicMintPricePerNft;
        }
    }

    function isClaimingActive() external view returns (bool) {
        return mintControlFlags.getBoolean(CLAIMING_PHASE);
    }

    function isPublicMintingActive() external view returns (bool) {
        return mintControlFlags.getBoolean(PUBLIC_MINT_PHASE);
    }

    function supportedPhases() external pure returns (uint256) {
        return PUBLIC_MINT_PHASE;
    }
}