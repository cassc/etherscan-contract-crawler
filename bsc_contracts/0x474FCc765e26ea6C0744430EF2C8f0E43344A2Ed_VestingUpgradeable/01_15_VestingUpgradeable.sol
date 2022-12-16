// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract VestingUpgradeable is AccessControlEnumerableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    struct VestingInfo {
        address token;
        uint256 totalAmount;
        uint256 releaseTotalRounds;
        uint256 startTimeVesting;
        uint256 daysPerRound;
        uint256 claimedRounds;
    }

    mapping(address => VestingInfo) private _vestings;

    event Vesting(
        address beneficiary,
        address token,
        uint256 amount,
        uint256 releaseTotalRounds,
        uint256 startTimeVesting,
        uint256 daysPerRound
    );
    event Revoke(address beneficiary, address token);
    event Claim(address beneficiary, address token, uint256 releaseAmount, uint256 releaseRound);

    function initialize(address multiSigAccount) public virtual initializer {
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, multiSigAccount);
    }

    function addVesting(
        address beneficiary,
        address token,
        uint256 amount,
        uint256 releaseTotalRounds,
        uint256 startTimeVesting,
        uint256 daysPerRound
    ) external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        require(beneficiary != address(0), "Error: zero address");
        require(amount != 0 && releaseTotalRounds != 0, "Error: invalid params");
        require(_vestings[beneficiary].claimedRounds == _vestings[beneficiary].releaseTotalRounds, "Error: duplicate");

        // if (token != address(0)) {
        //     require(
        //         msg.value == 0 && IERC20(token).transferFrom(_msgSender(), address(this), amount),
        //         "Error: invalid amount"
        //     );
        // } else require(msg.value == amount, "Error: invalid amount");

        VestingInfo memory vesting = VestingInfo(token, amount, releaseTotalRounds, startTimeVesting, daysPerRound, 0);
        _vestings[beneficiary] = vesting;

        emit Vesting(beneficiary, token, amount, releaseTotalRounds, startTimeVesting, daysPerRound);
    }

    function revokeVesting(address beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 returnAmount) {
        VestingInfo memory vesting = _vestings[beneficiary];

        require(
            _vestings[beneficiary].claimedRounds != _vestings[beneficiary].releaseTotalRounds,
            "Error: no beneficiary"
        );
        (, , uint256 claimedAmount) = _getVestingClaimable(vesting, 0);

        returnAmount = vesting.totalAmount - claimedAmount;

        // if (vesting.token != address(0)) {
        //     require(IERC20(vesting.token).balanceOf(address(this)) >= returnAmount, "Error: exceeds balance");
        //     require(IERC20(vesting.token).transfer(_msgSender(), returnAmount), "Error: transfer failed");
        // } else {
        //     require(address(this).balance >= returnAmount, "Error: exceeds balance");
        //     require(payable(_msgSender()).send(returnAmount), "Error: transfer failed");
        // }

        delete _vestings[beneficiary];

        emit Revoke(beneficiary, vesting.token);
    }

    function getVesting(address beneficiary)
        public
        view
        returns (
            VestingInfo memory vesting,
            uint256 claimable,
            uint256 roundsPassed,
            uint256 claimedAmount
        )
    {
        vesting = _vestings[beneficiary];
        (claimable, roundsPassed, claimedAmount) = _getVestingClaimable(vesting, 0);
    }

    function _getVestingClaimable(VestingInfo memory vesting, uint256 timestamp)
        internal
        view
        returns (
            uint256 claimable,
            uint256 roundsPassed,
            uint256 claimedAmount
        )
    {
        if (timestamp == 0) timestamp = block.timestamp;
        if (timestamp < vesting.startTimeVesting) return (0, 0, 0);
        if (vesting.claimedRounds == vesting.releaseTotalRounds)
            return (0, vesting.releaseTotalRounds, vesting.totalAmount);

        roundsPassed = ((timestamp - vesting.startTimeVesting) / (vesting.daysPerRound * 1 days)) + 1;
        claimedAmount = (vesting.claimedRounds * vesting.totalAmount) / vesting.releaseTotalRounds;
        if (roundsPassed >= vesting.releaseTotalRounds) {
            claimable = vesting.totalAmount - claimedAmount;
            roundsPassed = vesting.releaseTotalRounds;
        } else claimable = ((roundsPassed * vesting.totalAmount) / vesting.releaseTotalRounds) - claimedAmount;
    }

    function getVestingClaimable(address beneficiary, uint256 timestamp)
        external
        view
        returns (uint256 claimable, uint256 roundsPassed)
    {
        (claimable, roundsPassed, ) = _getVestingClaimable(_vestings[beneficiary], timestamp);
    }

    function claim() external whenNotPaused nonReentrant returns (uint256 releaseAmount, uint256 roundsPassed) {
        VestingInfo storage vesting = _vestings[_msgSender()];

        (releaseAmount, roundsPassed, ) = _getVestingClaimable(vesting, 0);
        require(releaseAmount != 0, "Error: nothing to claim");

        vesting.claimedRounds = roundsPassed;

        if (vesting.token != address(0)) {
            require(IERC20(vesting.token).balanceOf(address(this)) >= releaseAmount, "Error: exceeds balance");
            require(IERC20(vesting.token).transfer(_msgSender(), releaseAmount), "Error: transfer token failed");
        } else {
            require(address(this).balance >= releaseAmount, "Error: exceeds balance");
            require(payable(_msgSender()).send(releaseAmount), "Error: transfer failed");
        }

        emit Claim(_msgSender(), vesting.token, releaseAmount, roundsPassed);
    }

    function withdraw(
        address payable _to,
        address _token,
        uint256 _amount
    ) public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "Error: Exceeds balance");
            require(_to.send(_amount), "Error: Transfer failed");
        } else {
            require(IERC20(_token).balanceOf(address(this)) >= _amount, "Error: Exceeds balance");
            require(IERC20(_token).transfer(_to, _amount), "Error: Transfer failed");
        }
    }
}