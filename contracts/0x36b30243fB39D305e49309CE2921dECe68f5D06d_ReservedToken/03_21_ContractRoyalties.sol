// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ContractRoyalties {
    function _getBps() internal view virtual returns (uint256);

    function _getReceiver() internal view virtual returns (address payable);

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
        receivers[0] = _getReceiver();
        bps[0] = _getBps();
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
        receivers[0] = _getReceiver();
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
        bps[0] = _getBps();
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
        return _getRoyaltyInfo(value);
    }

    function _getRoyaltyInfo(uint256 value)
        internal
        view
        returns (address receiver, uint256 amount)
    {
        address _receiver = _getReceiver();
        uint256 _bps = _getBps();
        return (_receiver, (_bps * value) / 10000);
    }

    function _supportsRoyaltyInterfaces(bytes4 interfaceId)
        internal
        pure
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }
}