// Single Fixed Price Marketplace contract
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISingleNFT {
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);  
	function getRoyalties() external view returns (uint256);	
    function getOwner() external view returns (address); 
}

contract SingleFixed is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeMath for uint256;

	uint256 constant public PERCENTS_DIVIDER = 1000;

	uint256 public swapFee; // 25 for 2.5%	
	address public feeAddress; 
	
    /* Pairs to swap NFT _id => price */
	struct Pair {
		uint256 pairId;
		address collection;
		uint256 tokenId;
		address owner;
		address tokenAdr;
		uint256 price;
        bool bValid;		
	}

	// token id => Pair mapping
    mapping(uint256 => Pair) public pairs;
	uint256 public currentPairId;
	
	/** Events */
    event SingleItemListed(Pair pair);
	event SingleItemDelisted(address collection, uint256 tokenId, uint256 pairId);
    event SingleSwapped(address buyer, Pair pair);

	function initialize(
        address _feeAddress
    ) public initializer {
        __Ownable_init();
        require(_feeAddress != address(0), "Invalid commonOwner");
        feeAddress = _feeAddress;
        swapFee = 25;
        currentPairId = 1;
    }	
	
	function setFeePercent(uint256 _swapFee) external onlyOwner {		
		require(_swapFee < 1000 , "invalid percent");
        swapFee = _swapFee;
    }
	function setFeeAddress(address _feeAddress) external onlyOwner {
		require(_feeAddress != address(0x0), "invalid address");		
        feeAddress = _feeAddress;		
    }	

    function singleList(address _collection, uint256 _tokenId, address _tokenAdr, uint256 _price) OnlyItemOwner(_collection,_tokenId) public {
		require(_price > 0, "invalid price");	
		ISingleNFT nft = ISingleNFT(_collection);        
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

		currentPairId = currentPairId.add(2);
		pairs[currentPairId].pairId = currentPairId;
		pairs[currentPairId].collection = _collection;
		pairs[currentPairId].tokenId = _tokenId;		
        pairs[currentPairId].owner = msg.sender;
		pairs[currentPairId].tokenAdr = _tokenAdr;		
		pairs[currentPairId].price = _price;
		pairs[currentPairId].bValid = true;	

        emit SingleItemListed(pairs[currentPairId]);
    }

    function singleDelist(uint256 _id) external {        
        require(pairs[_id].bValid, "not exist");
        require(msg.sender == pairs[_id].owner || msg.sender == owner(), "Error, you are not the owner");        
        ISingleNFT(pairs[_id].collection).safeTransferFrom(address(this), pairs[_id].owner, pairs[_id].tokenId);        
        pairs[_id].bValid = false;
        emit SingleItemDelisted(pairs[_id].collection, pairs[_id].tokenId, _id);        
    }


    function singleBuy(uint256 _id) external payable {
		require(_id <= currentPairId && pairs[_id].pairId == _id, "Could not find item");
        require(pairs[_id].bValid, "invalid Pair id");
		require(pairs[_id].owner != msg.sender, "owner can not buy");

		Pair memory pair = pairs[_id];
		uint256 totalAmount = pair.price;

		uint256 collectionRoyalties = getCollectionRoyalties(pairs[_id].collection);
        address collectionOwner = getCollectionOwner(pairs[_id].collection);


		uint256 feeAmount = totalAmount.mul(swapFee).div(PERCENTS_DIVIDER);		
		uint256 creatorAmount = totalAmount.mul(collectionRoyalties).div(PERCENTS_DIVIDER);
        uint256 ownerAmount = totalAmount.sub(feeAmount).sub(creatorAmount);

		if (pairs[_id].tokenAdr == address(0x0)) {
            require(msg.value >= totalAmount, "too small amount");

			if(swapFee > 0) {
                (bool feeResult, ) = payable(feeAddress).call{value: feeAmount}("");
        		require(feeResult, "Failed to send coin to feeAddress");
			}	
			if(collectionRoyalties > 0) {
                (bool creatorResult, ) = payable(collectionOwner).call{value: creatorAmount}("");
        		require(creatorResult, "Failed to send coin to collectionOwner");					
			}
            (bool result, ) = payable(pair.owner).call{value: ownerAmount}("");
        	require(result, "Failed to send coin to item owner");		

        } else {
            IERC20 governanceToken = IERC20(pairs[_id].tokenAdr);

			require(governanceToken.transferFrom(msg.sender, address(this), totalAmount), "insufficient token balance");
		
			if(swapFee > 0) {
				// transfer governance token to feeAddress
				require(governanceToken.transfer(feeAddress, feeAmount));				
			}

			if(collectionRoyalties > 0) {
				// transfer governance token to creator
				require(governanceToken.transfer(collectionOwner, creatorAmount));				
			}
			
			// transfer governance token to owner
			require(governanceToken.transfer(pair.owner, ownerAmount));			
		
        }
		
		// transfer NFT token to buyer
		ISingleNFT(pairs[_id].collection).safeTransferFrom(address(this), msg.sender, pair.tokenId);
		
		pairs[_id].bValid = false;		

        emit SingleSwapped(msg.sender, pair);		
    }


	function getCollectionRoyalties(address collection) view private returns(uint256) {
        ISingleNFT nft = ISingleNFT(collection); 
        try nft.getRoyalties() returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }

    function getCollectionOwner(address collection) view private returns(address) {
        ISingleNFT nft = ISingleNFT(collection); 
        try nft.getOwner() returns (address ownerAddress) {
            return ownerAddress;
        } catch {
            return address(0x0);
        }
    }

	modifier OnlyItemOwner(address tokenAddress, uint256 tokenId){
        ISingleNFT tokenContract = ISingleNFT(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender);
        _;
    }

    modifier ItemExists(uint256 id){
        require(id <= currentPairId && pairs[id].pairId == id, "Could not find item");
        _;
    }
	/**
     * @dev To receive ETH
     */
    receive() external payable {}

}