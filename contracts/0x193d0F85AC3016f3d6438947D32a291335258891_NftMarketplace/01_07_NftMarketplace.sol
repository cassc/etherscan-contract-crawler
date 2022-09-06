// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftMarketplace is Ownable, ReentrancyGuard, Pausable {

    struct Asset {
        address collection;
        uint16[] ids;
        uint8 quantity;
    }

    enum Status {
        COMPLETED, CREATED, DELETED
    }

    struct Swap {
        address maker;
        mapping(address => uint16[]) assets;
        address[] assetsAddresses;
        mapping(address => uint8) quantity;
        mapping(address => uint16[]) requiredIds;
        address receiver;
        Status status;
    }

    struct Fees {
        uint swapFeePerNft;
        uint offerFee;
        uint swapFee;
    }

    Swap[] private swaps;
    Fees public fees;
    mapping(address => bool) allowedCollections;

    uint8 constant MAX_ASSET_SIZE = 3;
    uint8 constant MAX_QUANTITY = 10;

    event SwapCreated(uint id, address maker, Asset[] assets, Asset[] wantedAssets, address receiver, Status status);
    event SwapDeleted(uint id);
    event SwapCompleted(uint id);

    function create(Asset[] memory assets, Asset[] memory wantedAssets, address receiver) external whenNotPaused payable {
        require(msg.value >= fees.offerFee);
        validateInput(assets, wantedAssets, receiver, msg.sender);

        Swap storage swap = swaps.push();
        swap.maker = msg.sender;
        swap.receiver = receiver;

        address[] memory addresses = new address[](assets.length);
        for (uint8 i = 0; i < assets.length; i++) {
            Asset memory asset = assets[i];
            validateAsset(asset);
            for (uint8 j = 0; j < asset.ids.length; j++) {
                require(IERC721(asset.collection).ownerOf(asset.ids[j]) == msg.sender);
            }
            require(swap.assets[asset.collection].length == 0);
            swap.assets[asset.collection] = asset.ids;
            addresses[i] = asset.collection;
        }
        swap.assetsAddresses = addresses;

        for (uint8 i = 0; i < wantedAssets.length; i++) {
            Asset memory wantedAsset = wantedAssets[i];
            validateWantedAsset(wantedAsset);
            require(swap.quantity[wantedAsset.collection] == 0);
            swap.requiredIds[wantedAsset.collection] = wantedAsset.ids;
            swap.quantity[wantedAsset.collection] = wantedAsset.quantity;
        }
        swap.status = Status.CREATED;
        emit SwapCreated(swaps.length - 1, msg.sender, assets, wantedAssets, receiver, Status.CREATED);
    }

    function validateInput(Asset[] memory assets, Asset[] memory wantedAssets, address receiver, address sender) internal pure {
        require(receiver != sender);
        require(assets.length > 0 && assets.length <= MAX_ASSET_SIZE);
        require(wantedAssets.length > 0 && wantedAssets.length <= MAX_ASSET_SIZE);
    }

    function validateAsset(Asset memory asset) internal view {
        require(!ArrayUtils.hasDuplicate(asset.ids));
        require(asset.ids.length > 0 && asset.ids.length <= MAX_QUANTITY);
        require(isAllowedCollection(asset.collection));
    }

    function validateWantedAsset(Asset memory asset) internal view {
        require(asset.quantity > 0 && asset.quantity <= MAX_QUANTITY && asset.quantity >= asset.ids.length);
        require(!ArrayUtils.hasDuplicate(asset.ids));
        require(isAllowedCollection(asset.collection));
    }

    function isAllowedCollection(address collection) internal view returns (bool) {
        return allowedCollections[collection] == true;
    }

    function execute(uint swapId, Asset[] memory assets) public nonReentrant whenNotPaused payable {
        Swap storage swap = swaps[swapId];
        validateSender(msg.sender, swap.receiver);

        require(swap.status == Status.CREATED);
        require(swap.maker != msg.sender);

        uint nftCounter = 0;
        for (uint8 i = 0; i < assets.length; i++) {
            sendWantedAsset(assets[i], swap.requiredIds[assets[i].collection], swap.quantity[assets[i].collection], msg.sender, swap.maker);
            nftCounter = nftCounter + assets[i].ids.length;
        }

        for (uint8 i = 0; i < swap.assetsAddresses.length; i++) {
            address collectionAddress = swap.assetsAddresses[i];
            uint16[] memory ids = swap.assets[collectionAddress];
            for (uint8 j = 0; j < ids.length; j++) {
                IERC721(collectionAddress).safeTransferFrom(swap.maker, msg.sender, ids[j]);
            }
            nftCounter = nftCounter + ids.length;
        }
        require(msg.value >= nftCounter * fees.swapFeePerNft + fees.swapFee);
        swap.status = Status.COMPLETED;
        emit SwapCompleted(swapId);
    }

    function sendWantedAsset(Asset memory asset, uint16[] memory requiredIds, uint8 quantity, address from, address to) internal {
        require(quantity == asset.ids.length && quantity > 0);
        uint requiredIdsCount = 0;
        for (uint8 i = 0; i < asset.ids.length; i++) {
            if (ArrayUtils.contains(requiredIds, asset.ids[i])) {
                requiredIdsCount++;
            }
            IERC721(asset.collection).safeTransferFrom(from, to, asset.ids[i]);
        }
        require(requiredIdsCount == requiredIds.length);
    }

    function validateSender(address sender, address receiver) internal pure {
        bool receiverIsValid = true;
        if (receiver != address(0)) {
            receiverIsValid = sender == receiver;
        }
        require(receiverIsValid);
    }

    function deleteSwap(uint swapId) public whenNotPaused {
        Swap storage swap = swaps[swapId];
        require(swap.status == Status.CREATED);
        require(swap.maker == msg.sender);
        swap.status = Status.DELETED;

        emit SwapDeleted(swapId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function withdrawNft(address collection, uint id) external onlyOwner {
        IERC721(collection).safeTransferFrom(address(this), msg.sender, id);
    }

    function addAllowedCollections(address[] memory collections) external onlyOwner {
        for (uint8 i = 0; i < collections.length; i++) {
            allowedCollections[collections[i]] = true;
        }
    }

    function removeAllowedCollections(address[] memory collections) external onlyOwner {
        for (uint8 i = 0; i < collections.length; i++) {
            allowedCollections[collections[i]] = false;
        }
    }

    function setFees(Fees memory newFees) external onlyOwner {
        fees = newFees;
    }

    constructor(address[] memory collections, Fees memory initialFees) {
        for (uint8 i = 0; i < collections.length; i++) {
            allowedCollections[collections[i]] = true;
        }
        fees = initialFees;
    }

    function withdraw() external onlyOwner {
        (bool os,) = payable(owner()).call{value : address(this).balance}("");
        require(os);
    }

}

library ArrayUtils {

    function hasDuplicate(uint16[] memory A) internal pure returns (bool) {
        if (A.length == 0) {
            return false;
        }
        for (uint16 i = 0; i < A.length - 1; i++) {
            for (uint16 j = i + 1; j < A.length; j++) {
                if (A[i] == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    function contains(uint16[] memory A, uint16 a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    function indexOf(uint16[] memory A, uint16 a) private pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

}