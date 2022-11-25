//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Auction
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/IAuction.sol';
import './interfaces/IAdminPanel.sol';
import './NFTAssist.sol';
import './interfaces/IWETH.sol';
import 'hardhat/console.sol';

contract Auction is IAuction, Ownable, NFTAssist, ReentrancyGuard {
    using SafeERC20 for IERC20;

    Lot[] private _lots;
    address public WETH;
    IAdminPanel public adminPanel;

    mapping(address => uint256[]) private _userLots;
    mapping(address => uint256[]) private _userBids;
    mapping(uint256 => Bid[]) public bids;
    mapping(address => UserActivity[]) public _userActivities;
    mapping(address => UserHistory[]) public _userHistory;
    mapping(address => UserLot[]) public _userLotType;

    event LotCreated(
        uint256 indexed timestamp,
        uint256 indexed lotId,
        address indexed owner
    );
    event LotCanceled(
        uint256 indexed timestamp,
        uint256 indexed lotId,
        address indexed owner
    );
    event LotFinished(
        uint256 indexed timestamp,
        uint256 indexed lotId,
        address nftOwner,
        address nftWinner,
        uint256 price
    );
    event NewBid(
        uint256 indexed timestamp,
        uint256 indexed lotId,
        address bidder,
        uint256 bid
    );

    constructor(address WETH_, address adminPanel_) {
        WETH = WETH_;
        adminPanel = IAdminPanel(adminPanel_);
    }

    modifier isActive(uint256 lotId) {
        require(lotId < _lots.length, 'Lot does not exist');
        require(_lots[lotId].status == Status.ACTIVE, 'Lot is not active');
        _;
    }

    receive() external payable {}

    function _addUserActivity(
        address user,
        uint256 lotId,
        uint256 amount,
        Direction direction
    ) internal {
        _userActivities[user].push(
            UserActivity({
                timestamp: block.timestamp,
                lot: getLotNFT(lotId),
                user: user,
                amount: amount,
                direction: direction
            })
        );
    }

    function _addUserHistory(
        address user,
        uint256 lotId,
        uint256 amount,
        Direction direction
    ) internal {
        _userHistory[user].push(
            UserHistory({
                timestamp: block.timestamp,
                lot: getLotNFT(lotId),
                user: user,
                amount: amount,
                direction: direction
            })
        );
    }

    function _addUserLots(
        address user,
        uint256 lotId,
        UserLotType lotType
    ) internal {
        _userLotType[user].push(
            UserLot({
                timestamp: block.timestamp,
                lot: getLotNFT(lotId),
                user: user,
                userLotType: lotType
            })
        );
    }

    /// @dev Adds new lot structure in array, receives nft from nft owner and sets parameters
    /// @param nft address of nft to be placed on auction
    /// @param tokenId token if of nft address to be placed on auction
    /// @param parameters_ parameters of this nft auction act
    function createLot(
        address nft,
        uint256 tokenId,
        Parameters memory parameters_
    ) external {
        require(
            adminPanel.validTokens(parameters_.tokenAddress),
            'Not allowed token selected'
        );
        require(adminPanel.belongsToWhitelist(nft), 'NFT does not belong to whitelist');
        require(
            parameters_.startPrice < parameters_.finishPrice,
            'finish not requires start price'
        );
        require(parameters_.step.value > 0, 'step amount is zero');

        uint256 start = parameters_.startTimestamp;
        if (start != 0) require(block.timestamp <= start, 'Start in past');
        else start = block.timestamp;

        _transferNFT(msg.sender, address(this), nft, tokenId, 1);

        _lots.push(
            Lot({
                id: _lots.length,
                owner: msg.sender,
                startTimestamp: start,
                lastBidder: msg.sender,
                lastBid: parameters_.startPrice,
                nft: _getNFT(nft, tokenId),
                parameters: parameters_,
                status: Status.ACTIVE
            })
        );

        _addUserLots(msg.sender, _lots.length - 1, UserLotType.PLACED);
        _userLots[msg.sender].push(_lots.length - 1);
        emit LotCreated(block.timestamp, _lots.length - 1, msg.sender);
    }

    /// @dev Cancels selected nft lot, sends back last bit to last bidder
    /// @param lotId id of the lot to be canceled
    function cancelLot(uint256 lotId) external isActive(lotId) nonReentrant {
        Lot storage lot = _lots[lotId];
        require(lot.owner == msg.sender, 'Caller is not the lot owner');
        lot.status = Status.CANCELED;
        _transferNFT(address(this), lot.owner, lot.nft.nftContract, lot.nft.tokenId, 1);
        if (lot.lastBidder != lot.owner) {
            if (lot.parameters.tokenAddress == WETH) {
                IWETH(payable(WETH)).withdraw(lot.lastBid);
                if (!payable(lot.lastBidder).send(lot.lastBid)) {
                    IWETH(payable(WETH)).deposit{value: lot.lastBid}();
                    IWETH(payable(WETH)).transfer(lot.lastBidder, lot.lastBid);
                }
            } else {
                IERC20(lot.parameters.tokenAddress).safeTransfer(
                    lot.lastBidder,
                    lot.lastBid
                );
            }
            _addUserLots(lot.lastBidder, lotId, UserLotType.CANCELED);
            _addUserActivity(lot.lastBidder, lotId, lot.lastBid, Direction.BUY);
        }
        _addUserLots(msg.sender, lotId, UserLotType.CANCELED);
        emit LotCanceled(block.timestamp, lotId, msg.sender);
    }

    /// @dev Finishes the lot, lot owner gets profit, bidder gets nft, can be called only from lot owner
    /// @param lotId id of the lot to finish
    function finishLot(uint256 lotId) external isActive(lotId) nonReentrant {
        Lot memory lot = _lots[lotId];
        require(lot.owner == msg.sender, 'Caller is not the lot owner');
        require(lot.lastBidder != lot.owner, 'No one has bidded for this lot');
        _finishLot(lotId);
    }

    /// @dev Finishes the lot, lot owner gets profit, bidder gets nft,
    /// can be called if lot time is passed or finishPrice is reached
    /// @param lotId id of the lot to finish
    function claim(uint256 lotId) external isActive(lotId) nonReentrant {
        Lot memory lot = _lots[lotId];
        require(
            block.timestamp >= lot.startTimestamp + lot.parameters.period,
            'lot time is not passed'
        );
        require(msg.sender != lot.owner, 'owner cannot claim');
        _finishLot(lotId);
    }

    /// @dev Bids higher tokens amount on selected lot, last bidder gets his bid back, and caller becomes last bidder
    /// @param lotId id of the lot to bid on
    /// @param bid_ new higher than previos tokens amount
    function bid(uint256 lotId, uint256 bid_) external isActive(lotId) nonReentrant {
        Lot memory lot = _lots[lotId];
        bool finishPriceReached = false;
        if (bid_ >= lot.parameters.finishPrice) {
            bid_ = lot.parameters.finishPrice;
            finishPriceReached = true;
        }
        (address lastBidder, uint256 lastBid) = _bid(lotId, bid_, finishPriceReached);
        IERC20(lot.parameters.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            bid_
        );
        if (lastBidder != lot.owner)
            IERC20(lot.parameters.tokenAddress).safeTransfer(lastBidder, lastBid);
        if (finishPriceReached) {
            _finishLot(lotId);
        }
    }

    /// @dev Bids higher eth amount on selected lot, last bidder gets his eth bid back,
    /// and caller becomes last bidder, enabled only if token in lot parameters is weth
    /// @param lotId id of the lot to bid on
    function bidETH(uint256 lotId) external payable isActive(lotId) nonReentrant {
        Lot memory lot = _lots[lotId];
        require(
            lot.parameters.tokenAddress == WETH,
            'Enable to bid with eth in this lot'
        );
        bool finishPriceReached = false;
        uint256 bid_ = msg.value;
        if (bid_ >= lot.parameters.finishPrice) {
            finishPriceReached = true;
            if (bid_ != lot.parameters.finishPrice) {
                payable(msg.sender).transfer(bid_ - lot.parameters.finishPrice);
                bid_ = lot.parameters.finishPrice;
            }
        }
        IWETH(payable(WETH)).deposit{value: bid_}();
        (address lastBidder, uint256 lastBid) = _bid(lotId, bid_, finishPriceReached);
        if (lastBidder != lot.owner) {
            IWETH(payable(WETH)).withdraw(lastBid);
            if (!payable(lastBidder).send(lastBid)) {
                IWETH(payable(WETH)).deposit{value: lastBid}();
                IWETH(payable(WETH)).transfer(lastBidder, lastBid);
            }
        }
        if (finishPriceReached) {
            _finishLot(lotId);
        }
    }

    /// @dev Checks bid amount and time bidded, and changes last bidder and lasst bid
    /// @param lotId id of lot to bid on
    /// @param bid_ bid amount
    /// @param finishPriceReached flas is true when current bid is higher than finish price,
    /// means that after this bid automaticaly finishes the lot with msg.sender as winner
    /// @return previosBidder previos bidder to get his bid back
    /// @return previosBid bid amount to send prevois bidder
    function _bid(
        uint256 lotId,
        uint256 bid_,
        bool finishPriceReached
    ) internal isActive(lotId) returns (address previosBidder, uint256 previosBid) {
        Lot storage lot = _lots[lotId];

        require(
            block.timestamp < lot.startTimestamp + lot.parameters.period,
            'lot time is passed'
        );
        require(lot.owner != msg.sender, 'bidder is the owner');

        if (!finishPriceReached) {
            uint256 value;
            if (lot.parameters.step.inPercents) {
                value = lot.lastBid + (lot.lastBid * lot.parameters.step.value) / 100;
            } else {
                value = lot.lastBid + lot.parameters.step.value;
            }
            require(bid_ >= value, 'To low bid');

            // if time left to end of active period less than left time in lot parameters, increases period time
            if (
                lot.startTimestamp + lot.parameters.period <=
                block.timestamp + lot.parameters.bonusTime.left
            ) {
                lot.parameters.period += lot.parameters.bonusTime.bonus;
            }
        }

        if (lot.lastBidder != lot.owner)
            _addUserActivity(lot.lastBidder, lotId, bid_, Direction.BUY);
        _addUserLots(msg.sender, lotId, UserLotType.BID);

        _userBids[msg.sender].push(lot.id);

        previosBid = lot.lastBid;
        previosBidder = lot.lastBidder;
        lot.lastBid = bid_;
        lot.lastBidder = msg.sender;

        bids[lotId].push(
            Bid({
                id: bids[lotId].length,
                bidder: msg.sender,
                amount: bid_,
                timestamp: block.timestamp
            })
        );

        emit NewBid(block.timestamp, lotId, msg.sender, bid_);
    }

    /// @dev Transfers nft to auction winner, sends profit to nft owner
    /// @param lotId id of the lot to act with
    function _finishLot(uint256 lotId) internal {
        Lot storage lot = _lots[lotId];
        lot.status = Status.FINISHED;
        _transferNFT(
            address(this),
            lot.lastBidder,
            lot.nft.nftContract,
            lot.nft.tokenId,
            1
        );

        uint256 profit = _fee(lot.lastBid, lot.parameters.tokenAddress);
        if (lot.parameters.tokenAddress != WETH) {
            IERC20(lot.parameters.tokenAddress).safeTransfer(lot.owner, profit);
        } else {
            IWETH(payable(WETH)).withdraw(profit);
            if (!payable(lot.owner).send(profit)) {
                IWETH(payable(WETH)).deposit{value: profit}();
                IWETH(payable(WETH)).transfer(lot.owner, profit);
            }
        }

        _addUserActivity(lot.owner, lotId, profit, Direction.SELL);
        _addUserLots(lot.owner, lotId, UserLotType.FINISH);
        _addUserLots(lot.lastBidder, lotId, UserLotType.FINISH);
        _addUserHistory(lot.owner, lotId, profit, Direction.SELL);
        _addUserHistory(lot.lastBidder, lotId, lot.lastBid, Direction.BUY);

        emit LotFinished(block.timestamp, lotId, lot.owner, lot.lastBidder, lot.lastBid);
    }

    /// @dev Calculates fee amount and transfers it to fee address
    /// @param price the nft price in selected token
    /// @param token the fee transfer token
    /// @return profit with taking account of current fee
    function _fee(uint256 price, address token) internal returns (uint256) {
        IERC20(token).safeTransfer(
            adminPanel.feeAddress(),
            (price * adminPanel.feeX1000()) / 1000
        );
        return price - (price * adminPanel.feeX1000()) / 1000;
    }

    /// @dev Resturns lot with specific `lotId` with bids
    /// @param lotId id of lot
    function getLot(uint256 lotId) public view returns (LotOutput memory) {
        LotOutput memory lotOutput = LotOutput({
            lot: getLotNFT(lotId),
            bids: bids[lotId]
        });
        return lotOutput;
    }

    /// @dev Resturns lot with specific `lotId`
    /// @param lotId id of lot
    function getLotNFT(uint256 lotId) public view returns (Lot memory) {
        require(lotId < _lots.length, 'Not existed lotId');
        Lot memory lot = _lots[lotId];
        lot.nft.tokenURI = _tokenURI(lot.nft.nftContract, lot.nft.tokenId);
        return lot;
    }

    /// @dev Returns array of lots with `offset` and `limit`
    /// @param offset start index
    /// @param limit length of array
    function lots(uint256 offset, uint256 limit)
        external
        view
        returns (LotOutput[] memory)
    {
        LotOutput[] memory lotsOutput = new LotOutput[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (i + offset >= _lots.length) break;
            lotsOutput[i] = getLot(i + offset);
        }
        return lotsOutput;
    }

    /// @dev Returns array of lots with `offset` and `limit` with status `status`
    /// @param offset start index
    /// @param limit length of array
    /// @param status status of lot
    function lotsStatus(
        uint256 offset,
        uint256 limit,
        Status status
    ) external view returns (LotOutput[] memory) {
        LotOutput[] memory lotsOutput = new LotOutput[](limit);
        uint256 skiped = 0;
        uint256 inIndex = 0;
        uint256 outIndex = 0;

        while (inIndex < _lots.length && outIndex < limit) {
            LotOutput memory lotOutput = getLot(inIndex);

            if (lotOutput.lot.status == status) {
                if (skiped >= offset) {
                    lotsOutput[outIndex] = lotOutput;
                    outIndex++;
                } else skiped++;
            }
            inIndex++;
        }
        return lotsOutput;
    }

    /// @dev Allows to get all activites for user
    /// @param user addres of user
    /// @param offset start index
    /// @param limit length of array
    function getActivities(
        address user,
        uint256 offset,
        uint256 limit
    ) external view returns (UserActivity[] memory) {
        uint256 length = _userActivities[user].length;
        UserActivity[] memory activities_ = new UserActivity[](limit);

        for (uint256 i = 0; i < limit; i++) {
            if (length < (offset + i) + 1) break;
            activities_[i] = _userActivities[user][length - (offset + i) - 1];
        }

        return activities_;
    }

    /// @dev Allows to get all activites for user
    /// @param user addres of user
    /// @param offset start index
    /// @param limit length of array
    function getUserHistory(
        address user,
        uint256 offset,
        uint256 limit
    ) external view returns (UserHistory[] memory) {
        uint256 length = _userHistory[user].length;
        UserHistory[] memory activities_ = new UserHistory[](limit);

        for (uint256 i = 0; i < limit; i++) {
            if (length < (offset + i) + 1) break;
            activities_[i] = _userHistory[user][length - (offset + i) - 1];
        }

        return activities_;
    }

    /// @dev Allows to get all lot actions for user
    /// @param user address of user
    /// @param offset start index
    /// @param limit length of array
    function getUserLots(
        address user,
        uint256 offset,
        uint256 limit
    ) external view returns (UserLot[] memory) {
        uint256 length = _userLotType[user].length;
        UserLot[] memory lots_ = new UserLot[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (length < (offset + i) + 1) break;
            lots_[i] = _userLotType[user][length - (offset + i) - 1];
        }
        return lots_;
    }

    /// @dev Allows to get lot ids of user's lots
    /// @param user address to get his lots
    /// @param offset start index
    /// @param limit length of array
    /// @return ids of all user lots
    function userLots(
        address user,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (i + offset >= _userLots[user].length) break;
            ids[i] = _userLots[user][i + offset];
        }
        return ids;
    }

    /// @dev Allows to get ids of lots user bidded on
    /// @param user address who bidded
    /// @param offset start index
    /// @param limit length of array
    /// @return ids of user lots he bidded
    function userBids(
        address user,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (i + offset >= _userBids[user].length) break;
            ids[i] = _userBids[user][i + offset];
        }
        return ids;
    }

    /// @dev Sets new admin panel address
    /// @param newAdminPanel new admin panel address
    function setAdminPanel(address newAdminPanel) external onlyOwner {
        adminPanel = IAdminPanel(newAdminPanel);
    }
}