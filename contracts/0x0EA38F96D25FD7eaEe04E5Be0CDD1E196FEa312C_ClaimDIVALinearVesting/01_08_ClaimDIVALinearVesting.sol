//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ClaimDIVALinearVesting is Ownable2Step, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => bool) public claimed;

    mapping(address => uint256) public claimedAmount;

    mapping(address => uint256) public lastDrawnAt;

    bool public trigger;

    bytes32 public merkleRoot;
    uint256 public claimPeriodStarts;
    uint256 public constant YEAR = 31556926;

    IERC20 public immutable divaToken;

    event MerkleRootChanged(bytes32 _merkleRoot);
    event ClaimStartTimeChanged(uint256 _claimPeriodStarts);
    event Claim(address indexed _claimant, uint256 _amount);

    error Address0Error();
    error InvalidProof();
    error AlreadyClaimed();
    error ClaimNotStarted();
    error InitErrorMerkeRoot();
    error InitErrorClaimPeriod();
    error ZeroClaimableAmount();
    error ContractNotYetActivatedForClaim();
    error InvalidStartTime();
    error ClaimPeriodNotYetExpired();
    error ClaimAlreadyStarted();

    constructor(address _divaToken) {
        if (_divaToken == address(0)) revert Address0Error();
        divaToken = IERC20(_divaToken);
    }

    function claimTokens(
        uint256 _amount,
        uint256 _time,
        bytes32[] calldata _merkleProof
    ) external nonReentrant {
        if (!trigger) revert ContractNotYetActivatedForClaim();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount, _time));
        bool valid = MerkleProof.verify(_merkleProof, merkleRoot, leaf);
        if (!valid) revert InvalidProof();
        if (block.timestamp < claimPeriodStarts) revert ClaimNotStarted();

        uint256 immediateClaimableAmount = (_amount.mul(40)).div(100);
        uint256 vestingAmount = _amount.sub(immediateClaimableAmount);

        if (!claimed[msg.sender]) {
            claimedAmount[msg.sender] = immediateClaimableAmount;
            claimed[msg.sender] = true;
            divaToken.transfer(msg.sender, immediateClaimableAmount);
            emit Claim(msg.sender, immediateClaimableAmount);
        }

        // Note that the boundary for amountClaimable is set in `availableDrawDownAmount` and
        // it cannot exceed `_amount - claimedAmount[msg.sender]`.
        uint256 amountClaimable = availableDrawDownAmount(_amount, vestingAmount, _time, msg.sender);
        if (amountClaimable == 0) revert ZeroClaimableAmount();

        claimedAmount[msg.sender] = claimedAmount[msg.sender].add(amountClaimable);
        lastDrawnAt[msg.sender] = block.timestamp;
        emit Claim(msg.sender, amountClaimable);

        divaToken.transfer(msg.sender, amountClaimable);
    }

    function availableDrawDownAmount(
        uint256 _totalAmount,
        uint256 _vestingAmount,
        uint256 _time,
        address _beneficiary
    ) public view returns (uint256) {
        uint256 end = claimPeriodStarts.add(_time);

        if (block.timestamp <= claimPeriodStarts) {
            return 0;
        }

        if (block.timestamp > end) {
            return _totalAmount.sub(claimedAmount[_beneficiary]);
        }

        uint256 timeLastDrawnOrStart = lastDrawnAt[_beneficiary] == 0 ? claimPeriodStarts : lastDrawnAt[_beneficiary];
        // Find out how much time has passed since last invocation
        uint256 timePassedSinceLastInvocation = block.timestamp.sub(timeLastDrawnOrStart);

        // Work out how many due tokens - time passed * rate per second
        uint256 amountClaimable = timePassedSinceLastInvocation.mul(_vestingAmount).div(_time);

        return amountClaimable;
    }

    function setClaimPeriodStartTime(uint256 _claimPeriodStarts) external notTriggered onlyOwner {
        if (_claimPeriodStarts <= block.timestamp) revert InvalidStartTime();
        claimPeriodStarts = _claimPeriodStarts;
        emit ClaimStartTimeChanged(_claimPeriodStarts);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external notTriggered onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    function setTrigger() external onlyOwner notTriggered {
        if (merkleRoot == bytes32(0)) revert InitErrorMerkeRoot();
        if (claimPeriodStarts == 0) revert InitErrorClaimPeriod();
        trigger = true;
    }

    function withdrawUnclaimedDivaTokens() external onlyOwner {
        if (block.timestamp < claimPeriodStarts.add(YEAR.mul(3))) revert ClaimPeriodNotYetExpired();
        divaToken.transfer(msg.sender, divaToken.balanceOf(address(this)));
    }

    modifier notTriggered() {
        if (trigger) revert ClaimAlreadyStarted();
        _;
    }
}