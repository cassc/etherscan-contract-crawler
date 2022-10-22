// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/ISLARegistry.sol';
import './interfaces/IStakeRegistry.sol';
import './interfaces/IPeriodRegistry.sol';
import './interfaces/ISLORegistry.sol';
import './Staking.sol';

/**
 @title Service Level Agreement Contract
 */
contract SLA is Staking {
    enum Status {
        NotVerified,
        Respected,
        NotRespected
    }

    struct PeriodSLI {
        uint256 timestamp;
        uint256 sli;
        Status status;
    }

    string public ipfsHash;
    ISLARegistry private _slaRegistry;
    ISLORegistry private immutable _sloRegistry;
    uint256 public immutable creationBlockNumber;
    uint128 public immutable initialPeriodId;
    uint128 public immutable finalPeriodId;
    IPeriodRegistry.PeriodType public immutable periodType;
    /// @dev extra data for customized workflows
    uint256[] public severity;
    uint256[] public penalty;

    bool public terminateContract = false;
    uint256 public nextVerifiablePeriod;

    /// @dev periodId=>PeriodSLI mapping
    mapping(uint256 => PeriodSLI) public periodSLIs;

    /// @notice An event that is emitted when creating a new SLI
    event SLICreated(uint256 timestamp, uint256 sli, uint256 periodId);

    /// @notice An event that is emitted when staking in User or Provider Pool
    event Stake(
        address indexed tokenAddress,
        uint256 indexed periodId,
        address indexed caller,
        uint256 amount,
        Position position
    );
    /// @notice An event that is emitted when withdrawing from Provider Pool
    event ProviderWithdraw(
        address indexed tokenAddress,
        uint256 indexed periodId,
        address indexed caller,
        uint256 amount
    );

    /// @notice An event that is emitted when withdrawing from User Pool
    event UserWithdraw(
        address indexed tokenAddress,
        uint256 indexed periodId,
        address indexed caller,
        uint256 amount
    );

    /// @notice An event that is emitted when toggles termination
    event ToggleTermination(bool termination);

    /// @dev Modifier ensuring that certain function can only be called by Messenger
    modifier onlyMessenger() {
        require(msg.sender == messengerAddress, 'not messenger');
        _;
    }

    /**
     * @notice Constructor
     */
    constructor(
        address _owner,
        bool _whitelisted,
        IPeriodRegistry.PeriodType _periodType,
        address _messengerAddress,
        uint128 _initialPeriodId,
        uint128 _finalPeriodId,
        uint128 _slaID,
        string memory _ipfsHash,
        uint256[] memory _severity,
        uint256[] memory _penalty,
        uint64 _leverage
    )
        Staking(
            ISLARegistry(msg.sender),
            _whitelisted,
            _slaID,
            _leverage,
            _owner,
            _messengerAddress
        )
    {
        transferOwnership(_owner);
        ipfsHash = _ipfsHash;
        _slaRegistry = ISLARegistry(msg.sender);
        _sloRegistry = ISLORegistry(_slaRegistry.sloRegistry());
        creationBlockNumber = block.number;
        initialPeriodId = _initialPeriodId;
        finalPeriodId = _finalPeriodId;
        periodType = _periodType;
        severity = _severity;
        penalty = _penalty;
        nextVerifiablePeriod = _initialPeriodId;
    }

    /**
     * @notice External function that registers new SLI
     * @param _sli sli value to register
     * @param _periodId period id of new sli
     */
    function registerSLI(uint256 _sli, uint256 _periodId)
        external
        onlyMessenger
    {
        require(_periodId == nextVerifiablePeriod, 'invalid period id');
        emit SLICreated(block.timestamp, _sli, _periodId);
        nextVerifiablePeriod = _periodId + 1;
        PeriodSLI storage periodSLI = periodSLIs[_periodId];
        periodSLI.sli = _sli;
        periodSLI.timestamp = block.timestamp;

        uint256 deviation = _sloRegistry.getDeviation(
            _sli,
            address(this),
            severity,
            penalty
        );

        if (_sloRegistry.isRespected(_sli, address(this))) {
            periodSLI.status = Status.Respected;
            _setProviderReward(_periodId, deviation);
        } else {
            periodSLI.status = Status.NotRespected;
            _setUserReward(_periodId, deviation);
        }
    }

    /**
     @notice External view function to see if a period id is allowed or not
     @param _periodId period id to check
     @return bool allowed or not
     */
    function isAllowedPeriod(uint256 _periodId) external view returns (bool) {
        return _periodId >= initialPeriodId && _periodId <= finalPeriodId;
    }

    /**
     * @notice Public view function to check if the contract is finished
     * @dev finish condition = should pass last verified period and final period should not be verified.
     * @return Bool whether finished or not
     */
    function contractFinished() public view returns (bool) {
        (, uint256 endOfLastValidPeriod) = _periodRegistry.getPeriodStartAndEnd(
            periodType,
            finalPeriodId
        );
        return ((block.timestamp >= endOfLastValidPeriod &&
            periodSLIs[finalPeriodId].status != Status.NotVerified) ||
            terminateContract);
    }

    /**
     * @notice External function to stake tokens in User or Provider Pools
     * @param _amount amount to withdraw
     * @param _tokenAddress token address to withdraw
     * @param _position User or Provider pool
     */
    function stakeTokens(
        uint256 _amount,
        address _tokenAddress,
        Position _position
    ) external {
        require(!contractFinished(), 'This SLA has finished.');

        require(_amount > 0, 'Stake must be greater than 0.');

        _stake(_tokenAddress, nextVerifiablePeriod, _amount, _position);

        emit Stake(
            _tokenAddress,
            nextVerifiablePeriod,
            msg.sender,
            _amount,
            _position
        );

        IStakeRegistry(_slaRegistry.stakeRegistry()).registerStakedSla(
            msg.sender
        );
    }

    /**
     * @notice External function to withdraw staked tokens from Provider Pool
     * @param _amount amount to withdraw
     * @param _tokenAddress token address to withdraw
     */
    function withdrawProviderTokens(uint256 _amount, address _tokenAddress)
        external
    {
        _withdrawProviderTokens(
            _amount,
            _tokenAddress,
            nextVerifiablePeriod,
            contractFinished()
        );

        emit ProviderWithdraw(
            _tokenAddress,
            nextVerifiablePeriod,
            msg.sender,
            _amount
        );
    }

    /**
     * @notice External function to withdraw staked tokens from User Pool
     * @param _amount amount to withdraw
     * @param _tokenAddress token address to withdraw
     */
    function withdrawUserTokens(uint256 _amount, address _tokenAddress)
        external
    {
        _withdrawUserTokens(
            _amount,
            _tokenAddress,
            nextVerifiablePeriod,
            contractFinished()
        );

        emit UserWithdraw(
            _tokenAddress,
            nextVerifiablePeriod,
            msg.sender,
            _amount
        );
    }

    function toggleTermination() external onlyOwner {
        (, uint256 endOfLastValidPeriod) = _periodRegistry.getPeriodStartAndEnd(
            periodType,
            finalPeriodId
        );

        require(
            block.timestamp >= endOfLastValidPeriod,
            'This SLA has not finished.'
        );

        terminateContract = !terminateContract;

        emit ToggleTermination(terminateContract);
    }
}