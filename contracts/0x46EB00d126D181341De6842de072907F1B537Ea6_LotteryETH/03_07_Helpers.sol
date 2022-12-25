// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./Declerations.sol";
import "./TransferHelper.sol";

contract Helpers is Declerations, TransferHelper {

    function _setRequested(
        uint256 _lotteryIndex
    )
        internal
    {
        baseData[_lotteryIndex].status = Status.REQUEST_ORACLE;
        baseData[_lotteryIndex].timeLastRequest = block.timestamp;
    }

    function _setFinalized(
        uint256 _lotteryIndex
    )
        internal
    {
        baseData[_lotteryIndex].status = Status.FINALIZED;
    }

    function _increaseLotteryCount()
        internal
    {
        lotteryCount += 1;
    }

    function getStatus(
        uint256 _lotteryIndex
    )
        public
        view
        returns (Status)
    {
        return baseData[_lotteryIndex].status;
    }

    function _getTicketPrice(
        uint256 _totalPrice,
        uint256 _ticketCount
    )
        internal
        pure
        returns (uint256 res)
    {
        res = _totalPrice
            / _ticketCount;
    }

    function _getRetry(
        uint256 _lotteryIndex
    )
        internal
        view
        returns (bool)
    {
        return block.timestamp > _nextRetry(
            _lotteryIndex
        );
    }

    function _nextRetry(
        uint256 _lotteryIndex
    )
        internal
        view
        returns (uint256)
    {
        return baseData[_lotteryIndex].timeLastRequest + SECONDS_IN_DAY;
    }

    function applyUsageFee(
        uint256 _usageFee,
        uint256 _soldAmount
    )
        public
        pure
        returns (uint256)
    {
        return _soldAmount * _usageFee / PERCENT_BASE;
    }

    function calculateSoldAmount(
        uint256 _lotteryIndex
    )
        public
        view
        returns (uint256 res)
    {
        res = ticketData[_lotteryIndex].ticketPrice
            * ticketData[_lotteryIndex].soldTickets;
    }

    function _getDeadline(
        uint256 _secondsToPass
    )
        internal
        view
        returns (uint256)
    {
        return block.timestamp + _secondsToPass;
    }

    function _enoughTickets(
        uint256 _lotteryIndex,
        uint256 _numberTickets
    )
        internal
        view
    {
        if (hasEnoughTickets(_lotteryIndex, _numberTickets) == false) {
            revert("Helpers: NOT_ENOUGH_TICKETS_LEFT");
        }
    }

    function hasEnoughTickets(
        uint256 _lotteryIndex,
        uint256 _numberTickets
    )
        public
        view
        returns (bool)
    {
        return ticketData[_lotteryIndex].totalTickets
            >= ticketData[_lotteryIndex].soldTickets + _numberTickets;
    }

    function readyForOracle(
        uint256 _lotteryIndex
    )
        public
        view
        returns (bool)
    {
        if (block.timestamp > baseData[_lotteryIndex].closingTime) {
            return true;
        }

        TicketData memory tickets = ticketData[
            _lotteryIndex
        ];

        if (tickets.soldTickets == tickets.totalTickets) {
            return true;
        }

        return false;
    }

    function _getLuckyNumber(
        uint256 _lotteryIndex
    )
        internal
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        uint256 luckyNumber = ticketData[_lotteryIndex]
            .luckyNumber;

        uint256 soldAmount = calculateSoldAmount(
            _lotteryIndex
        );

        return (
            tickets[_lotteryIndex][luckyNumber],
            luckyNumber,
            soldAmount
        );
    }

    function _createLottery(
        address _owner,
        address _nftAddress,
        uint256 _nftId,
        address _sellToken,
        uint256 _totalPrice,
        uint256 _ticketCount,
        uint256 _time
    )
        internal
    {
        uint256 deadline = _getDeadline(
            _time
        );

        uint256 ticketPrice = _getTicketPrice(
            _totalPrice,
            _ticketCount
        );

        baseData[lotteryCount] = BaseData({
            status: Status.PURCHASING,
            owner: _owner,
            winner: ZERO_ADDRESS,
            nftAddress: _nftAddress,
            sellToken: _sellToken,
            nftId: _nftId,
            closingTime: deadline,
            timeLastRequest: 0
        });

        ticketData[lotteryCount] = TicketData({
            totalPrice: _totalPrice,
            ticketPrice: ticketPrice,
            totalTickets: _ticketCount,
            luckyNumber: 0,
            soldTickets: 0
        });
    }

    function _closeRound(
        uint256 _lotteryIndex,
        uint256 _luckyNumber,
        address _winnerAddress
    )
        internal
    {
        baseData[_lotteryIndex].winner = _winnerAddress;
        baseData[_lotteryIndex].closingTime = block.timestamp;
        ticketData[_lotteryIndex].luckyNumber = _luckyNumber;
    }

    function uniform(
        uint256 _entropy,
        uint256 _upperBound
    )
        public
        pure
        returns (uint256)
    {
        uint256 min = (type(uint256).max - _upperBound + 1)
            % _upperBound;

        uint256 random = _entropy;

        while (true) {
            if (random >= min) {
                break;
            }

            random = uint256(
                keccak256(
                    abi.encodePacked(
                        random
                    )
                )
            );
        }

        return random
            % _upperBound;
    }
}