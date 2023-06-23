// SPDX-License-Identifier: MIT

// ██╗░░██╗██╗██╗░░██╗░█████╗░███╗░░░███╗██╗███╗░░██╗████████╗░██████╗
// ██║░██╔╝██║██║░██╔╝██╔══██╗████╗░████║██║████╗░██║╚══██╔══╝██╔════╝
// █████═╝░██║█████═╝░██║░░██║██╔████╔██║██║██╔██╗██║░░░██║░░░╚█████╗░
// ██╔═██╗░██║██╔═██╗░██║░░██║██║╚██╔╝██║██║██║╚████║░░░██║░░░░╚═══██╗
// ██║░╚██╗██║██║░╚██╗╚█████╔╝██║░╚═╝░██║██║██║░╚███║░░░██║░░░██████╔╝
// ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝░░░╚═╝░░░╚═════╝░

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import './operator-filter-registry/DefaultOperatorFiltererUpgradeable.sol';

interface IKikoLoots is IERC1155Upgradeable {
    function useMaterialAndTools(address user, uint256[] memory mtTypes, uint256[] memory mtCounts, uint256 countMultiplier) external;
}

interface IVaultProxyWarmXYZ {
    function ownerOf(address contractAddress, uint256 tokenId) external view returns (address);
}

interface IVaultProxyDelegateCash {
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool);
}

