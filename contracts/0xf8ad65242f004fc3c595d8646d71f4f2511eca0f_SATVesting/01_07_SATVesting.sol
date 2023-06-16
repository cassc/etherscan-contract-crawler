pragma solidity ^0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SATVesting is Ownable {
    using SafeMath for uint256;
    using Address for address;

    IERC20 _token;
    bool public paused;
    mapping (address => uint256) public _amounts;
    mapping (address => uint256) public _balances;
    mapping (address => uint256) public _cliffs;
    mapping (address => uint256) public _lasts;
    mapping (address => uint256) public _lastClaim;

    event Claim(address indexed account, uint256 timestamp, uint256 amount);

    constructor(address _tokenAdd) public {
        _token = IERC20(_tokenAdd);
    }

    function vestedTokens(address account) public view returns (uint256) {
        uint256 totTime = _lasts[account].sub(_cliffs[account]);
        uint accTime;
        if (_balances[account] == 0 || _lastClaim[account] >= now) { return 0; }
        else {
            if (_lastClaim[account] <= _cliffs[account] && now <= _cliffs[account]) {
                return 0;
            } else if (_lastClaim[account] <= _cliffs[account] && _cliffs[account] < now && _lasts[account] > now) {
                accTime = now.sub(_cliffs[account]);
                return (_amounts[account].mul(accTime).div(totTime));
            } else if (_lasts[account] <= now) {
                return _balances[account];
            } else if (_lastClaim[account] > _cliffs[account] && _lasts[account] > now) {
                accTime = now.sub(_lastClaim[account]);
                return (_amounts[account].mul(accTime).div(totTime));
            } else {
                return 0;
            }
        }
    }

    function addVesters(address [] memory owners, uint256 [] memory amounts, uint256 [] memory cliffs, uint256 [] memory durations) external onlyOwner() {
        require(amounts.length == cliffs.length && amounts.length == durations.length && owners.length == amounts.length, "Vesting: Incorrect vesting data");
        uint256 totalTokens = 0;
        for(uint i=0; i < owners.length; i++) {
            _amounts[owners[i]] = amounts[i];
            _balances[owners[i]] = amounts[i];
            _cliffs[owners[i]] = cliffs[i];
            _lasts[owners[i]] = cliffs[i].add(durations[i]);
            totalTokens += amounts[i];
        }
        _token.transferFrom(_msgSender(), address(this), totalTokens);
    }

    function emergencyPause(bool _state) external onlyOwner() {
        paused = _state;
    }

    function emergencyWithdraw() external onlyOwner() {
        uint256 tokenBal = _token.balanceOf(address(this));
        _token.transfer(_msgSender(), tokenBal);
    }

    function claimVestedTokens() external notPaused {
        require(_lastClaim[_msgSender()] < now, "Vesting: not enough time");
        uint256 vested = vestedTokens(_msgSender());
        require(vested > 0 && _balances[_msgSender()] > 0, "Vesting: No vested tokens");
        _lastClaim[_msgSender()] = now;
        if (_balances[_msgSender()] < vested) {
            vested = _balances[_msgSender()];
        }
        _balances[_msgSender()] = _balances[_msgSender()].sub(vested);
        _token.transfer(_msgSender(), vested);
        emit Claim(_msgSender(),now,vested);       
    }

    modifier notPaused() {
        require(!paused, "Vesting: claims paused");
        _;
    }
}