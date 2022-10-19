// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { MerkleProof } from "@openzeppelin/contracts-0.8/utils/cryptography/MerkleProof.sol";
import {IWmxLocker} from "./Interfaces.sol";
import {WmxMath} from "./WmxMath.sol";
import { IERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";

/**
 * @title   WmxMerkleDrop
 * @dev     Forked from convex-platform/contracts/contracts/MerkleAirdrop.sol. Changes:
 *            - solc 0.8.11 & OpenZeppelin MerkleDrop
 *            - Delayed start w/ trigger
 *            - EndTime for withdrawal to treasuryDAO
 *            - Non custodial (cannot change root)
 */
contract WmxMerkleDrop {
    using SafeERC20 for IERC20;

    address public dao;
    bytes32 public merkleRoot;

    IERC20 public immutable wmx;
    IWmxLocker public wmxLocker;

    uint256 public immutable deployTime;
    uint256 public startTime;
    uint256 public immutable expiryTime;

    mapping(address => bool) public hasClaimed;

    event DaoSet(address newDao);
    event RootSet(bytes32 newRoot);
    event StartedEarly();
    event ExpiredWithdrawn(uint256 amount);
    event LockerSet(address newLocker);
    event Claimed(address addr, uint256 amt);
    event PenaltyForwarded(uint256 amount);
    event Rescued();

    /**
     * @param _dao              The Wmx Dao
     * @param _merkleRoot       Merkle root
     * @param _wmx              Wmx token
     * @param _wmxLocker        Wmx locker contract
     * @param _startDelay       Delay until claim is live
     * @param _expiresAfter     Timestamp claim expires
     */
    constructor(
        address _dao,
        bytes32 _merkleRoot,
        address _wmx,
        address _wmxLocker,
        uint256 _startDelay,
        uint256 _expiresAfter
    ) {
        require(_dao != address(0), "!dao");
        dao = _dao;
        merkleRoot = _merkleRoot;
        require(_wmx != address(0), "!wmx");
        wmx = IERC20(_wmx);
        wmxLocker = IWmxLocker(_wmxLocker);

        deployTime = block.timestamp;
        startTime = block.timestamp + _startDelay;

        require(_expiresAfter > 2 weeks, "!expiry");
        expiryTime = startTime + _expiresAfter;
    }

    /***************************************
                    CONFIG
    ****************************************/

    function setDao(address _newDao) external {
        require(msg.sender == dao, "!auth");
        dao = _newDao;
        emit DaoSet(_newDao);
    }

    function setRoot(bytes32 _merkleRoot) external {
        require(msg.sender == dao, "!auth");
        require(merkleRoot == bytes32(0), "already set");
        merkleRoot = _merkleRoot;
        emit RootSet(_merkleRoot);
    }

    function startEarly() external {
        require(msg.sender == dao, "!auth");
        require(block.timestamp < startTime, "!earlier");
        startTime = block.timestamp;
        emit StartedEarly();
    }

    function withdrawExpired() external {
        require(msg.sender == dao, "!auth");
        require(block.timestamp > expiryTime, "!expired");
        uint256 amt = wmx.balanceOf(address(this));
        wmx.safeTransfer(dao, amt);
        emit ExpiredWithdrawn(amt);
    }

    function setLocker(address _newLocker) external {
        require(msg.sender == dao, "!auth");
        wmxLocker = IWmxLocker(_newLocker);
        emit LockerSet(_newLocker);
    }

    function rescueReward() public {
        require(msg.sender == dao, "!auth");
        require(block.timestamp < WmxMath.min(deployTime + 1 weeks, startTime), "too late");

        uint256 amt = wmx.balanceOf(address(this));
        wmx.safeTransfer(dao, amt);

        emit Rescued();
    }

    /***************************************
                    CLAIM
    ****************************************/

    function claim(
        bytes32[] calldata _proof,
        uint256 _amount
    ) public returns (bool) {
        require(merkleRoot != bytes32(0), "!root");
        require(block.timestamp > startTime, "!started");
        require(block.timestamp < expiryTime, "!active");
        require(_amount > 0, "!amount");
        require(hasClaimed[msg.sender] == false, "already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "invalid proof");

        hasClaimed[msg.sender] = true;

        wmx.safeApprove(address(wmxLocker), 0);
        wmx.safeApprove(address(wmxLocker), _amount);
        wmxLocker.lock(msg.sender, _amount);

        emit Claimed(msg.sender, _amount);
        return true;
    }
}