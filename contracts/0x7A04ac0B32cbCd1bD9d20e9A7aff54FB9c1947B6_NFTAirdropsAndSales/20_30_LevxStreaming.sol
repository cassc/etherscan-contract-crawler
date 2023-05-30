// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LevxStreaming is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 constant STREAMING_PERIOD = 180 days;

    struct Stream {
        address recipient;
        uint64 startedAt;
        uint256 amount;
        uint256 claimed;
    }

    address public immutable levx;
    address public immutable signer;
    address public immutable wallet;
    uint64 public immutable deadline;
    mapping(bytes32 => Stream[]) public streams;

    event Start(bytes32 indexed id, uint256 nonce, uint256 amount, address indexed recipient);
    event Claim(bytes32 indexed id, uint256 nonce, uint256 amount, address indexed recipient);

    constructor(
        address _levx,
        address _signer,
        address _wallet,
        uint64 _deadline
    ) {
        levx = _levx;
        signer = _signer;
        wallet = _wallet;
        deadline = _deadline;
    }

    function start(
        bytes32 id,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, "LEVX: INVALID_AMOUNT");

        uint64 _now = uint64(block.timestamp);
        require(_now < deadline, "LEVX: EXPIRED");

        uint256 nonce = streams[id].length;
        bytes32 message = keccak256(abi.encodePacked(id, nonce, amount));
        require(ECDSA.recover(ECDSA.toEthSignedMessageHash(message), v, r, s) == signer, "LEVX: UNAUTHORIZED");

        Stream storage stream = streams[id].push();
        stream.recipient = msg.sender;
        stream.startedAt = _now;
        stream.amount = amount;

        emit Start(id, nonce, amount, msg.sender);

        IERC20(levx).safeTransferFrom(wallet, address(this), amount);
    }

    function claim(
        bytes32 id,
        uint256 nonce,
        address to,
        bytes calldata callData
    ) external {
        Stream storage stream = streams[id][nonce];
        require(stream.recipient == msg.sender, "LEVX: FORBIDDEN");

        uint256 amount = _amountReleased(stream);
        uint256 pending = amount - stream.claimed;
        stream.claimed = amount;

        if (to == address(0)) {
            emit Claim(id, nonce, pending, msg.sender);

            IERC20(levx).safeTransfer(msg.sender, pending);
        } else {
            emit Claim(id, nonce, pending, to);

            IERC20(levx).safeTransfer(to, pending);
            to.functionCall(callData);
        }
    }

    function pendingAmount(bytes32 id, uint256 index) external view returns (uint256) {
        Stream storage stream = streams[id][index];
        return _amountReleased(stream) - stream.claimed;
    }

    function _amountReleased(Stream storage stream) internal view returns (uint256) {
        uint256 duration = block.timestamp - stream.startedAt;
        if (duration > STREAMING_PERIOD) duration = STREAMING_PERIOD;
        return (stream.amount * duration) / STREAMING_PERIOD;
    }
}