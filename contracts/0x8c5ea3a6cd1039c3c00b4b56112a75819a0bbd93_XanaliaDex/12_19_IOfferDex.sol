// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IOfferDex {
	function makeOffer(
		address _collectionAddress,
		address _paymentToken,
		address _offerOwner,
		uint256 _tokenId,
		uint256 _price,
		uint256 _expireTime
	) external returns (uint256 _offerId);

	function acceptOffer(uint256 _offerId)
		external
		returns (
			address,
			address,
			address,
			uint256,
			uint256
		);

	function cancelOffer(uint256 _offerId, address _offerOwner) external returns (address, uint256);
}