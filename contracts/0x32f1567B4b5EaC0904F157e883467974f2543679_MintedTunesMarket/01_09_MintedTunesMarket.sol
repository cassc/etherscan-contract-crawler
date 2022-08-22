// MintedTunes Market contract
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintedTunesNFT {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);
    function creatorOf(uint256 _tokenId) external view returns (address);
	function royalties(uint256 _tokenId) external view returns (uint256);
}

contract MintedTunesMarket is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeMath for uint256;

    uint256 public constant PERCENTS_DIVIDER = 1000;

    uint256 public feePercent; // 5%
    address public feeAddress;

    /* Pairs to swap NFT _id => price */
    struct Pair {
        uint256 pair_id;
        address collection;
        uint256 token_id;
        address owner;
        address tokenAdr;
        uint256 price;
        bool bValid;
    }

    address[] public collections;

    // token id => Pair mapping
    mapping(uint256 => Pair) public pairs;
    uint256 public currentPairId;

    /** Events */

    event ItemListed(Pair pair);
    event ItemDelisted(uint256 id);
    event Swapped(address buyer, Pair pair);

    function initialize(address _feeAddress) public initializer {
        __Ownable_init();
        require(_feeAddress != address(0), "Invalid commonOwner");
        feeAddress = _feeAddress;
        feePercent = 50;
        currentPairId = 1;
    }

    function setFee(uint256 _feePercent, address _feeAddress)
        external
        onlyOwner
    {
        feePercent = _feePercent;
        feeAddress = _feeAddress;
    }

    function list(
        address _collection,
        uint256 _token_id,
        address _tokenAdr,
        uint256 _price
    ) public OnlyItemOwner(_collection, _token_id) {
        require(_price > 0, "invalid price");

        IMintedTunesNFT nft = IMintedTunesNFT(_collection);
        nft.safeTransferFrom(msg.sender, address(this), _token_id);

        currentPairId = currentPairId.add(1);

        pairs[currentPairId].pair_id = currentPairId;
        pairs[currentPairId].collection = _collection;
        pairs[currentPairId].token_id = _token_id;
        pairs[currentPairId].owner = msg.sender;
        pairs[currentPairId].tokenAdr = _tokenAdr;
        pairs[currentPairId].price = _price;
        pairs[currentPairId].bValid = true;

        emit ItemListed(pairs[currentPairId]);
    }

    function delist(uint256 _id) external {
        require(pairs[_id].bValid, "not exist");

        require(
            msg.sender == pairs[_id].owner || msg.sender == owner(),
            "Error, you are not the owner"
        );
        IMintedTunesNFT(pairs[_id].collection).safeTransferFrom(
            address(this),
            pairs[_id].owner,
            pairs[_id].token_id
        );
        pairs[_id].bValid = false;
        emit ItemDelisted(_id);
    }

    function buy(uint256 _id) external payable {
        require(
            _id <= currentPairId && pairs[_id].pair_id == _id,
            "Could not find item"
        );

        require(pairs[_id].bValid, "invalid Pair id");
        require(pairs[_id].owner != msg.sender, "owner can not buy");

        Pair memory pair = pairs[_id];
        uint256 totalAmount = pair.price;
        address _creator = getNFTCreator(pair.collection, pair.token_id);
        uint256 royalty = getNFTRoyalties(pair.collection, pair.token_id);        


        if (pairs[_id].tokenAdr == address(0x0)) {
            require(msg.value >= totalAmount, "insufficient balance");

            // transfer Coin to feeAddress
            if (feePercent > 0) {
                payable(feeAddress).transfer(
                    totalAmount.mul(feePercent).div(PERCENTS_DIVIDER)
                );
            }

            // transfer coin to creator
            if(royalty > 0) {
                payable(_creator).transfer(totalAmount.mul(royalty).div(PERCENTS_DIVIDER));
            }

            // transfer Coin to owner
            uint256 ownerPercent = PERCENTS_DIVIDER.sub(feePercent).sub(royalty);
            if (ownerPercent > 0) {
                payable(pair.owner).transfer(
                    totalAmount.mul(ownerPercent).div(PERCENTS_DIVIDER)
                );
            }
        } else {
            IERC20 governanceToken = IERC20(pairs[_id].tokenAdr);

            require(
                governanceToken.transferFrom(
                    msg.sender,
                    address(this),
                    totalAmount
                ),
                "insufficient token balance"
            );

			// transfer token to feeAddress
            if (feePercent > 0) {
                require(governanceToken.transfer(feeAddress, totalAmount.mul(feePercent).div(PERCENTS_DIVIDER)));
            }

            // transfer token to creator
            if(royalty > 0) {
                require(governanceToken.transfer(_creator, totalAmount.mul(royalty).div(PERCENTS_DIVIDER)));                
            }

            // transfer token to owner
			uint256 ownerPercent = PERCENTS_DIVIDER.sub(feePercent).sub(royalty);
            if (ownerPercent > 0) {
                require(governanceToken.transfer(pair.owner, totalAmount.mul(ownerPercent).div(PERCENTS_DIVIDER)));
            }
        }

        
        // transfer NFT token to buyer
        IMintedTunesNFT(pairs[_id].collection).safeTransferFrom(
            address(this),
            msg.sender,
            pair.token_id
        );

        pairs[_id].bValid = false;

        emit Swapped(msg.sender, pair);
    }

    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId) {
        IMintedTunesNFT tokenContract = IMintedTunesNFT(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender);
        _;
    }

	function withdrawBNB() external onlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, "insufficient balance");
		payable(msg.sender).transfer(balance);
	}

	function withdrawTokens(address token_, uint256 amount_)
        external
        onlyOwner
    {
        if (token_ == address(0x0)) {
            payable(msg.sender).transfer(amount_);
        } else {
            IERC20(token_).transfer(msg.sender, amount_);
        }
    }

    function getNFTRoyalties(address collection, uint256 tokenId) view private returns(uint256) {
        IMintedTunesNFT nft = IMintedTunesNFT(collection); 
        try nft.royalties(tokenId) returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }

    function getNFTCreator(address collection, uint256 tokenId) view private returns(address) {
        IMintedTunesNFT nft = IMintedTunesNFT(collection); 
        try nft.creatorOf(tokenId) returns (address creatorAddress) {
            return creatorAddress;
        } catch {
            return address(0x0);
        }
    }

	receive() external payable {}
}