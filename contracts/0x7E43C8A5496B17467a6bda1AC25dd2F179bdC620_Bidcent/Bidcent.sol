/**
 *Submitted for verification at Etherscan.io on 2023-07-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract Bidcent{
    address public owner;
    address signer;
    mapping(address => uint) public balance;
    mapping(address => uint) public left_balance;
    mapping(address => uint) public right_balance;
    mapping(uint => address) left_balance_index;
    mapping(uint => address) right_balance_index;
    uint left_balance_count;
    uint right_balance_count;
    uint left_bid_total;
    uint right_bid_total;
    
    enum GameStatus{Start, Live, Payout, End}
    enum Side{None, Left, Right}
    uint game_number;
    GameStatus game_status;
    uint countdown;
    uint countdown_end;
    uint delay;
    uint fee_num;
    uint immutable max_countdown;
    uint immutable max_delay;
    uint immutable fee_den;
    uint immutable max_fee_num;
    uint min_bid_value;
    uint min_bid_total;
    uint new_countdown;
    uint new_countdown_end;
    uint new_delay;
    uint new_fee_num;
    uint new_min_bid_value;
    uint new_min_bid_total;
    uint bid_time;
    uint payout_time;
    uint chunk_number;

    struct Game{
        uint game_number;
        GameStatus game_status;
        GameConfig game_config;       
        BidStats bidstats;
        BalanceStats balancestats;
        uint bid_time;
        uint payout_time;
    }

    struct GameConfig{
        uint countdown;
        uint countdown_end;
        uint delay;
        uint fee_num;
        uint min_bid_value;
        uint min_bid_total;
    }

    struct BidStats{
        uint left_bid_total;
        uint right_bid_total;
    }

    struct BalanceStats{
        uint left_balance_count;
        uint right_balance_count;
        uint chunk_number;
    }

    struct User{
        address sender;
        uint balance;
        uint left_balance;
        uint right_balance;
    }

    event DepositEvent(
        uint time,
        address indexed sender,
        uint value,
        uint balance
    );

    event WithdrawEvent(
        uint time,
        address indexed sender,
        uint value,
        uint balance
    );

    event BidEvent(
        uint time,
        address indexed sender,
        uint value,
        Side side,
        uint fee,
        uint indexed game_number,
        GameStatus game_status,
        BidStats bidstats,
        User user
    );

    event CancelEvent(
        uint time,
        uint indexed game_number,
        address indexed sender,
        uint value,
        uint balance
    );

    event PayEvent(
        uint time,
        address indexed sender,
        uint value,
        uint balance,
        uint indexed game_number
    );

    event PreparePayoutEvent(
        uint time,
        uint indexed game_number,
        address sender,
        uint value
    );

    event PayoutEvent(
        uint time,
        uint indexed game_number,
        BidStats bidstats
    );

    event ChunkPayoutEvent(
        uint time,
        uint indexed game_number,
        BidStats bidstats,
        uint chunk_number,
        uint new_chunk_number
    );

    event NewGameEvent(
        uint time,
        uint indexed game_number
    );

    event GameConfigEvent(
        uint time,
        uint countdown,
        uint countdown_end,
        uint delay,
        uint fee_num,
        uint min_bid_value,
        uint min_bid_total
    );

    constructor() {
        owner = msg.sender;
        signer = 0xC3905e354d22430F114177FEeB03e82A27ba258F;
        game_number = 1;
        game_status = GameStatus.Start;
        countdown = 60; // 1 minute
        countdown_end = 60; // 1 minute
        delay = 30; // 30 seconds
        fee_num = 30; // numerator
        fee_den = 100; // denominator
        max_countdown = 86400; // 1 day
        max_delay = 300; // 5 minutes
        max_fee_num = 100; // Max 1% Fee
        min_bid_value = 1e16; // 0.01
        min_bid_total = 1e17; // 0.1
        new_countdown = countdown;
        new_countdown_end = countdown_end;
        new_delay = delay;
        new_fee_num = fee_num;
        new_min_bid_value = min_bid_value;
        new_min_bid_total = min_bid_total;

        left_balance_count = 1;
        right_balance_count = 1;
        left_bid_total = 1;
        right_bid_total = 1;
        chunk_number = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function changeOwner(address new_owner) public {
        require(msg.sender == signer, 'Only signer');
        owner = new_owner;
    }

    function getGame() public view returns (Game memory){
        GameConfig memory game_config = GameConfig(countdown, countdown_end, delay, fee_num, min_bid_value, min_bid_total);
        BidStats memory bidstats = BidStats(left_bid_total, right_bid_total);
        BalanceStats memory balancestats = BalanceStats(left_balance_count, right_balance_count, chunk_number);
        Game memory game = Game(game_number, game_status, game_config, bidstats, balancestats, bid_time, payout_time); 
        return game;
    }

    function getUser(address sender) public view returns(User memory){
        User memory user = User(sender, balance[sender], left_balance[sender], right_balance[sender]);
        return user;
    }

    function deposit() public payable{
        uint time = block.timestamp;
        address sender = msg.sender;
        uint value = msg.value;
        if(balance[sender]==0){
            balance[sender] += value + 1;
        }else{
             balance[sender] += value;           
        }

        emit DepositEvent(time, sender, value, balance[sender]);
    }

    function withdraw(uint value) public{
        require(balance[msg.sender] > value, 'Insufficient Balance');
        uint time = block.timestamp;
        address payable sender = payable(msg.sender);
        balance[sender] -= value;
        sender.transfer(value);

        emit WithdrawEvent(time, sender, value, balance[sender]);
    }

    function bid(uint _game_number, Side side, uint value) public{
        require(game_number == _game_number, 'Game Number mismatch');
        require(side==Side.Left || side==Side.Right, 'Left or Right');
        require(value >= min_bid_value, 'Less than min bid value');  
        GameStatus _game_status = game_status;
        require(_game_status== GameStatus.Start || _game_status==GameStatus.Live, 'Countdown has end');
        uint fee = (fee_num*value)/(fee_den*100);
        uint balance_sender = balance[msg.sender];
        require(balance_sender > value + fee, 'Insufficient Balance');

        uint time = block.timestamp;
        address sender = msg.sender;    
        
        uint left_balance_sender = left_balance[sender];
        uint right_balance_sender = right_balance[sender];

        balance[sender] = balance_sender - value - fee;
        balance[owner] += fee;
        
        if(side==Side.Left){
            left_bid_total += value;
            if(left_balance_sender == 0){
                left_balance_index[left_balance_count] = sender;
                left_balance_count++;
                left_balance[sender] += value + 1;
            }else if(left_balance_sender == 1){
                left_balance_index[left_balance_count] = sender;
                left_balance_count++;
                left_balance[sender] += value;
            }else{
                left_balance[sender] += value;
            }
        }else if(side==Side.Right){
            right_bid_total += value;
            if(right_balance_sender == 0){
                right_balance_index[right_balance_count] = sender;
                right_balance_count++;
                right_balance[sender] += value + 1;
            }else if(right_balance_sender == 1){
                right_balance_index[right_balance_count] = sender;
                right_balance_count++;
                right_balance[sender] += value;
            }else{
                right_balance[sender] += value;
            }      
        }
        User memory user = User(sender, balance[sender], left_balance[sender], right_balance[sender]);
        BidStats memory bidstats = BidStats(left_bid_total, right_bid_total);
        bid_time = time;

        if(_game_status==GameStatus.Start && left_bid_total + right_bid_total >= min_bid_total && left_bid_total > 1 && right_bid_total > 1){
            _game_status=GameStatus.Live;
            game_status = _game_status;
        }

        emit BidEvent(time, sender, value, side, fee, _game_number, _game_status, bidstats, user);
    }

    function cancelBid() public{
        require(game_status == GameStatus.Start, 'Game status not Start');
        address sender = msg.sender;
        uint left_balance_sender = left_balance[sender];
        uint right_balance_sender = right_balance[sender];        
        require(left_balance_sender > 1 || right_balance_sender > 1, 'No bids');
        uint value;
    
        if(left_balance_sender > 1){
            left_balance[sender] = 1;
            left_bid_total = left_bid_total - left_balance_sender + 1;
            value += left_balance_sender - 1;
        }
        
        if(right_balance_sender > 1){
            right_balance[sender] = 1;
            right_bid_total = right_bid_total - right_balance_sender + 1;
            value += right_balance_sender - 1;
        }
        balance[sender] += value;

        emit CancelEvent(block.timestamp, game_number, sender, value, balance[sender]);
    }

    function preparePayout() public onlyOwner{
        require(game_status == GameStatus.Live, 'Game status not Live');
        require(left_bid_total != right_bid_total, 'Draw game');
        require(block.timestamp >= bid_time + countdown, 'Not yet time to payout');
        game_status = GameStatus.Payout;
        
        uint owner_balance = balance[owner] - 1;
        balance[owner] = 1;
        payable(owner).transfer(owner_balance);
        
        emit PreparePayoutEvent(block.timestamp, game_number, owner, owner_balance);
    }

    function payout() public onlyOwner{
        require(game_status == GameStatus.Payout, 'Game status not Payout');
        address sender;
        uint sender_bid_total;
        uint win_amount;
        uint pay_amount;

        if(left_bid_total > right_bid_total){
            for(uint i = 1; i < left_balance_count;){
                sender = left_balance_index[i]; 
                sender_bid_total = left_balance[sender];
                if(sender_bid_total > 1){
                    win_amount = ((sender_bid_total - 1) * (right_bid_total - 1)) / (left_bid_total - 1);
                    pay_amount = sender_bid_total - 1 + win_amount;
                    left_balance[sender] = 1;
                    balance[sender] += pay_amount;
                    emit PayEvent(block.timestamp, sender, pay_amount, balance[sender], game_number);
                }
                unchecked {
                    i++;
                }
            }
            for(uint i=1; i < right_balance_count;){
                sender = right_balance_index[i];
                right_balance[sender] = 1;
                unchecked {
                    i++;
                }
            }
        }else if(left_bid_total < right_bid_total){
            for(uint i = 1; i < right_balance_count;){
                sender = right_balance_index[i]; 
                sender_bid_total = right_balance[sender];
                if(sender_bid_total > 1){
                    win_amount = ((sender_bid_total - 1)* (left_bid_total - 1)) / (right_bid_total - 1) ;
                    pay_amount = sender_bid_total - 1 + win_amount;
                    balance[sender] += pay_amount;
                    right_balance[sender] = 1;

                    emit PayEvent(block.timestamp, sender, pay_amount, balance[sender], game_number);
                }
                unchecked {
                    i++;
                }
            }
            for(uint i=1; i < left_balance_count;){
                sender = left_balance_index[i];
                left_balance[sender] = 1;
                unchecked {
                    i++;
                }
            }
        }
        left_balance_count = 1;
        right_balance_count = 1;
        game_status = GameStatus.End;

        BidStats memory bidstats = BidStats(left_bid_total, right_bid_total);
        payout_time = block.timestamp;

        emit PayoutEvent(block.timestamp, game_number, bidstats); 
    }

    function cashout() public{
        require(game_status == GameStatus.Live || game_status == GameStatus.Payout, 'Game status not Live or Payout');
        require(left_bid_total != right_bid_total, 'Draw game');
        require(block.timestamp >= bid_time + countdown + delay,'Not yet time to cashout');
        address sender = msg.sender;
        uint sender_bid_total;
        uint win_amount;
        uint pay_amount;
        if(left_bid_total > right_bid_total){
            require(left_balance[sender] > 1, 'No winning bids');
            sender_bid_total = left_balance[sender];
            win_amount = ((sender_bid_total - 1) * (right_bid_total - 1)) / (left_bid_total - 1);
            pay_amount = sender_bid_total - 1 + win_amount;
            left_balance[sender] = 1;
            balance[sender] += pay_amount;
        }else if(left_bid_total < right_bid_total){
            require(right_balance[sender] > 1, 'No winning bids');
            sender_bid_total = right_balance[sender];
            win_amount = ((sender_bid_total - 1) * (left_bid_total - 1)) / (right_bid_total - 1);
            pay_amount = sender_bid_total - 1 + win_amount;
            right_balance[sender] = 1;
            balance[sender] += pay_amount;
        }
        emit PayEvent(block.timestamp, sender, pay_amount, balance[sender], game_number);

        if(game_status == GameStatus.Live){
            game_status = GameStatus.Payout;
            uint owner_balance = balance[owner] - 1;
            balance[owner] = 1;
            payable(owner).transfer(owner_balance);
        
            emit PreparePayoutEvent(block.timestamp, game_number, owner, owner_balance);
        }
    }

    function chunkPayout(uint n) public onlyOwner{
        require(game_status == GameStatus.Payout, 'Game not in payout status');        
        require(n > 0, 'Minimum n is 1');
        //uint start_index = chunk_number;
        uint time = block.timestamp;
        address sender;
        uint sender_bid_total;
        uint win_amount;
        uint pay_amount;

        uint new_chunk_number = chunk_number + n;
        uint _left_balance_count = new_chunk_number;
        uint _right_balance_count = new_chunk_number;
        if(new_chunk_number > left_balance_count){
            _left_balance_count = left_balance_count;
        }
        if(new_chunk_number > right_balance_count){
            _right_balance_count = right_balance_count;
        }
        if(left_bid_total > right_bid_total){
            for(uint i = chunk_number; i < _left_balance_count;){
                sender = left_balance_index[i]; 
                sender_bid_total = left_balance[sender];
                if(sender_bid_total > 1){
                    win_amount = ((sender_bid_total - 1) * (right_bid_total - 1)) / (left_bid_total - 1);
                    pay_amount = sender_bid_total - 1 + win_amount;
                    left_balance[sender] = 1;
                    balance[sender] += pay_amount;
                    emit PayEvent(time, sender, pay_amount, balance[sender], game_number);
                }
                unchecked {
                    i++;
                }
            }
            for(uint i=chunk_number; i < _right_balance_count;){
                sender = right_balance_index[i];
                right_balance[sender] = 1;
                
                unchecked {
                    i++;
                }
            }
        }else if(left_bid_total < right_bid_total){
            for(uint i = chunk_number; i < _right_balance_count;){
                sender = right_balance_index[i]; 
                sender_bid_total = right_balance[sender];
                if(sender_bid_total > 1){
                    win_amount = ((sender_bid_total - 1)* (left_bid_total - 1)) / (right_bid_total - 1) ;
                    pay_amount = sender_bid_total - 1 + win_amount;
                    balance[sender] += pay_amount;
                    right_balance[sender] = 1;

                    emit PayEvent(time, sender, pay_amount, balance[sender], game_number);
                }
                unchecked {
                    i++;
                }
            }
            for(uint i = chunk_number; i < _left_balance_count;){
                sender = left_balance_index[i];
                left_balance[sender] = 1;
                unchecked {
                    i++;
                }
            }
        }

        BidStats memory bidstats = BidStats(left_bid_total, right_bid_total);
        if(new_chunk_number >= left_balance_count && new_chunk_number >= right_balance_count){
            chunk_number = 1;
            left_balance_count = 1;
            right_balance_count = 1;
            game_status = GameStatus.End;
            payout_time = time;

            emit PayoutEvent(time, game_number, bidstats); 
        }else{
            emit ChunkPayoutEvent(time, game_number, bidstats, chunk_number, new_chunk_number);
            chunk_number = new_chunk_number;
        }
    }

    function startNewGame() public onlyOwner{
        require(game_status==GameStatus.End, 'Game has not ended');
        game_number += 1;
        game_status = GameStatus.Start;
        countdown = new_countdown;
        countdown_end = new_countdown_end;
        delay = new_delay;
        fee_num = new_fee_num;
        min_bid_value = new_min_bid_value;
        min_bid_total = new_min_bid_total;

        left_bid_total = 1;
        right_bid_total = 1;

        emit NewGameEvent(block.timestamp, game_number);
    }

    function setGameConfig(uint _new_countdown, uint _new_countdown_end, uint _new_delay, uint _new_fee_num, uint _new_min_bid_value, uint _new_min_bid_total) public onlyOwner{
        require(_new_fee_num <= max_fee_num, 'New fee is more than max fee');
        require(_new_countdown <= max_countdown, 'Countdown cannot be more than max countdown');
        require(_new_delay <= max_delay, 'Delay cannot be more than max delay');
        
        new_countdown = _new_countdown;
        new_countdown_end = _new_countdown_end;
        new_delay = _new_delay;
        new_fee_num = _new_fee_num;
        new_min_bid_value = _new_min_bid_value;
        new_min_bid_total = _new_min_bid_total;

        emit GameConfigEvent(block.timestamp, new_countdown, new_countdown_end, new_delay, new_fee_num, new_min_bid_value, new_min_bid_total);
    }
}