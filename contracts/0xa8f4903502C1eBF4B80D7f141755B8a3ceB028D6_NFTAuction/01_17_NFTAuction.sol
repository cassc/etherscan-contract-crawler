//
// NFT Auction Contract
// SPDX-License-Identifier: MIT
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IERC721NFT.sol";
import "./interfaces/IRoyaltyRegistry.sol";

contract NFTAuction is Ownable, ERC721Holder {
    using EnumerableSet for EnumerableSet.AddressSet;
    using ECDSA for bytes32;

    address public constant NATIVE_ADDRESS =
        address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public constant MIN_BID_INCREMENT_PERCENT = 100; // 1%
    uint256 public constant MAX_SWAP_FEE_PERCENT = 5000; // 50%

    uint256 public feePercent = 500; //5%
    address public feeAddress;

    address public royaltyRegistry;
    address public signerAddress;

    bool public _bLocked;

    mapping(uint256 => bool) public usedSignature;

    struct Splits {
        address receiver;
        uint256 commission;
    }

    // AuctionBid struct to hold bidder and amount
    struct AuctionBid {
        address from;
        uint256 bidPrice;
    }

    // Auction struct which holds all the required info
    struct Auction {
        uint256 auctionId;
        address collectionId;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        address tokenAddr;
        uint256 startPrice;
        address owner;
        bool active;
        Splits[] splits;
    }

    // Array with all auctions
    Auction[] public auctions;

    // Mapping from auction index to user bids
    mapping(uint256 => AuctionBid[]) public auctionBids;

    // Mapping from owner to a list of owned auctions
    mapping(address => uint256[]) public ownedAuctions;

    mapping(address => bool) public _managers;

    event ManagerAdded(address manager);
    event ManagerRemoved(address manager);

    event AuctionBidSuccess(
        address _from,
        Auction auction,
        uint256 price,
        uint256 _bidIndex
    );

    // AuctionCreated is fired when an auction is created
    event AuctionCreated(Auction auction);

    // AuctionCanceled is fired when an auction is canceled
    event AuctionCanceled(Auction auction);

    // AuctionFinalized is fired when an auction is finalized
    event AuctionFinalized(address buyer, uint256 price, Auction auction);

    constructor(address _owner, address _royaltyRegistry) {
        _transferOwnership(_owner);
        feeAddress = _owner;
        signerAddress = _owner;
        addManager(_owner);
        royaltyRegistry = _royaltyRegistry;
    }

    function addManager(address managerAddress) public onlyOwner {
        require(managerAddress != address(0), "manager: address is zero");
        require(
            _managers[managerAddress] != true,
            "manager: address is already manager"
        );
        _managers[managerAddress] = true;
        emit ManagerAdded(managerAddress);
    }

    function removeManager(address managerAddress) public onlyOwner {
        require(managerAddress != address(0), "manager: address is zero");
        require(
            _managers[managerAddress] != false,
            "manager: address is already not manager"
        );
        _managers[managerAddress] = false;
        emit ManagerRemoved(managerAddress);
    }

    function emergencyWithdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) public onlyOwner {
        SafeERC20.safeTransfer(IERC20(token_), to_, amount_);
    }

    function emergencyWithdrawCoin(
        address payable to_,
        uint256 amount_
    ) public onlyOwner {
        (bool result, ) = to_.call{value: amount_}("");
        require(result, "withdraw failed");
    }

    function setFee(address _feeAddress, uint256 _adminFee) external onlyOwner {
        feePercent = _adminFee;
        feeAddress = _feeAddress;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0), "Invalid address");
        signerAddress = _signerAddress;
    }

    function setRoyaltyRegistry(address _royaltyRegistry) external onlyOwner {
        require(_royaltyRegistry != address(0), "Invalid address");
        royaltyRegistry = _royaltyRegistry;
    }

    /*
     * @dev Creates an auction with the given informatin
     * @param _tokenRepositoryAddress address of the TokenRepository contract
     * @param _tokenId uint256 of the deed registered in DeedRepository
     * @param _startPrice uint256 starting price of the auction
     * @return bool whether the auction is created
     */
    function createAuction(
        address _collectionId,
        uint256 _tokenId,
        address _tokenAddr,
        uint256 _startPrice,
        uint256 _startTime,
        uint256 _endTime,
        Splits[] memory splits
    ) public onlyTokenOwner(_collectionId, _tokenId) ReentrancyGuard {
        require(_startTime < _endTime, "Invalid auction time");
        require(block.timestamp < _endTime, "End time is too early");

        uint256 auctionId = auctions.length;
        Auction memory newAuction;
        newAuction.auctionId = auctionId;
        newAuction.collectionId = _collectionId;
        newAuction.tokenId = _tokenId;
        newAuction.startPrice = _startPrice;
        newAuction.tokenAddr = _tokenAddr;
        newAuction.startTime = _startTime;
        newAuction.endTime = _endTime;
        newAuction.owner = msg.sender;
        newAuction.splits = splits;
        newAuction.active = true;

        auctions.push(newAuction);
        ownedAuctions[msg.sender].push(auctionId);

        IERC721NFT(_collectionId).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );
        emit AuctionCreated(newAuction);
    }

    /**
     * @dev Bidder sends bid on an auction
     * @dev Auction should be active and not ended
     * @dev Refund previous bidder if a new bid is valid and placed.
     * @param _auctionId uint256 ID of the created auction
     */
    function bidOnAuction(
        uint256 _auctionId,
        uint256 amount,
        address fromAddress
    ) external payable AuctionExists(_auctionId) ReentrancyGuard {
        Auction memory myAuction = auctions[_auctionId];
        address myOwner = myAuction.owner;
        address myTokenAddr = myAuction.tokenAddr;
        uint256 myStartPrice = myAuction.startPrice;
        uint256 myStartTime = myAuction.startTime;
        uint256 myEndTime = myAuction.endTime;
        bool myActive = myAuction.active;

        // owner can't bid on their auctions
        require(myOwner != fromAddress, "You are owner");
        require(myActive, "Auction doesn't exist");

        // if auction is expired
        require(block.timestamp < myEndTime, "Auction is expired");
        require(block.timestamp >= myStartTime, "Auction is not started");

        uint256 bidsLength = auctionBids[_auctionId].length;
        uint256 tempAmount = myStartPrice;
        AuctionBid memory lastBid;

        // there are previous bids
        if (bidsLength > 0) {
            lastBid = auctionBids[_auctionId][bidsLength - 1];
            tempAmount =
                (lastBid.bidPrice *
                    (PERCENTS_DIVIDER + MIN_BID_INCREMENT_PERCENT)) /
                PERCENTS_DIVIDER;
        }
        address lastFrom = lastBid.from;
        uint256 lastBidPrice = lastBid.bidPrice;

        if (myTokenAddr == NATIVE_ADDRESS) {
            require(msg.value >= tempAmount, "Amount too low");
            require(msg.value >= amount, "Insufficient amount");
            if (bidsLength > 0) {
                (bool result, ) = payable(lastFrom).call{value: lastBidPrice}(
                    ""
                );
                require(result, "Failed to refund coin to last bidder");
            }
        } else {
            // check if amount is greater than previous amount
            require(amount >= tempAmount, "Token amount too low");

            IERC20 buyToken = IERC20(myTokenAddr);

            SafeERC20.safeTransferFrom(
                buyToken,
                msg.sender,
                address(this),
                amount
            );

            if (bidsLength > 0)
                SafeERC20.safeTransfer(buyToken, lastFrom, lastBidPrice);
        }

        // insert bid
        AuctionBid memory newBid;
        newBid.from = fromAddress;
        newBid.bidPrice = amount;
        auctionBids[_auctionId].push(newBid);
        emit AuctionBidSuccess(
            fromAddress,
            myAuction,
            newBid.bidPrice,
            bidsLength
        );
    }

    /**
     * @dev Finalized an ended auction
     * @dev The auction should be ended, and there should be at least one bid
     * @dev On success Deed is transfered to bidder and auction owner gets the amount
     * @param _auctionId uint256 ID of the created auction
     */
    function finalizeAuction(
        uint256 _auctionId,
        uint256 expireTime,
        bytes memory signature
    ) public ReentrancyGuard {
        Auction memory myAuction = auctions[_auctionId];
        uint256 bidsLength = auctionBids[_auctionId].length;

        address myCollectionId = myAuction.collectionId;
        uint256 myTokenId = myAuction.tokenId;
        address myTokenAddr = myAuction.tokenAddr;
        address myOwner = myAuction.owner;

        checkSignature(
            msg.sender,
            _auctionId,
            expireTime,
            "finalizeAuction",
            signature
        );

        require(
            msg.sender == myOwner || _managers[msg.sender] == true,
            "You are not auction owner"
        );

        // if there are no bids cancel
        if (bidsLength == 0) {
            // 1. the nft goes to the auction creator
            IERC721NFT(myCollectionId).safeTransferFrom(
                address(this),
                myOwner,
                myTokenId
            );
            auctions[_auctionId].active = false;
            emit AuctionCanceled(auctions[_auctionId]);
        } else {
            // 2. the money goes to the seller
            AuctionBid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            Splits[] memory splits = myAuction.splits;

            address lastFrom = lastBid.from;
            uint256 lastBidPrice = lastBid.bidPrice;

            // % commission cut
            uint256 _adminFee = (lastBidPrice * feePercent) / PERCENTS_DIVIDER;
            uint256 _royalty = (lastBidPrice *
                IRoyaltyRegistry(royaltyRegistry).getRoyalty(
                    myCollectionId,
                    myTokenId
                )) / PERCENTS_DIVIDER;
            uint256 _sellerValue = lastBidPrice - _royalty - _adminFee;

            if (myTokenAddr == NATIVE_ADDRESS) {
                if (_adminFee > 0) {
                    (bool result2, ) = payable(feeAddress).call{
                        value: _adminFee
                    }("");
                    require(result2, "Failed to send fee coin");
                }
                if (_royalty > 0) {
                    (bool result1, ) = payable(
                        IRoyaltyRegistry(royaltyRegistry).getCreator(
                            myCollectionId,
                            myTokenId
                        )
                    ).call{value: _royalty}("");
                    require(result1, "Failed to send coin to creator");
                }
                if (_sellerValue > 0) {
                    uint256 splitsLen = splits.length;
                    uint256 lastSplit = _sellerValue;
                    for (uint256 i = 0; i < splitsLen; i++) {
                        uint256 _splitSend = (_sellerValue *
                            splits[i].commission) / PERCENTS_DIVIDER;
                        if (i == splitsLen - 1) _splitSend = lastSplit;
                        else lastSplit = lastSplit - _splitSend;
                        (bool result, ) = payable(splits[i].receiver).call{
                            value: _splitSend
                        }("");
                        require(result, "Failed to send coin to user");
                    }
                }
            } else {
                IERC20 buyToken = IERC20(myTokenAddr);

                if (_adminFee > 0)
                    SafeERC20.safeTransfer(buyToken, feeAddress, _adminFee);

                if (_royalty > 0)
                    SafeERC20.safeTransfer(
                        buyToken,
                        IRoyaltyRegistry(royaltyRegistry).getCreator(
                            myCollectionId,
                            myTokenId
                        ),
                        _royalty
                    );

                if (_sellerValue > 0) {
                    uint256 splitsLen = splits.length;
                    uint256 lastSplit = _sellerValue;
                    for (uint256 i = 0; i < splitsLen; i++) {
                        uint256 _splitSend = (_sellerValue *
                            splits[i].commission) / PERCENTS_DIVIDER;
                        if (i == splitsLen - 1) _splitSend = lastSplit;
                        else lastSplit = lastSplit - _splitSend;

                        SafeERC20.safeTransfer(
                            buyToken,
                            splits[i].receiver,
                            _splitSend
                        );
                    }
                }
            }

            // approve and transfer from this contract to the bid winner
            IERC721NFT(myCollectionId).safeTransferFrom(
                address(this),
                lastFrom,
                myTokenId
            );
            auctions[_auctionId].active = false;

            emit AuctionFinalized(lastFrom, lastBidPrice, myAuction);
        }
    }

    /**
     * @dev Gets the length of auctions
     * @return uint256 representing the auction count
     */
    function getAuctionsLength() public view returns (uint) {
        return auctions.length;
    }

    /**
     * @dev Gets the bid counts of a given auction
     * @param _auctionId uint256 ID of the auction
     */
    function getBidsAmount(uint256 _auctionId) public view returns (uint) {
        return auctionBids[_auctionId].length;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _owner address of the auction owner
     */
    function getOwnedAuctions(
        address _owner,
        uint256 _startIdx,
        uint256 _size
    ) public view returns (uint[] memory) {
        uint[] memory ownedAllAuctions = ownedAuctions[_owner];
        if (_startIdx == 0 && _size == 0) return ownedAllAuctions;

        uint256 endIdx = _startIdx + _size;
        uint256 idx = 0;

        uint[] memory returnData = new uint[](_size);
        for (uint256 i = _startIdx; i < endIdx; i++) {
            returnData[idx] = ownedAllAuctions[i];
            idx++;
        }
        return returnData;
    }

    /**
     * @dev Gets an array of owned auctions
     * @param _auctionId uint256 of the auction owner
     * @return amount uint256, address of last bidder
     */
    function getCurrentBids(
        uint256 _auctionId
    ) public view returns (uint256, address) {
        uint256 bidsLength = auctionBids[_auctionId].length;
        // if there are bids refund the last bid
        if (bidsLength >= 0) {
            AuctionBid memory lastBid = auctionBids[_auctionId][bidsLength - 1];
            return (lastBid.bidPrice, lastBid.from);
        }
        return (0, address(0));
    }

    /**
     * @dev Gets the total number of auctions owned by an address
     * @param _owner address of the owner
     * @return uint256 total number of auctions
     */
    function getAuctionsAmount(address _owner) public view returns (uint) {
        return ownedAuctions[_owner].length;
    }

    function checkSignature(
        address executor,
        uint256 uniqueId,
        uint256 expireTime,
        string memory functionName,
        bytes memory signature
    ) internal {
        require(usedSignature[uniqueId] == false, "Used signature");
        usedSignature[uniqueId] = true;

        require(block.timestamp < expireTime, "Expired signature");
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(
            keccak256(
                abi.encodePacked(
                    this,
                    chainId,
                    functionName,
                    executor,
                    uniqueId,
                    expireTime
                )
            ).toEthSignedMessageHash().recover(signature) == signerAddress,
            "Invalid signature"
        );
    }

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "caller is not the manager");
        _;
    }

    modifier onlyAuctionOwner(uint256 _auctionId) {
        require(auctions[_auctionId].owner == msg.sender);
        _;
    }

    modifier onlyTokenOwner(address _collectionId, uint256 _tokenId) {
        address tokenOwner = IERC721(_collectionId).ownerOf(_tokenId);
        require(tokenOwner == msg.sender);
        _;
    }

    modifier AuctionExists(uint256 auctionId) {
        require(
            auctionId <= auctions.length &&
                auctions[auctionId].auctionId == auctionId,
            "Could not find item"
        );
        _;
    }

    modifier ReentrancyGuard() {
        require(!_bLocked, "Execution locked");
        _bLocked = true;
        _;
        _bLocked = false;
    }
}