// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ReferralSystem is Ownable {

    address public operator;

    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions

    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(address indexed referrer, uint256 commission);
    event OperatorUpdated(address indexed operator);

    modifier onlyOperator {
        require(operator == msg.sender, "Operator: caller is not the operator");
        _;
    }

    function recordReferral(address _user, address _referrer) external onlyOperator {
        if (_user != address(0)
        && _referrer != address(0)
        && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    function recordReferralCommission(address _referrer, uint256 _commission) external onlyOperator {
        if (_referrer != address(0)) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) external view returns (address) {
        return referrers[_user];
    }


    function updateOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "operator cannot be the 0 address");
        require(operator == address(0), "operator is already set!");

        operator = _operator;

        emit OperatorUpdated(_operator);
    }
}