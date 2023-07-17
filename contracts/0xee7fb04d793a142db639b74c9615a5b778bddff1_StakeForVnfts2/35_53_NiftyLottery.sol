pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VNFT.sol";
import "./MuseToken.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract NiftyLottery is Ownable, TokenRecover {
    using SafeMath for uint256;
    VNFT public immutable vnft;
    MuseToken public immutable muse;
    uint256 public gem;

    mapping(uint256 => address[]) public players;
    mapping(uint256 => mapping(address => uint256)) public ticketsByPlayers;

    uint256 public currentVNFT = 0;
    uint256 public currentRound = 0;
    uint256 public end = 0;
    uint256 public start = 0;

    uint256 public randomBlockSize = 3;

    address winner1;
    address winner2;
    address winner3;
    address winner4;

    // overflow
    uint256 public MAX_INT = 2**256 - 1;

    event LotteryStarted(
        uint256 round,
        uint256 start,
        uint256 end,
        uint256 vnftId,
        uint256 gemId
    );
    event LotteryEnded(
        uint256 round,
        uint256 vnftId,
        uint256 musePrize,
        address winner1,
        address winner2,
        address winner3,
        address winner4
    );

    event LotteryTicketBought(address participant, uint256 tickets);

    constructor(VNFT _vnft, MuseToken _muse) public {
        vnft = _vnft;
        muse = _muse;
    }

    function startLottery(uint256 _gem, uint256 _days) external onlyOwner {
        gem = _gem;
        currentRound = currentRound + 1;
        end = now + _days * 1 days;
        start = now;
        muse.approve(address(vnft), MAX_INT);
        vnft.mint(address(this));
        currentVNFT = vnft.tokenOfOwnerByIndex(address(this), vnft.balanceOf(address(this)) - 1);
        emit LotteryStarted(currentRound, start, end, currentVNFT, gem);
    }

    function getInfos(address player)
        public
        view
        returns (
            uint256 _participants,
            uint256 _end,
            uint256 _start,
            uint256 _museSize,
            uint256 _gem,
            uint256 _currentVNFT,
            uint256 _gemPrice,
            uint256 _ownerTickets,
            uint256 _currentRound
        )
    {
        _participants = players[currentRound].length;
        _end = end;
        _start = start;
        _museSize = muse.balanceOf(address(this));
        _gem = gem;
        _currentVNFT = currentVNFT;
        _gemPrice = vnft.itemPrice(gem);
        _ownerTickets = ticketsByPlayers[currentRound][player];
        _currentRound = currentRound;
    }

    function buyTicket(address _player) external {
        require(start != 0, "The lottery did not start yet");
        if (now > end) {
            endLottery();
            return;
        }

        uint256 lastTimeMined = vnft.lastTimeMined(currentVNFT);
        uint8 tickets = 1;

        require(
            muse.transferFrom(msg.sender, address(this), vnft.itemPrice(gem))
        );
        vnft.buyAccesory(currentVNFT, gem);

        // We mine if possible, the person that get the feeding transaction gets an extra ticket
        if (lastTimeMined + 1 days < now) {
            vnft.claimMiningRewards(currentVNFT);
            tickets = 2;
        }

        for (uint256 i = 0; i < tickets; i++) {
            players[currentRound].push(_player);
            ticketsByPlayers[currentRound][_player] =
                ticketsByPlayers[currentRound][_player] +
                1;
        }
        emit LotteryTicketBought(_player, tickets);
    }

    function endLottery() public {
        require(now > end && end != 0);
        uint256 museBalance = muse.balanceOf(address(this));

        end = 0;
        start = 0;

        // pick first winner (the vNFT)
        winner1 = players[currentRound][randomNumber(
            block.number,
            players[currentRound].length
        )];
        vnft.safeTransferFrom(address(this), winner1, currentVNFT);

        // pick second winner (50% muse)
        winner2 = players[currentRound][randomNumber(
            block.number - 1,
            players[currentRound].length
        )];
        require(muse.transfer(winner2, museBalance.mul(37).div(100)));

        // pick third winner (25% muse)
        winner3 = players[currentRound][randomNumber(
            block.number - 3,
            players[currentRound].length
        )];
        require(muse.transfer(winner3, museBalance.mul(19).div(100)));

        // pick fourth winner (25% muse)
        winner4 = players[currentRound][randomNumber(
            block.number - 4,
            players[currentRound].length
        )];
        require(muse.transfer(winner4, museBalance.mul(19).div(100)));

        //burn the leftover (25%)
        muse.burn(muse.balanceOf(address(this)));

        emit LotteryEnded(
            currentRound,
            currentVNFT,
            museBalance,
            winner1,
            winner2,
            winner3,
            winner4
        );
    }

    /* generates a number from 0 to 2^n based on the last n blocks */
    function randomNumber(uint256 seed, uint256 max)
        public
        view
        returns (uint256 _randomNumber)
    {
        uint256 n = 0;
        for (uint256 i = 0; i < randomBlockSize; i++) {
            if (
                uint256(
                    keccak256(
                        abi.encodePacked(blockhash(block.number - i - 1), seed)
                    )
                ) %
                    2 ==
                0
            ) n += 2**i;
        }
        return n % max;
    }
}