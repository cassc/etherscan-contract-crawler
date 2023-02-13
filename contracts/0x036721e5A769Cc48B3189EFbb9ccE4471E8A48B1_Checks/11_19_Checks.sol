// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IChecks.sol";
import "./interfaces/IChecksEdition.sol";
import "./libraries/ChecksArt.sol";
import "./libraries/ChecksMetadata.sol";
import "./libraries/Utilities.sol";
import "./standards/CHECKS721.sol";

/**
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓  ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓          ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓                      ✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓                        ✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓                ✓✓       ✓✓✓✓✓✓✓
✓✓✓✓✓                 ✓✓✓          ✓✓✓✓✓
✓✓✓✓                 ✓✓✓            ✓✓✓✓
✓✓✓✓✓          ✓✓  ✓✓✓             ✓✓✓✓✓
✓✓✓✓✓✓✓          ✓✓✓             ✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓                        ✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓                      ✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓          ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓  ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
@title  Checks
@author VisualizeValue
@notice This artwork is notable.
*/
contract Checks is IChecks, CHECKS721 {

    /// @notice The VV Checks Edition contract.
    IChecksEdition public editionChecks;

    /// @dev We use this database for persistent storage.
    Checks checks;

    /// @dev Initializes the Checks Originals contract and links the Edition contract.
    constructor() {
        editionChecks = IChecksEdition(0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9);
        checks.day0 = uint32(block.timestamp);
        checks.epoch = 1;
    }

    /// @notice Migrate Checks Editions to Checks Originals by burning the Editions.
    ///         Requires the Approval of this contract on the Edition contract.
    /// @param tokenIds The Edition token IDs you want to migrate.
    /// @param recipient The address to receive the tokens.
    function mint(uint256[] calldata tokenIds, address recipient) external {
        uint256 count = tokenIds.length;

        // Initialize new epoch / resolve previous epoch.
        resolveEpochIfNecessary();

        // Burn the Editions for the given tokenIds & mint the Originals.
        for (uint256 i; i < count;) {
            uint256 id = tokenIds[i];
            address owner = editionChecks.ownerOf(id);

            // Check whether we're allowed to migrate this Edition.
            if (
                owner != msg.sender &&
                (! editionChecks.isApprovedForAll(owner, msg.sender)) &&
                editionChecks.getApproved(id) != msg.sender
            ) { revert NotAllowed(); }

            // Burn the Edition.
            editionChecks.burn(id);

            // Initialize our Check.
            StoredCheck storage check = checks.all[id];
            check.day = Utilities.day(checks.day0, block.timestamp);
            check.epoch = uint32(checks.epoch);
            check.seed = uint16(id);
            check.divisorIndex = 0;

            // Mint the original.
            // If we're minting to a vault, transfer it there.
            if (msg.sender != recipient) {
                _safeMintVia(recipient, msg.sender, id);
            } else {
                _safeMint(msg.sender, id);
            }

            unchecked { ++i; }
        }

        // Keep track of how many checks have been minted.
        unchecked { checks.minted += uint32(count); }
    }

    /// @notice Get a specific check with its genome settings.
    /// @param tokenId The token ID to fetch.
    function getCheck(uint256 tokenId) external view returns (Check memory check) {
        return ChecksArt.getCheck(tokenId, checks);
    }

    /// @notice Sacrifice a token to transfer its visual representation to another token.
    /// @param tokenId The token ID transfer the art into.
    /// @param burnId The token ID to sacrifice.
    function inItForTheArt(uint256 tokenId, uint256 burnId) external {
        _sacrifice(tokenId, burnId);

        unchecked { ++checks.burned; }
    }

    /// @notice Sacrifice multiple tokens to transfer their visual to other tokens.
    /// @param tokenIds The token IDs to transfer the art into.
    /// @param burnIds The token IDs to sacrifice.
    function inItForTheArts(uint256[] calldata tokenIds, uint256[] calldata burnIds) external {
        uint256 pairs = _multiTokenOperation(tokenIds, burnIds);

        for (uint256 i; i < pairs;) {
            _sacrifice(tokenIds[i], burnIds[i]);

            unchecked { ++i; }
        }

        unchecked { checks.burned += uint32(pairs); }
    }

    /// @notice Composite one token into another. This mixes the visual and reduces the number of checks.
    /// @param tokenId The token ID to keep alive. Its visual will change.
    /// @param burnId The token ID to composite into the tokenId.
    /// @param swap Swap the visuals before compositing.
    function composite(uint256 tokenId, uint256 burnId, bool swap) external {
        // Allow swapping the visuals before executing the composite.
        if (swap) {
            StoredCheck memory toKeep = checks.all[tokenId];

            checks.all[tokenId] = checks.all[burnId];
            checks.all[burnId] = toKeep;
        }

        _composite(tokenId, burnId);

        unchecked { ++checks.burned; }
    }

    /// @notice Composite multiple tokens. This mixes the visuals and checks in remaining tokens.
    /// @param tokenIds The token IDs to keep alive. Their art will change.
    /// @param burnIds The token IDs to composite.
    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) external {
        uint256 pairs = _multiTokenOperation(tokenIds, burnIds);

        for (uint256 i; i < pairs;) {
            _composite(tokenIds[i], burnIds[i]);

            unchecked { ++i; }
        }

        unchecked { checks.burned += uint32(pairs); }
    }

    /// @notice Sacrifice 64 single-check tokens to form a black check.
    /// @param tokenIds The token IDs to burn for the black check.
    /// @dev The check at index 0 survives.
    function infinity(uint256[] calldata tokenIds) external {
        uint256 count = tokenIds.length;

        // Make sure we're allowed to mint the black check.
        if (count != 64) {
            revert InvalidTokenCount();
        }
        for (uint256 i; i < count;) {
            uint256 id = tokenIds[i];
            if (checks.all[id].divisorIndex != 6) {
                revert BlackCheck__InvalidCheck();
            }
            if (!_isApprovedOrOwner(msg.sender, id)) {
                revert NotAllowed();
            }

            unchecked { ++i; }
        }

        // Complete final composite.
        uint256 blackCheckId = tokenIds[0];
        StoredCheck storage check = checks.all[blackCheckId];
        check.day = Utilities.day(checks.day0, block.timestamp);
        check.divisorIndex = 7;

        // Burn all 63 other Checks.
        for (uint i = 1; i < count;) {
            _burn(tokenIds[i]);

            unchecked { ++i; }
        }
        unchecked { checks.burned += 63; }

        // When one is released from the prison of self, that is indeed freedom.
        // For the most great prison is the prison of self.
        emit Infinity(blackCheckId, tokenIds[1:]);
        emit MetadataUpdate(blackCheckId);
    }

    /// @notice Burn a check. Note: This burn does not composite or swap tokens.
    /// @param tokenId The token ID to burn.
    /// @dev A common purpose burn method.
    function burn(uint256 tokenId) external {
        if (! _isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotAllowed();
        }

        // Perform the burn.
        _burn(tokenId);

        // Keep track of supply.
        unchecked { ++checks.burned; }
    }

    /// @notice Initializes and closes epochs.
    /// @dev Based on the commit-reveal scheme proposed by MouseDev.
    function resolveEpochIfNecessary() public {
        Epoch storage currentEpoch = checks.epochs[checks.epoch];

        if (
            // If epoch has not been committed,
            currentEpoch.committed == false ||
            // Or the reveal commitment timed out.
            (currentEpoch.revealed == false && currentEpoch.revealBlock < block.number - 256)
        ) {
            // This means the epoch has not been committed, OR the epoch was committed but has expired.
            // Set committed to true, and record the reveal block:
            currentEpoch.revealBlock = uint64(block.number + 50);
            currentEpoch.committed = true;

        } else if (block.number > currentEpoch.revealBlock) {
            // Epoch has been committed and is within range to be revealed.
            // Set its randomness to the target block hash.
            currentEpoch.randomness = uint128(uint256(keccak256(
                abi.encodePacked(
                    blockhash(currentEpoch.revealBlock),
                    block.difficulty
                ))) % (2 ** 128 - 1)
            );
            currentEpoch.revealed = true;

            // Notify DAPPs about the new epoch.
            emit NewEpoch(checks.epoch, currentEpoch.revealBlock);

            // Initialize the next epoch
            checks.epoch++;
            resolveEpochIfNecessary();
        }
    }

    /// @notice The identifier of the current epoch
    function getEpoch() view public returns(uint256) {
        return checks.epoch;
    }

    /// @notice Get the data for a given epoch
    /// @param index The identifier of the epoch to fetch
    function getEpochData(uint256 index) view public returns(Epoch memory) {
        return checks.epochs[index];
    }

    /// @notice Simulate a composite.
    /// @param tokenId The token to render.
    /// @param burnId The token to composite.
    function simulateComposite(uint256 tokenId, uint256 burnId) public view returns (Check memory check) {
        _requireMinted(tokenId);
        _requireMinted(burnId);

        // We want to simulate for the next divisor check count.
        uint8 index = checks.all[tokenId].divisorIndex;
        uint8 nextDivisor = index + 1;
        check = ChecksArt.getCheck(tokenId, nextDivisor, checks);

        // Simulate composite tree
        check.stored.composites[index] = uint16(burnId);

        // Simulate visual composite in stored data if we have many checks
        if (index < 5) {
            (uint8 gradient, uint8 colorBand) = _compositeGenes(tokenId, burnId);
            check.stored.colorBands[index] = colorBand;
            check.stored.gradients[index] = gradient;
        }

        // Simulate composite in memory data
        check.composite = !check.isRoot && index < 7 ? check.stored.composites[index] : 0;
        check.colorBand = ChecksArt.colorBandIndex(check, nextDivisor);
        check.gradient = ChecksArt.gradientIndex(check, nextDivisor);
    }

    /// @notice Render the SVG for a simulated composite.
    /// @param tokenId The token to render.
    /// @param burnId The token to composite.
    function simulateCompositeSVG(uint256 tokenId, uint256 burnId) external view returns (string memory) {
        return string(ChecksArt.generateSVG(simulateComposite(tokenId, burnId), checks));
    }

    /// @notice Get the colors of all checks in a given token.
    /// @param tokenId The token ID to get colors for.
    /// @dev Consider using the ChecksArt and EightyColors Libraries
    ///      in combination with the getCheck function to resolve this yourself.
    function colors(uint256 tokenId) external view returns (string[] memory, uint256[] memory)
    {
        return ChecksArt.colors(ChecksArt.getCheck(tokenId, checks), checks);
    }

    /// @notice Render the SVG for a given token.
    /// @param tokenId The token to render.
    /// @dev Consider using the ChecksArt Library directly.
    function svg(uint256 tokenId) external view returns (string memory) {
        return string(ChecksArt.generateSVG(ChecksArt.getCheck(tokenId, checks), checks));
    }

    /// @notice Get the metadata for a given token.
    /// @param tokenId The token to render.
    /// @dev Consider using the ChecksMetadata Library directly.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return ChecksMetadata.tokenURI(tokenId, checks);
    }

    /// @notice Returns how many tokens this contract manages.
    function totalSupply() public view returns (uint256) {
        return checks.minted - checks.burned;
    }

    /// @dev Sacrifice one token to transfer its art to another.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _sacrifice(uint256 tokenId, uint256 burnId) internal {
        (,StoredCheck storage toBurn,) = _tokenOperation(tokenId, burnId);

        // Copy over static genome settings
        checks.all[tokenId] = toBurn;

        // Update the birth date for this token.
        checks.all[tokenId].day = Utilities.day(checks.day0, block.timestamp);

        // Perform the burn.
        _burn(burnId);

        // Notify DAPPs about the Sacrifice.
        emit Sacrifice(burnId, tokenId);
        emit MetadataUpdate(tokenId);
    }

    /// @dev Composite one token into to another and burn it.
    /// @param tokenId The token ID to keep. Its art and check-count will change.
    /// @param burnId The token ID to burn in the process.
    function _composite(uint256 tokenId, uint256 burnId) internal {
        (
            StoredCheck storage toKeep,,
            uint8 divisorIndex
        ) = _tokenOperation(tokenId, burnId);

        uint8 nextDivisor = divisorIndex + 1;

        // We only need to breed band + gradient up until 4-Checks.
        if (divisorIndex < 5) {
            (uint8 gradient, uint8 colorBand) = _compositeGenes(tokenId, burnId);

            toKeep.colorBands[divisorIndex] = colorBand;
            toKeep.gradients[divisorIndex] = gradient;
        }

        // Composite our check
        toKeep.day = Utilities.day(checks.day0, block.timestamp);
        toKeep.composites[divisorIndex] = uint16(burnId);
        toKeep.divisorIndex = nextDivisor;

        // Perform the burn.
        _burn(burnId);

        // Notify DAPPs about the Composite.
        emit Composite(tokenId, burnId, ChecksArt.DIVISORS()[toKeep.divisorIndex]);
        emit MetadataUpdate(tokenId);
    }

    /// @dev Composite the gradient and colorBand settings.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _compositeGenes (uint256 tokenId, uint256 burnId) internal view
        returns (uint8 gradient, uint8 colorBand)
    {
        Check memory keeper = ChecksArt.getCheck(tokenId, checks);
        Check memory burner = ChecksArt.getCheck(burnId, checks);

        // Pseudorandom gene manipulation.
        uint256 randomizer = uint256(keccak256(abi.encodePacked(keeper.seed, burner.seed)));

        // If at least one token has a gradient, we force it in ~20% of cases.
        gradient = Utilities.random(randomizer, 100) > 80
            ? randomizer % 2 == 0
                ? Utilities.minGt0(keeper.gradient, burner.gradient)
                : Utilities.max(keeper.gradient, burner.gradient)
            : Utilities.min(keeper.gradient, burner.gradient);

        // We breed the lower end average color band when breeding.
        colorBand = Utilities.avg(keeper.colorBand, burner.colorBand);
    }

    /// @dev Make sure this is a valid request to composite/switch with multiple tokens.
    /// @param tokenIds The token IDs to keep.
    /// @param burnIds The token IDs to burn.
    function _multiTokenOperation(uint256[] calldata tokenIds, uint256[] calldata burnIds)
        internal pure returns (uint256 pairs)
    {
        pairs = tokenIds.length;
        if (pairs != burnIds.length) {
            revert InvalidTokenCount();
        }
    }

    /// @dev Make sure this is a valid request to composite/switch a token pair.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _tokenOperation(uint256 tokenId, uint256 burnId)
        internal view returns (
            StoredCheck storage toKeep,
            StoredCheck storage toBurn,
            uint8 divisorIndex
        )
    {
        toKeep = checks.all[tokenId];
        toBurn = checks.all[burnId];
        divisorIndex = toKeep.divisorIndex;

        if (
            ! _isApprovedOrOwner(msg.sender, tokenId) ||
            ! _isApprovedOrOwner(msg.sender, burnId) ||
            divisorIndex != toBurn.divisorIndex ||
            tokenId == burnId ||
            divisorIndex > 5
        ) {
            revert NotAllowed();
        }
    }
}