// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@divergencetech/ethier/contracts/erc721/ERC721Common.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/thirdparty/opensea/OpenSeaERC721Mintable.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";

contract ReactorMotors is OpenSeaERC721Mintable, BaseTokenURI, ERC721Common {
    using Monotonic for Monotonic.Increaser;
    using Monotonic for Monotonic.Decreaser;

    /// @notice Maximum number of tokens to be minted.
    uint256 public immutable MAX_TOKENS;

    constructor(
        uint256 maxTokens,
        string memory baseTokenURI,
        string memory baseOptionURI
    )
        ERC721Common("Reactor Motors", "REACTOR")
        OpenSeaERC721Mintable(
            "Reactor Motors Sale",
            "REACTORSALE",
            1,
            baseOptionURI
        )
        BaseTokenURI(baseTokenURI)
    {
        MAX_TOKENS = maxTokens;
    }

    /// @notice Tracks the number of tokens minted.
    Monotonic.Increaser private _totalSupply;

    /// @notice Required override for OpenSea-enabled minting.
    function factoryCanMint(uint256 optionId)
        public
        view
        override
        returns (bool)
    {
        return
            !paused() && optionId == 0 && _totalSupply.current() < MAX_TOKENS;
    }

    /// @notice Mint a new token when invoked by OpenSea minting mechanism.
    function _factoryMint(uint256 optionId, address to) internal override {
        require(optionId == 0, "Invalid option");
        uint256 curr = _totalSupply.current();
        require(curr < MAX_TOKENS, "Sold out");

        ERC721._safeMint(to, curr + 1);
        _totalSupply.add(1);
    }

    /// @notice Remaining quota available for mint by contract owner.
    Monotonic.Decreaser public ownerQuota = Monotonic.Decreaser(130);

    /// @notice Direct minting as the contract owner.
    function ownerMint(address to, uint256 n) external onlyOwner {
        require(n <= ownerQuota.current(), "Owner quota exceeded");

        uint256 curr = _totalSupply.current();
        uint256 last = curr + n;
        require(last < MAX_TOKENS, "Too many tokens");

        // Token IDs are 1-indexed.
        for (curr++; curr <= last; curr++) {
            ERC721._safeMint(to, curr);
        }
        _totalSupply.add(n);
        ownerQuota.subtract(n);
    }

    /// @notice Return the total number of tokens minted.
    function totalSupply() external view returns (uint256) {
        return _totalSupply.current();
    }

    /// @notice Public commitment to unrevealed metadata for all tokens.
    bytes32 public constant ALL_TOKEN_METADATA_KECCAK256 =
        0xb6eb383acd39b0a2f3b10b0c4cf1615ed8a5d2886f92a975f8d9b8db6e78c97d;

    /**
    @notice Override ERC721's base URI to use BaseTokenURI contract's mechanism.
    tokenURI() will return concatenation of _baseURI() and token ID.
     */
    function _baseURI()
        internal
        view
        override(ERC721, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }
}