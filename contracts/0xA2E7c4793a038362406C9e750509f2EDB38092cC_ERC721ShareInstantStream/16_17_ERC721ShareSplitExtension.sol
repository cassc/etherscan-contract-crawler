// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenStream.sol";

interface IERC721ShareSplitExtension {
    function hasERC721ShareSplitExtension() external view returns (bool);

    function setSharesForTokens(
        uint256[] memory _tokenIds,
        uint256[] memory _shares
    ) external;

    function getSharesByTokens(uint256[] calldata _tokenIds)
        external
        view
        returns (uint256[] memory);
}

abstract contract ERC721ShareSplitExtension is
    IERC721ShareSplitExtension,
    Initializable,
    ERC165Storage,
    Ownable,
    ERC721MultiTokenStream
{
    event SharesUpdated(uint256 tokenId, uint256 prevShares, uint256 newShares);

    // Sum of all the share units ever configured
    uint256 public totalShares;

    // Map of ticket token ID -> share of the stream
    mapping(uint256 => uint256) public shares;

    /* INTERNAL */

    function __ERC721ShareSplitExtension_init(
        uint256[] memory _tokenIds,
        uint256[] memory _shares
    ) internal onlyInitializing {
        __ERC721ShareSplitExtension_init_unchained(_tokenIds, _shares);
    }

    function __ERC721ShareSplitExtension_init_unchained(
        uint256[] memory _tokenIds,
        uint256[] memory _shares
    ) internal onlyInitializing {
        require(_shares.length == _tokenIds.length, "STREAM/ARGS_MISMATCH");
        _updateShares(_tokenIds, _shares);

        _registerInterface(type(IERC721ShareSplitExtension).interfaceId);
    }

    function setSharesForTokens(
        uint256[] memory _tokenIds,
        uint256[] memory _shares
    ) public onlyOwner {
        require(_shares.length == _tokenIds.length, "STREAM/ARGS_MISMATCH");
        require(lockedUntilTimestamp < block.timestamp, "STREAM/CONFIG_LOCKED");

        _updateShares(_tokenIds, _shares);
    }

    /* PUBLIC */

    function hasERC721ShareSplitExtension() external pure returns (bool) {
        return true;
    }

    function getSharesByTokens(uint256[] calldata _tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _shares = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _shares.length; i++) {
            _shares[i] = shares[_tokenIds[i]];
        }

        return _shares;
    }

    function _totalTokenReleasedAmount(
        uint256 totalReleasedAmount_,
        uint256 ticketTokenId_,
        address claimToken_
    ) internal view override returns (uint256) {
        claimToken_;

        return (totalReleasedAmount_ * shares[ticketTokenId_]) / totalShares;
    }

    /* INTERNAL */

    function _updateShares(uint256[] memory _tokenIds, uint256[] memory _shares)
        private
    {
        for (uint256 i = 0; i < _shares.length; i++) {
            _updateShares(_tokenIds[i], _shares[i]);
        }
    }

    function _updateShares(uint256 tokenId, uint256 newShares) private {
        uint256 prevShares = shares[tokenId];

        shares[tokenId] = newShares;
        totalShares = totalShares + newShares - prevShares;

        require(totalShares >= 0, "STREAM/NEGATIVE_SHARES");

        emit SharesUpdated(tokenId, prevShares, newShares);
    }
}