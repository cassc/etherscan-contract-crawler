// SPDX-License-Identifier: GPLv3
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Condition.sol";
import "./Verifier.sol";

/**
 * RedPacket with zk-proof.
 * https://redpacket.eth.itranswarp.com
 */
contract RedPacket is Verifier {
    using SafeERC20 for IERC20;

    enum BonusType {
        AVERAGE,
        RANDOM
    }

    struct RedPacketInfo {
        uint256 passcodeHash; // passcode hash of red packet
        uint256 amount; // amount of token
        uint256 amountLeft; // mutable: balance of token
        address creator; // creator address
        address token; // token address
        address condition; // condition contract address
        uint32 total; // total number of address
        uint32 totalLeft; // mutable: current number of address that can withdraw
        BonusType bonusType;
    }

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 internal nextId;
    mapping(uint256 => RedPacketInfo) internal redPackets;
    mapping(bytes32 => bool) internal withdrawedMap;

    event Create(
        uint256 redPacketId,
        address indexed creator,
        address indexed token,
        uint256 amount,
        uint32 total,
        BonusType bonusType
    );

    event Withdraw(
        uint256 redPacketId,
        address indexed to,
        address indexed token,
        uint256 bonus,
        uint256 bonusLeft,
        uint32 totalLeft
    );

    function getRedPacket(uint256 id)
        public
        view
        returns (RedPacketInfo memory)
    {
        RedPacketInfo memory p = redPackets[id];
        require(p.token != address(0), "Not exist");
        return p;
    }

    function create(
        address token,
        uint256 amount,
        uint32 total,
        BonusType bonusType,
        uint256 passcodeHash,
        address condition
    ) public payable returns (uint256) {
        require(token != address(0), "Invalid token address");
        require(total > 0, "Invalid total");
        require(amount >= total, "Invalid amount");

        // transfer token into contract:
        if (token == ETH) {
            require(msg.value == amount, "Invalid value");
        } else {
            (IERC20(token)).safeTransferFrom(msg.sender, address(this), amount);
        }

        nextId++;
        uint256 id = nextId;
        RedPacketInfo storage p = redPackets[id];
        p.passcodeHash = passcodeHash;
        p.amount = amount;
        p.amountLeft = amount;
        p.condition = condition;
        p.creator = msg.sender;
        p.token = token;
        p.total = total;
        p.totalLeft = total;
        p.bonusType = bonusType;
        emit Create(id, msg.sender, token, amount, total, bonusType);
        return id;
    }

    function isOpened(uint256 id, address addr) public view returns (bool) {
        bytes32 withdrawedHash = keccak256(abi.encodePacked(id, addr));
        return withdrawedMap[withdrawedHash];
    }

    function open(
        uint256 id,
        // zk proof:
        uint256[] memory proof
    ) public returns (uint256) {
        RedPacketInfo storage p = redPackets[id];
        require(p.token != address(0), "Not exist");
        address condition = p.condition;
        if (condition != address(0)) {
            require(
                ICondition(condition).check(address(this), id, msg.sender),
                "Address rejected"
            );
        }

        require(p.totalLeft > 0, "Red packet is empty");

        // can only withdraw once for same red packet:
        bytes32 withdrawedHash = keccak256(abi.encodePacked(id, msg.sender));
        require(!withdrawedMap[withdrawedHash], "Already opened");
        withdrawedMap[withdrawedHash] = true;

        // verify zk-proof
        require(proof.length == 8, "Invalid proof");
        uint256[2] memory a = [proof[0], proof[1]];
        uint256[2][2] memory b = [[proof[2], proof[3]], [proof[4], proof[5]]];
        uint256[2] memory c = [proof[6], proof[7]];
        uint256[2] memory input = [
            p.passcodeHash,
            uint256(uint160(msg.sender))
        ];
        require(verifyProof(a, b, c, input), "Failed verify proof");

        uint256 bonus = getBonus(
            p.amount,
            p.amountLeft,
            p.total,
            p.totalLeft,
            p.bonusType
        );

        uint256 bonusLeft = p.amountLeft - bonus;
        p.amountLeft = bonusLeft;
        p.totalLeft = p.totalLeft - 1;

        if (p.token == ETH) {
            (bool sent, bytes memory _data) = payable(msg.sender).call{
                value: bonus
            }("");
            require(sent, "Failed to send Ether");
        } else {
            (IERC20(p.token)).safeTransfer(msg.sender, bonus);
        }

        emit Withdraw(id, msg.sender, p.token, bonus, bonusLeft, p.totalLeft);
        return bonus;
    }

    function getBonus(
        uint256 amount,
        uint256 amountLeft,
        uint32 total,
        uint32 totalLeft,
        BonusType bonusType
    ) internal view returns (uint256) {
        if (totalLeft == 1) {
            return amountLeft; // last one picks all
        }
        if (bonusType == BonusType.AVERAGE) {
            return amount / total;
        }
        if (bonusType == BonusType.RANDOM) {
            uint256 up = amountLeft - totalLeft + 1;
            uint256 rnd = uint256(
                keccak256(
                    abi.encodePacked(msg.sender, amountLeft, block.timestamp)
                )
            ) % ((amount << 1) / total);
            if (rnd < 1) {
                return 1;
            }
            if (rnd > up) {
                return up;
            }
            return rnd;
        }
        revert("Invalid bonus type");
    }
}