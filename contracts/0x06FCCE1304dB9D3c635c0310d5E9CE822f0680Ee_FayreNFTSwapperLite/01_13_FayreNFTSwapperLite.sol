// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IFayreMembershipCard721.sol";
import "./interfaces/IFayreTokenLocker.sol";

contract FayreNFTSwapperLite is Ownable, IERC721Receiver, IERC1155Receiver {
    enum SwapAssetType {
        LIQUIDITY,
        ERC20,
        ERC721,
        ERC1155
    }

    struct SwapAssetData {
        address contractAddress;
        SwapAssetType assetType;
        uint256 id;
        uint256 amount;
    }

    struct SwapRequest {
        address seller;
        address bidder;
        SwapAssetData[] sellerAssetData;
        SwapAssetData[] bidderAssetData;
    }

    struct SwapData {
        SwapRequest swapRequest;
        uint256 end;
    }

    struct TokenLockerSwapFeeData {
        uint256 lockedTokensAmount;
        uint256 fee;
    }

    struct CollectionStatusData {
        address contractAddress;
        bool isWhitelisted;
    }

    event CreateSwap(uint256 indexed swapId, address indexed seller, address indexed bidder);
    event FinalizeSwap(uint256 indexed swapId, address indexed seller, address indexed bidder);
    event CancelSwap(uint256 indexed swapId, address indexed seller, address indexed bidder);
    event RejectSwap(uint256 indexed swapId, address indexed seller, address indexed bidder);

    mapping(uint256 => SwapData) public swapsData;
    address[] public membershipCardsAddresses;
    address public tokenLockerAddress;
    address public treasuryAddress;
    address public feeTokenAddress;
    uint256 public swapFee;
    uint256 public currentSwapId;
    mapping(string => uint256) public cardsSwapFee;
    mapping(string => uint256) public cardsExpirationDeltaTime;
    TokenLockerSwapFeeData[] public tokenLockerSwapFeesData;
    mapping(address => uint256[]) public usersSwapsIds;
    mapping(address => uint256) public usersSwapsCount;
    mapping(address => bool) public isCollectionWhitelisted;

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
 
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == 0x01ffc9a7 || interfaceID == type(IERC721Receiver).interfaceId || interfaceID == type(IERC1155Receiver).interfaceId;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function setFeeTokenAddress(address newFeeTokenAddress) external onlyOwner {
        feeTokenAddress = newFeeTokenAddress;
    }

    function setSwapFee(uint256 newSwapFee) external onlyOwner {
        swapFee = newSwapFee;
    }

    function addMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                revert("Membership card address already present");

        membershipCardsAddresses.push(membershipCardsAddress);
    }

    function removeMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "Membership card address not found");

        membershipCardsAddresses[indexToDelete] = membershipCardsAddresses[membershipCardsAddresses.length - 1];

        membershipCardsAddresses.pop();
    }

    function setTokenLockerAddress(address newTokenLockerAddress) external onlyOwner {
        tokenLockerAddress = newTokenLockerAddress;
    }

    function addTokenLockerSwapFeeData(uint256 lockedTokensAmount, uint256 fee) external onlyOwner {
        for (uint256 i = 0; i < tokenLockerSwapFeesData.length; i++)
            if (tokenLockerSwapFeesData[i].lockedTokensAmount == lockedTokensAmount)
                revert("E#17");

        tokenLockerSwapFeesData.push(TokenLockerSwapFeeData(lockedTokensAmount, fee));
    }

    function removeTokenLockerSwapFeeData(uint256 lockedTokensAmount) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < tokenLockerSwapFeesData.length; i++)
            if (tokenLockerSwapFeesData[i].lockedTokensAmount == lockedTokensAmount)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "Wrong token locker swap fee data");

        tokenLockerSwapFeesData[indexToDelete] = tokenLockerSwapFeesData[tokenLockerSwapFeesData.length - 1];

        tokenLockerSwapFeesData.pop();
    }

    function setCardSwapFee(string calldata symbol, uint256 newCardSwapFee) external onlyOwner {
        cardsSwapFee[symbol] = newCardSwapFee;
    }

    function setCardExpirationDeltaTime(string calldata symbol, uint256 newCardExpirationDeltaTime) external onlyOwner {
        cardsExpirationDeltaTime[symbol] = newCardExpirationDeltaTime;
    }

    function setCollectionsStatuses(CollectionStatusData[] calldata collectionsStatusesData) external onlyOwner {
        for (uint256 i = 0; i < collectionsStatusesData.length; i++)
            isCollectionWhitelisted[collectionsStatusesData[i].contractAddress] = collectionsStatusesData[i].isWhitelisted;
    }

    function createSwap(SwapRequest calldata swapRequest) external payable {
        require(swapRequest.seller == _msgSender(), "Only seller can create the swap");
        require(swapRequest.seller != swapRequest.bidder, "Seller and bidder cannot be the same address");

        bool sellerAssetNFTFound = _processAssetData(swapRequest.sellerAssetData);

        bool bidderAssetNFTFound = _processAssetData(swapRequest.bidderAssetData);

        require(sellerAssetNFTFound || bidderAssetNFTFound, "At least one basket must contains one nft");

        uint256 swapId = currentSwapId++;

        swapsData[swapId].swapRequest = swapRequest;

        _checkProvidedLiquidity(swapRequest.sellerAssetData);

        _processFee(_msgSender());

        _transferAsset(swapRequest.seller, address(this), swapsData[swapId].swapRequest.sellerAssetData);

        usersSwapsIds[swapRequest.seller].push(swapId);
        usersSwapsCount[swapRequest.seller]++;

        usersSwapsIds[swapRequest.bidder].push(swapId);
        usersSwapsCount[swapRequest.bidder]++;

        emit CreateSwap(swapId, swapRequest.seller, swapRequest.bidder);
    }

    function finalizeSwap(uint256 swapId, bool rejectSwap) external payable {
        SwapData storage swapData = swapsData[swapId];

        require(swapData.end == 0, "Swap already finalized");
        require(swapData.swapRequest.bidder == _msgSender() || swapData.swapRequest.seller == _msgSender(), "Only bidder/seller can conclude/reject the swap");

        swapData.end = block.timestamp;

        if (rejectSwap) {
            _cancelSwap(swapData);

            emit RejectSwap(swapId, swapData.swapRequest.seller, swapData.swapRequest.bidder);

            return;
        }

        require(swapData.swapRequest.bidder == _msgSender(), "Only the bidder can conclude the swap");

        _processFee(_msgSender());

        _checkProvidedLiquidity(swapData.swapRequest.bidderAssetData);

        _transferAsset(swapData.swapRequest.bidder, swapData.swapRequest.seller, swapData.swapRequest.bidderAssetData);

        _transferAsset(address(this), swapData.swapRequest.bidder, swapData.swapRequest.sellerAssetData);

        emit FinalizeSwap(swapId, swapData.swapRequest.seller, swapData.swapRequest.bidder);
    }

    function _cancelSwap(SwapData storage swapData) private {
        swapData.end = block.timestamp;

        _transferAsset(address(this), swapData.swapRequest.seller, swapData.swapRequest.sellerAssetData);
    }

    function _transferAsset(address from, address to, SwapAssetData[] storage assetData) private {
        for (uint256 i = 0; i < assetData.length; i++) {
            if (assetData[i].assetType == SwapAssetType.LIQUIDITY) {
                if (to != address(this)) {
                    (bool liquiditySendSuccess, ) = to.call{value: assetData[i].amount}("");

                    require(liquiditySendSuccess, "Unable to transfer liquidity");
                }
            }
            else if (assetData[i].assetType == SwapAssetType.ERC20) {
                if (from == address(this)) {
                    require(IERC20(assetData[i].contractAddress).transfer(to, assetData[i].amount), "ERC20 transfer failed");
                } else {
                    require(IERC20(assetData[i].contractAddress).transferFrom(from, to, assetData[i].amount), "ERC20 transfer failed");
                }
            }
            else if (assetData[i].assetType == SwapAssetType.ERC721) {
                IERC721(assetData[i].contractAddress).safeTransferFrom(from, to, assetData[i].id, "");
            }
            else if (assetData[i].assetType == SwapAssetType.ERC1155) {
                IERC1155(assetData[i].contractAddress).safeTransferFrom(from, to, assetData[i].id, assetData[i].amount, "");
            }
        }
    }

    function _processFee(address owner) private { 
        uint256 fee = swapFee;

        fee = _processMembershipCards(owner, fee);
    
        if (fee > 0)
            if (!IERC20(feeTokenAddress).transferFrom(owner, treasuryAddress, fee))
                revert("Error sending fee to treasury");
    }

    function _processMembershipCards(address owner, uint256 fee) private returns(uint256) {
        //Process locked tokens
        if (tokenLockerAddress != address(0)) {
            uint256 minLockDuration = IFayreTokenLocker(tokenLockerAddress).minLockDuration();

            IFayreTokenLocker.LockData memory lockData = IFayreTokenLocker(tokenLockerAddress).usersLockData(owner);

            if (lockData.amount > 0)
                if (lockData.start + minLockDuration <= lockData.expiration && lockData.start + minLockDuration >= block.timestamp)
                    for (uint256 j = 0; j < tokenLockerSwapFeesData.length; j++)
                        if (lockData.amount >= tokenLockerSwapFeesData[j].lockedTokensAmount)
                            if (fee > tokenLockerSwapFeesData[j].fee)
                                fee = tokenLockerSwapFeesData[j].fee;
        }

        //Process on-chain membership cards
        if (fee > 0)
            for (uint256 i = 0; i < membershipCardsAddresses.length; i++) {
                uint256 membershipCardsAmount = IFayreMembershipCard721(membershipCardsAddresses[i]).balanceOf(owner);

                if (membershipCardsAmount <= 0)
                    continue;

                string memory membershipCardSymbol = IFayreMembershipCard721(membershipCardsAddresses[i]).symbol();

                if (cardsExpirationDeltaTime[membershipCardSymbol] > 0) {
                    for (uint256 j = 0; j < membershipCardsAmount; j++) {
                        uint256 currentTokenId = IFayreMembershipCard721(membershipCardsAddresses[i]).tokenOfOwnerByIndex(owner, j);

                        if (IFayreMembershipCard721(membershipCardsAddresses[i]).membershipCardMintTimestamp(currentTokenId) + cardsExpirationDeltaTime[membershipCardSymbol] >= block.timestamp) {
                            uint256 cardSwapFee = cardsSwapFee[membershipCardSymbol];

                            if (fee > cardSwapFee)
                                fee = cardSwapFee;
                        }
                    }
                } else {
                    uint256 cardSwapFee = cardsSwapFee[membershipCardSymbol];

                    if (fee > cardSwapFee)
                        fee = cardSwapFee;
                }
            }

        return fee;
    }

    function _processAssetData(SwapAssetData[] calldata assetData) private view returns(bool nftFound) {
        for (uint256 i = 0; i < assetData.length; i++)
            if (assetData[i].assetType == SwapAssetType.ERC721 || assetData[i].assetType == SwapAssetType.ERC1155) {
                require(isCollectionWhitelisted[assetData[i].contractAddress], "Collection not whitelisted");

                nftFound = true;
            }     
    }

    function _checkProvidedLiquidity(SwapAssetData[] memory assetData) private {
        uint256 providedLiquidity = msg.value;

        for (uint256 i = 0; i < assetData.length; i++)
            if (assetData[i].assetType == SwapAssetType.LIQUIDITY)
                require(providedLiquidity == assetData[i].amount, "Wrong liquidity provided");
    }
}