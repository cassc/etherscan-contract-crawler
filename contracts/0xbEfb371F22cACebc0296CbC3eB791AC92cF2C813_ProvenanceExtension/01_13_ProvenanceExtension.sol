// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../manifold/libraries-solidity/access/AdminControl.sol";
import "../manifold/creator-core/core/IERC721CreatorCore.sol";
import "../openzeppelin/utils/math/SafeMath.sol";
import "../openzeppelin/utils/cryptography/ECDSA.sol";

contract ProvenanceExtension is AdminControl {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    address public CREATOR_CONTRACT;
    string public PROVENANCE_HASH = "";
    uint256 public MAX_CAP = 0;
    uint256 public TOTAL_TOKENS = 0;
    mapping(bytes32 => bool) public isRedeemed;

    // Boolean for contract pause status
    bool public paused = false;

    struct Voucher {
        bytes32 id;
        uint16 numberOfTokens;
        address redeemer;
        bytes signature;
    }

    constructor(address creator, uint256 maxCap) {
        CREATOR_CONTRACT = creator;
        MAX_CAP = maxCap;
    }

    /**
     * @notice Set paused to true
     * @dev Can only be done by Admin
     */
    function unpauseContract() external adminRequired {
        require(paused, "Contract is unpaused.");
        paused = false;
    }

    /**
     * @notice Set paused to false
     * @dev Can only be done by Admin
     */
    function pauseContract() external adminRequired {
        require(!paused, "Contract is paused.");
        paused = true;
    }

    /**
     * @notice Mint `numberOfTokens` to `mintTo` address
     * @dev Can only be done by Admin
     */
    function mintBatch(address mintTo, uint16 numberOfTokens)
        external
        adminRequired
        returns (uint256[] memory)
    {
        require(!paused, "Contract is paused.");
        require(numberOfTokens > 0, "Need to mint at least 1 token.");
        require(
            TOTAL_TOKENS.add(uint256(numberOfTokens)) <= MAX_CAP,
            "Cannot exceed max supply of available tokens."
        );

        uint256[] memory tokens = IERC721CreatorCore(CREATOR_CONTRACT)
            .mintExtensionBatch(mintTo, numberOfTokens);
        TOTAL_TOKENS += numberOfTokens;
        return tokens;
    }

    /**
     * @notice Set provenance hash
     * @dev Can only be done by Admin
     */
    function setProvenanceHash(string memory provenanceHash)
        external
        adminRequired
    {
        PROVENANCE_HASH = provenanceHash;
    }

    /**
     * @notice Update extension's baseURI
     * @dev Can only be done by Admin
     */
    function setBaseURI(string memory baseURI_) external adminRequired {
        IERC721CreatorCore(CREATOR_CONTRACT).setBaseTokenURIExtension(baseURI_);
    }

    /**
     * @notice Redeems a voucher
     * @param voucher A signed voucher containing minting info
     */
    function redeem(Voucher calldata voucher)
        public
        returns (uint256[] memory)
    {

        require(!paused, "Contract is paused.");
        require(voucher.numberOfTokens > 0, "Need to mint at least 1 token.");
        require(
            TOTAL_TOKENS.add(uint256(voucher.numberOfTokens)) <= MAX_CAP,
            "Cannot exceed max supply of available tokens."
        );
        require(!isRedeemed[voucher.id], "Voucher has already been redeemed");

        // get the address that signed the voucher
        address signer = getVoucherSigner(voucher);

        require(this.isAdmin(signer),  "Signature invalid or signer is not an admin" );

        isRedeemed[voucher.id] = true;
        uint256[] memory tokens = IERC721CreatorCore(CREATOR_CONTRACT)
            .mintExtensionBatch(voucher.redeemer, voucher.numberOfTokens);
        TOTAL_TOKENS += voucher.numberOfTokens;

        return tokens;
    }


    /**
     * @notice Verifies the signature for a given Voucher, returning the address of the signer.
     * @param voucher A signed voucher containing minting info
     */
    function getVoucherSigner(Voucher calldata voucher) public view returns (address) {
        bytes32 digest = getVoucherDigest(voucher);
        return digest.recover(voucher.signature);
    }

    /**
     * @notice Returns hash of Voucher
     * @param voucher A signed voucher containing minting info
     */
    function getVoucherDigest(Voucher calldata voucher) public view returns (bytes32) {

        return keccak256(
            abi.encode(
                voucher.id,
                voucher.numberOfTokens,
                voucher.redeemer,
                address(this)
            )
        );
    }

}