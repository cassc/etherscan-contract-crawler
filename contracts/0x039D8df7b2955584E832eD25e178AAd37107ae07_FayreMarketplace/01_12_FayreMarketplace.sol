// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IFayreMembershipCard721.sol";
import "./interfaces/IFayreTokenLocker.sol";

contract FayreMarketplace is Ownable {
    /**
        E#3: wrong base amount
        E#4: free offer expired
        E#5: token locker address not found 
        E#6: unable to send to treasury
        E#7: not the owner
        E#8: invalid trade type
        E#9: sale amount not specified
        E#10: sale expiration must be greater than start
        E#12: cannot finalize your sale, cancel?
        E#13: cannot accept your offer
        E#14: salelist expired
        E#15: asset type not supported
        E#16: unable to send to sale owner
        E#21: cannot finalize unexpired auction
    */

    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    enum TradeType {
        SALE_FIXEDPRICE,
        SALE_ENGLISHAUCTION,
        SALE_DUTCHAUCTION,
        BID
    }

    struct TradeRequest {
        uint256 tokenId;
        uint256 nftAmount;
        uint256 amount;
        uint256 start;
        uint256 expiration;
        uint256 saleId;
        uint256 baseAmount;
        TradeType tradeType;
        AssetType assetType;
        address collectionAddress;
        address owner;
        address tokenAddress;
    }

    struct TokenData {
        uint256 salesId;
        AssetType assetType;
        mapping(uint256 => uint256[]) bidsIds;
    }

    struct TokenLockerFeeData {
        uint256 lockedTokensAmount;
        uint256 fee;
    }

    event PutOnSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId);
    event CancelSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId);
    event FinalizeSale(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed saleId, address buyer);
    event PlaceBid(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId);
    event CancelBid(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId);
    event AcceptFreeOffer(address indexed collectionAddress, uint256 indexed tokenId, uint256 indexed bidId, address nftOwner);
    event ERC20Transfer(address indexed tokenAddress, address indexed from, address indexed to, uint256 amount);
    event ERC721Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId);
    event ERC1155Transfer(address indexed collectionAddress, address indexed from, address indexed to, uint256 tokenId, uint256 amount);

    uint256 public tradeFeePct;
    address public treasuryAddress;
    address[] public membershipCardsAddresses;
    address public tokenLockerAddress;
    mapping(uint256 => TradeRequest) public sales;
    mapping(uint256 => TradeRequest) public bids;
    mapping(address => uint256) public tokenLockersRequiredAmounts;
    TokenLockerFeeData[] public tokenLockerFeesData;
    uint256 public tokenLockerFeesCount;
    mapping(string => uint256) public cardsExpirationDeltaTime;
    mapping(string => uint256) public cardsFee;

    mapping(address => mapping(uint256 => TokenData)) private _tokensData;
    uint256 private _currentSaleId;
    uint256 private _currentBidId;

    function setTradeFee(uint256 newTradeFeePct) external onlyOwner {
        tradeFeePct = newTradeFeePct;
    }

    function setTreasury(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
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
        for (uint256 i = 0; i < tokenLockerFeesData.length; i++)
            if (tokenLockerFeesData[i].lockedTokensAmount == lockedTokensAmount)
                revert("Token locker fee data already present");

        tokenLockerFeesData.push(TokenLockerFeeData(lockedTokensAmount, fee));

        tokenLockerFeesCount++;
    }

    function removeTokenLockerSwapFeeData(uint256 lockedTokensAmount) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < tokenLockerFeesData.length; i++)
            if (tokenLockerFeesData[i].lockedTokensAmount == lockedTokensAmount)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "Wrong token locker swap fee data");

        tokenLockerFeesData[indexToDelete] = tokenLockerFeesData[tokenLockerFeesData.length - 1];

        tokenLockerFeesData.pop();

        tokenLockerFeesCount--;
    }

    function setCardFee(string calldata symbol, uint256 newCardFee) external onlyOwner {
        cardsFee[symbol] = newCardFee;
    }

    function setCardExpirationDeltaTime(string calldata symbol, uint256 newCardExpirationDeltaTime) external onlyOwner {
        cardsExpirationDeltaTime[symbol] = newCardExpirationDeltaTime;
    }

    function putOnSale(TradeRequest memory tradeRequest) external { 
        require(tradeRequest.owner == _msgSender(), "E#7");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#15");

        require(tradeRequest.amount > 0, "E#9");
        require(tradeRequest.expiration > block.timestamp, "E#10");
        require(tradeRequest.tradeType == TradeType.SALE_FIXEDPRICE || tradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION || tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION, "E#8");
        
        if (tradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION)
            require(tradeRequest.baseAmount > 0 && tradeRequest.baseAmount < tradeRequest.amount, "E#3");

        tradeRequest.start = block.timestamp;

        _tokensData[tradeRequest.collectionAddress][tradeRequest.tokenId].salesId = _currentSaleId;

        sales[_currentSaleId] = tradeRequest;

        emit PutOnSale(tradeRequest.collectionAddress, tradeRequest.tokenId, _currentSaleId);

        _currentSaleId++;
    }

    function cancelSale(uint256 saleId) external {
        require(sales[saleId].owner == _msgSender(), "E#7");

        sales[saleId].expiration = 0;

        emit CancelSale(sales[saleId].collectionAddress, sales[saleId].tokenId, saleId);
    }

    function finalizeSale(uint256 saleId) external {
        TradeRequest storage saleTradeRequest = sales[saleId];

        address buyer = address(0);

        if (saleTradeRequest.tradeType == TradeType.SALE_FIXEDPRICE) {
            require(saleTradeRequest.owner != _msgSender(), "E#12");
            require(saleTradeRequest.expiration > block.timestamp, "E#14");

            saleTradeRequest.expiration = 0;

            buyer = _msgSender();

            _sendAmountToSeller(saleTradeRequest.amount, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        } else if (saleTradeRequest.tradeType == TradeType.SALE_ENGLISHAUCTION) {
            require(saleTradeRequest.expiration <= block.timestamp, "E#21");

            uint256[] storage bidsIds = _tokensData[saleTradeRequest.collectionAddress][saleTradeRequest.tokenId].bidsIds[saleId];

            uint256 highestBidId = 0;
            uint256 highestBidAmount = 0;

            for (uint256 i = 0; i < bidsIds.length; i++)
                if (bids[bidsIds[i]].amount >= saleTradeRequest.amount)
                    if (bids[bidsIds[i]].amount > highestBidAmount) {
                        highestBidId = bidsIds[i];
                        highestBidAmount = bids[bidsIds[i]].amount;
                    }
                    
            buyer = bids[highestBidId].owner;

            _sendAmountToSeller(highestBidAmount, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        } else if (saleTradeRequest.tradeType == TradeType.SALE_DUTCHAUCTION) {
            require(saleTradeRequest.owner != _msgSender(), "E#12");
            require(saleTradeRequest.expiration > block.timestamp, "E#14");

            uint256 amountsDiff = saleTradeRequest.amount - saleTradeRequest.baseAmount;

            uint256 priceDelta = amountsDiff - ((amountsDiff * (block.timestamp - saleTradeRequest.start)) / (saleTradeRequest.expiration - saleTradeRequest.start));

            uint256 currentPrice = saleTradeRequest.baseAmount + priceDelta;
            
            saleTradeRequest.expiration = 0;

            buyer = _msgSender();

            _sendAmountToSeller(currentPrice, saleTradeRequest.tokenAddress, saleTradeRequest.owner, buyer);
        }

        _transferAsset(saleTradeRequest.assetType, saleTradeRequest.collectionAddress, saleTradeRequest.owner, buyer, saleTradeRequest.tokenId, saleTradeRequest.nftAmount, "");

        emit FinalizeSale(saleTradeRequest.collectionAddress, saleTradeRequest.tokenId, saleId, buyer);
    }

    function placeBid(TradeRequest memory tradeRequest) external {
        require(tradeRequest.owner == _msgSender(), "E#7");
        require(tradeRequest.assetType == AssetType.ERC721 || tradeRequest.assetType == AssetType.ERC1155, "E#15");

        require(tradeRequest.amount > 0, "E#9");
        require(tradeRequest.tradeType == TradeType.BID, "E#8");

        tradeRequest.start = block.timestamp;

        bids[_currentBidId] = tradeRequest;

        _tokensData[bids[_currentBidId].collectionAddress][bids[_currentBidId].tokenId].bidsIds[tradeRequest.saleId].push(_currentBidId);

        emit PlaceBid(tradeRequest.collectionAddress, tradeRequest.tokenId, _currentBidId);

        _currentBidId++;
    }

    function cancelBid(uint256 bidId) external {
        TradeRequest storage bidTradeRequest = bids[bidId];

        require(bidTradeRequest.owner == _msgSender(), "E#7");

        bidTradeRequest.start = 0;
        bidTradeRequest.expiration = 0;

        uint256[] storage bidsIds = _tokensData[bidTradeRequest.collectionAddress][bidTradeRequest.tokenId].bidsIds[bidTradeRequest.saleId];

        uint256 indexToDelete = 0;

        for (uint256 i = 0; i < bidsIds.length; i++)
            if (bidsIds[i] == bidId)
                indexToDelete = i;

        bidsIds[indexToDelete] = bidsIds[bidsIds.length - 1];

        bidsIds.pop();

        emit CancelBid(bidTradeRequest.collectionAddress, bidTradeRequest.tokenId, bidId);
    }

    function acceptFreeOffer(uint256 bidId) external {
        TradeRequest storage bidTradeRequest = bids[bidId];

        require(bidTradeRequest.owner != _msgSender(), "E#13");
        require(bidTradeRequest.start > 0 && bidTradeRequest.expiration > block.timestamp, "E#4");

        bidTradeRequest.start = 0;
        bidTradeRequest.expiration = 0;

        _sendAmountToSeller(bidTradeRequest.amount, bidTradeRequest.tokenAddress, _msgSender(), bidTradeRequest.owner);

        _transferAsset(bidTradeRequest.assetType, bidTradeRequest.collectionAddress, _msgSender(), bidTradeRequest.owner, bidTradeRequest.tokenId, bidTradeRequest.nftAmount, "");
    
        emit AcceptFreeOffer(bidTradeRequest.collectionAddress, bidTradeRequest.tokenId, bidId, _msgSender());
    }

    function _sendAmountToSeller(uint256 amount, address tokenAddress, address seller, address buyer) private {
        uint256 saleFee = (amount * tradeFeePct) / 10 ** 20;

        uint256 ownerRemainingSaleFee = 0;

        ownerRemainingSaleFee = _processFee(seller, saleFee * 10 ** (18 - IERC20Extended(tokenAddress).decimals()));

        _transferAsset(AssetType.ERC20, tokenAddress, buyer, seller, 0, amount - ownerRemainingSaleFee, "E#16");

        if (ownerRemainingSaleFee > 0)
            _transferAsset(AssetType.ERC20, tokenAddress, buyer, treasuryAddress, 0, ownerRemainingSaleFee, "E#6");
    }

    function _transferAsset(AssetType assetType, address contractAddress, address from, address to, uint256 tokenId, uint256 amount, string memory errorCode) private {
        if (assetType == AssetType.ERC20) {
            if (!IERC20Extended(contractAddress).transferFrom(from, to, amount))
                revert(errorCode);

            emit ERC20Transfer(contractAddress, from, to, amount);
        }
        else if (assetType == AssetType.ERC721) {
            IERC721(contractAddress).safeTransferFrom(from, to, tokenId);

            emit ERC721Transfer(contractAddress, from, to, tokenId);
        } 
        else if (assetType == AssetType.ERC1155) {
            IERC1155(contractAddress).safeTransferFrom(from, to, tokenId, amount, '');

            emit ERC1155Transfer(contractAddress, from, to, tokenId, amount);
        }      
    }

    function _processFee(address owner, uint256 fee) private returns(uint256) { 
        //Process locked tokens
        if (tokenLockerAddress != address(0)) {
            uint256 minLockDuration = IFayreTokenLocker(tokenLockerAddress).minLockDuration();

            IFayreTokenLocker.LockData memory lockData = IFayreTokenLocker(tokenLockerAddress).usersLockData(owner);

            if (lockData.amount > 0)
                if (lockData.start + minLockDuration <= lockData.expiration && lockData.start + minLockDuration >= block.timestamp)
                    for (uint256 j = 0; j < tokenLockerFeesData.length; j++)
                        if (lockData.amount >= tokenLockerFeesData[j].lockedTokensAmount)
                            if (fee > tokenLockerFeesData[j].fee)
                                fee = tokenLockerFeesData[j].fee;
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
                            uint256 cardFee = cardsFee[membershipCardSymbol];

                            if (fee > cardFee)
                                fee = cardFee;
                        }
                    }
                } else {
                    uint256 cardFee = cardsFee[membershipCardSymbol];

                    if (fee > cardFee)
                        fee = cardFee;
                }
            }

        return fee;
    }
}