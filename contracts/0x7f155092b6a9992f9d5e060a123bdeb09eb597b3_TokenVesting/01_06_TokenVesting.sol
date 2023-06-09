// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



import "./MultiSig.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "onlyOwner");
        _;
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Returns the address of the pending owner.
    */
    function pendingOwner() external view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() external {
        require(msg.sender == _pendingOwner, "onlyPendingOwner");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}

contract TokenVestingFactory is Ownable, MultiSig {


    event TokenVestingCreated(address tokenVesting);

    // enum VestingType { SeedInvestors, StrategicInvestors, Advisors, Team, All }

    struct BeneficiaryIndex {
        address tokenVesting;
        uint256 vestingType;
        bool isExist;
        // uint256 index;
    }

    mapping(address => BeneficiaryIndex) private _beneficiaryIndex;
    address[] private _beneficiaries;
    address private _tokenAddr;
    uint256 private _decimal;

    constructor (address tokenAddr, uint256 decimal, address[] memory owners, uint256 threshold) {
        require(tokenAddr != address(0), "TokenVestingFactory: token address must not be zero");

        _tokenAddr = tokenAddr;
        _decimal = decimal;
        setupMultiSig(owners, threshold);
    }

    function create(address beneficiary, uint256 start, uint256 cliff, uint256 initialShare, uint256 periodicShare, bool revocable, uint256 vestingType) onlyOwner external {
        require(!_beneficiaryIndex[beneficiary].isExist, "TokenVestingFactory: benficiery exists");
        require(vestingType != 0, "TokenVestingFactory: vestingType 0 is reserved");

        address tokenVesting = address(new TokenVesting(_tokenAddr, beneficiary, start, cliff, initialShare, periodicShare, _decimal, revocable));

        _beneficiaries.push(beneficiary);
        _beneficiaryIndex[beneficiary].tokenVesting = tokenVesting;
        _beneficiaryIndex[beneficiary].vestingType = vestingType;
        _beneficiaryIndex[beneficiary].isExist = true;

        emit TokenVestingCreated(tokenVesting);
    }

    function initialize(address tokenVesting, address from, uint256 amount) external onlyOwner {
        TokenVesting(tokenVesting).initialize(from, amount);
    }

    function update(address tokenVesting, uint256 start, uint256 cliff, uint256 initialShare, uint256 periodicShare, bool revocable) external onlyOwner {
        TokenVesting(tokenVesting).update(start, cliff, initialShare, periodicShare, revocable);
    }


    function getBeneficiaries(uint256 vestingType) external view returns (address[] memory) {
        uint256 j = 0;
        address[] memory beneficiaries = new address[](_beneficiaries.length);

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address beneficiary = _beneficiaries[i];
            if (_beneficiaryIndex[beneficiary].vestingType == vestingType || vestingType == 0) {
                beneficiaries[j] = beneficiary;
                j++;
            }
        }
        return beneficiaries;
    }

    function getVestingType(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary].isExist, "TokenVestingFactory: benficiery does not exist");
        return _beneficiaryIndex[beneficiary].vestingType;
    }

    function getTokenVesting(address beneficiary) external view returns (address) {
        require(_beneficiaryIndex[beneficiary].isExist, "TokenVestingFactory: benficiery does not exist");
        return _beneficiaryIndex[beneficiary].tokenVesting;
    }

    function getTokenAddress() external view returns (address) {
        return _tokenAddr;
    }

    function getDecimal() external view returns (uint256) {
        return _decimal;
    }

    function revoke(address tokenVesting) external onlyMultiSig{
        TokenVesting(tokenVesting).revoke(owner());
    }

}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {    
    using SafeERC20 for IERC20;

    event TokenVestingUpdated(uint256 start, uint256 cliff, uint256 initialShare, uint256 periodicShare, bool revocable);
    event TokensReleased(address beneficiary, uint256 amount);
    event TokenVestingRevoked(address refundAddress, uint256 amount);
    event TokenVestingInitialized(address from, uint256 amount);

    enum Status {NotInitialized, Initialized, Revoked}

    // beneficiary of tokens after they are released
    address private _beneficiary;

    uint256 private _cliff;
    uint256 private _start;
    address private _tokenAddr;
    uint256 private _initialShare;
    uint256 private _periodicShare;
    uint256 private _decimal;
    uint256 private _released;

    bool private _revocable;
    Status private _status;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param revocable whether the vesting is revocable or not
     */
    constructor(
        address tokenAddr,
        address beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 initialShare,
        uint256 periodicShare,
        uint256 decimal,
        bool revocable
    )

    {
        require(beneficiary != address(0), "TokenVesting: beneficiary address must not be zero");

        _tokenAddr = tokenAddr;
        _beneficiary = beneficiary;
        _revocable = revocable;
        _cliff = start + cliff;
        _start = start;
        _initialShare = initialShare;
        _periodicShare = periodicShare;
        _decimal = decimal;
        _status = Status.NotInitialized;

    }

    /**
    * @return TokenVesting details.
    */
    function getDetails() external view returns (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256) {
        uint256 _total = IERC20(_tokenAddr).balanceOf(address(this)) + _released;
        uint256 _vested = _vestedAmount();
        uint256 _releasable = _vestedAmount() - _released;
        return (_beneficiary, _initialShare, _periodicShare, _start, _cliff, _total, _vested, _released, _releasable, _revocable, uint256(_status));
    }


    /**
     * @return the initial share of the beneficiary.
     */
    function getInitialShare() external view returns (uint256) {
        return _initialShare;
    }


    /**
     * @return the periodic share of the beneficiary.
     */
    function getPeriodicShare() external view returns (uint256) {
        return _periodicShare;
    }


    /**
     * @return the beneficiary of the tokens.
     */
    function getBeneficiary() external view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function getStart() external view returns (uint256) {
        return _start;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function getCliff() external view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the total amount of the token.
     */
    function getTotal() external view returns (uint256) {
        return IERC20(_tokenAddr).balanceOf(address(this)) + _released;
    }

    /**
     * @return the amount of the vested token.
     */
    function getVested() external view returns (uint256) {
        return _vestedAmount();
    }

    /**
     * @return the amount of the token released.
     */
    function getReleased() external view returns (uint256) {
        return _released;
    }

    /**
     * @return the amount that has already vested but hasn't been released yet.
     */
    function getReleasable() public view returns (uint256) {
        return _vestedAmount() - _released;
    }

    /**
     * @return true if the vesting is revocable.
     */
    function isRevocable() external view returns (bool) {
        return _revocable;
    }

    /**
     * @return true if the token is revoked.
     */
    function isRevoked() external view returns (bool) {
        if (_status == Status.Revoked) {
            return true;
        } else {
            return false;
        }
    }

    /**
    * @return status.
    */
    function getStatus() external view returns (uint256) {
        return uint256(_status);
    }

    /**
     * @notice change status to initialized.
     */
    function initialize(address from, uint256 amount) public onlyOwner {

        require(_status == Status.NotInitialized, "TokenVesting: status must be NotInitialized");

        _status = Status.Initialized;

        emit TokenVestingInitialized(address(from), amount);

        IERC20(_tokenAddr).safeTransferFrom(from, address(this), amount);

    }

    /**
    * @notice update token vesting contract.
    */
    function update(
        uint256 start,
        uint256 cliff,
        uint256 initialShare,
        uint256 periodicShare,
        bool revocable

    ) external onlyOwner {

        require(_status == Status.NotInitialized, "TokenVesting: status must be NotInitialized");

        _start = start;
        _cliff = start + cliff;
        _initialShare = initialShare;
        _periodicShare = periodicShare;
        _revocable = revocable;

        emit TokenVestingUpdated(_start, _cliff, _initialShare, _periodicShare, _revocable);

    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() external {
        require(_status != Status.NotInitialized, "TokenVesting: status is NotInitialized");
        uint256 unreleased = getReleasable();

        require(unreleased > 0, "TokenVesting: releasable amount is zero");

        _released = _released + unreleased;

        emit TokensReleased(address(_beneficiary), unreleased);

        IERC20(_tokenAddr).safeTransfer(_beneficiary, unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     */
    function revoke(address refundAddress) external onlyOwner {
        require(_revocable, "TokenVesting: contract is not revocable");
        require(_status != Status.Revoked, "TokenVesting: status is Revoked");

        uint256 balance = IERC20(_tokenAddr).balanceOf(address(this));

        uint256 unreleased = getReleasable();
        uint256 refund = balance - unreleased;

        _status = Status.Revoked;

        emit TokenVestingRevoked(address(refundAddress), refund);
        
        IERC20(_tokenAddr).safeTransfer(refundAddress, refund);

    }


    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = IERC20(_tokenAddr).balanceOf(address(this));
        uint256 totalBalance = currentBalance + _released;
        uint256 initialRelease = (totalBalance * _initialShare) / ((10 ** _decimal) * 100) ;

        if (block.timestamp < _start)
            return 0;

        if (_status == Status.Revoked)
            return totalBalance;

        if (block.timestamp < _cliff)
            return initialRelease;

        uint256 monthlyRelease = (totalBalance * _periodicShare) / ((10 ** _decimal) * 100);
        uint256 _months = BokkyPooBahsDateTimeLibrary.diffMonths(_cliff, block.timestamp);

        if (initialRelease + (monthlyRelease * (_months + 1)) >= totalBalance) {
            return totalBalance;
        } else {
            return initialRelease + (monthlyRelease * (_months + 1));
        }
    }
}