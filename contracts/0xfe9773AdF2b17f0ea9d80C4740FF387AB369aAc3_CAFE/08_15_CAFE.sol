pragma solidity ^0.8.3;

// solhint-disable-next-line compiler-version
pragma abicoder v2;

import "./library/ERC20ReInitializable.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IWhitelist.sol";
import "./interfaces/IERC20Metadata.sol";

import "./math/BigDiv.sol";
import "./math/Sqrt.sol";

import "./mixins/OperatorRole.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Continuous Agreement for Future Equity
 */
contract CAFE
    is ERC20ReInitializable
{
    using Sqrt for uint;
    using SafeERC20 for IERC20;
    event Buy(
        address indexed _from,
        address indexed _to,
        uint _currencyValue,
        uint _fairValue
    );
    event Sell(
        address indexed _from,
        address indexed _to,
        uint _currencyValue,
        uint _fairValue
    );
    event Burn(
        address indexed _from,
        uint _fairValue
    );
    event StateChange(
        uint _previousState,
        uint _newState
    );
    event Close();
    event UpdateConfig(
        address _whitelistAddress,
        address indexed _beneficiary,
        address indexed _control,
        address indexed _feeCollector,
        uint _feeBasisPoints,
        uint _minInvestment,
        uint _minDuration,
        uint _stakeholdersPoolAuthorized,
        uint _gasFee
    );

    //
    // Constants
    //

    enum State {
        Init,
        Run,
        Close,
        Cancel
    }

    // The denominator component for values specified in basis points.
    uint internal constant BASIS_POINTS_DEN = 10000;

    uint internal constant MAX_ITERATION = 10;

    /**
     * Data specific to our token business logic
     */

    /// @notice The contract for transfer authorizations, if any.
    IWhitelist public whitelist;

    /// @notice The total number of burned FAIR tokens, excluding tokens burned from a `Sell` action in the DAT.
    uint public burnedSupply;

    /**
     * Data for DAT business logic
     */

    /// @notice The address of the beneficiary organization which receives the investments.
    /// Points to the wallet of the organization.
    address payable public beneficiary;

    struct BuySlope {
        uint128 num;
        uint128 den;
    }

    BuySlope public buySlope;

    /// @notice The address from which the updatable variables can be updated
    address public control;

    /// @notice The address of the token used as reserve in the bonding curve
    /// (e.g. the DAI contract). Use ETH if 0.
    IERC20 public currency;

    /// @notice The address where fees are sent.
    address payable public feeCollector;

    /// @notice The percent fee collected each time new FAIR are issued expressed in basis points.
    uint public feeBasisPoints;

    /// @notice The initial fundraising goal (expressed in FAIR) to start the c-org.
    /// `0` means that there is no initial fundraising and the c-org immediately moves to run state.
    uint public initGoal;

    /// @notice A map with all investors in init state using address as a key and amount as value.
    /// @dev This structure's purpose is to make sure that only investors can withdraw their money if init_goal is not reached.
    mapping(address => uint) public initInvestors;

    /// @notice The initial number of FAIR created at initialization for the beneficiary.
    /// Technically however, this variable is not a constant as we must always have
    ///`init_reserve>=total_supply+burnt_supply` which means that `init_reserve` will be automatically
    /// decreased to equal `total_supply+burnt_supply` in case `init_reserve>total_supply+burnt_supply`
    /// after an investor sells his FAIRs.
    /// @dev Organizations may move these tokens into vesting contract(s)
    uint public initReserve;

    /// @notice The minimum amount of `currency` investment accepted.
    uint public minInvestment;

    /// @notice The current state of the contract.
    /// @dev See the constants above for possible state values.
    State public state;

    /// @dev If this value changes we need to reconstruct the DOMAIN_SEPARATOR
    // solhint-disable-next-line const-name-snakecase	
    string public constant version = "cafe-2.0";
    // --- EIP712 niceties ---
    // Original source: https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f#code
    mapping (address => uint) public nonces;
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // The success fee (expressed in currency) that will be earned by setupFeeRecipient as soon as initGoal
    // is reached. We must have setup_fee <= buy_slope*init_goal^(2)/2
    uint public setupFee;

    // The recipient of the setup_fee once init_goal is reached
    address payable public setupFeeRecipient;

    /// @notice The minimum time before which the c-org contract cannot be closed once the contract has
    /// reached the `run` state.
    /// @dev When updated, the new value of `minimum_duration` cannot be earlier than the previous value.
    uint public minDuration;

    /// @dev Initialized at `0` and updated when the contract switches from `init` state to `run` state
    /// or when the initial trial period ends.
    uint private startedOn;

    // keccak256("PermitBuy(address from,address to,uint256 currencyValue,uint256 minTokensBought,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_BUY_TYPEHASH = 0xaf42a244b3020d6a2253d9f291b4d3e82240da42b22129a8113a58aa7a3ddb6a;

    // keccak256("PermitSell(address from,address to,uint256 quantityToSell,uint256 minCurrencyReturned,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_SELL_TYPEHASH = 0x5dfdc7fb4c68a4c249de5e08597626b84fbbe7bfef4ed3500f58003e722cc548;
    
    // keccak256("PermitManualBuy(address to,uint256 currencyValue,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_MANUAL_BUY_TYPEHASH = 0x2f5cb0d957693086baffb2c705f0bb99e7b504abc3003f38bdac1b0ef497c27c;

    // stkaeholdersPool struct separated
    uint public stakeholdersPoolIssued;

    uint public stakeholdersPoolAuthorized;

    // The orgs commitement that backs the value of CAFEs.
    // This value may be increased but not decreased.
    uint public equityCommitment;

    // Total number of tokens that have been attributed to current shareholders
    uint public shareholdersPool;

    // The max number of CAFEs investors can purchase (excludes the stakeholdersPool)
    uint public maxGoal;

    // The amount of CAFE to be sold to exit the trial mode.
    // 0 means there is no trial.
    uint public initTrial;

    // Represents the fundraising amount that can be sold as a fixed price
    uint public fundraisingGoal;

    // To fund operator a gasFee
    uint public gasFee;

    // increased when manual buy
    uint public manualBuybackReserve;

    uint public totalInvested;

    bytes32 private constant BEACON_SLOT = keccak256(abi.encodePacked("fairmint.beaconproxy.beacon"));
    modifier onlyBeaconOperator() {
        bytes32 slot = BEACON_SLOT;
        address beacon;
        assembly {
            beacon := sload(slot)
        }
        require(beacon == address(0) || OperatorRole(beacon).isOperator(msg.sender), "!BeaconOperator");
        _;
    }

    modifier authorizeTransfer(
        address _from,
        address _to,
        uint _value,
        bool _isSell
    )
    {
        require(state != State.Close, "INVALID_STATE");
        if(address(whitelist) != address(0))
        {
            // This is not set for the minting of initialReserve
            whitelist.authorizeTransfer(_from, _to, _value, _isSell);
        }
        _;
    }

    /**
     * BuySlope
     */
    function buySlopeNum() external view returns(uint256) {
        return uint256(buySlope.num);
    }
    
    function buySlopeDen() external view returns(uint256) {
        return uint256(buySlope.den);
    }

    /**
     * Stakeholders Pool
     */
    function stakeholdersPool() public view returns (uint256 issued, uint256 authorized) {
        return (stakeholdersPoolIssued, stakeholdersPoolAuthorized);
    }

    function trialEndedOn() public view returns(uint256 timestamp) {
        return startedOn;
    }

    /**
     * Buyback reserve
     */

    /// @notice The total amount of currency value currently locked in the contract and available to sellers.
    function buybackReserve() public view returns (uint)
    {
        uint reserve = address(this).balance;
        if(address(currency) != address(0))
        {
            reserve = currency.balanceOf(address(this));
        }

        if(reserve > type(uint128).max)
        {
            /// Math: If the reserve becomes excessive, cap the value to prevent overflowing in other formulas
            return type(uint128).max;
        }

        return reserve + manualBuybackReserve;
    }

    /**
     * Functions required by the ERC-20 token standard
     */

    /// @dev Moves tokens from one account to another if authorized.
    function _transfer(
        address _from,
        address _to,
        uint _amount
    ) internal override
        authorizeTransfer(_from, _to, _amount, false)
    {
        require(state != State.Init || _from == beneficiary, "ONLY_BENEFICIARY_DURING_INIT");
        super._transfer(_from, _to, _amount);
    }

    /// @dev Removes tokens from the circulating supply.
    function _burn(
        address _from,
        uint _amount,
        bool _isSell
    ) internal
        authorizeTransfer(_from, address(0), _amount, _isSell)
    {
        super._burn(_from, _amount);

        if(!_isSell)
        {
            // This is a burn
            // SafeMath not required as we cap how high this value may get during mint
            burnedSupply += _amount;
            emit Burn(_from, _amount);
        }
    }

    /// @notice Called to mint tokens on `buy`.
    function _mint(
        address _to,
        uint _quantity
    ) internal override
        authorizeTransfer(address(0), _to, _quantity, false)
    {
        super._mint(_to, _quantity);

        // Math: If this value got too large, the DAT may overflow on sell
        require(totalSupply() + burnedSupply <= type(uint128).max, "EXCESSIVE_SUPPLY");
    }

    /**
     * Transaction Helpers
     */

    /// @notice Confirms the transfer of `_quantityToInvest` currency to the contract.
    function _collectInvestment(
        address payable _from,
        uint _quantityToInvest,
        uint _msgValue
    ) internal
    {
        if(address(currency) == address(0))
        {
            // currency is ETH
            require(_quantityToInvest == _msgValue, "INCORRECT_MSG_VALUE");
        }
        else
        {
            // currency is ERC20
            require(_msgValue == 0, "DO_NOT_SEND_ETH");

            currency.safeTransferFrom(_from, address(this), _quantityToInvest);
        }
    }

    /// @dev Send `_amount` currency from the contract to the `_to` account.
    function _transferCurrency(
        address payable _to,
        uint _amount
    ) internal
    {
        if(_amount > 0)
        {
            if(address(currency) == address(0))
            {
                Address.sendValue(_to, _amount);
            }
            else
            {
                currency.safeTransfer(_to, _amount);
            }
        }
    }

    /**
     * Config / Control
     */

    struct MileStone {
        uint128 initReserve;
        uint128 initTrial;
        uint128 initGoal;
        uint128 maxGoal;
    }

    /// @notice Called once after deploy to set the initial configuration.
    /// None of the values provided here may change once initially set.
    /// @dev using the init pattern in order to support zos upgrades
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _currencyAddress,
        MileStone calldata _mileStone,
        BuySlope calldata _buySlope,
        uint _stakeholdersAuthorized,
        uint _equityCommitment,
        uint _setupFee,
        address payable _setupFeeRecipient
    ) external
        onlyBeaconOperator
    {
        // _initialize will enforce this is only called once
        // The ERC-20 implementation will confirm initialize is only run once
        ERC20ReInitializable.__ERC20_init(_name, _symbol);
        _initialize(
            _currencyAddress,
            _mileStone,
            _buySlope,
            _stakeholdersAuthorized,
            _equityCommitment,
            _setupFee,
            _setupFeeRecipient
        );
    }

    function reInitialize(
        string calldata _name,
        string calldata _symbol,
        address _currencyAddress,
        MileStone calldata _mileStone,
        BuySlope calldata _buySlope,
        uint _stakeholdersAuthorized,
        uint _equityCommitment,
        uint _setupFee,
        address payable _setupFeeRecipient
    ) external {
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_REINITIALIZE");
        require(balanceOf(msg.sender) == totalSupply(), "BENEFICIARY_SHOULD_HAVE_ALL_TOKENS");
        require(initReserve == totalSupply(), "SHOULD_NOT_HAVE_RECEIVED_ANY_FUND");
        ERC20ReInitializable.__ERC20_re_initialize(_name, _symbol);
        _burn(msg.sender, totalSupply());
        _initialize(
            _currencyAddress,
            _mileStone,
            _buySlope,
            _stakeholdersAuthorized,
            _equityCommitment,
            _setupFee,
            _setupFeeRecipient
        );
    }

    function _initialize(
        address _currencyAddress,
        MileStone memory _mileStone,
        BuySlope memory _buySlope,
        uint _stakeholdersAuthorized,
        uint _equityCommitment,
        uint _setupFee,
        address payable _setupFeeRecipient
    ) internal {
        require(_buySlope.num > 0, "INVALID_SLOPE_NUM");
        require(_buySlope.den > 0, "INVALID_SLOPE_DEN");
        buySlope = _buySlope;

        // Setup Fee
        require(_setupFee == 0 || _setupFeeRecipient != address(0), "MISSING_SETUP_FEE_RECIPIENT");
        require(_setupFeeRecipient == address(0) || _setupFee != 0, "MISSING_SETUP_FEE");
        // setup_fee <= (n/d)*(g^2)/2
        uint initGoalInCurrency = uint256(_mileStone.initGoal) * uint256(_mileStone.initGoal);
        initGoalInCurrency = initGoalInCurrency * uint256(_buySlope.num);
        initGoalInCurrency /= 2 * uint256(_buySlope.den);
        require(_setupFee <= initGoalInCurrency, "EXCESSIVE_SETUP_FEE");
        setupFee = _setupFee;
        setupFeeRecipient = _setupFeeRecipient;

        // Set default values (which may be updated using `updateConfig`)
        uint decimals = 18;
        if(_currencyAddress != address(0)){
            decimals = IERC20Metadata(_currencyAddress).decimals();
        }
        minInvestment = 100 * (10 ** decimals);
        beneficiary = payable(msg.sender);
        control = msg.sender;
        feeCollector = payable(msg.sender);

        // Save currency
        currency = IERC20(_currencyAddress);

        // Mint the initial reserve
        if(_mileStone.initReserve > 0)
        {
            initReserve = _mileStone.initReserve;
            _mint(beneficiary, initReserve);
        }

        initializeDomainSeparator();
        // Math: If this value got too large, the DAT would overflow on sell
        // new settings for CAFE
        require(_mileStone.maxGoal == 0 || _mileStone.initGoal == 0 || _mileStone.maxGoal >= _mileStone.initGoal, "MAX_GOAL_SMALLER_THAN_INIT_GOAL");
        require(_mileStone.initGoal == 0 || _mileStone.initTrial == 0 || _mileStone.initGoal >= _mileStone.initTrial, "INIT_GOAL_SMALLER_THAN_INIT_TRIAL");
        maxGoal = _mileStone.maxGoal;
        initTrial = _mileStone.initTrial;
        stakeholdersPoolIssued = _mileStone.initReserve;
        require(_stakeholdersAuthorized <= BASIS_POINTS_DEN, "STAKEHOLDERS_POOL_AUTHORIZED_SHOULD_BE_SMALLER_THAN_BASIS_POINTS_DEN");
        stakeholdersPoolAuthorized = _stakeholdersAuthorized;
        require(_equityCommitment > 0, "EQUITY_COMMITMENT_CANNOT_BE_ZERO");
        require(_equityCommitment <= BASIS_POINTS_DEN, "EQUITY_COMMITMENT_SHOULD_BE_LESS_THAN_100%");
        equityCommitment = _equityCommitment;
        // Set initGoal, which in turn defines the initial state
        if(_mileStone.initGoal == 0)
        {
            _stateChange(State.Run);
            startedOn = block.timestamp;
        }
        else
        {
            initGoal = _mileStone.initGoal;
            state = State.Init;
            startedOn = 0;
        }
    }

    function _stateChange(State _state) internal {
        emit StateChange(uint256(state), uint256(_state));
        state = _state;
    }

    function updateConfig(
        address _whitelistAddress,
        address payable _beneficiary,
        address _control,
        address payable _feeCollector,
        uint _feeBasisPoints,
        uint _minInvestment,
        uint _minDuration,
        uint _stakeholdersAuthorized,
        uint _gasFee
    ) external
    {
        // This require(also confirms that initialize has been called.
        require(msg.sender == control, "CONTROL_ONLY");

        // address(0) is okay
        whitelist = IWhitelist(_whitelistAddress);

        require(_control != address(0), "INVALID_ADDRESS");
        control = _control;

        require(_feeCollector != address(0), "INVALID_ADDRESS");
        feeCollector = _feeCollector;

        require(_feeBasisPoints <= BASIS_POINTS_DEN, "INVALID_FEE");
        feeBasisPoints = _feeBasisPoints;

        require(_minInvestment > 0, "INVALID_MIN_INVESTMENT");
        minInvestment = _minInvestment;

        require(_minDuration >= minDuration, "MIN_DURATION_MAY_NOT_BE_REDUCED");
        minDuration = _minDuration;

        if(beneficiary != _beneficiary)
        {
            require(_beneficiary != address(0), "INVALID_ADDRESS");
            uint tokens = balanceOf(beneficiary);
            initInvestors[_beneficiary] = initInvestors[_beneficiary] + initInvestors[beneficiary];
            initInvestors[beneficiary] = 0;
            if(tokens > 0)
            {
                _transfer(beneficiary, _beneficiary, tokens);
            }
            beneficiary = _beneficiary;
        }

        // new settings for CAFE
        require(_stakeholdersAuthorized <= BASIS_POINTS_DEN, "STAKEHOLDERS_POOL_AUTHORIZED_SHOULD_BE_SMALLER_THAN_BASIS_POINTS_DEN");
        stakeholdersPoolAuthorized = _stakeholdersAuthorized;

        gasFee = _gasFee;

        emit UpdateConfig(
            _whitelistAddress,
            _beneficiary,
            _control,
            _feeCollector,
            _feeBasisPoints,
            _minInvestment,
            _minDuration,
            _stakeholdersAuthorized,
            _gasFee
        );
    }

    /// @notice Used to initialize the domain separator used in meta-transactions
    /// @dev This is separate from `initialize` to allow upgraded contracts to update the version
    /// There is no harm in calling this multiple times / no permissions required
    function initializeDomainSeparator() public
    {
        uint id;
        assembly {
            id := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes(version)),
                id,
                address(this)
            )
        );
    }

    /**
     * Functions for our business logic
     */

    /// @notice Burn the amount of tokens from the address msg.sender if authorized.
    /// @dev Note that this is not the same as a `sell` via the DAT.
    function burn(
        uint _amount
    ) public
    {
        require(state == State.Run, "INVALID_STATE");
        require(msg.sender == beneficiary, "BENEFICIARY_ONLY");
        _burn(msg.sender, _amount, false);
    }

    // Buy

    /// @notice Purchase FAIR tokens with the given amount of currency.
    /// @param _to The account to receive the FAIR tokens from this purchase.
    /// @param _currencyValue How much currency to spend in order to buy FAIR.
    /// @param _minTokensBought Buy at least this many FAIR tokens or the transaction reverts.
    /// @dev _minTokensBought is necessary as the price will change if some elses transaction mines after
    /// yours was submitted.
    function buy(
        address _to,
        uint _currencyValue,
        uint _minTokensBought
    ) public payable
    {
        _collectInvestment(payable(msg.sender), _currencyValue, msg.value);
        //deduct gas fee and send it to feeCollector
        uint256 currencyValue = _currencyValue - gasFee;
        _transferCurrency(feeCollector, gasFee);
        _buy(payable(msg.sender), _to, currencyValue, _minTokensBought, false);
    }

    /// @notice Allow users to sign a message authorizing a buy
    function permitBuy(
        address payable _from,
        address _to,
        uint _currencyValue,
        uint _minTokensBought,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external
    {
        require(_deadline >= block.timestamp, "EXPIRED");
        bytes32 digest = keccak256(abi.encode(PERMIT_BUY_TYPEHASH, _from, _to, _currencyValue, _minTokensBought, nonces[_from]++, _deadline));
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                digest
            )
        );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress != address(0) && recoveredAddress == _from, "INVALID_SIGNATURE");
        // CHECK !!! this is suspicious!! 0 should be msg.value but this is not payable function
        // msg.value will be zero since it is non-payable function and designed to be used to usdc-base CAFE contract
        _collectInvestment(_from, _currencyValue, 0);
        uint256 currencyValue = _currencyValue - gasFee;
        _transferCurrency(feeCollector, gasFee);
        _buy(_from, _to, currencyValue, _minTokensBought, false);
    }

    function _buy(
        address payable _from,
        address _to,
        uint _currencyValue,
        uint _minTokensBought,
        bool _manual
    ) internal
    {
        require(_to != address(0), "INVALID_ADDRESS");
        require(_minTokensBought > 0, "MUST_BUY_AT_LEAST_1");
        require(state == State.Init || state == State.Run, "ONLY_BUY_IN_INIT_OR_RUN");
        // Calculate the tokenValue for this investment
        // returns zero if _currencyValue < minInvestment
        uint tokenValue = _estimateBuyValue(_currencyValue);
        require(tokenValue >= _minTokensBought, "PRICE_SLIPPAGE");
        if(state == State.Init){
            if(tokenValue + shareholdersPool < initTrial){
                //already received all currency from _collectInvestment
                if(!_manual) {
                    initInvestors[_to] = initInvestors[_to] + tokenValue;
                }
                initTrial = initTrial - tokenValue;
            }
            else if (initTrial > shareholdersPool){
                //already received all currency from _collectInvestment
                //send setup fee to beneficiary
                if(setupFee > 0){
                    _transferCurrency(setupFeeRecipient, setupFee);
                }
                _distributeInvestment(buybackReserve() - manualBuybackReserve);
                manualBuybackReserve = 0;
                initTrial = shareholdersPool;
                startedOn = block.timestamp;
            }
            else{
                _distributeInvestment(buybackReserve() - manualBuybackReserve);
                manualBuybackReserve = 0;
            }
        }
        else { //state == State.Run
            require(maxGoal == 0 || tokenValue + totalSupply() - stakeholdersPoolIssued <= maxGoal, "EXCEEDING_MAX_GOAL");
            _distributeInvestment(buybackReserve() - manualBuybackReserve);
            manualBuybackReserve = 0;
            if(fundraisingGoal != 0){
                if (tokenValue >= fundraisingGoal){
                    changeBuySlope(totalSupply() - stakeholdersPoolIssued, fundraisingGoal + totalSupply() - stakeholdersPoolIssued);
                    fundraisingGoal = 0;
                } else { //if (tokenValue < fundraisingGoal) {
                    changeBuySlope(totalSupply() - stakeholdersPoolIssued, tokenValue + totalSupply() - stakeholdersPoolIssued);
                    fundraisingGoal -= tokenValue;
                }
            }
        }

        totalInvested = totalInvested + _currencyValue;

        emit Buy(_from, _to, _currencyValue, tokenValue);
        _mint(_to, tokenValue);

        if(state == State.Init && totalSupply() - stakeholdersPoolIssued >= initGoal){
            _stateChange(State.Run);
        }
    }

    /// @dev Distributes _value currency between the beneficiary and feeCollector.
    function _distributeInvestment(
        uint _value
    ) internal
    {
        uint fee = _value * feeBasisPoints;
        fee /= BASIS_POINTS_DEN;

        // Math: since feeBasisPoints is <= BASIS_POINTS_DEN, this will never underflow.
        _transferCurrency(beneficiary, _value - fee);
        _transferCurrency(feeCollector, fee);
    }

    function estimateBuyValue(
        uint _currencyValue
    ) external view
    returns(uint)
    {
        return _estimateBuyValue(_currencyValue - gasFee);
    }

    /// @notice Calculate how many FAIR tokens you would buy with the given amount of currency if `buy` was called now.
    /// @param _currencyValue How much currency to spend in order to buy FAIR.
    function _estimateBuyValue(
        uint _currencyValue
    ) internal view
    returns(uint)
    {
        if(_currencyValue < minInvestment){
            return 0;
        }
        if(state == State.Init){
            uint currencyValue = _currencyValue;
            uint _totalSupply = totalSupply();
            uint max = BigDiv.bigDiv2x1(
                initGoal * uint256(buySlope.num),
                initGoal - (_totalSupply - stakeholdersPoolIssued),
                buySlope.den
            );

            if(currencyValue > max)
            {
                currencyValue = max;
            }

            uint256 tokenAmount = BigDiv.bigDiv2x1(
                currencyValue,
                buySlope.den,
                initGoal * uint256(buySlope.num)
            );
            if(currencyValue != _currencyValue)
            {
                currencyValue = _currencyValue - max;
                // ((2*next_amount/buy_slope)+init_goal^2)^(1/2)-init_goal
                // a: next_amount | currencyValue
                // n/d: buy_slope (type(uint128).max / type(uint128).max)
                // g: init_goal (type(uint128).max/2)
                // r: init_reserve (type(uint128).max/2)
                // sqrt(((2*a/(n/d))+g^2)-g
                // sqrt((2 d a + n g^2)/n) - g

                // currencyValue == 2 d a
                uint temp = 2 * uint256(buySlope.den);
                currencyValue = temp * currencyValue;

                // temp == g^2
                temp = initGoal;
                temp *= temp;

                // temp == n g^2
                temp = temp * uint256(buySlope.num);

                // temp == (2 d a) + n g^2
                temp = currencyValue + temp;

                // temp == (2 d a + n g^2)/n
                temp /= uint256(buySlope.num);

                // temp == sqrt((2 d a + n g^2)/n)
                temp = temp.sqrt();

                // temp == sqrt((2 d a + n g^2)/n) - g
                temp -= initGoal;

                tokenAmount = tokenAmount + temp;
            }
            return tokenAmount;
        }
        else if(state == State.Run) {//state == State.Run{
            uint supply = totalSupply() - stakeholdersPoolIssued;
            // calculate fundraising amount (static price)
            uint currencyValue = _currencyValue;
            uint fundraisedAmount;
            if(fundraisingGoal > 0){
                uint max = BigDiv.bigDiv2x1(
                    supply,
                    fundraisingGoal * uint256(buySlope.num),
                    buySlope.den
                );
                if(currencyValue > max){
                    currencyValue = max;
                }
                fundraisedAmount = BigDiv.bigDiv2x2(
                    currencyValue,
                    buySlope.den,
                    supply,
                    buySlope.num
                );
                //forward leftover currency to be used as normal buy
                currencyValue = _currencyValue - currencyValue;
            }

            // initReserve is reduced on sell as necessary to ensure that this line will not overflow
            // Math: worst case
            // MAX * 2 * type(uint128).max
            // / type(uint128).max
            uint tokenAmount = BigDiv.bigDiv2x1(
                currencyValue,
                2 * uint256(buySlope.den),
                buySlope.num
            );

            // Math: worst case MAX + (type(uint128).max * type(uint128).max)
            tokenAmount = tokenAmount + supply * supply;
            tokenAmount = tokenAmount.sqrt();

            // Math: small chance of underflow due to possible rounding in sqrt
            tokenAmount = tokenAmount - supply;
            return fundraisedAmount + tokenAmount;
        } else {
            return 0;
        }
    }

    // Sell

    /// @notice Sell FAIR tokens for at least the given amount of currency.
    /// @param _to The account to receive the currency from this sale.
    /// @param _quantityToSell How many FAIR tokens to sell for currency value.
    /// @param _minCurrencyReturned Get at least this many currency tokens or the transaction reverts.
    /// @dev _minCurrencyReturned is necessary as the price will change if some elses transaction mines after
    /// yours was submitted.
    function sell(
        address payable _to,
        uint _quantityToSell,
        uint _minCurrencyReturned
    ) public
    {
        _sell(msg.sender, _to, _quantityToSell, _minCurrencyReturned);
    }

    /// @notice Allow users to sign a message authorizing a sell
    function permitSell(
        address _from,
        address payable _to,
        uint _quantityToSell,
        uint _minCurrencyReturned,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external
    {
        require(_deadline >= block.timestamp, "EXPIRED");
        bytes32 digest = keccak256(
            abi.encode(PERMIT_SELL_TYPEHASH, _from, _to, _quantityToSell, _minCurrencyReturned, nonces[_from]++, _deadline)
        );
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                digest
            )
        );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress != address(0) && recoveredAddress == _from, "INVALID_SIGNATURE");
        _sell(_from, _to, _quantityToSell, _minCurrencyReturned);
    }

    function _sell(
        address _from,
        address payable _to,
        uint _quantityToSell,
        uint _minCurrencyReturned
    ) internal
    {
        require(_from != beneficiary, "BENEFICIARY_CANNOT_SELL");
        require(state != State.Init || initTrial != shareholdersPool, "INIT_TRIAL_ENDED");
        require(state == State.Init || state == State.Cancel, "ONLY_SELL_IN_INIT_OR_CANCEL");
        require(_minCurrencyReturned > 0, "MUST_SELL_AT_LEAST_1");
        // check for slippage
        uint currencyValue = estimateSellValue(_quantityToSell);
        require(currencyValue >= _minCurrencyReturned, "PRICE_SLIPPAGE");
        // it will work as checking _from has morethan _quantityToSell as initInvestors
        initInvestors[_from] = initInvestors[_from] - _quantityToSell;
        _burn(_from, _quantityToSell, true);
        _transferCurrency(_to, currencyValue);
        if(state == State.Init && initTrial != 0){
            // this can only happen if initTrial is set to zero from day one
            initTrial = initTrial + _quantityToSell;
        }
        totalInvested = totalInvested - currencyValue;
        emit Sell(_from, _to, currencyValue, _quantityToSell);
    }

    function estimateSellValue(
        uint _quantityToSell
    ) public view
        returns(uint)
    {
        if(state != State.Init && state != State.Cancel){
            return 0;
        }
        uint reserve = buybackReserve();

        // Calculate currencyValue for this sale
        uint currencyValue;
        // State.Init or State.Cancel
        // Math worst case:
        // MAX * type(uint128).max
        currencyValue = _quantityToSell * reserve;
        // Math: FAIR blocks initReserve from being burned unless we reach the RUN state which prevents an underflow
        currencyValue /= totalSupply() - stakeholdersPoolIssued - shareholdersPool;

        return currencyValue;
    }


    // Close

    /// @notice Called by the beneficiary account to State.Close or State.Cancel the c-org,
    /// preventing any more tokens from being minted.
    function close() public
    {
        _close();
        emit Close();
    }

    /// @notice Called by the beneficiary account to State.Close or State.Cancel the c-org,
    /// preventing any more tokens from being minted.
    /// @dev Requires an `exitFee` to be paid.    If the currency is ETH, include a little more than
    /// what appears to be required and any remainder will be returned to your account.    This is
    /// because another user may have a transaction mined which changes the exitFee required.
    /// For other `currency` types, the beneficiary account will be billed the exact amount required.
    function _close() internal
    {
        require(msg.sender == beneficiary, "BENEFICIARY_ONLY");

        if(state == State.Init)
        {
            // Allow the org to cancel anytime if the initGoal was not reached.
            require(initTrial > shareholdersPool,"CANNOT_CANCEL_IF_INITTRIAL_IS_ZERO");
            _stateChange(State.Cancel);
        }
        else if(state == State.Run)
        {
            require(type(uint256).max - minDuration > startedOn, "MAY_NOT_CLOSE");
            require(minDuration + startedOn <= block.timestamp, "TOO_EARLY");
            _stateChange(State.Close);
        }
        else
        {
            revert("INVALID_STATE");
        }
    }

    /// @notice mint new CAFE and send them to `wallet`
    function mint(
        address _wallet,
        uint256 _amount
    ) external
    {
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_MINT");
        require(
            _amount + stakeholdersPoolIssued <= (stakeholdersPoolAuthorized * (totalSupply() + _amount)) / BASIS_POINTS_DEN,
            "CANNOT_MINT_MORE_THAN_AUTHORIZED_PERCENTAGE"
        );
        //update stakeholdersPool issued value
        stakeholdersPoolIssued = stakeholdersPoolIssued + _amount;
        address to = _wallet == address(0) ? beneficiary : _wallet;
        //check if wallet is whitelist in the _mint() function
        _mint(to, _amount);
    }

    function manualBuy(
        address payable _wallet,
        uint256 _currencyValue
    ) external
    {
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_MINT");
        manualBuybackReserve += _currencyValue;
        _buy(_wallet, _wallet, _currencyValue, 1, true);
    }

    function permitManualBuy(
        address payable _wallet,
        uint256 _currencyValue,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_deadline >= block.timestamp, "EXPIRED");
        bytes32 digest = keccak256(
            abi.encode(PERMIT_MANUAL_BUY_TYPEHASH, _wallet, _currencyValue, nonces[beneficiary]++, _deadline)
        );
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                digest
            )
        );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress != address(0) && recoveredAddress == beneficiary, "INVALID_SIGNATURE");
        manualBuybackReserve += _currencyValue;
        _buy(_wallet, _wallet, _currencyValue, 1, true);
    }


    function increaseCommitment(
        uint256 _newCommitment,
        uint256 _amount
    ) external
    {
        require(state == State.Init || state == State.Run, "ONLY_IN_INIT_OR_RUN");
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_INCREASE_COMMITMENT");
        require(_newCommitment > 0, "COMMITMENT_CANT_BE_ZERO");
        require(equityCommitment + _newCommitment <= BASIS_POINTS_DEN, "EQUITY_COMMITMENT_SHOULD_BE_LESS_THAN_100%");
        equityCommitment = equityCommitment + _newCommitment;
        if(_amount > 0 ){
            if(state == State.Init){
                changeBuySlope(initGoal, _amount + initGoal);
                initGoal = initGoal + _amount;
            } else {
                fundraisingGoal = _amount;
            }
            if(maxGoal != 0){
                maxGoal = maxGoal + _amount;
            }
        }
    }

    function convertToCafe(
        uint256 _newCommitment,
        uint256 _amount,
        address _wallet
    ) external {
        require(state == State.Init || state == State.Run, "ONLY_IN_INIT_OR_RUN");
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_INCREASE_COMMITMENT");
        require(_newCommitment > 0, "COMMITMENT_CANT_BE_ZERO");
        require(equityCommitment + _newCommitment <= BASIS_POINTS_DEN, "EQUITY_COMMITMENT_SHOULD_BE_LESS_THAN_100%");
        require(_wallet != beneficiary && _wallet != address(0), "WALLET_CANNOT_BE_ZERO_OR_BENEFICIARY");
        equityCommitment = equityCommitment + _newCommitment;
        if(_amount > 0 ){
            shareholdersPool = shareholdersPool + _amount;
            if(state == State.Init){
                changeBuySlope(initGoal, _amount + initGoal);
                initGoal = initGoal + _amount;
                if(initTrial != 0){
                    initTrial = initTrial + _amount;
                }
            }
            else {
                changeBuySlope(totalSupply() - stakeholdersPoolIssued, _amount + totalSupply() - stakeholdersPoolIssued);
            }
            _mint(_wallet, _amount);
            if(maxGoal != 0){
                maxGoal = maxGoal + _amount;
            }
        }
    }

    function increaseValuation(uint256 _newValuation) external {
        require(state == State.Init || state == State.Run, "ONLY_IN_INIT_OR_RUN");
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_INCREASE_VALUATION");
        uint256 oldValuation;
        if(state == State.Init){
            oldValuation = (initGoal * initGoal * uint256(buySlope.num) * BASIS_POINTS_DEN) / (uint256(buySlope.den) * equityCommitment);
            require(_newValuation > oldValuation, "VALUATION_CAN_NOT_DECREASE");
            changeBuySlope(_newValuation, oldValuation);
        }else {
            oldValuation = ((totalSupply() - stakeholdersPoolIssued) * (totalSupply() - stakeholdersPoolIssued) * uint256(buySlope.num) * BASIS_POINTS_DEN) / (uint256(buySlope.den) * equityCommitment);
            require(_newValuation > oldValuation, "VALUATION_CAN_NOT_DECREASE");
            changeBuySlope(_newValuation, oldValuation);
        }
    }

    function changeBuySlope(uint256 _numerator, uint256 _denominator) internal {
        require(_denominator > 0, "DIV_0");
        if(_numerator == 0){
            buySlope.num = 0;
            return;
        }
        uint256 tryDen = BigDiv.bigDiv2x1(
            buySlope.den,
            _denominator,
            _numerator
        );
        if(tryDen <= type(uint128).max){
            buySlope.den = uint128(tryDen);
            return;
        }
        //if den exceeds type(uint128).max try num
        uint256 tryNum = BigDiv.bigDiv2x1(
            buySlope.num,
            _numerator,
            _denominator
        );
        if(tryNum > 0 && tryNum <= type(uint128).max) {
            buySlope.num = uint128(tryNum);
            return;
        }
        revert("error while changing slope");
    }

    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_BATCH_TRANSFER");
        require(recipients.length == amounts.length, "ARRAY_LENGTH_DIFF");
        require(recipients.length <= MAX_ITERATION, "EXCEEDS_MAX_ITERATION");
        for(uint256 i = 0; i<recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[0]);
        }
    }

    /// @notice Pay the organization on-chain without minting any tokens.
    /// @dev This allows you to add funds directly to the buybackReserve.
    receive() external payable {
        require(address(currency) == address(0), "ONLY_FOR_CURRENCY_ETH");
    }


    // --- Approve by signature ---
    // EIP-2612
    // Original source: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external
    {
        require(deadline >= block.timestamp, "EXPIRED");
        bytes32 digest = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                digest
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    uint256[50] private __gap;
}