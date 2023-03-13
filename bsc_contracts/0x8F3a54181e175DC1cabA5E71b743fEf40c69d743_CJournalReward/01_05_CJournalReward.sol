// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "ERC20.sol";

contract CJournalReward {
    address public OWNER;
    address public ADMIN;
    // Infos
    ERC20 public TOKEN;
    bytes32 public MERKLE_ROOT;
    bytes32 public PREV_MERKLE_ROOT;
    uint64 public POINT_TOTAL;
    uint64 public POINT_USED;
    uint256 public TOKEN_CLAIMED;
    uint32 public UNIQUE_USER;

    mapping(address => uint32) private USER_POINT_CLAIMED;

    event Claim(address indexed sender, uint32 point, uint32 sum, uint256 token);
    error NotOwner();

    constructor(address admin, ERC20 token) {
        OWNER = msg.sender;
        ADMIN = admin;
        TOKEN = token;
    }

    function updateAdmin(address admin) public {
        if (OWNER != msg.sender) {
            revert NotOwner();
        }
        ADMIN = admin;
    }

    function updateToken(ERC20 token) public {
        if (OWNER != msg.sender) {
            revert NotOwner();
        }
        TOKEN = token;
    }

    function withdraw(uint256 amount) public {
        if (OWNER != msg.sender) {
            revert NotOwner();
        }
        TOKEN.transfer(OWNER, amount);
    }

    function updateClaimData(bytes32 root, uint64 total) public {
        if (OWNER != msg.sender && ADMIN != msg.sender) {
            revert NotOwner();
        }
        PREV_MERKLE_ROOT = MERKLE_ROOT;
        MERKLE_ROOT = root;
        POINT_TOTAL = total;
    }

    function claim(
        uint32 point,
        uint32 sum,
        bytes32 dataHash,
        bytes32[] memory proof
    ) public {
        bytes32 computedHash = keccak256(abi.encodePacked(sum, msg.sender, dataHash));
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        // Check prev merkle root to ensure users' transactions won't fail after merkle root is updated.
        require((computedHash == MERKLE_ROOT || computedHash == PREV_MERKLE_ROOT), "INVALID_PROOF");
        uint32 pointClaimed = USER_POINT_CLAIMED[msg.sender];
        require(pointClaimed + point <= sum, "NOT_ENOUGH_POINT");
        uint256 token = exchangeRate() * uint256(point);
        require(token > 0, "INVALID_CLAIM");
        TOKEN.transfer(msg.sender, token);
        USER_POINT_CLAIMED[msg.sender] = pointClaimed + point;
        POINT_USED += uint64(point);
        TOKEN_CLAIMED += token;
        if (pointClaimed == 0) {
            UNIQUE_USER++;
        }
        emit Claim(msg.sender, point, sum, token);
    }

    function exchangeRate() public view returns (uint256) {
        return TOKEN.balanceOf(address(this)) / uint256(POINT_TOTAL - POINT_USED);
    }

    function userPointClaimed(address user) public view returns (uint256) {
        return USER_POINT_CLAIMED[user];
    }

    function info()
        public
        view
        returns (
            address,
            bytes32,
            uint64,
            uint64,
            uint256,
            uint32
        )
    {
        return (address(TOKEN), MERKLE_ROOT, POINT_TOTAL, POINT_USED, TOKEN_CLAIMED, UNIQUE_USER);
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}