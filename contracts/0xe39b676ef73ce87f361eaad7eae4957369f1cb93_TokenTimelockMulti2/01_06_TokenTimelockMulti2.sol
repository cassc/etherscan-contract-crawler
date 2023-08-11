pragma solidity 0.5.8;

// TokenTimelockMulti - Copyright (c) 2019-2020 Ossip Kaehr

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

/**
 * @dev A token holder contract that will allow beneficiaries to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 * based on openzeppelin - TokenTimelock expanded for multiple beneficiaries;
 */


contract TokenTimelockMulti2 is Ownable {
    using SafeMath for uint256;
    // ERC20 token contract being held
    ERC20Detailed private _token;

    string _name;
    bool _locked;
    // timestamp when token release is enabled
    uint256 private _releaseTime;

    mapping(address => uint256) private _balances;
    uint256 private _total; // total assigned balance

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor (string memory name, ERC20Detailed token, uint256 releaseTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime > block.timestamp, "release time is before current time");
        _name = name;
        _token = token;
        _releaseTime = releaseTime;
        _total = 0;
        _locked = false;
    }

    function name() public view returns (string memory) { // for ERC20 compliance
        return _name;
    }

    function token() public view returns (ERC20Detailed) {
        return _token;
    }

    function decimals() public view returns (uint256) { // for ERC20 compliance
        return _token.decimals();
    }

    function symbol() public view returns (string memory) { // for ERC20 compliance
        return _token.symbol();
    }

    function setName(string memory name) public onlyOwner {
//        require(name != "", "name can't be empty");
        _name = name;
    }

    function locked() public view returns (bool) {
        return _locked;
    }
    modifier onlyUnlocked {
        require(_locked == false);
        _;
    }
    function lock() public onlyOwner {
        require(_locked == false, "already locked");
        _locked = true;
    }

    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    function changeReleaseTime(uint256 time) public onlyOwner onlyUnlocked {
        require(time > block.timestamp, "release time is before current time");
        _releaseTime = time;
    }

    function total() public view returns (uint256) {
        return _total;
    }

    function totalSupply() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function balanceOf(address beneficiary) public view returns (uint) {
        return _balances[beneficiary];
    }

    function withdraw(address beneficiary) public {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "current time is before release time");

        uint256 amount = _balances[beneficiary];
        require(amount > 0, "no tokens to release");

        uint256 available = totalSupply();
        require(available > 0, "no tokens to release");
        if (amount > available) amount = available; // max available - better give what we have

        _total = _total.sub(amount);
        _balances[beneficiary] = _balances[beneficiary].sub(amount);
        _token.transfer(beneficiary, amount);

        emit Transfer(beneficiary, address(0), amount);
    }

    function canWithdraw() public view returns (bool) {
        return block.timestamp >= _releaseTime;
    }

    function issue(address payable beneficiary, uint256 amount) public onlyOwner {
        require(amount > 0, "amount zero");
        require(beneficiary != address(0), "invalid zero address");

        uint256 available = totalSupply();
        require(available - _total >= amount, "not enough tokens available");

        _total = _total.add(amount);
        _balances[beneficiary] = _balances[beneficiary].add(amount);

        emit Transfer(address(0), beneficiary, amount);
    }

    function revoke(address beneficiary) public onlyOwner onlyUnlocked {
        require(beneficiary != address(0), "invalid zero address");
        uint256 bal = _balances[beneficiary];
        if (bal > 0) {
            _total = _total.sub(bal);
            _balances[beneficiary] = 0;
            emit Transfer(beneficiary, address(0), bal);
        }
    }

    // release unallocated funds to owner
    function releaseFunds() public onlyOwner {
        uint256 available = totalSupply();
        require(available > _total, "no additional funds to release");
        _token.transfer(owner(), available - _total);
    }

    // maybe overkill, but allow user to change his wallet
    function changeAddress(address payable beneficiary) public {
        require(beneficiary != address(0), "invalid zero address");
        require(msg.sender != beneficiary, "send from old address");
        uint256 bal = _balances[msg.sender];
        require(bal > 0, "no balance");
        _balances[msg.sender] = 0;
        _balances[beneficiary] = _balances[beneficiary].add(bal);

        emit Transfer(msg.sender, beneficiary, bal);
    }

}