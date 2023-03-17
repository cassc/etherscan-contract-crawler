// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// NOTE: OTHER ERC20 TOKEN and native token sent to this contract cannot be transferred out.
contract Vesting is Ownable {
    using SafeERC20 for IERC20;
    event TokensReleased(address token, uint256 amount);

    // The SpaceID ERC20 token.
    IERC20 private immutable _sidToken;
    // beneficiary of tokens after they are released
    address private immutable _beneficiary;
    // Durations and timestamps are expressed in UNIX timestamp.
    uint256 private immutable _start;
    // Release total/numVestings token to beneficiary for every duration cliff.
    uint256 private immutable _duration;
    // The number of vestings.
    uint256 private immutable _numVestings;
    // The number of ERC20 token released.
    uint256 private _released;

    /**
     * @dev Creates a vesting contract that vests its balance of SpaceID token to the
     * beneficiary. (total/numVesting) Tokens are vested every duration since start.
     * @param sidToken_ address of SpaceID ERC20 token.
     * @param beneficiary_ address of the beneficiary to whom vested tokens are transferred
     * @param start_ the time (as Unix timestamp) at which point vesting starts
     * @param duration_ the time between vesting
     * @param numVestings_ the number of vesting
     */
    constructor (
        address owner_,
        address sidToken_,
        address beneficiary_,
        uint256 start_,
        uint256 duration_,
        uint256 numVestings_
    ) {
        require(sidToken_ != address(0), "TokenVesting: erc20 token is the zero address");
        require(beneficiary_ != address(0), "TokenVesting: beneficiary is the zero address");
        require(duration_ > 0, "TokenVesting: duration is 0");
        require(numVestings_ > 0, "TokenVesting: vestingCount is 0");
        require(start_ + duration_ * numVestings_ > block.timestamp, "TokenVesting: final time is before current time");

        _sidToken = IERC20(sidToken_);
        _beneficiary = beneficiary_;
        _start = start_;
        _duration = duration_;
        _numVestings = numVestings_;

        transferOwnership(owner_);
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function token() public view returns (IERC20) {
        return _sidToken;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return the number of vestings.
     */
    function numVestings() public view returns (uint256) {
        return _numVestings;
    }

    /**
     * @return the amount of the token released.
     */
    function released() public view returns (uint256) {
        return _released;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "TokenVesting: no tokens are due");
        _released = _released + unreleased;
        _sidToken.safeTransfer(_beneficiary, unreleased);
        emit TokensReleased(address(_sidToken), unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function releasableAmount() public view returns (uint256) {
        return _vestedAmount() - _released;
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = _sidToken.balanceOf(address(this));
        uint256 totalBalance = currentBalance + _released;
        if (block.timestamp < _start) {
            // not start
            return 0;
        } else if (block.timestamp >= _start + _duration * _numVestings) {
            // all vested, transfer out all remaining tokens.
            return totalBalance;
        } else {
            // For every duration passed after _start, vest (totalBalance / _numVestings) tokens.
            return ((block.timestamp - _start) / _duration) * (totalBalance / _numVestings);
        }
    }

    function recoverOtherERC20(
        address tokenAddress, uint256 tokenAmount) public onlyOwner {
        require(tokenAddress != address(_sidToken), "only other token can be recovered");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    // Not necessary, unless someone force ether to this contract in strange ways, e.g. selfdestruct.
    // function recoverNativeToken() public onlyOwner {
    //      (bool sent, ) = this.owner().call{value: address(this).balance}("");
    //     require(sent, "Failed to send Ether");
    // }
}