// SPDX-License-Identifier: CC-BY-NC-ND-4.0

pragma solidity ^0.8.10;
pragma abicoder v2;

contract DropFunctions {

    // ---
    // Properties
    // ---

    uint256 public invocations = 0;
    uint256 public maxInvocations;
    uint256 public nextTokenId;
    uint256 public mintPriceInWei;
    uint256 public maxQuantityPerTransaction;
    string public metadataBaseUri;
    bool public autoPayout;
    bool public active;
    bool public paused;
    bool public completed;
    uint256 public royaltyFeeBps;
    uint256 public imnotArtBps;
    address public artistPayoutAddress;
    bool public maxPerWalletEnabled;
    uint256 public maxPerWalletQuantity;

    // ---
    // Mappings
    // ---

    mapping(address => uint256) mintsPerWallet;

    // ---
    // Function Modifiers
    // ---

    modifier onlyActive() {
        require(active, "Minting is not active.");
        _;
    }

    modifier onlyNonPaused() {
        require(!paused, "Minting is paused.");
        _;
    }

    // ---
    // Functions
    // ---

    function totalSupply() external view returns (uint256) {
        return invocations;
    }
}