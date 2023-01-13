// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IGetRoyalties.sol";

/**
 * @title A contract for fees which a marketplace can implement
 * @dev see { EIP-2981: NFT Royalty Standard }
 * @notice this implementation of has a lot of in common with the royalty standard
 * @notice type(GetRoyalties).interfaceId = 0x0c423a52
 */
abstract contract GetRoyalties is IGetRoyalties {
    event SecondarySaleFees(
        uint256 tokenId,
        address[] recipients,
        uint256[] bps
    );

    struct Fee {
        address payable recipient;
        uint16 value;
    }

    // tokenId => fees
    mapping(uint256 => Fee[]) private fees;

    /**
     * @notice returns fee recipients for a token id
     * @param _id token id
     */

    function getFeeRecipients(uint256 _id)
        external
        view
        override
        returns (address payable[] memory)
    {
        Fee[] memory _fees = fees[_id];
        address payable[] memory result = new address payable[](_fees.length);
        for (uint256 i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].recipient;
        }
        return result;
    }

    /**
     * @notice returns an array of fees for a token id
     * @param _id token id
     */
    function getFeeBps(uint256 _id)
        external
        view
        override
        returns (uint16[] memory)
    {
        Fee[] memory _fees = fees[_id];
        uint16[] memory result = new uint16[](_fees.length);
        for (uint256 i = 0; i < _fees.length; i++) {
            result[i] = _fees[i].value;
        }
        return result;
    }

    /**
     * @notice returns royalties array: an address and corresponding fee
     * @param _id token id
     */
    function getRoyalties(uint256 _id)
        external
        view
        returns (address payable[] memory, uint256[] memory)
    {
        Fee[] memory _fees = fees[_id];
        address payable[] memory recipients = new address payable[](
            _fees.length
        );
        uint256[] memory feesInBasisPoints = new uint256[](_fees.length);

        for (uint256 i = 0; i < _fees.length; i++) {
            recipients[i] = _fees[i].recipient;
            feesInBasisPoints[i] = _fees[i].value;
        }

        return (recipients, feesInBasisPoints);
    }

    /// @dev sets fee, only used internally
    function setFees(uint256 _tokenId, Fee[] memory _fees) internal {
        address[] memory recipients = new address[](_fees.length);
        uint256[] memory bps = new uint256[](_fees.length);

        unchecked {
            for (uint256 i = 0; i < _fees.length; i++) {
                require(
                    _fees[i].recipient != address(0x0),
                    "Recipient should be present"
                );
                require(_fees[i].value != 0, "Fee value should be positive");

                fees[_tokenId].push(_fees[i]);
                recipients[i] = _fees[i].recipient;
                bps[i] = _fees[i].value;
            }
            if (_fees.length > 0) {
                emit SecondarySaleFees(_tokenId, recipients, bps);
            }
        }
    }

    /**
     * @notice check for interface support
     * @dev Implementation of the {IERC165} interface.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IGetRoyalties).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}