// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IMarketplace.sol';

contract Marketplace is IMarketplace, Ownable {
	mapping(address => bool) public isAdvisor;
	mapping(bytes32 => Offer) public offerData;
	uint256 private _feeAmount;
	uint256 private _decimal;

	event OfferSent(bytes32 _offerId);
	event OfferCanceled(bytes32 _offerId);
	event OfferAchieved(bytes32 _offerId);

	modifier onlyAdvisor(address _addr) {
		require(isAdvisor[_addr], 'The caller must be the Advisor.');
		_;
	}

	modifier onlyContractor(bytes32 _offerId, address _addr) {
		require(
			offerData[_offerId].seller == _addr || offerData[_offerId].buyer == _addr,
			'The caller must be the seller/buyer.'
		);
		_;
	}

	constructor() {
		_feeAmount = 25;
		_decimal = 1;
	}

	function addAdvisor(address _newAdvisor) public onlyOwner {
		isAdvisor[_newAdvisor] = true;
	}

	function deleteAdvisor(address _advisor) public onlyOwner {
		isAdvisor[_advisor] = false;
	}

	function sendOffer(
		address _seller,
		address _buyer,
		address _collection, // land_contract_address
		uint256 _assetId, // land_token_id
		address _token, // token_contract_address
		uint256 _price // token_amount
	) public onlyAdvisor(msg.sender) {
		require(
			IERC20(_token).balanceOf(_buyer) >= _price,
			"The Bidder's balance must be greater than Bid Price."
		);
		require(
			IERC721(_collection).ownerOf(_assetId) == _seller,
			'The Seller must be owner of the NFT.'
		);

		bytes32 _generatedId = keccak256(abi.encodePacked(block.difficulty, block.timestamp));
		offerData[_generatedId] = Offer(
			_seller,
			_buyer,
			_collection,
			_assetId,
			_token,
			_price,
			0, // waiting for the buyer to accept/decline the offer
			0, // waiting for the seller to accept/decline the offer
			0
		);

		emit OfferSent(_generatedId);
	}

	function acceptOffer(bytes32 _offerId) public onlyContractor(_offerId, msg.sender) {
		Offer memory _offer = offerData[_offerId];

		// require(!_offer.canceled, 'The offer already canceled.');
		require(offerData[_offerId].status != 2, 'The offer already canceled.');
		require(offerData[_offerId].status != 3, "");
		require(offerData[_offerId].status == 0, "");
		if(msg.sender == offerData[_offerId].buyer) {
			require(offerData[_offerId].buyerAcceptStatus != 1,"Buyer already accepted");
		} else if(msg.sender == offerData[_offerId].seller) {
			require(offerData[_offerId].sellerAcceptStatus != 1,"Seller already accepted");
		}
		require(
			IERC20(_offer.token).balanceOf(_offer.buyer) >= _offer.price,
			"The buyer's balance must be greater than Bid Price."
		);
		require(
			IERC721(_offer.collection).ownerOf(_offer.assetId) == _offer.seller,
			'The seller must be owner of the NFT.'
		);

		if (msg.sender == _offer.seller) {
			offerData[_offerId].sellerAcceptStatus = 1;
		} else {
			offerData[_offerId].buyerAcceptStatus = 1;
		}

		if (
			offerData[_offerId].status != 1 &&
			offerData[_offerId].buyerAcceptStatus == 1 &&
			offerData[_offerId].sellerAcceptStatus == 1
		) {
			uint256 _factor = 10**_decimal;
			uint256 _fee = (_offer.price * _feeAmount) / (100 * _factor);
			uint256 _realPrice = _offer.price - _fee;

			address _admin = owner();

			IERC721(_offer.collection).transferFrom(_offer.seller, _offer.buyer, _offer.assetId);
			SafeERC20.safeTransferFrom(IERC20(_offer.token), _offer.buyer, _offer.seller, _realPrice);
			SafeERC20.safeTransferFrom(IERC20(_offer.token), _offer.buyer, _admin, _fee);

			emit OfferAchieved(_offerId);

			offerData[_offerId].status = 1; //offer is finished
		}
	}

	function cancelOffer(bytes32 _offerId) public onlyAdvisor(msg.sender) {
		require(offerData[_offerId].status != 2, 'The offer already canceled.');
		require(offerData[_offerId].status == 0,"");
		require(offerData[_offerId].buyerAcceptStatus == 0, "");
		require(offerData[_offerId].sellerAcceptStatus == 0, "");

		emit OfferCanceled(_offerId);

		offerData[_offerId].status = 2;
	}

	function declineOffer(bytes32 _offerId) public onlyContractor(_offerId, msg.sender) {
		require(offerData[_offerId].status != 2, 'The offer already canceled.');
		require(offerData[_offerId].status != 3,"");
		require(offerData[_offerId].status == 0,"");
		if(msg.sender == offerData[_offerId].buyer) {
			require(offerData[_offerId].buyerAcceptStatus != 1,"Buyer already accepted");
		} else if(msg.sender == offerData[_offerId].seller) {
			require(offerData[_offerId].sellerAcceptStatus != 1,"Seller already accepted");
		}

		if(offerData[_offerId].seller == msg.sender ) {
			offerData[_offerId].sellerAcceptStatus = 2;
		} else {
			offerData[_offerId].buyerAcceptStatus = 2;
		}
		offerData[_offerId].status = 3;
	}
}