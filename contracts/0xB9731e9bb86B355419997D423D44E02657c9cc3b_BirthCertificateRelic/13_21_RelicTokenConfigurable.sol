/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IERC5192.sol";
import "./interfaces/ITokenURI.sol";
import "./RelicToken.sol";

/**
 * @title RelicTokenConfigurable
 * @author Theori, Inc.
 * @notice RelicTokenConfigurable augments the RelicToken contract to allow
 *         for configurable tokenURIs.
 */
abstract contract RelicTokenConfigurable is RelicToken {
    mapping(uint64 => ITokenURI[]) TokenURIProviders;

    function addURIProvider(address provider, uint64 bulkId) external onlyOwner {
        TokenURIProviders[bulkId].push(ITokenURI(provider));
    }

    function getLatestProviderIdx(uint64 bulkId) internal view returns (uint256) {
        uint256 length = TokenURIProviders[bulkId].length;
        if (length == 0) {
            return 0;
        }
        return length - 1;
    }

    /**
     * @notice Helper function to break a tokenId into its constituent data
     * @return who the address bound to this token
     * @return data any additional data bound to this token
     * @return idx the index of the URI provider for this token
     * @return bulkId the generic "class" of this Relic
     *         (eg: eventId for AttendanceArtifacts)
     */
    function parseTokenIdData(uint256 tokenId)
        internal
        pure
        returns (
            address who,
            uint96 data,
            uint32 idx,
            uint64 bulkId
        )
    {
        (who, data) = parseTokenId(tokenId);
        idx = uint32(data >> 64);
        bulkId = uint64(data);
    }

    /// @inheritdoc RelicToken
    function mint(address who, uint96 data) public override {
        require(uint32(data >> 64) == 0, "high data bits in use");
        uint64 bulkId = uint64(data);
        uint32 providerIdx = uint32(getLatestProviderIdx(bulkId));
        uint96 newData = uint96(bulkId) | (uint96(providerIdx) << 64);

        return super.mint(who, newData);
    }

    /// @inheritdoc RelicToken
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        (address who, uint96 data, uint32 providerIdx, uint64 bulkId) = parseTokenIdData(tokenId);

        require(hasToken(who, data), "token does not exist");
        require(providerIdx < TokenURIProviders[bulkId].length, "uri provider not set");

        return TokenURIProviders[bulkId][providerIdx].tokenURI(tokenId);
    }

    /**
     * @notice request a token be replaced with another representing the same
     *         data, but with a different URI provider.
     * @param tokenId the existing token to recycle
     * @param newProviderIdx the new URI provider to use
     * @dev emits Unlock and Transfer to 0 for the existing tokenId, and then
     *      Transfer and Lock for the new tokenId.
     * @dev Due to not using storage, this function will not revert so long as
     *      the msg.sender is entitled to the tokenId they originally provide,
     *      even if that tokenId has never been issued. Misuse may cause confusion
     *      for tools attempting to track ERC-721 transfers.
     */
    function exchange(uint256 tokenId, uint32 newProviderIdx) external {
        (address who, uint96 data, , uint64 bulkId) = parseTokenIdData(tokenId);

        require(who == msg.sender, "only token owner may exchange");
        require(hasToken(who, data), "token does not exist");
        require(newProviderIdx < TokenURIProviders[bulkId].length, "invalid URI provider");

        uint256 newTokenId = (uint256(uint160(who)) |
            (uint256(bulkId) << 160) |
            (uint256(newProviderIdx) << 224));

        emit Unlocked(tokenId);
        emit Transfer(who, address(0), tokenId);
        emit Transfer(address(0), who, newTokenId);
        emit Locked(newTokenId);
    }
}