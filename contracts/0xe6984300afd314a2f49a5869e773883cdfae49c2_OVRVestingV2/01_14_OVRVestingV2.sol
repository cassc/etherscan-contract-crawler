// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OVRVestingV2 is AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // prettier-ignore
    event GrantRevoked(address indexed beneficiary, uint256 amount, uint256 released);
    event NewGrant(address indexed beneficiary, uint256 amount);
    event ERC20Released(address indexed beneficiary, uint256 amount);

    mapping(address => Grant) public grants;
    IERC20 public token;

    struct Grant {
        address beneficiary;
        uint256 value;
        uint256 start;
        uint256 end;
        uint256 duration;
        uint256 releasedAmount;
        uint256 lastReleaseDate;
        bool exist;
        bool revocable;
    }

    constructor(IERC20 _token) {
        token = _token;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Grant tokens to a specified address.
     * @param _beneficiary beneficiary address
     * @param _amount the amount of tokens to be granted
     * @param _start unix start date
     * @param _end unix end date
     * @param _revocable whether the grant is revocable or not
     */
    function granting(
        address _beneficiary,
        uint256 _amount,
        uint256 _start,
        uint256 _end,
        bool _revocable
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // prettier-ignore
        require(_beneficiary != address(0) || _beneficiary != address(this), "Invalid beneficiary");

        require(_now() < _end, "Invalid end date");
        require(_amount > 0, "Invalid amount");

        // prettier-ignore
        grants[_beneficiary] = Grant({ beneficiary: _beneficiary, value: _amount, start: _start, end: _end, duration: _end.sub(_start), releasedAmount: 0, lastReleaseDate: 0, exist: true, revocable: _revocable});
        emit NewGrant(_beneficiary, _amount);
    }

    function unlockVestedTokens() external nonReentrant {
        require(grants[_msgSender()].exist, "Not authorized");
        require(_now() > grants[_msgSender()].start, "Not started");

        uint256 toWithdraw = calcAmountToWithdraw(_msgSender());
        require(toWithdraw > 0, "Nothing to withdraw");

        // prettier-ignore
        grants[_msgSender()].releasedAmount = grants[_msgSender()].releasedAmount.add(toWithdraw);
        grants[_msgSender()].lastReleaseDate = _now();

        token.transfer(_msgSender(), toWithdraw);
        emit ERC20Released(_msgSender(), toWithdraw);
    }

    /**
     * @dev  calculate withdraw amount of vested tokens at a specifc time
     * @param _account beneficiary address
     */
    function calcAmountToWithdraw(address _account)
        public
        view
        returns (uint256)
    {
        bool isExpired = grants[_account].end < _now();

        // Not authorized
        if (!grants[_account].exist) return 0;

        if (isExpired) {
            return
                grants[_msgSender()].value.sub(
                    grants[_msgSender()].releasedAmount
                );
        }

        if (grants[_account].lastReleaseDate == 0) {
            // never withdrawn
            return
                grants[_account]
                    .value
                    .mul(_now().sub(grants[_account].start))
                    .div(grants[_account].duration);
        } else {
            // already withdrawn
            return
                grants[_account]
                    .value
                    .mul(_now().sub(grants[_account].lastReleaseDate))
                    .div(grants[_account].duration);
        }
    }

    /**
     * @dev Revoke the grant of tokens of a specifed address.
     * @param _account the address which will have its tokens revoked
     */
    function revoke(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(grants[_account].revocable, "Not revocable");

        uint256 value = grants[_account].value;
        uint256 released = grants[_account].releasedAmount;
        uint256 refund = value.sub(released);

        delete grants[_account];
        token.safeTransfer(_msgSender(), refund);
        emit GrantRevoked(_account, value, released);
    }

    function _now() internal view returns (uint256) {
        return block.timestamp;
    }

    function addAdmin(address _admin) public {
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function removeAdmin(address _admin) public {
        revokeRole(DEFAULT_ADMIN_ROLE, _admin);
    }
}