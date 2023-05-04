// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './IReferral.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ReferalHandler is IReferralHandler, Ownable {
    using SafeERC20 for IERC20;

    address public operator;

    mapping(address => User) public users;
    uint public constant referalLength = 3;

    struct User {
        address referrer;
        uint256 totalReferralCommissions;
        uint256[referalLength] levels;
    }

    event RecordReferral(address indexed referrer, address indexed referral, uint256 indexed level);
    event ReferralCommissionRecorded(address indexed referrer, uint256 commission);
    event OperatorUpdated(address indexed oldOperator, address indexed newOperator);

    modifier onlyOperator() {
        require(operator == msg.sender, "REFERRAL:: operator: caller is not the operator");
        _;
    }

    function recordReferral(address _user, address _referrer) public override onlyOperator {
        User storage user = users[_user];
        if (_user != address(0)
        && _referrer != address(0)
        && _user != _referrer
        && user.referrer == address(0) &&
        _user != users[_referrer].referrer
        ) {
            user.referrer = _referrer;
            address upline = _referrer;
            for (uint256 i; i < referalLength; i++) {
                if (upline != address(0)) {
					users[upline].levels[i] += 1;
					emit RecordReferral(upline, _user, i);
					upline = users[upline].referrer;
                } else break;
            }
        }
    }

    function recordReferralCommission(address _referrer, uint256 _commission) public override onlyOperator {
        if (_referrer != address(0) && _commission > 0) {
            users[_referrer].totalReferralCommissions += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) public override view returns (address) {
        return users[_user].referrer;
    }

    // Update the status of the operator
    function updateOperator(address _operator) external onlyOwner {
        require(operator == address(0), "REFFERAL:: operator already set");
        emit OperatorUpdated(operator, _operator);
        operator = _operator;
    }

    // Owner can drain tokens that are sent here by mistake
    function drainBEP20Token(IERC20 _token, uint256 _amount, address _to) external onlyOwner {
        _token.safeTransfer(_to, _amount);
    }

    function getUserData(address _user) external view returns(address _referrer,
    uint256 _totalReferralCommissions, uint256[referalLength] memory _levels)
    {
        User storage user = users[_user];
        _referrer = user.referrer;
        _totalReferralCommissions = user.totalReferralCommissions;
        _levels = user.levels;
    }

    fallback() external payable {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {
        payable(owner()).transfer(address(this).balance);
    }
}