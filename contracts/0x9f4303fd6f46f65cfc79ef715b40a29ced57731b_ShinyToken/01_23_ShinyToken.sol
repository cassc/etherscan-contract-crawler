// SPDX-License-Identifier: GPL-3.0

/// @title The Shiny Club ERC-721 Token

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/governance/utils/Votes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import { IShinyDescriptor } from './interfaces/IShinyDescriptor.sol';
import { IShinySeeder } from './interfaces/IShinySeeder.sol';
import { IShinyState } from './interfaces/IShinyState.sol';
import { IShinyToken } from './interfaces/IShinyToken.sol';


contract ShinyToken is IShinyToken, ERC721, Ownable, EIP712, Votes {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    //  Contract-level metadata as base64 encoded string
    string private _contractURI = '';

    // An address who has permissions to mint Shinys
    address public minter;

    // The Shiny token URI descriptor
    IShinyDescriptor public descriptor;

    // The Shiny token seeder
    IShinySeeder public seeder;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // Mapping owner address to voting balance. Voting balance is
    // based on the number of times the token has been reconfigured.
    mapping(address => uint256) private _votingBalances;

    // The Shiny seeds
    mapping(uint256 => IShinySeeder.Seed) public seeds;

    // The Shiny shiny states (whether or not a shiny is actually shiny)
    mapping(uint256 => IShinyState.State) public shinyStates;

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(_msgSender() == minter, 'ShinyToken: Sender is not the minter');
        _;
    }

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'ShinyToken: Minter is locked');
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'ShinyToken: Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'ShinyToken: Seeder is locked');
        _;
    }

    constructor(
        address _minter,
        IShinyDescriptor _descriptor,
        IShinySeeder _seeder
    ) ERC721("ShinyClub", "SCLUB") EIP712("ShinyClub", "1") {
        minter = _minter;
        descriptor = _descriptor;
        seeder = _seeder;
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ShinyToken: URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId], shinyStates[tokenId].isShiny);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ShinyToken: URI query for nonexistent token');
        return descriptor.dataURI(tokenId, seeds[tokenId], shinyStates[tokenId].isShiny);
    }

    /**
     * @notice Mint a Shiny to the purchaser.
     * @dev Call _mintTo with the to address(es).
     */
    function mint(address to, uint16 shinyChanceBasisPoints) public override onlyMinter returns (uint256) {
        return _mintTo(to, shinyChanceBasisPoints);
    }

    /**
     * @notice Allows the tokenId owner to reconfigure (specify a new seed) for their shiny. If the Shiny is "shiny" they can modify the special "shinyAccessory" layer as well.
     */
    function reconfigureShiny(uint256 tokenId,
                              address msgSender,
                              IShinySeeder.Seed calldata newSeed) public onlyMinter returns (IShinySeeder.Seed memory) {
        IShinyState.State storage state = shinyStates[tokenId];

        if (newSeed.shinyAccessory != 0) {
            require(state.isShiny == true, 'ShinyToken: cannot change shinyAccessory for non-shiny token');
        }

        IShinySeeder.Seed memory validNewSeed =
                seeder.generateSeedWithValues(newSeed,
                                              descriptor,
                                              state.isShiny);

        seeds[tokenId] = validNewSeed;

        // Count this reconfig to add to voting units for this token.
        state.reconfigurationCount += 1;
        // Track voting balance by address.
        _votingBalances[msgSender] += 1;
        // Give a new vote each time Shiny is reconfigured.
        _transferVotingUnits(address(0), msgSender, 1);

        // If undelegated, delegate to self.
        if (delegates(msgSender) == address(0)) {
            _delegate(msgSender, msgSender);
        }

        emit ShinyReconfigured(tokenId, validNewSeed, state.reconfigurationCount);
        return validNewSeed;
    }

    /**
     * @notice Reveals whether a Shiny is "shiny" or not.
     */
    function revealShiny(uint256 tokenId) external override returns (bool) {
        // Anyone can call this, even if not token owner
        // Verify token exists
        require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
        // Look up state, get block number
        IShinyState.State storage state = shinyStates[tokenId];
        uint256 shinyChanceBlockId = state.mintedBlock + 1;

        // Require 7 blocks after mint for finality
        require(block.number >= shinyChanceBlockId, 'ShinyToken: reveal must wait at least 1 block post-mint');
        uint256 blockHash = uint256(blockhash(shinyChanceBlockId));

        require(blockHash != 0, 'ShinyToken: block number is too far in the past');

        // Hash block with tokenId and check if shiny based on shiny basis points
        uint256 randomness = uint256(
            keccak256(abi.encodePacked(blockHash, tokenId))
        );

        // If good, make shiny!
        if (randomness % 10_000 <= state.shinyChanceBasisPoints) {
            state.isShiny = true;
            // Make shiny state visible (user can change this later)
            seeds[tokenId].shinyAccessory = uint16(1);
        }

        emit ShinyRevealed(tokenId, state.isShiny);
        return state.isShiny;
    }

    /**
     * @notice Return whether a token is shiny or not.
     */
    function tokenShinyState(uint256 tokenId) public view virtual returns (bool) {
        require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
        return shinyStates[tokenId].isShiny;
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(IShinyDescriptor _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(IShinySeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a Shiny with `tokenId` to the provided `to` address.
     */
    function _mintTo(address to, uint16 shinyChanceBasisPoints) internal returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Establish initial Shiny state
        bool isShiny = shinyChanceBasisPoints == 10_000 ? true : false;
        shinyStates[tokenId] = IShinyState.State({
            isShiny: isShiny,
            mintedBlock: block.number,
            shinyChanceBasisPoints: shinyChanceBasisPoints,
            reconfigurationCount: 0
        });

        IShinySeeder.Seed memory seed = seeds[tokenId] = seeder.generateSeedForMint(tokenId, descriptor, isShiny);

        _safeMint(to, tokenId);
        emit ShinyCreated(tokenId, seed, shinyChanceBasisPoints);
        return tokenId;
    }

    /**
     * @dev Returns the voting balance of `account`.
     */
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return _votingBalances[account];
    }

    function totalVotingUnits() public view virtual returns (uint256) {
        return _getTotalSupply();
    }

    /**
     * @dev Adjusts votes when tokens are transferred.
     *
     * Emits a {Votes-DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        // Maintain votingBalances for quick lookup.
        _votingBalances[from] -= shinyStates[tokenId].reconfigurationCount;
        if (to != address(0)) { // Don't transfer votes to null address.
            _votingBalances[to] += shinyStates[tokenId].reconfigurationCount;
        }
        // Transfer voting rights of delegated votes.
        _transferVotingUnits(from, to, shinyStates[tokenId].reconfigurationCount);
        super._afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Returns the contract metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Sets the contract metadata as a base64 encoded URI
     */
    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
        emit ContractMetadataUpdated(_contractURI);
    }
}