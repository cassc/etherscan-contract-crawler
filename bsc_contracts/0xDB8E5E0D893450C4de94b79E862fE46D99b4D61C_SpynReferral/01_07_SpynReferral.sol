pragma solidity >=0.6.0 <=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/ISpynReferral.sol";

contract SpynReferral is ISpynReferral, Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) public operators;
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    mapping(address => mapping(uint256 => address)) public referrals;
    mapping(address => mapping(address => uint256)) public totalReferralCommissions; // referrer address => total referral commissions
    mapping(uint256 => address) public participants;
    uint256 public participantIndex;

    event ReferralRecorded(address indexed user, address indexed referrer);
    event ReferralCommissionRecorded(
        address indexed _referrer,
        address _referee,
        uint256 _commission,
        address _token,
        uint256 _type,
        uint256 _level
    );
    event ReferralCommissionMissed(
        address indexed _referrer,
        address _referee,
        uint256 _commission,
        address _token,
        uint256 _type,
        uint256 _level
    );
    event OperatorUpdated(address indexed operator, bool indexed status);

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    // If no referrer for the user yet, record
    function recordReferral(address _user, address _referrer) public override onlyOperator {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] == address(0)
            && referralsCount[_referrer] < 5
            && !hasInReferralTree(_user, _referrer)
        ) {

            if (referralsCount[_referrer] == 0) {
                participants[participantIndex] = _referrer;
                participantIndex ++;
            }

            referrers[_user] = _referrer;
            referrals[_referrer][referralsCount[_referrer]] = _user;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    // record referral comission
    function recordReferralCommission(
        address _referrer,
        address _referee,
        uint256 _commission,
        address _token,
        uint256 _type,
        uint256 _level
    ) public override onlyOperator {
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer][_token] += _commission;
            emit ReferralCommissionRecorded(_referrer, _referee, _commission, _token, _type, _level);
        }
    }

    // record referral comission
    function recordReferralCommissionMissing(
        address _referrer,
        address _referee,
        uint256 _commission,
        address _token,
        uint256 _type,
        uint256 _level
    ) public override onlyOperator {
        if (_referrer != address(0) && _commission > 0) {
            emit ReferralCommissionMissed(_referrer, _referee, _commission, _token, _type, _level);
        }
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) public override view returns (address) {
        return referrers[_user];
    }

    function getReferrersByLevel(address _user, uint256 count) public override view returns (
        address[] memory
    ) {
        address[] memory referrersByLevel = new address[](count);
        for (uint256 i = 0; i < count; i ++) {
            if (i == 0) {
                referrersByLevel[i] = referrers[_user];
            } else {
                referrersByLevel[i] = referrers[referrersByLevel[i - 1]];
            }
        }
        return referrersByLevel;
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    // Owner can drain tokens that are sent here by mistake
    function drainBEP20Token(IERC20 _token, uint256 _amount, address _to) external onlyOwner {
        _token.safeTransfer(_to, _amount);
    }

    function randomReferrer(address account) external view returns (address){
        if (participantIndex == 0) {
            return address(0);
        }
        uint256 base = uint256(keccak256(abi.encodePacked(account, participantIndex))) % participantIndex;
        for (uint256 i = 0; i < participantIndex; i ++) {
            uint256 index = base + i;
            address res = participants[index % participantIndex];
            if (res != account && referralsCount[res] < 5) {
                return res;
            }
        }
        return address(0);
    }

    function nextReferrerAvailable(address account) external view returns (address, uint256){
        if (referralsCount[account] < 5) {
            return (account, 0);
        }

        address res;
        // depth 1
        res = getNextReferrerAvailable(account, 1, 1);
        if (res != address(0x0)) {
            return (res, 1);
        }

        // depth 2
        res = getNextReferrerAvailable(account, 2, 1);
        if (res != address(0x0)) {
            return (res, 2);
        }

        // depth 3
        res = getNextReferrerAvailable(account, 3, 1);
        if (res != address(0x0)) {
            return (res, 3);
        }

        // depth 4
        res = getNextReferrerAvailable(account, 4, 1);
        if (res != address(0x0)) {
            return (res, 4);
        }
        
        return (address(0x0), 0);
    }

    function getNextReferrerAvailable( address account, uint256 depth, uint256 currentDepth) internal view returns (address) {
        if (currentDepth > depth) {
            return address(0x0);
        }

        if (currentDepth == depth) {
            for (uint256 i = 0; i < referralsCount[account]; i ++) {
                address nextReferrer = referrals[account][i];
                if (referralsCount[nextReferrer] < 5) {
                    return nextReferrer;
                }
            }
        } else {
            for (uint256 i = 0; i < referralsCount[account]; i ++) {
                address nextReferrer = referrals[account][i];
                address res = getNextReferrerAvailable(nextReferrer, depth, currentDepth + 1);
                if (res != address(0x0)) {
                    return res;
                }
            }
        }

        return address(0x0);
    }

    function hasInReferralTree(address _user, address _referrer) internal returns (bool) {
        if (referrers[_referrer] == _user) {
            return true;
        }

        if (referrers[_referrer] == address(0)) {
            return false;
        }

        return hasInReferralTree(_user, referrers[_referrer]);
    }
}