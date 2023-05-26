/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface ve {
    function locked__end(address) external view returns (uint);
    function deposit_for(address, uint) external;
}

interface delegate {
    function get_adjusted_ve_balance(address, address) external view returns (uint);
}

interface Gauge {
    function deposit_reward_token(address, uint) external;
}

contract GaugeProxy {
    address constant _rkp3r = 0xEdB67Ee1B171c4eC66E6c10EC43EDBbA20FaE8e9;
    address constant _vkp3r = 0x2FC52C61fB0C03489649311989CE2689D93dC1a2;
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    uint public totalWeight;

    address public gov;
    address public nextgov;
    uint public commitgov;
    uint public constant delay = 1 days;

    address[] internal _tokens;
    mapping(address => address) public gauges; // token => gauge
    mapping(address => uint) public weights; // token => weight
    mapping(address => mapping(address => uint)) public votes; // msg.sender => votes
    mapping(address => address[]) public tokenVote;// msg.sender => token
    mapping(address => uint) public usedWeights;  // msg.sender => total voting weight of user
    mapping(address => bool) public enabled;

    function tokens() external view returns (address[] memory) {
        return _tokens;
    }

    constructor() {
        gov = msg.sender;
    }

    modifier g() {
        require(msg.sender == gov);
        _;
    }

    function setGov(address _gov) external g {
        nextgov = _gov;
        commitgov = block.timestamp + delay;
    }

    function acceptGov() external {
        require(msg.sender == nextgov && commitgov < block.timestamp);
        gov = nextgov;
    }

    function reset() external {
        _reset(msg.sender);
    }

    function _reset(address _owner) internal {
        address[] storage _tokenVote = tokenVote[_owner];
        uint _tokenVoteCnt = _tokenVote.length;

        for (uint i = 0; i < _tokenVoteCnt; i ++) {
            address _token = _tokenVote[i];
            uint _votes = votes[_owner][_token];

            if (_votes > 0) {
                totalWeight -= _votes;
                weights[_token] -= _votes;
                votes[_owner][_token] = 0;
            }
        }

        delete tokenVote[_owner];
    }

    function poke(address _owner) public {
        address[] memory _tokenVote = tokenVote[_owner];
        uint _tokenCnt = _tokenVote.length;
        uint[] memory _weights = new uint[](_tokenCnt);

        uint _prevUsedWeight = usedWeights[_owner];
        uint _weight = delegate(_vkp3r).get_adjusted_ve_balance(_owner, ZERO_ADDRESS);

        for (uint i = 0; i < _tokenCnt; i ++) {
            uint _prevWeight = votes[_owner][_tokenVote[i]];
            _weights[i] = _prevWeight * _weight / _prevUsedWeight;
        }

        _vote(_owner, _tokenVote, _weights);
    }

    function _vote(address _owner, address[] memory _tokenVote, uint[] memory _weights) internal {
        // _weights[i] = percentage * 100
        _reset(_owner);
        uint _tokenCnt = _tokenVote.length;
        uint _weight = delegate(_vkp3r).get_adjusted_ve_balance(_owner, ZERO_ADDRESS);
        uint _totalVoteWeight = 0;
        uint _usedWeight = 0;

        for (uint i = 0; i < _tokenCnt; i ++) {
            _totalVoteWeight += _weights[i];
        }

        for (uint i = 0; i < _tokenCnt; i ++) {
            address _token = _tokenVote[i];
            address _gauge = gauges[_token];
            uint _tokenWeight = _weights[i] * _weight / _totalVoteWeight;

            if (_gauge != address(0x0)) {
                _usedWeight += _tokenWeight;
                totalWeight += _tokenWeight;
                weights[_token] += _tokenWeight;
                tokenVote[_owner].push(_token);
                votes[_owner][_token] = _tokenWeight;
            }
        }

        usedWeights[_owner] = _usedWeight;
    }

    function vote(address[] calldata _tokenVote, uint[] calldata _weights) external {
        require(_tokenVote.length == _weights.length);
        _vote(msg.sender, _tokenVote, _weights);
    }

    function addGauge(address _token, address _gauge) external g {
        require(gauges[_token] == address(0x0), "exists");
        _safeApprove(_rkp3r, _gauge, type(uint).max);
        gauges[_token] = _gauge;
        enabled[_token] = true;
        _tokens.push(_token);
    }

    function disable(address _token) external g {
        enabled[_token] = false;
    }

    function enable(address _token) external g {
        enabled[_token] = true;
    }

    function length() external view returns (uint) {
        return _tokens.length;
    }

    function distribute() external g {
        uint _balance = erc20(_rkp3r).balanceOf(address(this));
        if (_balance > 0 && totalWeight > 0) {
            uint _totalWeight = totalWeight;
            for (uint i = 0; i < _tokens.length; i++) {
                if (!enabled[_tokens[i]]) {
                    _totalWeight -= weights[_tokens[i]];
                }
            }
            for (uint x = 0; x < _tokens.length; x++) {
                if (enabled[_tokens[x]]) {
                    uint _reward = _balance * weights[_tokens[x]] / _totalWeight;
                    if (_reward > 0) {
                        address _gauge = gauges[_tokens[x]];
                        Gauge(_gauge).deposit_reward_token(_rkp3r, _reward);
                    }
                }
            }
        }
    }

    function _safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.approve.selector, spender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}