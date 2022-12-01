// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./Auth.sol";

interface ISTDNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function creatorOf(uint256 _tokenId) external view returns (address);
    function royalty() external view returns (uint256);
    function royalties(uint256 _tokenId) external view returns (uint256);
    function collectionOwner() external view returns (address);
}

interface IAderloNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

contract AderloMarket is Auth, ERC721Holder {
    using SafeMath for uint256;
    using Address for address;

    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 public swapFee = 25;  // 2.5% for admin tx fee
    address public swapFeeAddress;

    /* Pairs to market NFT _id => price */
    struct Pair {
        uint256 pair_id;
        address collection;
        uint256 token_id;
        address creator;
        address owner;
        uint256 price;
        bool bValid;
    }
    uint256 public currentID;
    // token id => Pair mapping
    mapping(uint256 => Pair) public pairs;

    uint256 public referral_fee = 50;  // unit=1000, (5% = 50)
    struct Referral {
        bool referred;
        address referred_by;
    }
    mapping(address => Referral) public referrals;

    event ItemListed(Pair pair);
	event ItemDelisted(uint256 id);
    event Swapped(address buyer, Pair pair);

    constructor () Auth(msg.sender) { swapFeeAddress = msg.sender; }

    function setFee(uint256 _swapFee, address _swapFeeAddress) external authorized {
        swapFee = _swapFee;
        swapFeeAddress = _swapFeeAddress;
    }

    function list(
        address _collection, 
        uint256 _token_id, 
        uint256 _price
    ) OnlyItemOwner(_collection, _token_id) external {
        require(_price > 0, "Invalid price");
        ISTDNFT nft = ISTDNFT(_collection);
        nft.safeTransferFrom(msg.sender, address(this), _token_id);
        // Create new pair item
        currentID = currentID.add(1);
        Pair memory item;
        item.pair_id = currentID;
        item.collection = _collection;
        item.token_id = _token_id;
        item.creator = getNFTCreator(_collection, _token_id);
        item.owner = msg.sender;
        item.price = _price;
        item.bValid = true;
        pairs[currentID] = item;
        emit ItemListed(item);
    }

    function delist(uint256 _id) external {
        require(pairs[_id].bValid && msg.sender == pairs[_id].owner, "Unauthorized owner");
        ISTDNFT(pairs[_id].collection).safeTransferFrom(address(this), msg.sender, pairs[_id].token_id);
        pairs[_id].bValid = false;
        pairs[_id].price = 0;
        emit ItemDelisted(_id);
    }

    function buy(uint256 _id, address _ref_address) external payable {
        Pair storage pair = pairs[_id];
        require(_id <= currentID && pair.bValid, "Invalid Pair Id");
        require(pair.owner != msg.sender, "Owner can not buy");
        if (referrals[msg.sender].referred == false && _ref_address != msg.sender && _ref_address != address(0)) {
            referrals[msg.sender].referred_by = _ref_address;
            referrals[msg.sender].referred = true;
        }
        
        uint256 totalAmount = pair.price;
        require(msg.value >= totalAmount, "insufficient balance");

        uint256 nftRoyalty = getRoyalty(pair.collection);
        address collection_owner = getCollectionOwner(pair.collection);
        uint256 nftRoyalties = getRoyalties(pair.collection, pair.token_id);
        address itemCreator = getNFTCreator(pair.collection, pair.token_id);
        
        uint256 feeAmount = totalAmount.mul(swapFee).div(PERCENTS_DIVIDER);
        uint256 royaltyAmount = totalAmount.mul(nftRoyalty).div(PERCENTS_DIVIDER);
        uint256 royaltiesAmount = totalAmount.mul(nftRoyalties).div(PERCENTS_DIVIDER);
        uint256 sellerAmount = totalAmount.sub(feeAmount).sub(royaltyAmount).sub(royaltiesAmount);
        uint256 referralAmount = 0;
        if (referrals[msg.sender].referred) {
            referralAmount = totalAmount.mul(referral_fee).div(PERCENTS_DIVIDER);
            sellerAmount = sellerAmount.sub(referralAmount);
        }
        if(swapFee > 0) {
            (bool fs, ) = payable(swapFeeAddress).call{value: feeAmount}("");
            require(fs, "Failed to send fee to fee address");
        }
        if(nftRoyalty > 0 && collection_owner != address(0x0)) {
            (bool hs, ) = payable(collection_owner).call{value: royaltyAmount}("");
            require(hs, "Failed to send collection royalty to collection owner");
        }
        if(nftRoyalties > 0 && itemCreator != address(0x0)) {
            (bool ps, ) = payable(itemCreator).call{value: royaltiesAmount}("");
            require(ps, "Failed to send item royalties to item creator");
        }
        (bool os, ) = payable(pair.owner).call{value: sellerAmount}("");
        require(os, "Failed to send to item owner"); 
        if (referralAmount > 0) {
            (bool rs, ) = payable(referrals[msg.sender].referred_by).call{value: referralAmount}("");
            require(rs, "Failed to send referral fee to referral user");
        }
        // transfer NFT token to buyer
        ISTDNFT(pair.collection).safeTransferFrom(address(this), msg.sender, pair.token_id);
        pair.bValid = false;

        emit Swapped(msg.sender, pair);
    }

    function getRoyalty(address collection) view internal returns(uint256) {
        ISTDNFT nft = ISTDNFT(collection);
        try nft.royalty() returns (uint256 value) {
            return value;
        } catch {
            IAderloNFT aderloNFT = IAderloNFT(collection);
            try aderloNFT.royaltyInfo(1, 1000) returns (address, uint256 _salePrice) {
                return _salePrice;
            } catch {
                return 0;
            }
        }
    }

    function getRoyalties(address collection, uint256 tokenId) view internal returns(uint256) {
        ISTDNFT nft = ISTDNFT(collection);
        try nft.royalties(tokenId) returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }

    function getNFTCreator(address collection, uint256 tokenId) view internal returns(address) {
        ISTDNFT nft = ISTDNFT(collection); 
        try nft.creatorOf(tokenId) returns (address creatorAddress) {
            return creatorAddress;
        } catch {
            return address(0x0);
        }
    }

    function getCollectionOwner(address collection) view internal returns(address) {
        ISTDNFT nft = ISTDNFT(collection); 
        try nft.collectionOwner() returns (address collection_owner) {
            return collection_owner;
        } catch {
            IAderloNFT aderloNFT = IAderloNFT(collection);
            try aderloNFT.royaltyInfo(1, 1000) returns (address _receiver, uint256) {
                return _receiver;
            } catch {
                return address(0x0);
            }
        }
    }

    modifier OnlyItemOwner(address _collection, uint256 _tokenId) {
        ISTDNFT collectionContract = ISTDNFT(_collection);
        require(collectionContract.ownerOf(_tokenId) == msg.sender);
        _;
    }

    function setReferralFee(uint256 _ref_fee) external authorized {
        require(_ref_fee < 100, "Fee should not greater than product cost!");
        referral_fee = _ref_fee;
    }
}