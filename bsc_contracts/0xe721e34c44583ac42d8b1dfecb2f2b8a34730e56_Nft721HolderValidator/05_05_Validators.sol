// SPDX-License-Identifier: GPLv3
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICondition {
    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view returns (bool);
}

interface IRedPacket {
    enum BonusType {
        AVERAGE,
        RANDOM
    }
    struct RedPacketInfo {
        uint256 passcodeHash;
        uint256 amount;
        uint256 amountLeft;
        address creator;
        address token;
        address condition;
        uint32 total;
        uint32 totalLeft;
        BonusType bonusType;
    }

    function getRedPacket(uint256 id)
        external
        view
        returns (RedPacketInfo memory);

    function isOpened(uint256 id, address addr) external view returns (bool);
}

abstract contract BaseValidator is ICondition {
    IRedPacket internal redPacket;

    constructor(address redPacketAddr) {
        redPacket = IRedPacket(redPacketAddr);
    }

    modifier onlyCreator(uint256 redPacketId) {
        IRedPacket.RedPacketInfo memory rp = redPacket.getRedPacket(
            redPacketId
        );
        require(msg.sender == rp.creator, "not creator");
        _;
    }

    modifier checkContract(address addr) {
        require(addr == address(redPacket), "invalid red packet address");
        _;
    }
}

/**
 * Only address in the pool can open the red packet.
 */
contract AddressPoolValidator is BaseValidator {
    mapping(uint256 => mapping(address => bool)) pools;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function addAddresses(uint256 redPacketId, address[] memory addrs)
        public
        onlyCreator(redPacketId)
    {
        setAddresses(true, redPacketId, addrs);
    }

    function removeAddresses(uint256 redPacketId, address[] memory addrs)
        public
        onlyCreator(redPacketId)
    {
        setAddresses(false, redPacketId, addrs);
    }

    function setAddresses(
        bool add,
        uint256 redPacketId,
        address[] memory addrs
    ) internal {
        mapping(address => bool) storage pool = pools[redPacketId];
        for (uint256 i = 0; i < addrs.length; i++) {
            pool[addrs[i]] = add;
        }
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        mapping(address => bool) storage pool = pools[redPacketId];
        return pool[operator];
    }
}

/**
 * Only the NFT-721 holder can open the red packet
 */
contract Nft721HolderValidator is BaseValidator {
    mapping(uint256 => address) nftAddrs;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function setERC721(uint256 redPacketId, address nftAddr)
        public
        onlyCreator(redPacketId)
    {
        nftAddrs[redPacketId] = nftAddr;
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        address nftAddr = nftAddrs[redPacketId];
        if (nftAddr == address(0)) {
            return false;
        }
        return IERC721(nftAddr).balanceOf(operator) > 0;
    }
}

/**
 * Only the NFT-1155 holder can open the red packet
 */
contract Nft1155HolderValidator is BaseValidator {
    mapping(uint256 => address) nftAddrs;
    mapping(uint256 => uint256) nftIds;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function setERC1155(
        uint256 redPacketId,
        address nftAddr,
        uint256 nftId
    ) public onlyCreator(redPacketId) {
        nftAddrs[redPacketId] = nftAddr;
        nftIds[redPacketId] = nftId;
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        address nftAddr = nftAddrs[redPacketId];
        if (nftAddr == address(0)) {
            return false;
        }
        return IERC1155(nftAddr).balanceOf(operator, nftIds[redPacketId]) > 0;
    }
}

/**
 * Only the ERC20 holder with minimum balance can open the red packet
 */
contract ERC20HolderValidator is BaseValidator {
    mapping(uint256 => address) ercAddrs;
    mapping(uint256 => uint256) ercHolds;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function setERC20(
        uint256 redPacketId,
        address ercAddr,
        uint256 ercMinHold
    ) public onlyCreator(redPacketId) {
        ercAddrs[redPacketId] = ercAddr;
        ercHolds[redPacketId] = ercMinHold;
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        address erc = ercAddrs[redPacketId];
        if (erc == address(0)) {
            return false;
        }
        return IERC20(erc).balanceOf(operator) >= ercHolds[redPacketId];
    }
}

/**
 * Can open the red packet after specific timestamp.
 */
contract TimeBasedValidator is BaseValidator {
    mapping(uint256 => uint256) timestamps;

    constructor(address redPacketAddr) BaseValidator(redPacketAddr) {}

    function setTimestamp(uint256 redPacketId, uint256 timestamp)
        public
        onlyCreator(redPacketId)
    {
        timestamps[redPacketId] = timestamp;
    }

    function check(
        address redPacketContract,
        uint256 redPacketId,
        address operator
    ) external view checkContract(redPacketContract) returns (bool) {
        uint256 timestamp = timestamps[redPacketId];
        if (timestamp == 0) {
            return false;
        }
        return block.timestamp >= timestamp;
    }
}