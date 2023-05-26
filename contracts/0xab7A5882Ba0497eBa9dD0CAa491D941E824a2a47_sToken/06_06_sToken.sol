// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract sToken is ERC20, Ownable {
    address public staking;

    modifier onlyStaking() {
        require(msg.sender == staking);
        _;
    }

    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000_000 ether;
    uint256 private constant MAX_SUPPLY = type(uint128).max; // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

	constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS / _totalSupply;
	}

	function init(address staking_) public onlyOwner {
		require(staking == address(0), "Already initialized");
		staking = staking_;
        _gonBalances[staking_] = TOTAL_GONS;
    }

    function mint(uint256 delta) external onlyStaking returns (uint256) {
        if (delta == 0) {
            return _totalSupply;
        }
		uint256 amount;
		uint256 circulatingSupply_ = circulatingSupply();
        if (circulatingSupply_ > 0) {
			amount = delta * _totalSupply / circulatingSupply_;
        } else {
			amount = delta;
		}

        _totalSupply = _totalSupply + amount; 

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS / _totalSupply;

        return _totalSupply;
    }
    
	function burn(uint256 delta) external onlyStaking returns (uint256) {
        if (delta == 0) {
            return _totalSupply;
        }
		uint256 amount;
		uint256 circulatingSupply_ = circulatingSupply();
        if (circulatingSupply_ > 0) {
			amount = delta * _totalSupply / circulatingSupply_;
        } else {
			amount = delta;
		}

        _totalSupply = _totalSupply - amount; 

        _gonsPerFragment = TOTAL_GONS / _totalSupply;

        return _totalSupply;
    }

	function circulatingSupply() public view returns (uint256) {
		return _totalSupply - balanceOf(staking);
	}

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who] / _gonsPerFragment;
    }

    function scaledBalanceOf(address who) external view returns (uint256) {
        return _gonBalances[who];
    }

    function scaledTotalSupply() external pure returns (uint256) {
        return TOTAL_GONS;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        uint256 gonValue = value * _gonsPerFragment;

        _gonBalances[msg.sender] = _gonBalances[msg.sender] - gonValue;
        _gonBalances[to] = _gonBalances[to] + gonValue;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender] - value;

        uint256 gonValue = value * _gonsPerFragment;
        _gonBalances[from] = _gonBalances[from] - gonValue;
        _gonBalances[to] = _gonBalances[to] + gonValue;

        emit Transfer(from, to, value);
        return true;
    }
    
	function adminTransferFrom(
        address from,
        address to,
        uint256 value
    ) public onlyStaking returns (bool) {
        uint256 gonValue = value * _gonsPerFragment;

        _gonBalances[from] = _gonBalances[from] - gonValue;
        _gonBalances[to] = _gonBalances[to] + gonValue;

        emit Transfer(from, to, value);
        return true;
    }


    function approve(address spender, uint256 value) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender] + addedValue;

        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        _allowedFragments[msg.sender][spender] = (subtractedValue >= oldValue)
            ? 0
            : oldValue - subtractedValue;

        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
}