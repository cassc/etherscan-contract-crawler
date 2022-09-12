pragma solidity >=0.6.0 <=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SpynLeaderboard is Ownable {

    mapping(address => bool) public operators;
    mapping(address => mapping (address => uint256)) public userLeaderboard;
    mapping(address => mapping (uint256 => address)) public userTokens;
    mapping(address => uint256) public userTokenCount;

    event StakingRecorded(address indexed user, address token, uint256 amount);
    event UnstakingRecorded(address indexed user, address token, uint256 amount);

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
    }

    function recordStaking(
        address _user,
        address _token,
        uint256 _amount
    ) external onlyOperator {
        if (userLeaderboard[_user][_token] == 0) {
            userTokens[_user][userTokenCount[_user]] = _token;
            userTokenCount[_user] += 1;
        }
        userLeaderboard[_user][_token] += _amount;

        emit StakingRecorded(_user, _token, _amount);
    }

    function recordUnstaking(
        address _user,
        address _token,
        uint256 _amount
    ) external onlyOperator {
        if (userLeaderboard[_user][_token] > _amount) {
            userLeaderboard[_user][_token] -= _amount;
        } else {
            userLeaderboard[_user][_token] = 0;
        }

        if (userLeaderboard[_user][_token] == 0) {
            uint256 count = userTokenCount[_user];
            for (uint256 index = 0; index < count; index ++) {
                if (userTokens[_user][index] == _token && index < count - 1) {
                    userTokens[_user][index] = userTokens[_user][count - 1];
                }
                userTokenCount[_user] -= 1;
                count -= 1;
            }
        }

        emit UnstakingRecorded(_user, _token, _amount);
    }

    function hasStaking(address _user) external view returns(bool) {
        for (uint256 index = 0; index < userTokenCount[_user]; index ++) {
            address _token = userTokens[_user][index];
            if (userLeaderboard[_user][_token] > 0) {
                return true;
            }
        }
        return false;
    }
}