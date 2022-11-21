// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Token.sol";
import "./Events.sol";

contract Lottery is Token, Events {
    uint256 public _round_interval;
    uint256 public _ticket_price;
    uint256 public _ticket_price_cl;
    uint256 public _fee;
    uint256 public _fee_value;
    uint256 public _token_reward;
    uint256 public _purchased_tickets;
    uint256 public _purchased_free_tickets;
    uint256 public _all_eth_reward;
    uint[12] public _tiers;
    uint[3] public _percent;
    uint public _promotion_money;
    uint256 private _secret_key;
    uint256 public _next_game_reward;
    address payable public _lottery_owner;
    
    modifier onlyOwner {
      require(msg.sender == _lottery_owner, "You are not an owner");
      _;
    }
   
    enum RoundStatus {
        End,
        Start
    }

    mapping(address => TicketRef[]) private _tickets_ref;
    mapping(address => uint256) private _free_tickets;

    Round[] public _rounds;
    Ticket[] public _tickets;

    constructor(
        uint256 round_interval,
        uint256 ticket_price,
        uint256 ticket_price_cl,
        uint256 fee,
        uint256 next_game_reward
    ) {
        _round_interval = round_interval;
        _ticket_price = ticket_price;
        _ticket_price_cl = ticket_price_cl;
        _fee = fee;
        _lottery_owner = payable(msg.sender);
        _percent[0] = 3;
        _percent[1] = 10;
        _percent[2] = 30;
        _next_game_reward = next_game_reward;
    }

    struct Round {
        uint256 startTime;
        uint256 endTime;
        RoundStatus status;
        uint256[] win;
        uint256 number;
        uint tickets;
    }

    struct TicketRef {
        uint256 round;
        uint256 number;
    }

    struct Ticket {
        address owner;
        uint256[6] numbers;
        uint256 win_count;
        bool win_last_digit;
        uint256 eth_reward;
        uint256 token_reward;
        bool free_ticket;
        uint256 round;
        uint256 number;
        bool paid;
        uint256 time;
        uint256 tier;
    }

    function createRound() internal {
        if (
            _rounds.length > 0 &&
            _rounds[_rounds.length - 1].status != RoundStatus.End
        ) {
            revert("Error: the last round in progress");
        }

        uint256[] memory win;

        Round memory round = Round(
            block.timestamp,
            block.timestamp + _round_interval,
            RoundStatus.Start,
            win,
            _rounds.length,
            0
        );

        _rounds.push(round);

        _mint(msg.sender, _next_game_reward);

        _token_reward += _next_game_reward;

        emit CreateRoundEvent(
            _rounds.length, 
            _next_game_reward, 
            msg.sender, 
            block.timestamp
        );
    }

    function buyTicket(uint256[6] memory _numbers) external payable {
        require(_ticket_price == msg.value, "not valid value");
        require(
            _rounds[_rounds.length - 1].status == RoundStatus.Start,
            "Error: the last round ended"
        );

        Ticket memory ticket = Ticket(
            msg.sender,
            _numbers,
            0,
            false,
            0,
            0,
            false,
            _rounds.length - 1,
            _tickets.length,
            false,
            block.timestamp,
            0
        );

        TicketRef memory ticket_ref = TicketRef(
            _rounds.length - 1,
            _tickets.length
        );

        _rounds[_rounds.length - 1].tickets += 1;
        _purchased_tickets += 1;

        _tickets.push(ticket);
        _tickets_ref[msg.sender].push(ticket_ref);

        _fee_value += (_fee * msg.value) / 100;

        emit BuyTicketEvent( 
            _tickets.length,
             msg.sender,
            _numbers,
            block.timestamp
        );

    }

    function buyFreeTicket(uint256[6] memory _numbers) external {
        require(_free_tickets[msg.sender] > 0, "You do not have a free ticket");
        require(
            _rounds[_rounds.length - 1].status == RoundStatus.Start,
            "Error: the last round ended"
        );

        Ticket memory ticket = Ticket(
            msg.sender,
            _numbers,
            0,
            false,
            0,
            0,
            false,
            _rounds.length - 1,
            _tickets.length,
            false,
            block.timestamp,
            0
        );

        TicketRef memory ticket_ref = TicketRef(
            _rounds.length - 1,
            _tickets.length
        );
        
        _tickets.push(ticket);
        _tickets_ref[msg.sender].push(ticket_ref);

        _rounds[_rounds.length - 1].tickets += 1;
        _purchased_free_tickets += 1;
        _free_tickets[msg.sender] -= 1;

        emit BuyFreeTicketEvent(
            _tickets.length,
             msg.sender,
            _numbers,
            block.timestamp
        );
    }

    function buyCLTicket(uint256[6] memory _numbers) external {

        require(
            _rounds[_rounds.length - 1].status == RoundStatus.Start,
            "Error: the last round ended"
        );

        _burn(msg.sender, _ticket_price_cl);

        Ticket memory ticket = Ticket(
            msg.sender,
            _numbers,
            0,
            false,
            0,
            0,
            false,
            _rounds.length - 1,
            _tickets.length,
            false,
            block.timestamp,
            0
        );

        TicketRef memory ticket_ref = TicketRef(
            _rounds.length - 1,
            _tickets.length
        );
        
        _tickets.push(ticket);
        _tickets_ref[msg.sender].push(ticket_ref);

        _rounds[_rounds.length - 1].tickets += 1;
        _purchased_tickets += 1;

        emit BuyCLTicketEvent(
            _tickets.length,
             msg.sender,
            _numbers,
            block.timestamp
        );
    }

    function _random(uint256 key) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        key,
                        block.difficulty,
                        block.timestamp,
                        block.coinbase
                    )
                )
            );
    }

    function lastCombination() internal {
        if (_rounds[_rounds.length - 1].win.length == 0) {
            uint256[6] memory _cache;
            uint256 _num;

            for (uint256 i = 0; i < 6; i++) {
                if (i < 5) {
                    _secret_key += 1;
                    uint256 _number = _random(_secret_key) % 69;
                    _cache[i] = _number + 1;
                } else {
                    _secret_key += 1;
                    uint256 _number = _random(_secret_key) % 26;
                    _cache[i] = _number + 1;
                }
            }

            for (uint256 i = 0; i < _cache.length; i++) {
                for (uint256 z = 0; z < _cache.length; z++) {
                    if (_cache[i] == _cache[z]) {
                        _num += 1;
                    }
                }
            }

            if (_num > 6) {
                lastCombination();
            } else {
                _rounds[_rounds.length - 1].win = _cache;
            }
        } else {
            revert("Error: the win combination already exist");
        }
    }

    function closeRound() internal {
        if (_rounds[_rounds.length - 1].status == RoundStatus.End) {
            revert("The round end");
        }

        if (block.timestamp < _rounds[_rounds.length - 1].endTime) {
            revert("The round can't closed");
        }

        _rounds[_rounds.length - 1].status = RoundStatus.End;

        lastCombination();
    }
    
    function claimPay(uint256 number) internal {
        require(
            msg.sender == _tickets[number].owner,
            "You are not an owner"
        );
        require(
            _rounds[_tickets[number].round].status == RoundStatus.End,
            "The Round is in process"
        );

        require(_tickets[number].paid == false, "The Ticket was paid");

        _tickets[number].paid = true;

        if (_tickets[number].free_ticket) {
            _free_tickets[_tickets[number].owner] += 1;
        }
        if (_tickets[number].eth_reward > 0) {
            payable(_tickets[number].owner).transfer(
                _tickets[number].eth_reward
            );
        }

        if (_tickets[number].token_reward > 0) {
            _mint(
                _tickets[number].owner,
                _tickets[number].token_reward
            );
        }

        emit ClaimTicketRewardEvent(
            _tickets[number].tier,
            _tickets[number].free_ticket,
            _tickets[number].token_reward,
            _tickets[number].eth_reward
        );
    }

    function getTicketWinNumbers(uint256 number) internal {
        
        require(_tickets[number].win_count == 0, "Win numbers already exist");

        uint256[] memory _numbers = _rounds[_tickets[number].round].win;
        

        for (
            uint256 z = 0;
            z < _tickets[number].numbers.length;
            z++
        ) {
            for (uint256 y = 0; y < _numbers.length; y++) {
                if (_tickets[number].numbers[z] == _numbers[y]) {
                    _tickets[number].win_count += 1;

                    if (_numbers[y] == 6) {
                        _tickets[number].win_last_digit = true;
                    }
                }
            }
        }
    }

    function addTicketReward(uint number) internal {

      require(_tickets[number].tier == 0, "Already exist");

        /* 
      0 - free ticket + 250 CL
      1 - 500 CL
      
      0 + 1 - x2 + 1000 CL
      1 + 1 x2 + 2000 CL  
      2 - x2 + 2000 CL
      
      2 + 1 - x5 + 5000 CL
      3 - x10 + 10000 CL
      3 + 1 - x50  + 50000  CL
      4 + 0 - x100 + 100000 CL
       
      // jackpots
 
      4 + 1 - 2% of bank
      5 + 0 - 10% of bank
      5 + 1 - 30% of bank
 
     */

            if (_tickets[number].win_count == 0) {
                _tickets[number].token_reward = 250 * 10**18;
                _tickets[number].free_ticket = true;

                _token_reward += _tickets[number].token_reward;
                _tickets[number].tier = 1;
                _tiers[0] += 1;
            }

            if (
                _tickets[number].win_count == 1 &&
                _tickets[number].win_last_digit == false
            ) {
                _tickets[number].token_reward = 500 * 10**18;
                _token_reward += _tickets[number].token_reward;
                _tickets[number].tier = 2;
                _tiers[1] += 1;
            }

            if (
                _tickets[number].win_count == 1 &&
                _tickets[number].win_last_digit == true
            ) {
                _tickets[number].eth_reward = _ticket_price * 2;
                _tickets[number].token_reward = 1000 * 10**18;
                _token_reward += _tickets[number].token_reward;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 3;

                _tiers[2] += 1;
            }

            if (
                _tickets[number].win_count == 2 &&
                _tickets[number].win_last_digit == false
            ) {
                _tickets[number].eth_reward = _ticket_price * 2;
                _tickets[number].token_reward = 2000 * 10**18;
                _token_reward += _tickets[number].token_reward;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 4;

                _tiers[3] += 1;
            }

            if (
                _tickets[number].win_count == 2 &&
                _tickets[number].win_last_digit == true
            ) {
                _tickets[number].eth_reward = _ticket_price * 2;
                _tickets[number].token_reward = 2000 * 10**18;
                _token_reward += _tickets[number].token_reward;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 5;

                _tiers[4] += 1;
            }

            if (
                _tickets[number].win_count == 3 &&
                _tickets[number].win_last_digit == true
            ) {
                _tickets[number].eth_reward = _ticket_price * 5;
                _tickets[number].token_reward = 5000 * 10**18;
                _token_reward += _tickets[number].token_reward;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 6;

                _tiers[5] += 1;
            }

            if (
                _tickets[number].win_count == 3 &&
                _tickets[number].win_last_digit == false
            ) {
                _tickets[number].eth_reward = _ticket_price * 10;
                _tickets[number].token_reward = 10000 * 10**18;

                _token_reward += _tickets[number].token_reward;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 7;

                _tiers[6] += 1;
            }

            if (
                _tickets[number].win_count == 4 &&
                _tickets[number].win_last_digit == true
            ) {
                _tickets[number].eth_reward = _ticket_price * 50;
                _tickets[number].token_reward = 50000 * 10**18;
                _token_reward += _tickets[number].token_reward;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 8;

                _tiers[7] += 1;
            }

            if (
                _tickets[number].win_count == 4 &&
                _tickets[number].win_last_digit == false
            ) {
                _tickets[number].eth_reward =
                    _ticket_price *
                    100;
                _tickets[number].token_reward = 100000 * 10**18;

                _token_reward += _tickets[number].token_reward;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 9;

                _tiers[8] += 1;
            }

            if (
                _tickets[number].win_count == 5 &&
                _tickets[number].win_last_digit == true
            ) {
                _tickets[number].eth_reward =
                    (_percent[0] * address(this).balance) /
                    100;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 10;

                _tiers[9] += 1;
            }

            if (
                _tickets[number].win_count == 5 &&
                _tickets[number].win_last_digit == false
            ) {
                _tickets[number].eth_reward =
                    (_percent[1] * address(this).balance) /
                    100;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 11;

                _tiers[10] += 1;
            }

            if (
                _tickets[number].win_count == 6 &&
                _tickets[number].win_last_digit == true
            ) {
                _tickets[number].eth_reward =
                    (_percent[2] * address(this).balance) /
                    100;

                _all_eth_reward += _tickets[number].eth_reward;

                _tickets[number].tier = 12;

                _tiers[11] += 1;
            }
        
    }

    function claimTicketReward (uint number) external {
        getTicketWinNumbers(number);
        addTicketReward(number);
        claimPay(number);
    } 

    function claimOwnerEthReward(uint number) external onlyOwner {
        require(_fee_value >= number, "not enough of eth");
        payable(_lottery_owner).transfer(_fee_value);
        _fee_value -= number;
    }

    function claimOwnerTokenReward(uint number) external onlyOwner {
        require(_token_reward >= number, "not enough of tokens");
        _mint(_lottery_owner, number);
        _token_reward -= number;
    }

    function getRoundsCount() external view returns (uint256) {
        return _rounds.length;
    }

    function getTicketsCount() external view returns (uint256) {
        return _tickets.length;
    }

    function getRoundTicketCount(uint round) external view returns (uint256) {
        return _rounds[round].tickets;
    }

    function getLastRoundTicketCount() external view returns (uint256) {
        return _rounds[_rounds.length - 1].tickets;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getWinnerTiers() external view returns (uint[12] memory winners) {
        return _tiers;
    }

    function getTicketRef(address user)
        external
        view
        returns (TicketRef[] memory ref)
    {
        TicketRef[] memory ref_ = new TicketRef[](_tickets_ref[user].length);

        for (uint256 i = 0; i < _tickets_ref[user].length; i++) {
            ref_[i] = _tickets_ref[user][i];
        }

        return ref_;
    }

    function getRoundById(uint256 id)
        external
        view
        returns (Round[] memory _round)
    {
        Round[] memory round = new Round[](1);
        round[0] = _rounds[id];
        return round;
    }

    function getLastRound() external view returns (Round[] memory _round) {
        Round[] memory round = new Round[](1);
        round[0] = _rounds[_rounds.length - 1];
        return round;
    }

    function getLastRounds(uint256 cursor, uint256 howMany)
        external
        view
        returns (
            Round[] memory rounds,
            uint256 oldCursor,
            uint256 newCursor,
            uint256 total
        )
    {
        uint256 length = howMany;
        uint256 _total = _rounds.length;
        if (length > _rounds.length - cursor) {
            length = _rounds.length - cursor;
        }
     
        Round[] memory __array = new Round[](length);

        for (uint256 i = 0; i < length; i++) {
            __array[i] = _rounds[_total - cursor - i - 1];
        }

        return (__array, cursor, cursor + length, _total);
    }

    function getLastTickets(uint256 cursor, uint256 howMany)
        external
        view
        returns (
            Ticket[] memory tickets,
            uint256 oldCursor,
            uint256 newCursor,
            uint256 total
        )
    {
        uint256 length = howMany;
        uint256 _total = _tickets.length;
        if (length > _tickets.length - cursor) {
            length = _tickets.length - cursor;
        }
        
        Ticket[] memory __array = new Ticket[](length);

        for (uint256 i = 0; i < length; i++) {
            __array[i] = _tickets[_total - cursor - i - 1];
        }

        return (__array, cursor, cursor + length, _total);
    }

    function getUserTickets(
        address user,
        uint256 cursor,
        uint256 howMany
    )
        external
        view
        returns (
            Ticket[] memory tickets,
            uint256 oldCursor,
            uint256 newCursor,
            uint256 total
        )
    {
        uint256 length = howMany;
        uint256 _total = _tickets_ref[user].length;
        if (length > _tickets_ref[user].length - cursor) {
            length = _tickets_ref[user].length - cursor;
        }

        Ticket[] memory __array = new Ticket[](length);

        for (uint256 i = 0; i < length; i++) {

            __array[i] = _tickets[_tickets_ref[user][_total - cursor - i - 1].number];
        }

        return (__array, cursor, cursor + length, _total);
    }

    function getUserFreeTicketsCount(address user)
        external
        view
        returns (uint256)
    {
        return _free_tickets[user];
    }


    function changeRoundInterval(uint256 interval) external onlyOwner {
        _round_interval = interval;
    }

    function changeTicketPrice(uint256 price) external onlyOwner {
        _ticket_price = price;
    }

    function changeTicketCLPrice(uint price) external onlyOwner{
        _ticket_price_cl = price;
    }

    function changeFee(uint256 fee) external onlyOwner {
        require(fee >= 1 && fee <= 20, "Error: Badly range");
        _fee = fee;
    }
    
    function changeReward(uint256 reward) external onlyOwner {
        _next_game_reward = reward;
    }

    function changePercent(uint256 _percent0, uint256 _percent1, uint256 _percent2) external onlyOwner {
        require(_percent0 >= 3, "Percent can't be less than");
        require(_percent1 >= 10, "Percent can't be less than");
        require(_percent2 >= 30, "Percent can't be less than");

        _percent[0] = _percent0;
        _percent[1] = _percent1;
        _percent[2] = _percent2;
    }

    function addPromoMoney() external payable onlyOwner {
        _promotion_money += msg.value;
    }

    function withdrawPromoMoney(uint value) external onlyOwner {
        require(_promotion_money >= value, "Not enough");
        payable(_lottery_owner).transfer(value);
        _promotion_money -= value;
    }

    function nextGame() external {
        if (_rounds.length > 0) {
            closeRound();
        }

        createRound();
    }

    receive() external payable {}
}