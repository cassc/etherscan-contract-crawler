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
    /**
        E#1: only the seller can create the swap
        E#2: swap already finalized
        E#3: only the bidder or the seller can conclude or reject the swap
        E#4: wrong token locker address
        E#5: seller and bidder cannot be the same address
        E#6: unable to transfer liquidity
        E#7: wrong liquidity provided
        E#8: ERC20 transfer failed
        E#9: membership card address already present
        E#10: membership card address not found
        E#11: error sending fee to treasury
        E#12: only the bidder can conclude the swap
        E#13: at least one basket must contains one nft
    */

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
        bool isMultiAssetSwap;
        uint256 end;
    }

    struct MultichainMembershipCardData {
        address owner;
        string symbol;
        uint256 volume;
        uint256 freeMultiAssetSwapCount;
    }

    event CreateSwap(uint256 indexed swapId, address indexed seller, address indexed bidder);
    event FinalizeSwap(uint256 indexed swapId, address indexed seller, address indexed bidder);
    event CancelSwap(uint256 indexed swapId, address indexed seller, address indexed bidder);
    event RejectSwap(uint256 indexed swapId, address indexed seller, address indexed bidder);

    mapping(uint256 => SwapData) public swapsData;
    address[] public membershipCardsAddresses;
    address[] public tokenLockersAddresses;
    address public treasuryAddress;
    address public feeTokenAddress;
    uint256 public singleAssetSwapFee;
    uint256 public multiAssetSwapFee;
    uint256 public currentSwapId;
    mapping(string => uint256) public cardsSingleAssetSwapFee;
    mapping(string => uint256) public cardsMultiAssetSwapFee;
    mapping(address => uint256) public tokenLockersRequiredAmounts;
    mapping(address => uint256[]) public usersSwapsIds;
    mapping(address => uint256) public usersSwapsCount;

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

    function setSingleAssetSwapFee(uint256 newSingleAssetSwapFee) external onlyOwner {
        singleAssetSwapFee = newSingleAssetSwapFee;
    }

    function setMultiAssetSwapFee(uint256 newMultiAssetSwapFee) external onlyOwner {
        multiAssetSwapFee = newMultiAssetSwapFee;
    }

    function addMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                revert("E#9");

        membershipCardsAddresses.push(membershipCardsAddress);
    }

    function removeMembershipCardAddress(address membershipCardsAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < membershipCardsAddresses.length; i++)
            if (membershipCardsAddresses[i] == membershipCardsAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "E#10");

        membershipCardsAddresses[indexToDelete] = membershipCardsAddresses[membershipCardsAddresses.length - 1];

        membershipCardsAddresses.pop();
    }

    function addTokenLockerAddress(address tokenLockerAddress) external onlyOwner {
        for (uint256 i = 0; i < tokenLockersAddresses.length; i++)
            if (tokenLockersAddresses[i] == tokenLockerAddress)
                revert("E#17");

        tokenLockersAddresses.push(tokenLockerAddress);
    }

    function removeTokenLockerAddress(address tokenLockerAddress) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < tokenLockersAddresses.length; i++)
            if (tokenLockersAddresses[i] == tokenLockerAddress)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "E#4");

        tokenLockersAddresses[indexToDelete] = tokenLockersAddresses[tokenLockersAddresses.length - 1];

        tokenLockersAddresses.pop();
    }

    function setTokenLockerRequiredAmount(address tokenLockerAddress, uint256 amount) external onlyOwner {
        tokenLockersRequiredAmounts[tokenLockerAddress] = amount;
    }

    function setCardSingleAssetSwapFee(string calldata symbol, uint256 newCardSingleAssetSwapFee) external onlyOwner {
        cardsSingleAssetSwapFee[symbol] = newCardSingleAssetSwapFee;
    }

    function setCardMultiAssetSwapFee(string calldata symbol, uint256 newCardMultiAssetSwapFee) external onlyOwner {
        cardsMultiAssetSwapFee[symbol] = newCardMultiAssetSwapFee;
    }

    function createSwap(SwapRequest calldata swapRequest) external payable {
        require(swapRequest.seller == _msgSender(), "E#1");
        require(swapRequest.seller != swapRequest.bidder, "E#5");

        (bool sellerAssetNFTFound, bool sellerAssetSingleCollection, address sellerAssetNFTCollectionAddress) = _processAssetData(swapRequest.sellerAssetData);

        (bool bidderAssetNFTFound, bool bidderAssetSingleCollection, address bidderAssetNFTCollectionAddress) = _processAssetData(swapRequest.bidderAssetData);

        require(sellerAssetNFTFound || bidderAssetNFTFound, "E#13");

        swapsData[currentSwapId].swapRequest = swapRequest;
        swapsData[currentSwapId].isMultiAssetSwap = !sellerAssetSingleCollection || !bidderAssetSingleCollection || sellerAssetNFTCollectionAddress != bidderAssetNFTCollectionAddress;

        _checkProvidedLiquidity(swapRequest.sellerAssetData);

        _processFee(_msgSender(), swapsData[currentSwapId].isMultiAssetSwap);

        _transferAsset(swapRequest.seller, address(this), swapsData[currentSwapId].swapRequest.sellerAssetData);

        usersSwapsIds[swapRequest.seller].push(currentSwapId);
        usersSwapsCount[swapRequest.seller]++;

        usersSwapsIds[swapRequest.bidder].push(currentSwapId);
        usersSwapsCount[swapRequest.bidder]++;

        emit CreateSwap(currentSwapId, swapRequest.seller, swapRequest.bidder);

        currentSwapId++;
    }

    function finalizeSwap(uint256 swapId, bool rejectSwap) external payable {
        SwapData storage swapData = swapsData[swapId];

        require(swapData.end == 0, "E#2");
        require(swapData.swapRequest.bidder == _msgSender() || swapData.swapRequest.seller == _msgSender(), "E#3");

        swapData.end = block.timestamp;

        if (rejectSwap) {
            _cancelSwap(swapData);

            emit RejectSwap(swapId, swapData.swapRequest.seller, swapData.swapRequest.bidder);

            return;
        }

        require(swapData.swapRequest.bidder == _msgSender(), "E#12");

        _processFee(_msgSender(), swapData.isMultiAssetSwap);

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

                    require(liquiditySendSuccess, "E#6");
                }
            }
            else if (assetData[i].assetType == SwapAssetType.ERC20) {
                if (from == address(this)) {
                    require(IERC20(assetData[i].contractAddress).transfer(to, assetData[i].amount), "E#8");
                } else {
                    require(IERC20(assetData[i].contractAddress).transferFrom(from, to, assetData[i].amount), "E#8");
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

    function _processFee(address owner, bool isMultiAssetSwap) private { 
        uint256 fee;

        if (isMultiAssetSwap)
            fee = multiAssetSwapFee;
        else
            fee = singleAssetSwapFee;

        fee = _processMembershipCards(owner, isMultiAssetSwap, fee);
    
        if (fee > 0)
            if (!IERC20(feeTokenAddress).transferFrom(owner, treasuryAddress, fee))
                revert("E#11");
    }

    function _processMembershipCards(address owner, bool isMultiAssetSwap, uint256 fee) private returns(uint256) {
        //Process locked tokens
        for (uint256 i = 0; i < tokenLockersAddresses.length; i++) {
            IFayreTokenLocker.LockData memory lockData = IFayreTokenLocker(tokenLockersAddresses[i]).usersLockData(owner);

            if (lockData.amount > 0)
                if (lockData.amount >= tokenLockersRequiredAmounts[tokenLockersAddresses[i]] && lockData.expiration > block.timestamp)
                    fee = 0;
        }

        //Process on-chain membership cards
        if (fee > 0)
            for (uint256 i = 0; i < membershipCardsAddresses.length; i++) {
                string memory membershipCardSymbol = IFayreMembershipCard721(membershipCardsAddresses[i]).symbol();

                uint256 cardSwapFee = 0;

                if (isMultiAssetSwap)
                    cardSwapFee = cardsMultiAssetSwapFee[membershipCardSymbol];
                else
                    cardSwapFee = cardsSingleAssetSwapFee[membershipCardSymbol];

                uint256 membershipCardsAmount = IFayreMembershipCard721(membershipCardsAddresses[i]).balanceOf(owner);

                if (membershipCardsAmount <= 0)
                    continue;

                if (fee > cardSwapFee)
                    fee = cardSwapFee;
            }

        return fee;
    }

    function _processAssetData(SwapAssetData[] calldata assetData) private pure returns(bool nftFound, bool singleCollection, address nftCollectionAddress) {
        singleCollection = true;

        for (uint256 i = 0; i < assetData.length; i++)
            if (assetData[i].assetType == SwapAssetType.ERC721 || assetData[i].assetType == SwapAssetType.ERC1155) {
                nftFound = true;

                if (nftCollectionAddress == address(0))
                    nftCollectionAddress = assetData[i].contractAddress;
                else
                    if (nftCollectionAddress != assetData[i].contractAddress)
                        singleCollection = false;
            }
    }

    function _checkProvidedLiquidity(SwapAssetData[] memory assetData) private {
        uint256 providedLiquidity = msg.value;

        for (uint256 i = 0; i < assetData.length; i++)
            if (assetData[i].assetType == SwapAssetType.LIQUIDITY)
                require(providedLiquidity == assetData[i].amount, "E#7");
    }
}