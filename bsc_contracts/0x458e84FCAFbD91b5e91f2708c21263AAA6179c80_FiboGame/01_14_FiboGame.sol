// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FiboGame is Pausable, AccessControl {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant ROUND_DURATION_SECONDS = 7 * 24 * 60 * 60;
    // The start time of each round, expressed in seconds of the day.
    // West + 6h = UTC
    uint256 public constant ROUND_BEGIN_TIME = 6 * 60 * 60;
    uint256 public BASIC_REWARDS;
    uint256 public TICKET_PRICE;
    address private SIGNER;
    address public DEV;
    IERC20 public erc20;
    IERC20Metadata public erc20Metadata;

    mapping(address => uint256[]) public beginTimes;
    mapping(address => uint256) public nonces;

    event GameHook(
        uint256 opcode,
        address owner,
        uint256 beginTime,
        uint256 amount,
        uint256 nonce
    );

    constructor(address _token) {
        erc20 = IERC20(_token);
        erc20Metadata = IERC20Metadata(_token);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        SIGNER = msg.sender;
        DEV = msg.sender;
        TICKET_PRICE = 100 * 10**erc20Metadata.decimals();
        BASIC_REWARDS = 10 * 10**erc20Metadata.decimals();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function changeDev(address _dev) public onlyRole(DEFAULT_ADMIN_ROLE) {
        DEV = _dev;
    }

    function changeSigner(address _signer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        SIGNER = _signer;
    }

    function newRound() external whenNotPaused {
        require(msg.sender.code.length == 0, "must user call");

        uint256[] storage times = beginTimes[msg.sender];
        require(times.length < 20, "maximum number of game rounds reached");
        if (times.length > 0) {
            require(
                (times[times.length - 1] + ROUND_DURATION_SECONDS) <
                block.timestamp,
                "current round is not over"
            );
        }

        uint256 amount = 0;
        // new round 1
        if (times.length == 0) {
            require(
                erc20.allowance(msg.sender, address(this)) >= TICKET_PRICE,
                "not enough approve tokens"
            );
            erc20.safeTransferFrom(msg.sender, address(this), TICKET_PRICE);
            amount = TICKET_PRICE;
        }

        uint256 nroundTime = nextRoundTime();
        times.push(nroundTime);

        uint256 nonce = nonces[msg.sender];
        emit GameHook(times.length, msg.sender, nroundTime, amount, nonce);
        nonces[msg.sender] = (nonce + 1);
    }

    function withdraw(
        uint256 round1Invitations,
        uint256 round2Invitations,
        uint256 deadline,
        bytes calldata signature
    ) public payable whenNotPaused {
        require(msg.sender.code.length == 0, "must user call");
        require(deadline >= block.timestamp, "expired");
        require(
            round1Invitations >= 0,
            "round1Invitations must be greater than or equal to 0"
        );
        require(
            round2Invitations >= 0,
            "round2Invitations must be greater than or equal to 0"
        );
        require(
            round1Invitations <= 5,
            "round1Invitation must be less than or equal to 5"
        );
        require(
            round2Invitations <= 5,
            "round2Invitation must be less than or equal to 5"
        );

        uint256[] memory times = beginTimes[msg.sender];
        delete beginTimes[msg.sender];

        require(times.length > 0, "did not participate in the game");
        require(
            (times[times.length - 1] + ROUND_DURATION_SECONDS) <
            block.timestamp,
            "current round is not over"
        );

        bytes32 message = hashWithdraw(
            msg.sender,
            round1Invitations,
            round2Invitations,
            deadline
        );

        require(
            message.toEthSignedMessageHash().recover(signature) == SIGNER,
            "invalid signature"
        );

        uint256 totalAmount = calculate(
            round1Invitations,
            round2Invitations,
            times.length
        );
        // 14% fee
        uint256 fee = (totalAmount * 14) / 100;
        uint256 amount = totalAmount - fee;

        uint256 nonce = nonces[msg.sender];
        nonces[msg.sender] = (nonce + 1);

        erc20.safeTransfer(DEV, fee);
        erc20.safeTransfer(msg.sender, amount);

        emit GameHook(0, msg.sender, 0, totalAmount, nonce);
    }

    function calculate(
        uint256 round1Invitations,
        uint256 round2Invitations,
        uint256 rounds
    ) public view returns (uint256) {
        require(rounds > 0, "rounds must be greater than 0");
        require(rounds <= 20, "rounds must be less than or equal to 20");
        require(
            round1Invitations >= 0,
            "round1Invitations must be greater than or equal to 0"
        );
        require(
            round2Invitations >= 0,
            "round2Invitations must be greater than or equal to 0"
        );
        require(
            round1Invitations <= 5,
            "round1Invitation must be less than or equal to 5"
        );
        require(
            round2Invitations <= 5,
            "round2Invitation must be less than or equal to 5"
        );

        uint256 amount = 0;
        uint256 amountTemp = 0;
        uint256[] memory amounts = new uint256[](rounds);
        for (uint256 index = 0; index < rounds; index++) {
            if (index <= 1) {
                amounts[index] =
                BASIC_REWARDS +
                ((BASIC_REWARDS * 4) / 10) *
                (index == 0 ? round1Invitations : round2Invitations);
                amount += amounts[index];
                continue;
            }
            amountTemp = (amounts[index - 2] + amounts[index - 1]);
            amount += amountTemp;
            amounts[index] = amountTemp;
        }
        return amount + TICKET_PRICE;
    }

    function nextRoundTime() public view returns (uint256) {
        uint256 secondsOfDay = block.timestamp % 86400;
        return
        secondsOfDay > ROUND_BEGIN_TIME
        ? (86400 - secondsOfDay + ROUND_BEGIN_TIME + block.timestamp)
        : (ROUND_BEGIN_TIME - secondsOfDay + block.timestamp);
    }

    function getBeginTimes(address _user)
    public
    view
    returns (uint256[] memory)
    {
        return beginTimes[_user];
    }

    function hashWithdraw(
        address sender,
        uint256 round1Invitations,
        uint256 round2Invitations,
        uint256 deadline
    ) public view returns (bytes32) {
        uint256 nonce = nonces[sender];
        return
        keccak256(
            abi.encodePacked(
                sender,
                round1Invitations,
                round2Invitations,
                nonce,
                deadline
            )
        );
    }
}