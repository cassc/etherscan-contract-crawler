// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract Royalties {
    mapping(uint256 => address payable) internal _tokenRoyaltyReceiver;
    mapping(uint256 => uint256) internal _tokenRoyaltyBPS;

    function _existsRoyalties(uint256 tokenId)
        internal
        view
        virtual
        returns (bool);

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

    function _setRoyalties(
        uint256 tokenId,
        address payable receiver,
        uint256 basisPoints
    ) internal {
        require(basisPoints > 0);
        _tokenRoyaltyReceiver[tokenId] = receiver;
        _tokenRoyaltyBPS[tokenId] = basisPoints;
    }

    /**
     * @dev 3rd party Marketplace Royalty Support
     */

    /**
     * @dev IFoundation
     */
    function getFees(uint256 tokenId)
        external
        view
        virtual
        returns (address payable[] memory, uint256[] memory)
    {
        require(_existsRoyalties(tokenId), "Nonexistent token");

        address payable[] memory receivers = new address payable[](1);
        uint256[] memory bps = new uint256[](1);
        receivers[0] = _getReceiver(tokenId);
        bps[0] = _getBps(tokenId);
        return (receivers, bps);
    }

    /**
     * @dev IRaribleV1
     */
    function getFeeRecipients(uint256 tokenId)
        external
        view
        virtual
        returns (address payable[] memory)
    {
        require(_existsRoyalties(tokenId), "Nonexistent token");

        address payable[] memory receivers = new address payable[](1);
        receivers[0] = _getReceiver(tokenId);
        return receivers;
    }

    function getFeeBps(uint256 tokenId)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        require(_existsRoyalties(tokenId), "Nonexistent token");

        uint256[] memory bps = new uint256[](1);
        bps[0] = _getBps(tokenId);
        return bps;
    }

    /**
     * @dev EIP-2981
     * Returns primary receiver i.e. receivers[0]
     */
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        virtual
        returns (address, uint256)
    {
        require(_existsRoyalties(tokenId), "Nonexistent token");
        return _getRoyaltyInfo(tokenId, value);
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value)
        internal
        view
        returns (address receiver, uint256 amount)
    {
        address _receiver = _getReceiver(tokenId);
        return (_receiver, (_tokenRoyaltyBPS[tokenId] * value) / 10000);
    }

    function _getBps(uint256 tokenId) internal view returns (uint256) {
        return _tokenRoyaltyBPS[tokenId];
    }

    function _getReceiver(uint256 tokenId)
        internal
        view
        returns (address payable)
    {
        uint256 bps = _getBps(tokenId);
        address payable receiver = _tokenRoyaltyReceiver[tokenId];
        if (bps == 0 || receiver == address(0)) {
            /**
             * @dev: If bps is 0 the receiver was never set
             * Fall back to this contract so badly behaved
             * marketplaces have somewhere to send money to
             */
            return (_getRoyaltyFallback());
        }

        return receiver;
    }

    function _getRoyaltyFallback()
        internal
        view
        virtual
        returns (address payable);

    function _supportsRoyaltyInterfaces(bytes4 interfaceId)
        public
        pure
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }
}