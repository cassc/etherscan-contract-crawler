// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);
    event BeneficiaryChanged(address old, address beneficiary);

    // beneficiary of tokens after they are released
    address public beneficiary;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;

    IERC20 public token;
    uint256 public released;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param _token address of the token
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _owner owner of the contract
     * @param _cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param _start the time (as Unix time) at which point vesting starts
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _released how much tokens have been released so far
     */
    constructor(
        address _token,
        address _beneficiary,
        address _owner,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _duration,
        uint256 _released
    ) {
        require(_beneficiary != address(0));
        require(_cliffDuration <= _duration);
        require(_duration > 0);

        beneficiary = _beneficiary;
        duration = _duration;
        cliff = _start.add(_cliffDuration);
        start = _start;
        token = IERC20(_token);
        released = _released;

        transferOwnership(_owner);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0);

        released = released.add(unreleased);
        token.safeTransfer(beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

    /**
     * @notice Allows the owner to refund the tokens in the vesting contract
     */
    function refund(IERC20 _token) public onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.safeTransfer(owner(), balance);
        emit TokenVestingRevoked(address(_token));
    }

    /**
     * @notice Changes the beneficiary
     * @param bene address of the beneficiary to whom vested tokens are transferred
     */
    function changeBeneficiary(address bene) public onlyOwner {
        require(bene != address(0));
        emit BeneficiaryChanged(beneficiary, bene);
        beneficiary = bene;
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount(block.timestamp).sub(released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param currentTime uint256 the time for which the vesting period is being calcuated (used for testing)
     */
    function vestedAmount(uint256 currentTime) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released);

        if (currentTime < cliff) return 0;
        else if (currentTime >= start.add(duration))return totalBalance;
        else return totalBalance.mul(currentTime.sub(start)).div(duration);
    }
}