// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../open-zeppelin/interfaces/IERC20.sol";
import "../open-zeppelin/libraries/SafeERC20.sol";
import "../open-zeppelin/utils/Ownable.sol";

/** @title MultiVesting contract  */
/// @author Paladin
/*
    Contract that manages locked tokens for multiple users.
    Tokens can be released according to a vesting schedule, with a cliff and a vesting period
    If set at creation, vesting can be revoked by the owner
*/
contract MultiVesting is Ownable {
    using SafeERC20 for IERC20;


    // Storage : 

    // ERC20 token locked in the contract
    IERC20 public pal;

    // address to receive the tokens
    mapping(address => bool) public beneficiaries;

    // dates are in seconds
    mapping(address => uint256) public start;
    // durations are in seconds
    mapping(address => uint256) public cliff;
    mapping(address => uint256) public duration;

    // beneficiary accepted the vesting terms
    mapping(address => bool) public accepted;

    // vesting can be set as revocable when created, and allow owner to revoke unvested tokens
    mapping(address => bool) public revocable;
    mapping(address => bool) public revoked;

    // amount of tokens locked when starting the Vesting
    mapping(address => uint256) public lockedAmount;
    // amount of tokens released to the beneficiary
    mapping(address => uint256) public totalReleasedAmount;


    // Events : 

    event TokensReleased(address indexed beneficiary, uint256 releasedAmount);
    event TokenVestingRevoked(address indexed beneficiary, uint256 revokedAmount);
    event LockAccepted(address indexed beneficiary);
    event LockCanceled(address indexed beneficiary);


    //Modifiers : 

    modifier isBeneficiary() {
        require(beneficiaries[msg.sender], "TokenVesting: Caller not beneficiary");
        _;
    }

    modifier onlyIfAccepted() {
        require(beneficiaries[msg.sender], "TokenVesting: Caller not beneficiary");
        require(accepted[msg.sender], "TokenVesting: Vesting not accepted");
        _;
    }


    // Constructor : 
    /**
     * @dev Creates the vesting contract
     * @param _palAddress address of the locked token (PAL token)
     */
    constructor(
        address _admin,
        address _palAddress
    ){
        require(_admin != address(0), "TokenVesting: admin is address zero");
        require(_palAddress != address(0), "TokenVesting: incorrect PAL address");

        pal = IERC20(_palAddress);

        transferOwnership(_admin);
    }


    // Functions : 

    /**
     * @dev Adds beneficiary to the vesting contract with a cliff. Cliff can be 0
     * @param _beneficiary address receiving the vested tokens
     * @param _lockedAmount amount of tokens locked in the contract
     * @param _startTimestamp timestamp when the vesting starts (Unix Timestamp)
     * @param _cliffDuration duration of the cliff period (in seconds)
     * @param _duration duration of the vesting period (in seconds)
     * @param _revocable is vesting revocable
     */
    function addBeneficiary(
        address _beneficiary,
        uint256 _lockedAmount,
        uint256 _startTimestamp, //Unix Timestamp
        uint256 _cliffDuration, //in seconds
        uint256 _duration, //in seconds
        bool _revocable
    ) external onlyOwner {
        require(beneficiaries[_beneficiary] == false, "TokenVesting: Beneficiary already added");


        require(_beneficiary != address(0), "TokenVesting: beneficiary is address zero");
        require(_lockedAmount > 0, "TokenVesting: locked amount is null");
        require(_duration > 0, "TokenVesting: duration is null");
        require(_cliffDuration <= _duration, "TokenVesting: cliff longer than duration");
        require(_startTimestamp + _duration > block.timestamp, "TokenVesting: incorrect vesting dates");


        beneficiaries[_beneficiary] = true;

        lockedAmount[_beneficiary] = _lockedAmount;

        start[_beneficiary] = _startTimestamp;
        cliff[_beneficiary] = _cliffDuration;
        duration[_beneficiary] = _duration;

        revocable[_beneficiary] = _revocable;
        
    }

    function acceptLock() external isBeneficiary {
        address beneficiary = msg.sender;

        accepted[beneficiary] = true;

        emit LockAccepted(beneficiary);
    }


    function cancelLock(address beneficiary) external onlyOwner {
        require(accepted[beneficiary] == false, "TokenVesting: Cannot cancel accepted contract");

        pal.safeTransfer(owner(), lockedAmount[beneficiary]);

        emit LockCanceled(beneficiary);
    }


    function release() external onlyIfAccepted {
        address beneficiary = msg.sender;

        uint256 unreleasedAmount = _releasableAmount(beneficiary);

        require(unreleasedAmount > 0, "TokenVesting: No tokens to release");

        totalReleasedAmount[beneficiary] = totalReleasedAmount[beneficiary] + unreleasedAmount;

        pal.safeTransfer(beneficiary, unreleasedAmount);

        emit TokensReleased(beneficiary, unreleasedAmount);
    }


    function releasableAmount(address beneficiary) external view returns (uint256){
        return _releasableAmount(beneficiary);
    }


    function _vestedAmount(address beneficiary) private view returns (uint256) {
        if (block.timestamp < start[beneficiary] + cliff[beneficiary] || !accepted[beneficiary]) {
            return 0;
        } else if (block.timestamp >= start[beneficiary] + duration[beneficiary] || revoked[beneficiary]) {
            return lockedAmount[beneficiary];
        } else {
            return (lockedAmount[beneficiary] * (block.timestamp - start[beneficiary])) / duration[beneficiary];
        }
    }


    function _releasableAmount(address beneficiary) private view returns (uint256) {
        return _vestedAmount(beneficiary) - totalReleasedAmount[beneficiary];
    }


    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Cannot recover the locked token
        require(tokenAddress != address(pal), "TokenVesting: Cannot recover locked tokens");

        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }


    // Admin Functions : 

    function revoke(address beneficiary) external onlyOwner {
        require(revocable[beneficiary], "TokenVesting: Not revocable");
        require(!revoked[beneficiary], "TokenVesting: Already revoked");

        uint256 remaingingAmount = lockedAmount[beneficiary] - totalReleasedAmount[beneficiary];

        uint256 unreleasedAmount = _releasableAmount(beneficiary);
        uint256 revokedAmount = remaingingAmount - unreleasedAmount;

        revoked[beneficiary] = true;

        pal.safeTransfer(owner(), revokedAmount);

        emit TokenVestingRevoked(beneficiary, revokedAmount);
    }

}