contract KikoMints is ERC721Upgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
	
    /**
     * ======= Structs and enums definitions =======
     * 
     */
    
    struct EditUint256 {
        uint256 index;
        uint256 value;
    }
    
    struct EditString {
        uint256 index;
        string value;
    }
    
    struct EditAddress {
        uint256 index;
        address value;
    }
    
    struct EditBool {
        uint256 index;
        bool value;
    }
    
    struct EditUint256Array {
        uint256 index;
        uint256[] value;
    }
    
    struct Collection {
        string itemLabel;
        string baseURI;
        address baseToken;
        uint256 baseCollection;
        uint256 price;
        uint256 discountPrice;
        uint256 totalTokenIds;
        uint256[] mtRequirementIds;
        uint256[] mtRequirementCounts;
        uint256 collectionType;
        uint256 paymentErc20Price;
        address paymentErc20Address;
        bool available;
    }
    
    struct CollectionUpdate {
        EditString[] updatedItemLabel;
        EditString[] updatedBaseURI;
        EditAddress[] updatedBaseToken;
        EditUint256[] updatedBaseCollection;
        EditUint256[] updatedPrice;
        EditUint256[] updatedDiscountPrice;
        EditUint256[] updatedTotalTokenIds;
        EditUint256Array[] updatedMtRequirementIds;
        EditUint256Array[] updatedMtRequirementCounts;
        EditUint256[] updatedPaymentErc20Price;
        EditAddress[] updatedPaymentErc20Address;
        EditUint256[] updatedCollectionType;
        EditBool[] updatedAvailable;
    }
    
    /**
     * ======= Variables =======
     * 
     * We are using the upgradeable pattern - please do not change names, types, or order of variables
     * New variables must be added at the end of the list
     * 
     */
     
    uint256 public constant DECIMALS_FOR_TOKENID = 10**10;
    Collection[] public collections;
    IKikoLoots public materialsAndToolsContract;
    IERC721Upgradeable public vipPassContract;
    mapping (uint256 => bool) public isCollectionFreezed;
    mapping (address => bool) isAdmin;
    
    IVaultProxyWarmXYZ vaultProxyWarmXYZ;
    IVaultProxyDelegateCash vaultProxyDelegateCash;

    uint256 public couponHashPrecision;
    mapping (bytes32 => uint256) public couponHashToDiscountPercentageTimesPrecision;
    mapping (bytes32 => uint256) public couponHashToUses;

    mapping (uint256 => mapping (uint256 => uint256)) public collectionIdAndTokenIdInCollectionToCustomDiscount;
    mapping (bytes32 => uint256) public voucherHashToValue;
    mapping (bytes32 => uint256) public voucherHashToUses;

    /**
     * ======= Events =======
     * 
     */
    event ToggleCollection(uint256 indexed index, bool indexed available);
    event SetAdmin(address indexed addr, bool indexed enabled);
    event Minted(uint256 indexed collectionId, uint256 indexed tokenIdInCollection);
    event SetCoupon(bytes32 indexed couponHash, uint256 discountValue, uint256 uses);
    event SetVoucher(bytes32 indexed voucherHash, uint256 discountValue, uint256 uses);
    event SetCustomDiscount(uint256 indexed collectionId, uint256 indexed tokenIdInCollection, uint256 customDiscount);
    
    /**
     * ======= Constructor =======
     * 
     */
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(address warmXYZ, address delegateCash) public initializer {
        __ERC721_init("KikoMints", "KIKO");
        __Ownable_init();
        __DefaultOperatorFilterer_init();

        vaultProxyWarmXYZ = IVaultProxyWarmXYZ(warmXYZ);
        vaultProxyDelegateCash = IVaultProxyDelegateCash(delegateCash);
        couponHashPrecision = 100;
    }
    
    /**
     * ======= Token handling functions =======
     *
     */
     
    /**
     * @dev Converts contract tokenId to collectionId and tokenId from collection 
     */
    function tokenIdToCollectionIdAndBaseTokenId(uint256 tokenId) public pure returns (uint256, uint256) {
        uint256 collectionId = tokenId / DECIMALS_FOR_TOKENID;
        uint256 baseTokenId = tokenId % DECIMALS_FOR_TOKENID;
        return (collectionId, baseTokenId);
    }
    
    /**
     * @dev Converts collectionId and tokenId from collection to contract tokenId
     */
    function collectionIdAndBaseTokenIdToTokenId(uint256 collectionId, uint256 baseTokenId) public pure returns (uint256) {
        return collectionId * DECIMALS_FOR_TOKENID + baseTokenId;
    }
    
    /**
     * ======= Internal functions =======
     * 
     */
    function internalMintFromCollection(uint256 collectionId, uint256 tokenIdInCollection, address mintTo, bool fromAdmin, uint256 proxyType) internal {
        // revert if collection id is outside bounds
        require(collectionId < collections.length, "Bad collection ID");
        
        if (!fromAdmin) {
            // revert if minting is not available
            require(collections[collectionId].available, "Not available");

            // revert if total token ids is set and selected token id is higher than that
            if (collections[collectionId].totalTokenIds > 0) {
                require(tokenIdInCollection < collections[collectionId].totalTokenIds, "Token id too high");
            }

            // revert if user does not hold required materials and tools
            if (collections[collectionId].mtRequirementIds.length > 0) {
                materialsAndToolsContract.useMaterialAndTools(mintTo, collections[collectionId].mtRequirementIds, collections[collectionId].mtRequirementCounts, 1);
            }

            // collect ERC20 payment
            if (collections[collectionId].paymentErc20Price > 0) {
                IERC20Upgradeable(collections[collectionId].paymentErc20Address).transferFrom(mintTo, owner(), collections[collectionId].paymentErc20Price);
            }

            // revert if sender is not owner of corresponding token
            if (collections[collectionId].collectionType == 0) {
                // based on ERC721 external token
                if (proxyType == 0) {
                    // no proxy
                    require(mintTo == IERC721Upgradeable(collections[collectionId].baseToken).ownerOf(tokenIdInCollection), "You do not own the token");
                } else if (proxyType == 1) {
                    // warm.xyz
                    require(mintTo == vaultProxyWarmXYZ.ownerOf(collections[collectionId].baseToken, tokenIdInCollection), "You do not own the token");
                } else if (proxyType == 2) {
                    // delegate.cash
                    require(vaultProxyDelegateCash.checkDelegateForToken(mintTo, IERC721Upgradeable(collections[collectionId].baseToken).ownerOf(tokenIdInCollection), collections[collectionId].baseToken, tokenIdInCollection), "You do not own the token");
                }
            } else if (collections[collectionId].collectionType == 1) {
                // based on other internal collection
                uint256 tok = collectionIdAndBaseTokenIdToTokenId(collections[collectionId].baseCollection, tokenIdInCollection);
                require(mintTo == ownerOf(tok), "You do not own the token");
            } else if (collections[collectionId].collectionType == 3) {
                // based on ERC1155 external token
                require(IERC1155Upgradeable(collections[collectionId].baseToken).balanceOf(mintTo, tokenIdInCollection) > 0, "You do not own the token");
            }
        }
        
        uint256 tokenId = collectionIdAndBaseTokenIdToTokenId(collectionId, tokenIdInCollection);
        _mint(mintTo, tokenId);
        emit Minted(collectionId, tokenIdInCollection);
    }
    
    /**
     * ======= Collection management functions =======
     * 
     * All functions in this section are marked `onlyOwner`
     * 
     */
    
     /**
     * @dev Add and edit collections in a single tx
     */
    function addAndEditCollections(CollectionUpdate calldata collectionsToUpdate, Collection[] calldata collectionsToAdd) external onlyOwner {
        uint256 i;
        
        for (i = 0; i < collectionsToUpdate.updatedItemLabel.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedItemLabel[i].index], "Freezed");
            collections[collectionsToUpdate.updatedItemLabel[i].index].itemLabel = collectionsToUpdate.updatedItemLabel[i].value;
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedBaseURI.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedBaseURI[i].index], "Freezed");
            collections[collectionsToUpdate.updatedBaseURI[i].index].baseURI = collectionsToUpdate.updatedBaseURI[i].value;
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedBaseToken.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedBaseToken[i].index], "Freezed");
            collections[collectionsToUpdate.updatedBaseToken[i].index].baseToken = collectionsToUpdate.updatedBaseToken[i].value;
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedBaseCollection.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedBaseCollection[i].index], "Freezed");
            collections[collectionsToUpdate.updatedBaseCollection[i].index].baseCollection = collectionsToUpdate.updatedBaseCollection[i].value;
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedPrice.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedPrice[i].index], "Freezed");
            collections[collectionsToUpdate.updatedPrice[i].index].price = collectionsToUpdate.updatedPrice[i].value;
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedDiscountPrice.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedDiscountPrice[i].index], "Freezed");
            collections[collectionsToUpdate.updatedDiscountPrice[i].index].discountPrice = collectionsToUpdate.updatedDiscountPrice[i].value;
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedTotalTokenIds.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedTotalTokenIds[i].index], "Freezed");
            collections[collectionsToUpdate.updatedTotalTokenIds[i].index].totalTokenIds = collectionsToUpdate.updatedTotalTokenIds[i].value;
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedMtRequirementIds.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedMtRequirementIds[i].index], "Freezed");
            collections[collectionsToUpdate.updatedMtRequirementIds[i].index].mtRequirementIds = collectionsToUpdate.updatedMtRequirementIds[i].value;
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedMtRequirementCounts.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedMtRequirementCounts[i].index], "Freezed");
            collections[collectionsToUpdate.updatedMtRequirementCounts[i].index].mtRequirementCounts = collectionsToUpdate.updatedMtRequirementCounts[i].value;
            require(collections[collectionsToUpdate.updatedMtRequirementCounts[i].index].mtRequirementCounts.length == collections[collectionsToUpdate.updatedMtRequirementCounts[i].index].mtRequirementIds.length, "Bad lengths");
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedCollectionType.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedCollectionType[i].index], "Freezed");
            collections[collectionsToUpdate.updatedCollectionType[i].index].collectionType = collectionsToUpdate.updatedCollectionType[i].value;
            unchecked{i++;}
        }

        for (i = 0; i < collectionsToUpdate.updatedPaymentErc20Price.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedPaymentErc20Price[i].index], "Freezed");
            collections[collectionsToUpdate.updatedPaymentErc20Price[i].index].paymentErc20Price = collectionsToUpdate.updatedPaymentErc20Price[i].value;
            unchecked{i++;}
        }

        for (i = 0; i < collectionsToUpdate.updatedPaymentErc20Address.length;) {
            require(!isCollectionFreezed[collectionsToUpdate.updatedPaymentErc20Address[i].index], "Freezed");
            collections[collectionsToUpdate.updatedPaymentErc20Address[i].index].paymentErc20Address = collectionsToUpdate.updatedPaymentErc20Address[i].value;
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToUpdate.updatedAvailable.length;) {
            require(!collectionsToUpdate.updatedAvailable[i].value || !isCollectionFreezed[collectionsToUpdate.updatedAvailable[i].index], "Freezed");
            collections[collectionsToUpdate.updatedAvailable[i].index].available = collectionsToUpdate.updatedAvailable[i].value;
            emit ToggleCollection(collectionsToUpdate.updatedAvailable[i].index, collectionsToUpdate.updatedAvailable[i].value);
            unchecked{i++;}
        }
        
        for (i = 0; i < collectionsToAdd.length;) {
            require(collectionsToAdd[i].mtRequirementIds.length == collectionsToAdd[i].mtRequirementCounts.length, "Bad lengths");
            emit ToggleCollection(collections.length, collectionsToAdd[i].available);
            collections.push(collectionsToAdd[i]);
            unchecked{i++;}
        }
    }
    
    /**
     * @dev Freeze collections forever
     */
    function freezeCollectionsForever(uint256[] calldata collectionIds) external onlyOwner {
        for (uint256 i = 0; i < collectionIds.length;) {
            require(collectionIds[i] < collections.length, "Invalid collection");
            isCollectionFreezed[collectionIds[i]] = true;
            unchecked{i++;}
        }
    }
    
    /**
     * ======= User facing minting =======
     * 
     */
    
    /**
     * @dev Mint a token from a specific collection
     */
    function mintFromCollection(uint256 collectionId, uint256 tokenIdInCollection, string calldata coupon, string calldata voucher) external payable {
        uint256 expectedPrice;
        if (vipPassContract.balanceOf(msg.sender) > 0) {
            expectedPrice = collections[collectionId].discountPrice;
        } else {
            expectedPrice = collections[collectionId].price;
        }

        uint256 customDiscount = collectionIdAndTokenIdInCollectionToCustomDiscount[collectionId][tokenIdInCollection];
        if (customDiscount > expectedPrice) {
            expectedPrice = 0;
        } else {
            expectedPrice -= customDiscount;
        }

        if (bytes(coupon).length != 0) {
            bytes32 couponHash = keccak256(abi.encodePacked(coupon));
            couponHashToUses[couponHash]--;
            expectedPrice -= expectedPrice*couponHashToDiscountPercentageTimesPrecision[couponHash]/(couponHashPrecision*100);
        }

        if (bytes(voucher).length != 0) {
            bytes32 voucherHash = keccak256(abi.encodePacked(voucher));
            voucherHashToUses[voucherHash]--;
            uint256 voucherDiscount = voucherHashToValue[voucherHash];
            if (voucherDiscount >= expectedPrice) {
                expectedPrice = 0;
            } else {
                expectedPrice -= voucherDiscount;
            }
        }

        require(msg.value == expectedPrice, "Wrong amount of ETH");
        internalMintFromCollection(collectionId, tokenIdInCollection, msg.sender, false, 0);
    }

    /**
     * @dev Mint multiple tokens from collections
     */
    function mintFromCollectionMultiple(uint256[] calldata collectionIds, uint256[] calldata tokenIdsInCollection, uint256[] calldata proxyTypes, string calldata coupon, string calldata voucher) external payable {
        require(collectionIds.length == tokenIdsInCollection.length, "Bad lengths");

        uint256 sum = 0;
        if (vipPassContract.balanceOf(msg.sender) > 0) {
            for (uint256 i=0; i < collectionIds.length;) {
                uint256 customDiscount = collectionIdAndTokenIdInCollectionToCustomDiscount[collectionIds[i]][tokenIdsInCollection[i]];
                if (customDiscount < collections[collectionIds[i]].discountPrice) {
                    sum += collections[collectionIds[i]].discountPrice - customDiscount;   
                }
                unchecked{i++;}
            }
        } else {
            for (uint256 i=0; i < collectionIds.length;) {
                uint256 customDiscount = collectionIdAndTokenIdInCollectionToCustomDiscount[collectionIds[i]][tokenIdsInCollection[i]];
                if (customDiscount < collections[collectionIds[i]].price) {
                    sum += collections[collectionIds[i]].price - customDiscount;   
                }
                unchecked{i++;}
            }
        }

        if (bytes(coupon).length != 0) {
            bytes32 couponHash = keccak256(abi.encodePacked(coupon));
            couponHashToUses[couponHash]--;
            sum -= sum*couponHashToDiscountPercentageTimesPrecision[couponHash]/(couponHashPrecision*100);
        }

        if (bytes(voucher).length != 0) {
            bytes32 voucherHash = keccak256(abi.encodePacked(voucher));
            voucherHashToUses[voucherHash]--;
            uint256 voucherDiscount = voucherHashToValue[voucherHash];
            if (voucherDiscount >= sum) {
                sum = 0;
            } else {
                sum -= voucherDiscount;
            }
        }

        require(sum == msg.value, "Wrong ETH sum");

        for (uint256 i=0; i < collectionIds.length;) {
            internalMintFromCollection(collectionIds[i], tokenIdsInCollection[i], msg.sender, false, proxyTypes[i]);
            unchecked{i++;}
        }
    }
    
    /**
     * ======= Owner facing functions =======
     * 
     */

    /**
     * @dev Edit coupon's uses and discount value
     */
    function setCoupons(bytes32[] calldata couponHashes, uint256[] calldata uses, uint256[] calldata discounts) external onlyOwner {
        for (uint256 i=0; i<couponHashes.length; i++) {
            couponHashToDiscountPercentageTimesPrecision[couponHashes[i]] = discounts[i];
            couponHashToUses[couponHashes[i]] = uses[i];
            emit SetCoupon(couponHashes[i], discounts[i], uses[i]);
        }
    }

    /**
     * @dev Edit voucher's uses and discount value
     */
    function setVouchers(bytes32[] calldata voucherHashes, uint256[] calldata uses, uint256[] calldata values) external onlyOwner {
        for (uint256 i=0; i<voucherHashes.length; i++) {
            voucherHashToValue[voucherHashes[i]] = values[i];
            voucherHashToUses[voucherHashes[i]] = uses[i];
            emit SetVoucher(voucherHashes[i], values[i], uses[i]);
        }
    }

    /**
     * @dev Set custom discount for specific collection id and token id
     */
    function setCustomDiscount(uint256[] calldata collectionIds, uint256[] calldata tokenIdsInCollection, uint256[] calldata customDiscounts) external onlyOwner {
        for (uint256 i=0; i<collectionIds.length; i++) {
            collectionIdAndTokenIdInCollectionToCustomDiscount[collectionIds[i]][tokenIdsInCollection[i]] = customDiscounts[i];
            emit SetCustomDiscount(collectionIds[i], tokenIdsInCollection[i], customDiscounts[i]);
        }
    }
     
    /**
     * @dev Set address of Materials&Tools contract
     */
    function setMaterialsAndToolsContract(address _contract) external onlyOwner {
        materialsAndToolsContract = IKikoLoots(_contract);
    }

    /**
     * @dev Set address of Materials&Tools contract
     */
    function setVipPassContract(address _contract) external onlyOwner {
        vipPassContract = IERC721Upgradeable(_contract);
    }

    /**
     * @dev Mint tokens in type 2 collections by specifying collection id, token indexes, and owner address (callable by owner)
     */
    function runAirdrop(uint256[] calldata collectionIds, uint256[] calldata tokenIds, address[] calldata owners) external {
        require(isAdmin[msg.sender], "Not authorized");
        require(collectionIds.length == tokenIds.length && tokenIds.length == owners.length, "Bad lengths");
        
        for (uint256 i = 0; i < tokenIds.length;) {
            internalMintFromCollection(collectionIds[i], tokenIds[i], owners[i], true, 0);
            unchecked{i++;}
        }
    }
    
    /**
     * @dev Mark address as admin/non-admin
     */
    function setAdmin(address addr, bool enabled) external onlyOwner {
        isAdmin[addr] = enabled;
        emit SetAdmin(addr, enabled);
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    /**
     * ======= View functions =======
     *
     */
     
    /**
     * @dev Returns true if tokenId from collectionId has been minted already
     */
    function getTokenInCollectionHasBeenMinted(uint256 collectionId, uint256 tokenIdInCollection) public view returns (bool) {
        return _exists(collectionIdAndBaseTokenIdToTokenId(collectionId, tokenIdInCollection));
    }

    /**
     * @dev Returns owner of token from collection
     */
    function getOwnerOfTokenInCollection(uint256 collectionId, uint256 tokenIdInCollection) public view returns (address) {
        return ownerOf(collectionIdAndBaseTokenIdToTokenId(collectionId, tokenIdInCollection));
    }
     
    /**
     * @dev Get number of collections
     */
    function getCollectionCount() public view returns (uint256) {
        return collections.length;
    }
    
    /**
     * @dev Get Materials&Tools requirements of collection by collection id
     */
    function getCollectionMts(uint256 collectionId) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory ids = collections[collectionId].mtRequirementIds;
        uint256[] memory counts = collections[collectionId].mtRequirementCounts;
        return (ids, counts);
    }
     
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        (uint256 collectionId, uint256 tokenIdInCollection) = tokenIdToCollectionIdAndBaseTokenId(tokenId);
        
        string memory base = collections[collectionId].baseURI;
        return string(abi.encodePacked(base, tokenIdInCollection.toString()));
    }

    
    /**
     * ------------ OPENSEA OPERATOR FILTER OVERRIDES ------------
     */
    
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}