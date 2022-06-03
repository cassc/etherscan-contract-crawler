// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../library/Ownable.sol";
import "../library/TransferHelper.sol";
import "../Metadata.sol";

contract LiquidityLocker is ReentrancyGuard, Ownable, Metadata {
    using SafeMath for uint256;

    /// @notice event emitted when a locking schedule is created
    event ScheduleCreated(
        address indexed _beneficiary,
        uint256 indexed _amount
    );

    /// @notice event emitted when a successful drawn down of locking tokens is made
    event DrawDown(address indexed _beneficiary, uint256 indexed _amount);

    event URLUpdated(address _tokenAddress, string _tokenUrl);

    /// @notice start of locking period as a timestamp
    uint256 public start;

    /// @notice end of locking period as a timestamp
    uint256 public end;

    /// @notice cliff duration in seconds
    uint256 public cliffDuration;

    /// @notice amount locked for a beneficiary. Note beneficiary address can not be reused
    mapping(address => uint256) public vestedAmount;

    /// @notice cumulative total of tokens drawn down (and transferred from this liqudity contract) per beneficiary
    mapping(address => uint256) public totalDrawn;

    /// @notice last drawn down time (seconds) per beneficiary
    mapping(address => uint256) public lastDrawnAt;

    /// @notice ERC20 token we are locking
    IERC20 public token;

    uint256 public exchangeIdentifier;

    bool public initialized;

    /**
     * @notice Construct a new liquidity locker contract
     */
    constructor() {
        initialized = true;
    }

    /**
     * @notice Construct a new vesting contract
     * @param _encodedData Encoded Data
     */
    function init(bytes memory _encodedData) external {
        require(initialized == false, "Contract already initialized");

        (token, , start, end, cliffDuration, exchangeIdentifier, owner) = abi
            .decode(
                _encodedData,
                (IERC20, address, uint256, uint256, uint256, uint256, address)
            );

        address token0;
        address token1;
        string memory token0URL;
        string memory token1URL;
        string memory inputTokenUrl;
        address routerAddress;
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            token0URL,
            token1URL,
            inputTokenUrl,
            routerAddress,
            token0,
            token1
        ) = abi.decode(
            _encodedData,
            (
                IERC20,
                address,
                uint256,
                uint256,
                uint256,
                uint256,
                address,
                string,
                string,
                string,
                address,
                address,
                address
            )
        );

        require(
            address(token) != address(0),
            "VestingContract::constructor: Invalid token"
        );

        updateMeta(address(token), routerAddress, inputTokenUrl);
        updateMeta(token0, address(0), token0URL);
        updateMeta(token1, address(0), token1URL);

        require(
            end >= start.add(cliffDuration),
            "VestingContract::constructor: Start must be before end"
        );

        initialized = true;
    }

    function updateTokenURL(address _tokenAddress, string memory _tokenURL)
        external
        onlyOwner
    {
        updateMetaURL(_tokenAddress, _tokenURL);
        emit URLUpdated(_tokenAddress, _tokenURL);
    }

    function rescueFunds(IERC20 _token, address _recipient) external onlyOwner {
        TransferHelper.safeTransfer(
            address(_token),
            _recipient,
            _token.balanceOf(address(this))
        );
    }

    /**
     * @notice Create new vesting schedules in a batch
     * @dev should only be invoked via contract Owner
     * @notice A transfer is used to bring tokens into this Contract so pre-approval is required
     * @param _beneficiaries array of beneficiaries of the vested tokens
     * @param _amounts array of amount of tokens (in wei)
     * @dev array index of address should be the same as the array index of the amount
     */
    function createVestingSchedules(
        address[] calldata _beneficiaries,
        uint256[] calldata _amounts
    ) external onlyOwner returns (bool) {
        require(
            _beneficiaries.length > 0,
            "VestingContract::createVestingSchedules: Empty Data"
        );
        require(
            _beneficiaries.length == _amounts.length,
            "VestingContract::createVestingSchedules: Array lengths do not match"
        );

        bool result = true;

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address beneficiary = _beneficiaries[i];
            uint256 amount = _amounts[i];
            _createVestingSchedule(beneficiary, amount);
        }

        return result;
    }

    /**
     * @notice Create a new vesting schedule
     * @dev should only be invoked via contract Owner
     * @notice A transfer is used to bring tokens into this Contract so pre-approval is required
     * @param _beneficiary beneficiary of the vested tokens
     * @param _amount amount of tokens (in wei)
     */
    function createVestingSchedule(address _beneficiary, uint256 _amount)
        external
        onlyOwner
        returns (bool)
    {
        return _createVestingSchedule(_beneficiary, _amount);
    }

    /**
     * @notice Draws down any vested tokens due
     * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
     */
    function drawDown() external nonReentrant returns (bool) {
        return _drawDown(msg.sender);
    }

    // Accessors

    /**
     * @notice Total token balance of the contract
     * @return _tokenBalance total balance proxied via the ERC20 token
     */
    function tokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Vesting schedule and associated data for a beneficiary
     * @dev Must be called directly by the beneficiary assigned the tokens in the schedule
     * @return _amount
     * @return _totalDrawn
     * @return _lastDrawnAt
     * @return _remainingBalance
     */
    function vestingScheduleForBeneficiary(address _beneficiary)
        external
        view
        returns (
            uint256 _amount,
            uint256 _totalDrawn,
            uint256 _lastDrawnAt,
            uint256 _remainingBalance
        )
    {
        return (
            vestedAmount[_beneficiary],
            totalDrawn[_beneficiary],
            lastDrawnAt[_beneficiary],
            vestedAmount[_beneficiary].sub(totalDrawn[_beneficiary])
        );
    }

    /**
     * @notice Draw down amount currently available (based on the block timestamp)
     * @param _beneficiary beneficiary of the vested tokens
     * @return _amount tokens due from vesting schedule
     */
    function availableDrawDownAmount(address _beneficiary)
        external
        view
        returns (uint256 _amount)
    {
        return _availableDrawDownAmount(_beneficiary);
    }

    /**
     * @notice Balance remaining in vesting schedule
     * @param _beneficiary beneficiary of the vested tokens
     * @return _remainingBalance tokens still due (and currently locked) from vesting schedule
     */
    function remainingBalance(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return vestedAmount[_beneficiary].sub(totalDrawn[_beneficiary]);
    }

    // Internal

    function _createVestingSchedule(address _beneficiary, uint256 _amount)
        internal
        returns (bool)
    {
        require(
            _beneficiary != address(0),
            "VestingContract::createVestingSchedule: Beneficiary cannot be empty"
        );
        require(
            _amount > 0,
            "VestingContract::createVestingSchedule: Amount cannot be empty"
        );

        // Ensure one per address
        require(
            vestedAmount[_beneficiary] == 0,
            "VestingContract::createVestingSchedule: Schedule already in flight"
        );

        vestedAmount[_beneficiary] = _amount;

        // Vest the tokens into this vesting contract and delegate to the beneficiary
        TransferHelper.safeTransferFrom(
            address(token),
            msg.sender,
            address(this),
            _amount
        );

        emit ScheduleCreated(_beneficiary, _amount);

        return true;
    }

    function _drawDown(address _beneficiary) internal returns (bool) {
        require(
            vestedAmount[_beneficiary] > 0,
            "VestingContract::_drawDown: There is no schedule currently in flight"
        );

        uint256 amount = _availableDrawDownAmount(_beneficiary);
        require(
            amount > 0,
            "VestingContract::_drawDown: No allowance left to withdraw"
        );

        // Update last drawn to now
        lastDrawnAt[_beneficiary] = _getNow();

        // Increase total drawn amount
        totalDrawn[_beneficiary] = totalDrawn[_beneficiary].add(amount);

        // Safety measure - this should never trigger
        require(
            totalDrawn[_beneficiary] <= vestedAmount[_beneficiary],
            "VestingContract::_drawDown: Safety Mechanism - Drawn exceeded Amount Vested"
        );

        // Issue tokens to beneficiary
        TransferHelper.safeTransfer(address(token), _beneficiary, amount);

        emit DrawDown(_beneficiary, amount);

        return true;
    }

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    function _availableDrawDownAmount(address _beneficiary)
        internal
        view
        returns (uint256 _amount)
    {
        // Cliff Period
        if (_getNow() <= start.add(cliffDuration)) {
            // the cliff period has not ended, no tokens to draw down
            return 0;
        }

        // Schedule complete
        if (_getNow() > end) {
            return vestedAmount[_beneficiary].sub(totalDrawn[_beneficiary]);
        }

        // Schedule is active

        // Work out when the last invocation was
        uint256 timeLastDrawnOrStart = lastDrawnAt[_beneficiary] == 0
            ? start
            : lastDrawnAt[_beneficiary];

        // Find out how much time has past since last invocation
        uint256 timePassedSinceLastInvocation = _getNow().sub(
            timeLastDrawnOrStart
        );

        // Work out how many due tokens - time passed * rate per second
        uint256 drawDownRate = (vestedAmount[_beneficiary].mul(1e18)).div(
            end.sub(start)
        );
        uint256 amount = (timePassedSinceLastInvocation.mul(drawDownRate)).div(
            1e18
        );

        return amount;
    }
}