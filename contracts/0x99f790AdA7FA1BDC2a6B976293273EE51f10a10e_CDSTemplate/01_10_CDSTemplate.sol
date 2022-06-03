pragma solidity 0.8.10;

/**
 * @author InsureDAO
 * @title InsureDAO CDS template contract
 * SPDX-License-Identifier: GPL-3.0
 */

import "./interfaces/IUniversalMarket.sol";
import "./InsureDAOERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IParameters.sol";
import "./interfaces/ICDSTemplate.sol";

contract CDSTemplate is InsureDAOERC20, ICDSTemplate, IUniversalMarket {
    /**
     * EVENTS
     */
    event Deposit(address indexed depositor, uint256 amount, uint256 mint);
    event Fund(address indexed depositor, uint256 amount, uint256 attribution);
    event Defund(
        address indexed depositor,
        uint256 amount,
        uint256 attribution
    );

    event WithdrawRequested(
        address indexed withdrawer,
        uint256 amount,
        uint256 unlockTime
    );
    event Withdraw(address indexed withdrawer, uint256 amount, uint256 retVal);
    event Compensated(address indexed index, uint256 amount);
    event Paused(bool paused);
    event MetadataChanged(string metadata);

    /**
     * Storage
     */
    /// @notice Market setting
    bool public initialized;
    bool public paused;
    string public metadata;

    /// @notice External contract call addresses
    IParameters public parameters;
    IRegistry public registry;
    IVault public vault;
    uint256 public surplusPool;
    uint256 public crowdPool;
    uint256 private constant MAGIC_SCALE_1E6 = 1e6; //internal multiplication scale 1e6 to reduce decimal truncation

    ///@notice user status management
    struct Withdrawal {
        uint256 timestamp;
        uint256 amount;
    }
    mapping(address => Withdrawal) public withdrawalReq;

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            msg.sender == parameters.getOwner(),
            "ERROR: ONLY_OWNER"
        );
        _;
    }

    constructor() {
        initialized = true;
    }

    /**
     * Initialize interaction
     */

    /**
     * @notice Initialize market
     * This function registers market conditions.
     * references[0] = underlying token address
     * references[1] = registry
     * references[2] = parameter
     * @param _metaData arbitrary string to store market information
     * @param _conditions array of conditions
     * @param _references array of references
     */
    function initialize(
        address _depositor,
        string calldata _metaData,
        uint256[] calldata _conditions,
        address[] calldata _references
    ) external override{
        require(
            !initialized &&
                bytes(_metaData).length != 0 &&
                _references[0] != address(0) &&
                _references[1] != address(0) &&
                _references[2] != address(0),
            "INITIALIZATION_BAD_CONDITIONS"
        );

        initialized = true;

        initializeToken("InsureDAO-Reserve", "iReserve", IERC20Metadata(_references[0]).decimals());

        parameters = IParameters(_references[2]);
        vault = IVault(parameters.getVault(_references[0]));
        registry = IRegistry(_references[1]);

        metadata = _metaData;
    }

    /**
     * Pool initeractions
     */

    /**
     * @notice A liquidity provider supplies collatral to the pool and receives iTokens
     * @param _amount amount of token to deposit
     */
    function deposit(uint256 _amount) external returns (uint256 _mintAmount) {
        require(!paused, "ERROR: PAUSED");
        require(_amount != 0, "ERROR: DEPOSIT_ZERO");

        //deposit and pay fees
        uint256 _liquidity = vault.attributionValue(crowdPool); //get USDC balance with crowdPool's attribution
        uint256 _supply = totalSupply();

        crowdPool += vault.addValue(_amount, msg.sender, address(this)); //increase attribution

        if (_supply != 0) {
            _mintAmount = _liquidity == 0 ? _amount * _supply : (_amount * _supply) / _liquidity;
        } else {
            _mintAmount = _amount;
        }

        emit Deposit(msg.sender, _amount, _mintAmount);

        //mint iToken
        _mint(msg.sender, _mintAmount);
    }

    /**
     * @notice A depositor supplies fund to the pool without receiving iTokens
     * @param _amount amount of token to deposit
     */
    function fund(uint256 _amount) external {
        require(!paused, "ERROR: PAUSED");

        //deposit and pay fees
        uint256 _attribution = vault.addValue(
            _amount,
            msg.sender,
            address(this)
        );

        surplusPool += _attribution;

        emit Fund(msg.sender, _amount, _attribution);
    }

    function defund(address _to, uint256 _amount) external override onlyOwner {
        require(!paused, "ERROR: PAUSED");

        uint256 _attribution = vault.withdrawValue(_amount, _to);
        surplusPool -= _attribution;

        emit Defund(_to, _amount, _attribution);
    }

    /**
     * @notice A liquidity provider request withdrawal of collateral
     * @param _amount amount of iToken to burn
     */
    function requestWithdraw(uint256 _amount) external {
        require(_amount != 0, "ERROR: REQUEST_ZERO");
        require(balanceOf(msg.sender) >= _amount, "ERROR: REQUEST_EXCEED_BALANCE");

        uint256 _unlocksAt = block.timestamp + parameters.getLockup(address(this));

        withdrawalReq[msg.sender].timestamp = _unlocksAt;
        withdrawalReq[msg.sender].amount = _amount;

        emit WithdrawRequested(msg.sender, _amount, _unlocksAt);
    }

    /**
     * @notice A liquidity provider burns iToken and receives collatral from the pool
     * @param _amount amount of iToken to burn
     * @return _retVal the amount underlying token returned
     */
    function withdraw(uint256 _amount) external returns (uint256 _retVal) {
        require(!paused, "ERROR: PAUSED");
        require(_amount != 0, "ERROR: WITHDRAWAL_ZERO");
        
        Withdrawal memory request = withdrawalReq[msg.sender];
        
        require(
            request.timestamp <
                block.timestamp,
            "ERROR: WITHDRAWAL_QUEUE"
        );
        require(
            request.timestamp +
                parameters.getWithdrawable(address(this)) >
                block.timestamp,
            "WITHDRAWAL_NO_ACTIVE_REQUEST"
        );
        require(
            request.amount >= _amount,
            "WITHDRAWAL_EXCEEDED_REQUEST"
        );

        //Calculate underlying value
        uint256 _totalSupply = totalSupply();
        if (_totalSupply != 0) {
            _retVal = (vault.attributionValue(crowdPool) * _amount) / _totalSupply;
        }


        //reduce requested amount
        withdrawalReq[msg.sender].amount -= _amount;

        //Burn iToken
        _burn(msg.sender, _amount);

        //Withdraw liquidity
        crowdPool -= vault.withdrawValue(_retVal, msg.sender);
        emit Withdraw(msg.sender, _amount, _retVal);
    }

    /**
     * Insurance interactions
     */

    /**
     * @notice Compensate the shortage if an index is insolvent
     * @param _amount amount of underlier token to compensate shortage within index
     */
    function compensate(uint256 _amount)
        external
        override
        returns (uint256 _compensated)
    {
        require(registry.isListed(msg.sender), "ERROR:UNREGISTERED");
        
        uint256 _available = vault.underlyingValue(address(this));
        uint256 _crowdAttribution = crowdPool;
        uint256 _attributionLoss;

        //when CDS cannot afford, pay as much as possible
        _compensated = _available >= _amount ? _amount : _available;
        _attributionLoss = vault.transferValue(_compensated, msg.sender);
        emit Compensated(msg.sender, _compensated);

        uint256 _crowdPoolLoss =
            (_crowdAttribution * _attributionLoss) /
            (_crowdAttribution + surplusPool);

        crowdPool -= _crowdPoolLoss;
        surplusPool -= (_attributionLoss - _crowdPoolLoss);
    }

    /**
     * Utilities
     */

    /**
     * @notice total Liquidity of the pool (how much can the pool sell cover)
     * @return available liquidity of this pool
     */
    function totalLiquidity() external view returns (uint256) {
        return vault.underlyingValue(address(this));
    }

    /**
     * @notice Get the exchange rate of LP token against underlying asset(scaled by MAGIC_SCALE_1E6, if MAGIC_SCALE_1E6, the value of iToken vs underlier is 1:1)
     * @return The value against the underlying token balance.
     */
    function rate() external view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply != 0) {
            return
                (vault.attributionValue(crowdPool) * MAGIC_SCALE_1E6) / _totalSupply;
        }
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @param _owner the target address to look up value
     * @return The balance of underlying token for the specified address
     */
    function valueOfUnderlying(address _owner) external view returns (uint256) {
        uint256 _balance = balanceOf(_owner);
        uint256 _totalSupply = totalSupply();
        
        if (_balance != 0 || _totalSupply != 0) {
            return _balance * vault.attributionValue(crowdPool) / _totalSupply;
        }
    }

    /**
     * Admin functions
     */

    /**
     * @notice Change metadata string
     * @param _metadata new metadata string
     */
    function changeMetadata(string calldata _metadata)
        external
        override
        onlyOwner
    {
        metadata = _metadata;
        emit MetadataChanged(_metadata);
    }

    /**
     * @notice Used for changing settlementFeeRecipient
     * @param _state true to set paused and vice versa
     */
    function setPaused(bool _state) external override onlyOwner {
        if (paused != _state) {
            paused = _state;
            emit Paused(_state);
        }
    }

    /**
     * Internal functions
     */

    /**
     * @notice Internal function to offset withdraw request and latest balance
     * @param from the account who send
     * @param to a
     * @param amount the amount of token to offset
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from != address(0)) {
            uint256 _after = balanceOf(from) - amount;
            if (_after < withdrawalReq[from].amount) {
                withdrawalReq[from].amount = _after;
            }
        }
    }
}