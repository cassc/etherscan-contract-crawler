// SPDX-License-Identifier: MIT
/*
 __       __  ________  __    __ 
|  \  _  |  \|        \|  \  |  \
| $$ / \ | $$| $$$$$$$$| $$\ | $$
| $$/  $\| $$| $$__    | $$$\| $$
| $$  $$$\ $$| $$  \   | $$$$\ $$
| $$ $$\$$\$$| $$$$$   | $$\$$ $$
| $$$$  \$$$$| $$_____ | $$ \$$$$
| $$$    \$$$| $$     \| $$  \$$$
 \$$      \$$ \$$$$$$$$ \$$   \$$
*/

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IDelegationRegistry {
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);
}

/**
 * @title WENAirdrop
 */
contract WENAirdrop is Ownable, ReentrancyGuard {

    IDelegationRegistry immutable dc;

    event ClaimStatusUpdated(bool _isActive);
    event MerkleRootUpdated(bytes32 _merkleRoot);
    event Claimed(address indexed _address, uint256 _tokens);
    event Released(address indexed _address, uint256 _tokens);

    struct VestingSchedule {
        bool initialized;
        // start time of the vesting period
        uint256 start;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
    }

    // address of the ERC20 token
    address public immutable _token;
    // duration of the vesting period in seconds
    uint256 public immutable _duration;
    // merkle root for airdrop
    bytes32 public _merkleRoot;
    // claim status
    bool public _claimIsActive;
    // total amount vesting
    uint256 public vestingSchedulesTotalAmount;
    // vesing schedules
    mapping(address => VestingSchedule) public vestingSchedules;
    // tracks which beneficiaries have claimed their airdrop
    mapping(address => bool) public hasClaimed;
    
    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the ERC20 token contract
     * @param duration_ of the vesting period in seconds
     * @param delegatecash_ is the delegate.cash contract address
     */
    constructor(address token_, uint256 duration_, address delegatecash_) {
        // Check that duration is greater than 0.
        require(duration_ > 0, "Bad duration");
        // Check that the token address is not 0x0.
        require(token_ != address(0x0), "Bad token address");
        // Check that delegate.cash address is not 0x0.
        require(delegatecash_ != address(0x0), "Bad delegate.cash address");
        // Set the token address.
        _token = token_;
        // Set the duration.
        _duration = duration_;
        // initialize delegate.cash
        dc = IDelegationRegistry(delegatecash_);
    }

    function setClaimStatus(bool claimIsActive_) external onlyOwner {
        _claimIsActive = claimIsActive_;
        emit ClaimStatusUpdated(claimIsActive_);
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _merkleRoot = merkleRoot_;
        emit MerkleRootUpdated(merkleRoot_);
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary and pays out 10% of _amount.
     * @param _address delegate.cash vault or msg.sender if delegate.cash isn't being used
     * @param _amount total amount (with 18 decimals) of tokens to be released at the end of the vesting
     * @param _proof merkle proof
     */
    function claim(
        address _address,
        uint256 _amount, 
        bytes32[] memory _proof
    ) external nonReentrant {
        // claim must be on for new vesting schedules to be created
        require(_claimIsActive, "Claim is off");
        // Check that _address is not 0x0.
        require(_address != address(0x0), "Bad address");
        if (_address != msg.sender) require(dc.checkDelegateForContract(msg.sender, _address, address(this)), "Unauthorized");
        // Make sure the vesting schedule hasn't already been created
        require(!hasClaimed[_address], "Already claimed");
        // Verify that the beneficiary is in the allowlist
        bytes32 _leaf = keccak256(abi.encode(_address, _amount));
        require(MerkleProof.verify(_proof, _merkleRoot, _leaf), "Bad proof");
        // Release 10% of tokens now and create a vesting schedule for the rest
        uint256 _initial = _amount * 10/100;
        createVestingSchedule(_address, _amount - _initial);
        IERC20(_token).transfer(_address, _initial);
        hasClaimed[_address] = true;
        emit Claimed(_address, _amount);
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function createVestingSchedule(address _beneficiary, uint256 _amount) 
        internal 
    {
        require(getWithdrawableAmount() >= _amount, "Insufficient tokens");
        require(_amount > 0, "Invalid amount");
        vestingSchedules[_beneficiary] = VestingSchedule(
            true,
            block.timestamp,
            _amount,
            0
        );
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount + _amount;
    }

    /**
     * @notice Release vested amount of tokens.
     * @param _address delegate.cash vault or msg.sender if delegate.cash isn't being used
     */
    function release(address _address) external nonReentrant {
        require(_address != address(0x0), "Bad address");
        if (_address != msg.sender) require(dc.checkDelegateForContract(msg.sender, _address, address(this)), "Unauthorized");
        require(vestingSchedules[_address].initialized);
        VestingSchedule storage vestingSchedule = vestingSchedules[_address];
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount > 0, "None releasable");
        vestingSchedule.released = vestingSchedule.released + vestedAmount;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - vestedAmount;
        IERC20(_token).transfer(_address, vestedAmount);
        emit Released(_address, vestedAmount);
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @return the amount of releasable tokens
     */
    function computeReleasableAmount(address _beneficiary)
        external
        view
        returns (uint256) {
        VestingSchedule storage vestingSchedule = vestingSchedules[_beneficiary];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @param vestingSchedule that tracks the vesting of a beneficiary
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
        internal 
        view 
        returns (uint256) {
        // Retrieve the current time.
        uint256 currentTime = block.timestamp;
        if (currentTime >= vestingSchedule.start + _duration) {
            // If the current time is after the vesting period, all tokens are releasable,
            // minus the amount already released.
            return vestingSchedule.amountTotal - vestingSchedule.released;
        } else {
            // Otherwise, some tokens are releasable.
            // Compute the number of seconds that have elapsed.
            uint256 vestedSeconds = currentTime - vestingSchedule.start;
            // Compute the amount of tokens that are vested.
            uint256 vestedAmount = (vestingSchedule.amountTotal * vestedSeconds) / _duration;
            // Subtract the amount already released and return.
            return vestedAmount - vestingSchedule.released;
        }
    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @param amount the amount to withdraw
     */
    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        require(getWithdrawableAmount() >= amount, "Insufficient funds");
        IERC20(_token).transfer(msg.sender, amount);
    }

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
    */
    function getWithdrawableAmount() public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }
}