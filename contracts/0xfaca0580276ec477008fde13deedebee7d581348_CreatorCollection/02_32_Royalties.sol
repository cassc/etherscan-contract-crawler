// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract Royalties {
    event RoyaltiesUpdated(
        uint256 indexed tokenId,
        address payable[] receivers,
        uint256[] basisPoints
    );

    event DefaultRoyaltiesUpdated(
        address payable[] receivers,
        uint256[] basisPoints
    );

    struct RoyaltyConfig {
        address payable receiver;
        uint16 bps;
    }

    mapping(uint256 => RoyaltyConfig[]) private _tokenRoyalties;
    RoyaltyConfig[] private _defaultRoyalties;

    function _existsRoyalties(
        uint256 tokenId
    ) internal view virtual returns (bool);

    /**
     *  @dev CreatorCore
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    function _setTokenRoyaltiesOnMint(
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) internal {
        _checkRoyalties(receivers, basisPoints);
        // No delete necessary because the token will not have existed before this point
        _setRoyalties(receivers, basisPoints, _tokenRoyalties[tokenId]);
    }

    function _setTokenRoyaltiesAfterMint(
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) internal {
        _checkRoyalties(receivers, basisPoints);
        delete _tokenRoyalties[tokenId];
        _setRoyalties(receivers, basisPoints, _tokenRoyalties[tokenId]);

        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    function _setDefaultRoyalties(
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) internal {
        _checkRoyalties(receivers, basisPoints);
        delete _defaultRoyalties;
        _setRoyalties(receivers, basisPoints, _defaultRoyalties);

        emit DefaultRoyaltiesUpdated(receivers, basisPoints);
    }

    function _checkRoyalties(
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) private pure {
        require(
            receivers.length == basisPoints.length,
            "Mismatch in array lengths"
        );
        uint256 totalBasisPoints;
        for (uint256 i; i < basisPoints.length; ) {
            totalBasisPoints += basisPoints[i];
            unchecked {
                ++i;
            }
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
    }

    function _setRoyalties(
        address payable[] calldata receivers,
        uint256[] calldata basisPoints,
        RoyaltyConfig[] storage royalties
    ) private {
        for (uint256 i; i < basisPoints.length; ) {
            royalties.push(
                RoyaltyConfig({
                    receiver: receivers[i],
                    bps: uint16(basisPoints[i])
                })
            );
            unchecked {
                ++i;
            }
        }
    }

    function _getRoyalties(
        uint256 tokenId
    )
        private
        view
        returns (address payable[] memory receivers, uint256[] memory bps)
    {
        // Get token level royalties
        RoyaltyConfig[] memory royalties = _tokenRoyalties[tokenId];

        if (royalties.length == 0) {
            // Get the default royalty
            royalties = _defaultRoyalties;
        }

        if (royalties.length > 0) {
            receivers = new address payable[](royalties.length);
            bps = new uint256[](royalties.length);
            for (uint i; i < royalties.length; ) {
                receivers[i] = royalties[i].receiver;
                bps[i] = royalties[i].bps;
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * Manifold CreatorCore
     */
    function getRoyalties(
        uint256 tokenId
    )
        external
        view
        virtual
        returns (address payable[] memory, uint256[] memory)
    {
        require(_existsRoyalties(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev IFoundation
     */
    function getFees(
        uint256 tokenId
    )
        external
        view
        virtual
        returns (address payable[] memory, uint256[] memory)
    {
        require(_existsRoyalties(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev IRaribleV1
     */
    function getFeeRecipients(
        uint256 tokenId
    ) external view virtual returns (address payable[] memory) {
        require(_existsRoyalties(tokenId), "Nonexistent token");

        address payable[] memory receivers;
        uint256[] memory bps;
        (receivers, bps) = _getRoyalties(tokenId);
        return receivers;
    }

    function getFeeBps(
        uint256 tokenId
    ) external view virtual returns (uint256[] memory) {
        require(_existsRoyalties(tokenId), "Nonexistent token");

        address payable[] memory receivers;
        uint256[] memory bps;
        (receivers, bps) = _getRoyalties(tokenId);
        return bps;
    }

    /**
     * @dev EIP-2981
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 value
    ) external view virtual returns (address, uint256) {
        require(_existsRoyalties(tokenId), "Nonexistent token");

        address payable[] memory receivers;
        uint256[] memory bps;

        (receivers, bps) = _getRoyalties(tokenId);

        require(receivers.length <= 1, "More than 1 royalties found");

        if (receivers.length == 0) {
            return (address(0x0), 0);
        }

        return (receivers[0], (bps[0] * value) / 10000);
    }

    function _supportsRoyaltyInterfaces(
        bytes4 interfaceId
    ) internal pure returns (bool) {
        return
            interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }
}