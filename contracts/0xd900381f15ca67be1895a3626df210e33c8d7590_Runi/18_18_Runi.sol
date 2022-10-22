// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721PartnerSeaDrop} from "seadrop/ERC721PartnerSeaDrop.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";

contract Runi is ERC721PartnerSeaDrop, Pausable {
    // The contract is paused.
    error ContractPaused();

    // The hive user is empty.
    error MissingHiveUser();

    // The hive user is invalid.
    error InvalidHiveUser();

    // The caller must own the token.
    error StakeCallerNotOwner();

    // The caller must own the token.
    error UnstakeCallerNotOwner();

    // Cannot transfer staked token.
    error TransferForStaked();

    // Emitted when `tokenId` token is staked from `owner` to hive user `hiveUser`.
    event Stake(address indexed owner, uint256 indexed tokenId, string indexed hiveUser);

    // Emitted when `tokenId` token is unstaked from `hiveUser` hive user by `owner` caller.
    event Unstake(address indexed owner, uint256 indexed tokenId, string indexed hiveUser);

    // Mapping from token ID to hive user.
    mapping(uint256 => string) public cardStakedTo;

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    constructor(string memory name, string memory symbol, address administrator, address[] memory allowedSeaDrop)
        ERC721PartnerSeaDrop(name, symbol, administrator, allowedSeaDrop)
    {
        _maxSupply = 6500;
        _tokenBaseURI = "https://runi.splinterlands.com/metadata/";
        _contractURI = "https://runi.splinterlands.com/metadata/contract.json";
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     *         ERC721A tracks these values automatically, but this note and
     *         nonReentrant modifier are left here to encourage best-practices
     *         when referencing this contract.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function mintSeaDrop(address minter, uint256 quantity) external payable override onlyAllowedSeaDrop(msg.sender) {
        if (paused()) {
            revert ContractPaused();
        }

        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(_totalMinted() + quantity, maxSupply());
        }

        // Mint the quantity of tokens to the minter.
        _safeMint(minter, quantity);
    }

    /*
     * Called prior to transfer of any token.
     *
     * Requirements:
     *
     * - Contract must not be paused.
     * - Token must not be staked.
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (paused()) {
            revert ContractPaused();
        }

        for (uint256 id = startTokenId; id < startTokenId + quantity; id++) {
            if (bytes(cardStakedTo[id]).length != 0) {
                revert TransferForStaked();
            }
        }
    }

    /*
     * Pauses the contract.
     *
     * Requirements:
     *
     * - Caller must be owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * Unpauses the contract.
     *
     * Requirements:
     *
     * - Caller must be owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /*
     * Stake the `tokenId` token to a hive user.
     *
     * Only a single hive account can be staked at a time.
     * If staking a staked token, unstake will be called first.
     *
     * Requirements:
     *
     * - The caller must own the token.
     * - `tokenId` must exist.
     *
     * Emits a {Stake} event.
     */
    function stake(uint256 tokenId, string memory hiveUser) external payable {
        if (paused()) {
            revert ContractPaused();
        }

        // Check owner
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner) {
            revert StakeCallerNotOwner();
        }

        // Check hive user
        bytes memory strBytes = bytes(hiveUser);

        if (strBytes.length == 0) {
            revert MissingHiveUser();
        }

        if (strBytes[0] == bytes1("@")) {
            revert InvalidHiveUser();
        }

        // Unstake if needed
        if (bytes(cardStakedTo[tokenId]).length != 0) {
            unstake(tokenId);
        }

        // Stake
        cardStakedTo[tokenId] = hiveUser;
        emit Stake(msg.sender, tokenId, cardStakedTo[tokenId]);
    }

    /*
     * Removes stake of `tokenId` token from a hive user.
     *
     * Requirements:
     *
     * - The caller must own the token.
     * - `tokenId` must exist.
     *
     * Emits a {Unstake} event.
     */
    function unstake(uint256 tokenId) public payable {
        if (paused()) {
            revert ContractPaused();
        }

        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner) {
            revert UnstakeCallerNotOwner();
        }

        string memory previousStakedTo = cardStakedTo[tokenId];

        delete cardStakedTo[tokenId];
        emit Unstake(msg.sender, tokenId, previousStakedTo);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }
}