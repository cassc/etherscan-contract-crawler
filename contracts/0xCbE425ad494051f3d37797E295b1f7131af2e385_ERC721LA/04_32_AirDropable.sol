// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../libraries/CustomErrors.sol";
import "../libraries/BPS.sol";
import "../libraries/CustomErrors.sol";
import "../libraries/LANFTUtils.sol";
import "../tokens/ERC721State.sol";
import "../tokens/ERC721LACore.sol";
import "./IAirDropable.sol";
import "../platform/royalties/RoyaltiesState.sol";

abstract contract AirDropable is IAirDropable, ERC721LACore {
    uint256 public constant AIRDROP_MAX_BATCH_SIZE = 100;

    function airdrop(
        uint256 editionId,
        address[] calldata recipients,
        uint24 quantityPerAddress
    ) external onlyAdmin {
        if (recipients.length > AIRDROP_MAX_BATCH_SIZE) {
            revert TooManyAddresses();
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(editionId, quantityPerAddress, recipients[i]);
        }
    }
}