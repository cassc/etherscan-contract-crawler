// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../library/NftTransferLibrary.sol";

interface ILiqdRentalWallet {
    function initialize(
        address _owner,
        address _collection,
        uint256 _tokenId,
        NftTransferLibrary.NftTokenType _nftTokenType,
        uint256 _rentalId
    ) external;

    function withdrawNft() external;
}