// SPDX-License-Identifier: BUSL-1.1
// This is a multivesting contract of ZENF Token of Zenland. This contract would be used for token presale rounds of Zenland. Each round would have a seperate contract. This contract is for first round of presale

pragma solidity 0.8.9;

import "./IERC20.sol";
import "./SafeERC20.sol";


/// @title Multi Vesting Contract for ZENF Token Presale
/// @author Shamsutdinov Ruslan
contract ZenlandPresaleOneMultivesting {
    using SafeERC20 for IERC20;

    /// @dev Emitted when contract owner adds new vesting
    event AddVesting(address indexed _beneficiary, uint256 _amount, uint256 _cliff, uint256 _duration);

    /// @dev Emitted when msg.sender withdraws the tokens
    event Withdraw(address indexed _receiver, uint256 _amount);

    struct Vesting {
        uint256 createdAt; // Timestamp when vesting object was created
        uint256 cliff; // Period (in seconds) after which the allocation should start
        uint256 duration; // Period (in seconds) during which the tokens will be allocated
        uint256 totalAmount; // Vested amount
        uint256 releasedAmount; // Amount that beneficiary withdraw
        bool exists; // Boolean to check if address is in mapping
    }

    address public immutable owner;
    uint256 public totalVestedAmount;
    uint256 public totalReleasedAmount;
    IERC20 public immutable token;
    mapping(address => Vesting) vestingMap;

    /// @dev Sets the values for {_token} and {msg.sender}.
    /// All two of these values are immutable: they can only be set once during construction.
    constructor(IERC20 _token) {
        require(address(_token) != address(0), "ME010");
        token = _token;
        owner = msg.sender;
    }

    /// @notice Creates vesting for beneficiary with a given amount of funds to allocate
    /// @param _beneficiary Address of the investor
    /// @param _amount Amount of tokens the beneficiary will receive at the end
    /// @param _cliff Period (in seconds) after which the allocation should start
    /// @param _duration Period (in seconds) during which the tokens will be allocated
    function addVesting(address _beneficiary, uint256 _amount, uint256 _cliff, uint256 _duration) external onlyOwner {
        require(_beneficiary != address(0), "ME001");
        require(_duration >= 2592000 && _duration <= 63072000, "ME002"); // 1 month <= _duration <= 2 years
        require(_cliff <= 63072000, "ME003"); // 2 years
        require(getUnallocatedFundsAmount() >= _amount, "ME004");
        require(!vestingMap[_beneficiary].exists, "ME005");

        Vesting memory v = Vesting({
            createdAt: block.timestamp,
            cliff: _cliff,
            duration: _duration,
            totalAmount: _amount,
            releasedAmount: 0,
            exists: true
        });

        emit AddVesting(_beneficiary, _amount, _cliff, _duration);
        vestingMap[_beneficiary] = v;
        totalVestedAmount = totalVestedAmount + _amount;
    }

    /// @notice Method that allows a beneficiary to withdraw their allocated funds
    function withdraw() external {
        uint256 amount = getReleasableAmount(msg.sender);
        require(amount > 0, "ME006");

        emit Withdraw(msg.sender, amount);

        // @custom Increase released amount in mapping
        vestingMap[msg.sender].releasedAmount = vestingMap[msg.sender].releasedAmount + amount;

        // @custom Increase total released in contract
        totalReleasedAmount = totalReleasedAmount + amount;
        token.safeTransfer(msg.sender, amount);
    }

    /// @notice Method that allows the owner to withdraw unallocated funds to a specific address
    /// @param _receiver Address where the owner wants to withdraw tokens
    function withdrawUnallocatedFunds(address _receiver) external onlyOwner {
        require(_receiver != address(0), "ME007");
        uint256 amount = getUnallocatedFundsAmount();
        require(amount > 0, "ME008.");
        token.safeTransfer(_receiver, amount);
    }

    /// @notice Method that allows the owner to withdraw wrong tokens transferred to the contract
    /// @param _token Address of the tokens that owner transferred by mistake
    /// @param _receiver Address where the owner wants to withdraw tokens
    function withdrawWrongToken(IERC20 _token, address _receiver) external onlyOwner {
        require(address(_token) != address(0), "ME010");
        require(address(_token) != address(token), "ME011");
        require(_receiver != address(0), "ME007");
        require(token.balanceOf(address(this)) > 0, "ME004");
        SafeERC20.safeTransfer(_token, _receiver, token.balanceOf(address(this)));
    }

    // ===============================================================================================================
    // Getters
    // ===============================================================================================================

    /// @dev Returns the amount vested, as a function of time, for an asset given its total historical allocation.
    /// @param _beneficiary Address of the investor
    /// @param _timestamp Unix timestamp
    function _vestingSchedule(address _beneficiary, uint256 _timestamp) internal view virtual returns (uint256) {
        Vesting memory vesting = vestingMap[_beneficiary];
        uint256 startedAt = vesting.createdAt + vesting.cliff;
        if (_timestamp < startedAt) {
            return 0;
        } else if (_timestamp > startedAt +  vesting.duration) {
            return vesting.totalAmount;
        } else {
            return (vesting.totalAmount * (_timestamp - startedAt)) / vesting.duration;
        }
    }

    /// @notice Returns amount of funds that beneficiary will be able to withdraw at the given timestamp
    /// @param _beneficiary Address of the investor
    /// @param _timestamp Unix timestamp
    function getReleasableAmountAtTimestamp(address _beneficiary, uint256 _timestamp) public view returns (uint256) {
        return _vestingSchedule(_beneficiary, _timestamp) - vestingMap[_beneficiary].releasedAmount;
    }

    /// @notice Returns amount of funds that beneficiary will be able to withdraw at the current moment
    /// @param _beneficiary Address of the investor
    function getReleasableAmount(address _beneficiary) public view returns (uint256) {
        return getReleasableAmountAtTimestamp(_beneficiary, block.timestamp);
    }

    /// @notice Returns amount of unallocated funds that contract owner can withdraw
    function getUnallocatedFundsAmount() public view returns (uint256) {
        return token.balanceOf(address(this)) - (totalVestedAmount - totalReleasedAmount);
    }

    /// @notice Returns the amount of beneficiary's tokens that still will be allocated at the given timestamp
    /// @param _beneficiary Address of the investor
    /// @param _timestamp Unix timestamp
    function getVestingAmountAtTimestamp(address _beneficiary, uint256 _timestamp) public view returns (uint256) {
        return vestingMap[_beneficiary].totalAmount - _vestingSchedule(_beneficiary, _timestamp);
    }

    /// @notice Returns the amount of beneficiary's tokens that still will be allocated at the current moment
    /// @param _beneficiary Address of the investor
    function getVestingAmount(address _beneficiary) public view returns (uint256) {
        return getVestingAmountAtTimestamp(_beneficiary, block.timestamp);
    }

    /// @notice Returns the total amount of beneficiary's tokens in the contract
    /// @param _beneficiary Address of the investor
    function getTotalVestingAmount(address _beneficiary) public view returns (uint256) {
        return vestingMap[_beneficiary].totalAmount;
    }

    /// @notice Returns cliff duration of beneficiary's investment in seconds
    /// @param _beneficiary Address of the investor
    function getCliffDuration(address _beneficiary) public view returns (uint256) {
        return vestingMap[_beneficiary].cliff;
    }

    /// @notice Returns vesting period duration of beneficiary's investment in seconds
    /// @param _beneficiary Address of the investor
    function getVestingDuration(address _beneficiary) public view returns (uint256) {
        return vestingMap[_beneficiary].duration;
    }

    /// @notice Returns beneficiary's investment creation timestamp in seconds
    /// @param _beneficiary Address of the investor
    function getInvestmentCreationTimestamp(address _beneficiary) public view returns (uint256) {
        return vestingMap[_beneficiary].createdAt;
    }

    // ===============================================================================================================
    // Modifiers
    // ===============================================================================================================

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /// @dev Throws if the sender is not the owner
    function _checkOwner() internal view virtual {
        require(owner == msg.sender, "ME009");
    }
}


// ===============================================================================================================
// ERRORS
// ===============================================================================================================

// ME001 - Beneficiary is zero address.
// ME002 - Duration must be >= 1 month and <= 2 years.
// ME003 - Cliff cannot be more than 2 years.
// ME004 - Not enough tokens.
// ME005 - Vesting object for this beneficiary already exists.
// ME006 - Don't have released tokens.
// ME007 - Receiver is zero address.
// ME008 - Don't have unallocated tokens.
// ME009 - Caller is not the owner.
// ME010 - Token is zero address.