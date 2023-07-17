// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 Arran Schlosberg (@divergencearran / @divergence_art)
pragma solidity >=0.8.0 <0.9.0;

import "@divergencetech/ethier/contracts/random/PRNG.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract MetaPurse is Ownable {
    using PRNG for PRNG.Source;

    /// @notice The primary GB contract that deployed this one.
    IERC721 public immutable glitchyBitches;

    constructor() {
        glitchyBitches = IERC721(msg.sender);
    }

    /// @notice Requires that the message sender is the primary GB contract.
    modifier onlyGlitchyBitches() {
        require(
            msg.sender == address(glitchyBitches),
            "Only GlitchyBitches contract"
        );
        _;
    }

    /// @notice Total number of versions for each token.
    uint8 private constant NUM_VERSIONS = 6;

    /// @notice Carries per-token metadata.
    struct Token {
        uint8 version;
        uint8 highestRevealed;
        // Changing a token to a different version requires an allowance,
        // increasing by 1 per day. This is calculated as the difference in time
        // since the token's allowance started incrementing, less the amount
        // spent. See allowanceOf().
        uint64 changeAllowanceStartTime;
        int64 spent;
        uint8 glitched;
    }

    /// @notice All token metadata.
    /// @dev Tokens are minted incrementally to correspond to array index.
    Token[] public tokens;

    /// @notice Adds metadata for a new set of tokens.
    function newTokens(uint256 num, bool extraAllowance)
        public
        onlyGlitchyBitches
    {
        int64 initialSpent = extraAllowance ? int64(-30) : int64(0);
        for (uint256 i = 0; i < num; i++) {
            tokens.push(
                Token({
                    version: 0,
                    highestRevealed: 0,
                    changeAllowanceStartTime: uint64(block.timestamp),
                    spent: initialSpent,
                    glitched: 0
                })
            );
        }
    }

    /// @notice Returns tokens[tokenId].version, for use by GB tokenURI().
    function tokenVersion(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (uint8)
    {
        return tokens[tokenId].version;
    }

    /// @notice Tokens that have a higher rate of increasing allowance.
    mapping(uint256 => uint64) private _allowanceRate;

    /// @notice Sets the higher allowance rate for the specified tokens.
    /// @dev These are only set after minting because that stops people from
    /// waiting to mint a specific valuable piece. The off-chain data makes it
    /// clear that they're different, so we can't arbitrarily set these at whim.
    function setHigherAllowanceRates(uint64 rate, uint256[] memory tokenIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _allowanceRate[tokenIds[i]] = rate;
        }
    }

    /// @notice Requires that a token exists.
    function _requireTokenExists(uint256 tokenId) private view {
        require(tokenId < tokens.length, "Token doesn't exist");
    }

    /// @notice Modifier equivalent of _requireTokenExists.
    modifier tokenExists(uint256 tokenId) {
        _requireTokenExists(tokenId);
        _;
    }

    /**
    @notice Requires that the message sender either owns or is approved for the
    token.
     */
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _requireTokenExists(tokenId);
        require(
            glitchyBitches.ownerOf(tokenId) == msg.sender ||
                glitchyBitches.getApproved(tokenId) == msg.sender,
            "Not approved nor owner"
        );
        _;
    }

    /// @notice Returns the version-change allowance of the token.
    function allowanceOf(uint256 tokenId)
        public
        view
        tokenExists(tokenId)
        returns (uint32)
    {
        Token storage token = tokens[tokenId];
        uint64 higherRate = _allowanceRate[tokenId];
        uint64 rate = uint64(higherRate > 0 ? higherRate : 1);
        uint64 allowance = ((uint64(block.timestamp) -
            token.changeAllowanceStartTime) / 86400) * rate;
        return uint32(uint64(int64(allowance) - token.spent));
    }

    /// @notice Reduces the version-change allowance of the token by amount.
    /// @dev Enforces a non-negative allowanceOf().
    /// @param amount The amount by which allowanceOf() will be reduced.
    function _spend(uint256 tokenId, uint32 amount)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        require(allowanceOf(tokenId) >= amount, "Insufficient allowance");
        tokens[tokenId].spent += int64(int32(amount));
    }

    /// @notice Costs for version-changing actions. See allowanceOf().
    uint32 public REVEAL_COST = 30;
    uint32 public CHANGE_COST = 10;

    event VersionRevealed(uint256 indexed tokenId, uint8 version);

    /// @notice Reveals the next version for the token, if one exists, and sets
    /// the token metadata to show this version.
    /// @dev The use of _spend() limits this to owners / approved.
    function revealVersion(uint256 tokenId) external tokenExists(tokenId) {
        Token storage token = tokens[tokenId];
        token.highestRevealed++;
        require(token.highestRevealed < NUM_VERSIONS, "All revealed");
        _spend(tokenId, REVEAL_COST);

        token.version = token.highestRevealed;
        emit VersionRevealed(tokenId, token.highestRevealed);
    }

    event VersionChanged(uint256 indexed tokenId, uint8 version);

    /// @notice Changes to an already-revealed version of the token.
    /// @dev The use of _spend() limits this to owners / approved.
    function changeToVersion(uint256 tokenId, uint8 version)
        external
        tokenExists(tokenId)
    {
        Token storage token = tokens[tokenId];

        // There's a 1-in-8 chance that she glitches. See the comment re
        // randomness in changeToRandomVersion(); TL;DR doesn't need to be
        // secure.
        if (token.highestRevealed == NUM_VERSIONS - 1) {
            bytes32 rand = keccak256(abi.encodePacked(tokenId, block.number));
            if (uint256(rand) & 7 == 0) {
                return _changeToRandomVersion(tokenId, true, version);
            }
        }

        require(version <= token.highestRevealed, "Version not revealed");
        require(version != token.version, "Already on version");
        _spend(tokenId, CHANGE_COST);

        token.version = version;
        token.glitched = 0;
        emit VersionChanged(tokenId, version);
    }

    /// @notice Randomly changes to an already-revealed version of the token.
    /// @dev The use of _spend() limits this to owners / approved.
    function changeToRandomVersion(uint256 tokenId)
        external
        tokenExists(tokenId)
    {
        _changeToRandomVersion(tokenId, false, 255);
    }

    /// @notice Randomly changes to an already-revealed version of the token.
    /// @dev The use of _spend() limits this to owners / approved.
    /// @param glitched Whether this function was called due to a "glitch".
    /// @param wanted The version number actually requested; used to avoid
    /// glitching to the same value.
    function _changeToRandomVersion(
        uint256 tokenId,
        bool glitched,
        uint8 wanted
    ) internal {
        Token storage token = tokens[tokenId];
        require(token.highestRevealed > 0, "Insufficient reveals");
        _spend(tokenId, CHANGE_COST);

        // This function only requires randomness for "fun" to allow collectors
        // to change to an unexpected version. We don't need to protect against
        // bad actors, so it's safe to assume that a specific token won't be
        // changed more than once per block.
        PRNG.Source src = PRNG.newSource(
            keccak256(abi.encodePacked(tokenId, block.number))
        );

        uint256 version;
        for (
            version = NUM_VERSIONS; // guarantee at least one read from src
            version >= NUM_VERSIONS || // unbiased
                version == token.version ||
                version == wanted;
            version = src.read(3)
        ) {}
        token.version = uint8(version);
        token.glitched = glitched ? 1 : 0;
        emit VersionChanged(tokenId, uint8(version));
    }

    /// @notice Donate version-changing allowance to a different token.
    /// @dev The use of _spend() limits this to owners / approved of fromId.
    function donate(
        uint256 fromId,
        uint256 toId,
        uint32 amount
    ) external tokenExists(fromId) tokenExists(toId) {
        _spend(fromId, amount);
        tokens[toId].spent -= int64(int32(amount));
    }

    /// @notice Input parameter for increaseAllowance(), coupling a tokenId with
    /// the amount of version-changing allowance it will receive.
    struct Allocation {
        uint256 tokenId;
        uint32 amount;
    }

    /// @notice Allocate version-changing allowance to a set of tokens.
    function increaseAllowance(Allocation[] memory allocs) external onlyOwner {
        for (uint256 i = 0; i < allocs.length; i++) {
            _requireTokenExists(allocs[i].tokenId);
            tokens[allocs[i].tokenId].spent -= int64(int32(allocs[i].amount));
        }
    }
}