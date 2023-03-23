// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/// @title LibERC721
/// @notice Stores payment tokens and fees for each ERC-721
library LibERC721 {
    bytes32 constant ERC721_STORAGE_POSITION =
        keccak256("erc721.storage.position");

    struct Storage {
        // ERC-721 contract to Payment Token
        mapping(address => address) payments;
        // Stores all fees for wrapped tokens
        mapping(address => uint256) fees;
    }

    function erc721Storage() internal pure returns (Storage storage s) {
        bytes32 position = ERC721_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    function setERC721PaymentFee(
        address _erc721,
        address _payment,
        uint256 _fee
    ) internal {
        Storage storage s = erc721Storage();

        s.payments[_erc721] = _payment;
        s.fees[_erc721] = _fee;
    }

    function erc721Payment(address _erc721) internal view returns (address) {
        return erc721Storage().payments[_erc721];
    }

    function erc721Fee(address _erc721) internal view returns (uint256) {
        return erc721Storage().fees[_erc721];
    }
}