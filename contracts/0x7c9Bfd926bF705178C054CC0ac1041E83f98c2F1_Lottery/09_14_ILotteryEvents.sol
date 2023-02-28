// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface ILotteryEvents {
    event RaffleCreated(
        uint256 _raffleNumber,
        string _raffleName,
        uint16 _maxTickets,
        uint256 _ticketPrice,
        uint32 _startTime,
        uint32 _endTime,
        uint16 rewardPercent,
        address _rewardToken
    );

    event BurnWalletUpdated(address burnWallet);

    event ProfitWallet1Updated(address _profitWallet1);

    event ProfitWallet2Updated(address _profitWallet2);

    event ProfitSplitPercentUpdated(uint16 _split1BP, uint256 _split2BP);

    event BuyTicket(
        uint256 raffleNumber,
        address _buyer,
        uint16 _ticketStart,
        uint16 _ticketCounter,
        uint256 _BurnAmountPerRaffle,
        uint256 _totalRevenue,
        uint256 _profitAmount
    );

    event RewardClaimed(
        uint256 _raffleId,
        address _to,
        address _rewardToken,
        uint256 _amount
    );

    event burnCollected(uint256 _amount, address _to);

    event WinnerDeclared(
        uint256 _raffleId,
        uint256 winningTicket,
        address _winner,
        uint256 _tokenAmount,
        uint256 _rewardInEth
    );

    event BurnAndProfitPercentUpdated(uint16 _burnPercent, uint16 _profitPercent);

    event AdminChanged(address _newAdmin);

    event OperatorChanged(address _newOperator);

    event RewardTokenUpdate(uint256 _raffleNumber, address _rewardToken);

    event taxBPUpdated(uint16 _taxBP);

}