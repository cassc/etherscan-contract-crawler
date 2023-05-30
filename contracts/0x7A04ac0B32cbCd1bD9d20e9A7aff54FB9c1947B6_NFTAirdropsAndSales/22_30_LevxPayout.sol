// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LevxPayout is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public immutable levx;

    Payout[] public payouts;

    struct Payout {
        address wallet;
        address recipient;
        uint32 startedAt;
        uint32 duration;
        uint32 stoppedAt;
        uint256 amount;
        uint256 claimed;
    }

    event Start(uint256 indexed id, address wallet, address indexed recipient, uint32 duration, uint256 amount);
    event Stop(uint256 indexed id, uint256 pendingAmount);
    event Claim(uint256 indexed id, uint256 amount, address indexed recipient);

    constructor(address _levx) {
        levx = _levx;
    }

    function start(
        address wallet,
        address recipient,
        uint32 duration,
        uint256 amount
    ) external onlyOwner {
        require(amount > 0, "LEVX: INVALID_AMOUNT");

        uint256 id = payouts.length;
        Payout storage payout = payouts.push();
        payout.wallet = wallet;
        payout.recipient = recipient;
        payout.startedAt = uint32(block.timestamp);
        payout.duration = duration;
        payout.amount = amount;

        emit Start(id, wallet, recipient, duration, amount);

        IERC20(levx).safeTransferFrom(wallet, address(this), amount);
    }

    function stop(uint256 id) external onlyOwner {
        Payout storage payout = payouts[id];
        require(payout.stoppedAt == 0, "LEVX: STOPPED");

        uint256 released = _amountReleased(payout);
        uint256 remaining = payout.amount - released;
        require(remaining > 0, "LEVX: FINISHED");

        payout.claimed = released;
        payout.stoppedAt = uint32(block.timestamp);

        uint256 pending = released - payout.claimed;
        emit Stop(id, pending);
        IERC20(levx).safeTransfer(payout.wallet, remaining);
        if (pending > 0) {
            IERC20(levx).safeTransfer(payout.recipient, pending);
        }
    }

    function claim(
        uint256 id,
        address to,
        bytes calldata callData
    ) external {
        Payout storage payout = payouts[id];
        require(payout.recipient == msg.sender, "LEVX: FORBIDDEN");

        uint256 released = _amountReleased(payout);
        uint256 pending = released - payout.claimed;
        payout.claimed = released;

        if (to == address(0)) {
            emit Claim(id, pending, msg.sender);

            IERC20(levx).safeTransfer(msg.sender, pending);
        } else {
            emit Claim(id, pending, to);

            IERC20(levx).safeTransfer(to, pending);
            to.functionCall(callData);
        }
    }

    function pendingAmount(uint256 id) external view returns (uint256) {
        Payout storage payout = payouts[id];
        return _amountReleased(payout) - payout.claimed;
    }

    function _amountReleased(Payout storage stream) internal view returns (uint256) {
        uint256 duration = block.timestamp - stream.startedAt;
        uint256 _total = uint256(stream.duration);
        if (duration >= _total) return stream.amount;
        return (stream.amount * duration) / _total;
    }
}