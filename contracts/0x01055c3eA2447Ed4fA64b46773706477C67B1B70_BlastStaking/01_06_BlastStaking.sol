// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlastStaking is Pausable, ReentrancyGuard, Ownable {
    address public immutable TOKEN;

    struct UserStake {
        uint256 amountStaked;
        uint256 stakeTime;
    }

    mapping(address => UserStake) public Stake;

    event Staked(address user, uint256 amount, uint256 timestamp);
    event UnStaked(address user, uint256 amount, uint256 timestamp);

    constructor(address _token) {
        require(_token != address(0), "Invalid Token Address");
        TOKEN = _token;
    }

    function stakeTokens(uint256 _amount) external {
        require(_amount > 0, "Invalid Amount");
        require(
            IERC20(TOKEN).balanceOf(msg.sender) >= _amount,
            "Insufficient Balance"
        );

        UserStake memory _cache = Stake[msg.sender];
        _cache.amountStaked += _amount;
        _cache.stakeTime = block.timestamp;
        Stake[msg.sender] = _cache;

        IERC20(TOKEN).transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function unstakeTokens(uint256 _amount) external nonReentrant {
        UserStake memory _cache = Stake[msg.sender];
        require(_amount > 0, "Invalid Amount");
        require(_cache.amountStaked > 0, "No Staked Tokens");
        require(_cache.amountStaked >= _amount, "Not Enough Staking");

        if (_cache.amountStaked - _amount == 0) {
            delete Stake[msg.sender];
        } else {
            _cache.amountStaked -= _amount;
            Stake[msg.sender] = _cache;
        }
        IERC20(TOKEN).transfer(msg.sender, _amount);
        emit UnStaked(msg.sender, _amount, block.timestamp);
    }

    function getTierAndEligibility(address _user)
        external
        view
        returns (string memory, bool)
    {
        UserStake memory _cache = Stake[_user];
        require(_cache.amountStaked > 0, "No Staked Tokens");
        string memory _tier;
        bool _isEligible;
        if (_cache.amountStaked > 0 && _cache.amountStaked <= 10000000000000) {
            _tier = "TIER 1";
        } else if (
            _cache.amountStaked > 10000000000000 &&
            _cache.amountStaked <= 50000000000000
        ) {
            _tier = "TIER 2";
        } else {
            _tier = "TIER 3";
        }

        if (_cache.stakeTime + 7 days <= block.timestamp) {
            _isEligible = true;
        }
        return (_tier, _isEligible);
    }
}