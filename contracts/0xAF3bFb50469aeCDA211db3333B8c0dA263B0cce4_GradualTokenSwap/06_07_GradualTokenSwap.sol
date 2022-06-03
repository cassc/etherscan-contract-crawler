pragma solidity 0.8.6;
// SPDX-License-Identifier: GPL-3.0-or-later
import "../utils/ERC20Recovery.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title GTS
 * @dev A token swap contract that gradually releases tokens on its balance
 */
contract GradualTokenSwap is ERC20Recovery {
    // solhint-disable not-rely-on-time
    using SafeERC20 for IERC20;

    event Withdrawn(address account, uint256 amount);

    // Durations and timestamps in UNIX time, also in block.timestamp.
    uint256 public immutable start;
    uint256 public immutable duration;
    IERC20 public immutable rHEGIC;
    IERC20 public immutable HEGIC;

    mapping(address => uint256) public released;
    mapping(address => uint256) public provided;

    /**
     * @dev Creates a contract that can be used for swapping rHEGIC into HEGIC
     * @param _start UNIX time at which the unlock period starts
     * @param _duration Duration in seconds for unlocking tokens
     */
    constructor(
        uint256 _start,
        uint256 _duration,
        IERC20 _rHEGIC,
        IERC20 _HEGIC
    ) {
        if (_start == 0) _start = block.timestamp;
        require(_duration > 0, "GTS: duration is 0");

        duration = _duration;
        start = _start;
        rHEGIC = _rHEGIC;
        HEGIC = _HEGIC;
    }

    /**
     * @dev Provide rHEGIC tokens to the contract for later exchange
     */
    function provide(uint256 amount) external {
        rHEGIC.safeTransferFrom(msg.sender, address(this), amount);
        provided[msg.sender] += amount;
    }

    /**
     * @dev Withdraw unlocked user's HEGIC tokens
     */
    function withdraw() external {
        uint256 amount = available(msg.sender);
        require(amount > 0, "GTS: You are have not unlocked tokens yet");
        released[msg.sender] += amount;
        HEGIC.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Calculates the amount of tokens that has already been unlocked but hasn't been swapped yet
     */
    function available(address account) public view returns (uint256) {
        return unlocked(account) - released[account];
    }

    /**
     * @dev Calculates the total amount of tokens that has already been unlocked
     */
    function unlocked(address account) public view returns (uint256) {
        if (block.timestamp < start) return 0;
        if (block.timestamp >= start + duration) {
            return provided[account];
        } else {
            return (provided[account] * (block.timestamp - start)) / duration;
        }
    }
}