// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {WithdrawAnyERC20Token} from "../Utils/WithdrawAnyERC20Token.sol";
import {IRDNRegistry} from "../RDN/interfaces/IRDNRegistry.sol";


contract AMPERStaking is AccessControlEnumerable, WithdrawAnyERC20Token {
    
    IRDNRegistry public immutable registry;
    IERC20 public token;
    bool public withdrawalEnabled;

    struct Deposit {
        uint created;
        uint amount;
    }

    struct Member {
        uint stakedTotalAmount;
        uint outOfStakingAmount;
        Deposit[] deposits;
    }

    mapping (uint => Member) public members;
    uint[] public membersArr;

    struct Config {
        uint created;
        uint[2][10] rules;
    }
    Config[] public configs;

    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");
    bytes32 public constant DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");


    constructor (address _registry, address _admin) WithdrawAnyERC20Token(_admin, false) {
        registry = IRDNRegistry(_registry);

        uint[2][10] memory _rules = [
            [uint(0), uint(0)],
            [uint(0), uint(0)],
            [uint(0), uint(0)],
            [uint(2200 ether), uint(12 ether / 100)],
            [uint(3500 ether), uint(15 ether / 100)],
            [uint(5000 ether), uint(18 ether / 100)],
            [uint(7500 ether), uint(22 ether / 100)],
            [uint(11000 ether), uint(25 ether / 100)],
            [uint(16000 ether), uint(30 ether / 100)],
            [uint(25000 ether), uint(45 ether / 100)]
        ];
        Config memory _config = Config(block.timestamp, _rules);
        configs.push(_config);


        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(CONFIG_ROLE, _admin);
        _setupRole(DEPOSIT_ROLE, _admin);
    }

    function deposit(uint _userId, uint _amount, uint _outOfStakingAmount) public onlyRole(DEPOSIT_ROLE) {
        require(registry.isValidUser(_userId), "Not registered in RDN");
        require(_amount > 0, "Nothing to deposit");
        Deposit memory _deposit = Deposit(block.timestamp, _amount);
        if (members[_userId].stakedTotalAmount == 0 && members[_userId].outOfStakingAmount == 0) {
            membersArr.push(_userId);
        }
        members[_userId].stakedTotalAmount += _amount;
        members[_userId].deposits.push(_deposit);
        members[_userId].outOfStakingAmount += _outOfStakingAmount;
    }

    function income(uint _userId) public view returns(uint) {
        uint _configsCount = configs.length;
        uint _staked;
        uint _nextBreak;
        uint _income;
        uint _lastIncome;
        Member memory _member = members[_userId];
        Config memory _conf = configs[0];

        for (uint i; i < _configsCount; i++) {
            _conf = configs[i];
            if (i == (_configsCount - 1)) {
                _nextBreak = block.timestamp;
            } else {
                _nextBreak = configs[i+1].created;
            }
            if (i > 0) {
                _income += ((_conf.created - _lastIncome) * _staked * _rule(configs[i-1], _staked)) / (365 days * 10**18);
            }
            _lastIncome = _conf.created;
            for (uint j; j < _member.deposits.length; j++) {
                if ((_member.deposits[j].created > _conf.created) && (_member.deposits[j].created <= _nextBreak)) {
                    _income += ((_member.deposits[j].created - _lastIncome) * _staked * _rule(_conf, _staked)) / (365 days * 10**18);
                    _staked += _member.deposits[j].amount;
                    _lastIncome = _member.deposits[j].created;
                }
            }
        }
        _income += ((block.timestamp - _lastIncome) * _staked * _rule(_conf, _staked)) / (365 days * 10**18);
        return _income;
    }

    function rule(uint _amount) public view returns(uint) {
        return _rule(configs[configs.length - 1], _amount);
    }

    function _rule(Config memory _conf, uint _amount) pure private returns (uint) {
        uint _val;
        for (uint i; i < _conf.rules.length; i++) {
            if (_amount >= _conf.rules[i][0]) {
                _val = _conf.rules[i][1];
            } else {
                break;
            }
        }
        return _val;
    }

    function balanceSummary(uint _userId) public view returns(uint, uint, uint) {
        uint _staked = members[_userId].stakedTotalAmount;
        uint _outStaking = members[_userId].outOfStakingAmount;
        uint _income = income(_userId);
        return (_staked, _outStaking, _income);
    }

    function staked(uint _userId) public view returns(uint) {
        return members[_userId].stakedTotalAmount;
    }

    function outStaking(uint _userId) public view returns(uint) {
        return members[_userId].outOfStakingAmount;
    }

    function configRules(uint[2][10] memory _rules) public {
        Config memory _conf = Config(block.timestamp, _rules);
        configs.push(_conf);
    }

    function configStaking(address _token, bool _withdrawalEnabled) public onlyRole(CONFIG_ROLE) {
        token = IERC20(_token);
        withdrawalEnabled = _withdrawalEnabled;
    }

    function getAllMembers() public view returns(uint[] memory) {
        return membersArr;
    }
}