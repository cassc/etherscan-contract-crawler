// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;
import "./interfaces/Interfaces.sol";

/// @title Option ERC721
/// @author dannydoritoeth
/// @notice An NFT token that represents the individual option positions. It is shared across all vaults created by
///  OptionsVaultFactory. It also acts as the primary interface between users who want to purchase options and the
///  underlying vaults that want to sell them.
contract OptionsERC721 is ERC721, AccessControl, IStructs, IFeeCalcs, ReentrancyGuard, IOptionsHealthCheck {
    using SafeERC20 for IERC20;

    // properties
    Option[] public options;
    IOptionsVaultFactory public immutable factory;
    IOptionsHealthCheck public healthCheck;
    IReferrals public referrals;
    address public protocolFeeRecipient;
    IFeeCalcs public protocolFeeCalcs;
    uint public protocolFee = 100;  //1%
    uint public autoExercisePeriod = 30 minutes;

    // events

    /// @notice A new option is created
    /// @param optionId ID of the option
    /// @param inParams the parameters passed to the premium function in a struct
    /// @param fees the premium calculated for the option in a struct
    event CreateOption(uint256 indexed optionId, InputParams inParams, IStructs.Fees fees);

    /// @notice An option is exercised
    /// @param optionId ID of the option
    /// @param vaultId Vault id
    /// @param profit the profit the option buyer received
    event Exercise(uint256 indexed optionId, uint vaultId, uint256 profit);

    /// @notice An option has expired
    /// @param optionId ID of the option
    /// @param vaultId Vault id
    /// @param premium the total premium
    event Expire(uint256 indexed optionId, uint vaultId, uint256 premium);

    /// @notice An option has been transferred to a new user
    /// @param optionId ID of the option
    /// @param from Changing from
    /// @param to Changing to
    event TransferOption(uint256 indexed optionId, address from, address to);

    /// @notice Change a global int variable
    /// @param byAccount The account making the change
    /// @param eventType The type of event this change is
    /// @param from Changing from
    /// @param to Changing to
    event SetGlobalInt(address indexed byAccount, SetVariableType indexed eventType, uint256 from, uint256 to);

    /// @notice Change a global address variable
    /// @param byAccount The account making the change
    /// @param eventType The type of event this change is
    /// @param from Changing from
    /// @param to Changing to
    event SetGlobalAddress(address indexed byAccount, SetVariableType indexed eventType, address from, address to);

    /// @notice Deploy new NFT contract
    /// @dev Explain to a developer any extra details
    /// @param _protocolFeeRecipient the address who will receive the protocol fee
    /// @param _factory the factory contract where options vaults will be accessed from
    /// @param _referrals an implementation of the referrals
    /// @param name the token name for the nft
    /// @param symbol the token symbol for the nft
    constructor(
        address _protocolFeeRecipient,
        IOptionsVaultFactory _factory,
        IReferrals _referrals,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol)  {
        require(_protocolFeeRecipient!=address(0), "OptionsERC721: protocolFeeRecipient address is zero");
        factory = _factory;
        referrals = _referrals;
        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeCalcs = this;
        healthCheck = this;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Calculates the premium that a vault will offer for the option parameters supplied
    /// @param period Option period in seconds
    /// @param optionSize Option size
    /// @param strike Strike price of the option
    /// @param optionType Call or Put option type
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    /// @param referredBy Referred by address
    /// @return premium_ the premium calculated for the option in a struct
    /// @return inParams_ the parameters passed to the premium function in a struct
    function premium(
        uint256 period,
        uint256 optionSize,
        uint256 strike,
        OptionType optionType,
        uint vaultId,
        IOracle oracle,
        address referredBy
    )   public
        view
        returns (Fees memory premium_,InputParams memory inParams_)
    {
        inParams_ = OptionsLib.getStructs(factory, _msgSender(), period, optionSize, strike, optionType, vaultId, oracle, referredBy);
        ( uint256 currentPrice, OracleResponse memory oracleResponse) = latestAnswer(oracle);
        inParams_.currentPrice = currentPrice;
        inParams_.oracleResponse = oracleResponse;

        Fees memory protocolFees = protocolFeeCalcs.getFees(inParams_);
        Fees memory vaultFees = inParams_.vault.vaultFeeCalc().getFees(inParams_);

        premium_.protocolFee = protocolFees.protocolFee;
        premium_.referFee = protocolFees.referFee;
        premium_.intrinsicFee = vaultFees.intrinsicFee;
        premium_.extrinsicFee = vaultFees.extrinsicFee;
        premium_.vaultFee = vaultFees.vaultFee;
        premium_.total = premium_.protocolFee + premium_.referFee + premium_.intrinsicFee + premium_.extrinsicFee + premium_.vaultFee;
        inParams_.vault.isOptionValid(_msgSender(),period,optionSize,oracle,premium_.intrinsicFee + premium_.extrinsicFee);
    }

    /// @notice Default implementation of the fee interface to calculate the protocol & refer fees
    /// @dev Explain to a developer any extra details
    /// @param inParams the parameters passed to the premium function in a struct
    /// @return fees_ the fees struct with the relevant params updated
    function getFees(IStructs.InputParams memory inParams) external view returns (Fees memory fees_){
        fees_.protocolFee = protocolFee*inParams.optionSize/1e4;
        fees_.referFee = referrals.getReferFee(inParams);
    }

     /**
     * @notice The main function to purchase an option is the create function. When called, the user can provide all details of the option they are interested in purchasing: the strike price, the oracle to use (in which currency the option is denominated), whether the option is a call or put and when it expires (the maturity date). When creating an option, the user needs to transfer in collateral tokens of the vault as payment for the option. These tokens are then distributed to various recipients as fees and as compensation for the vault. 
     * @param period Option period in seconds
     * @param optionSize Option size
     * @param strike Strike price of the option
     * @param optionType Call or Put option type
     * @param vaultId Vault id
     * @param oracle Oracle address
     * @param referredBy Referred by address
     * @return optionID Created option's ID
     */
    function create(
        uint256 period,
        uint256 optionSize,
        uint256 strike,
        OptionType optionType,
        uint256 vaultId,
        IOracle oracle,
        address referredBy,
        uint256 maxPremium
    )
        public nonReentrant
        returns (uint optionID)
    {
        require(
            optionType == OptionType.Call || optionType == OptionType.Put,
            "OptionsERC721: Wrong option type"
        );

        (Fees memory premium, InputParams memory inParams) = premium(period, optionSize, strike, optionType, vaultId, oracle, referredBy);

        optionID = options.length;
        inParams.referrer = referrals.captureReferral(_msgSender(), referredBy);
        Option memory option = _createOption(premium,inParams);

        require(premium.total<=maxPremium,"OptionsERC721: Greater than max premium");

        inParams.vault.provideAndMint(premium.intrinsicFee+premium.extrinsicFee, false, true);
        inParams.vault.lock(optionID, option.optionSize, optionType);
        options.push(option);

        require(healthCheck.IsSafeToCreateOption(premium, inParams),"OptionsERC721: Not safe to create option");
        _safeMint(_msgSender(), optionID);

        emit CreateOption(optionID, inParams, premium);

        //pay protocol, referer & vault owner
        IERC20 token = inParams.vault.collateralToken();
        token.safeTransferFrom(_msgSender(), address(protocolFeeRecipient), premium.protocolFee);
        token.safeTransferFrom(_msgSender(), address(inParams.referrer), premium.referFee);
        token.safeTransferFrom(_msgSender(), inParams.vault.vaultFeeRecipient(), premium.vaultFee);
        token.safeTransferFrom(_msgSender(), address(inParams.vault), premium.intrinsicFee+premium.extrinsicFee);
    }

    /// @notice An internal function to create the option struct
    /// @param _premium the struct to be used to pass the premium calculated
    /// @param inParams the parameters passed to the premium function in a struct
    /// @return option the return variables of a contract’s function state variable
    function _createOption(Fees memory _premium, InputParams memory inParams) internal view returns (Option memory option){
        option = Option(
           State.Active,
            inParams.holder,
            inParams.strike,
            inParams.optionSize,
            _premium,
            block.timestamp + inParams.period,
            inParams.optionType,
            inParams.vaultId,
            inParams.oracle,
            inParams.referrer
        );
    }

     /// @notice Call when creating an option and returns false if the option fails some risk check
     /// @param premium_ the premium calculated for the option in a struct
     /// @param inParams_ the parameters passed to the premium function in a struct
     /// @return Documents the return variables of a contract’s function state variable
    function IsSafeToCreateOption(IStructs.Fees memory premium_,IStructs.InputParams memory inParams_) public override returns(bool){
        require(inParams_.oracleResponse.answeredInRound >= inParams_.oracleResponse.roundId, "OptionsERC721: Stale oracle answer");
        require(inParams_.oracleResponse.updatedAt != 0, "OptionsERC721: Oracle round incomplete");
        return true;
    }

    /// @notice Get the latest price for a given oracle. If the price is less than 0 it returns 0.
    /// @param oracle Oracle address
    function latestAnswer(IOracle oracle) public view returns (uint256 currentPrice, OracleResponse memory oracleResponse){

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) = oracle.latestRoundData();
        oracleResponse.roundId = roundId;
        oracleResponse.answer = answer;
        oracleResponse.startedAt = startedAt;
        oracleResponse.updatedAt = timeStamp;
        oracleResponse.answeredInRound = answeredInRound;

        require(answer >= 0, "OptionsERC721: Oracle value must be atleast 0");
        currentPrice = SafeCast.toUint256(answer);
    }

    /// @notice Exercises an active option. The option can be exercised at any point in time up to the expiration timestamp. Exercising is only allowed if the option is in-the-money. The option holder is the only account that can exercise their option. However, for the last 30 minutes of the option, anyone can exercise the option for the holder as the option would have no value anyway after it expires. In this case, the profits are still sent to the original option holder.
    /// @param optionID ID of your option
    function exercise(uint256 optionID) external nonReentrant {
        Option memory option = options[optionID];

        require(option.expiration >= block.timestamp, "OptionsERC721: Option has expired");
        require(option.state == State.Active, "OptionsERC721: Wrong state");

        //only holder or approved can exercise within the auto exercise period
        if(block.timestamp < option.expiration-autoExercisePeriod){
            require((option.holder == _msgSender())||isApprovedForAll(option.holder,_msgSender()), "OptionsERC721: Not sender or approved");
        }

        options[optionID].state = State.Exercised;

        uint256 profit;
        ( uint256 currentPrice, ) = latestAnswer(option.oracle);

        if (option.optionType == OptionType.Call) {
            require(option.strike < currentPrice, "OptionsERC721: Current price is too low");
            profit = (currentPrice-option.strike)*(option.optionSize)/(option.strike);
        } else if (option.optionType == OptionType.Put) {
            require(option.strike > currentPrice, "OptionsERC721: Current price is too high");
            profit = (option.strike-currentPrice)*(option.optionSize)/(option.strike);
        }

        if (profit > option.optionSize)
            profit = option.optionSize;

        factory.vaults(option.vaultId).send(optionID, option.holder, profit);

        emit Exercise(optionID, option.vaultId, profit);
    }

    /// @notice Overrides the nft transfer function to support transferring an option to someone else
    /// @dev Explain to a developer any extra details
    /// @param from Changing from
    /// @param to Changing to
    /// @param optionID ID of the option
    function _transfer(
        address from,
        address to,
        uint256 optionID
    ) internal override nonReentrant {
        super._transfer(from,to,optionID);

        Option storage option = options[optionID];

        require(to != address(0), "OptionsERC721: New holder address is zero");
        require(option.expiration >= block.timestamp, "OptionsERC721: Option has expired");
        require(option.holder == _msgSender(), "OptionsERC721: Wrong _msgSender()");
        require(option.state == State.Active, "OptionsERC721: Only active option could be transferred");

        address oldHolder = option.holder;
        option.holder = to;
        emit TransferOption(optionID, oldHolder, to);
    }

    /// @notice Unlock funds locked in the expired options
    /// @param optionID ID of the option
    function unlock(uint256 optionID) public nonReentrant {
        Option storage option = options[optionID];
        require(option.state == State.Active, "OptionsERC721: Option is not active");
        require(option.expiration < block.timestamp, "OptionsERC721: Option has not expired yet");
        option.state = State.Expired;
        factory.vaults(option.vaultId).unlock(optionID);
        emit Expire(optionID, option.vaultId, option.premium.total);
    }


    /// @notice Unlocks an array of options
    /// @param optionIDs array of option ids
    function unlockAll(uint256[] calldata optionIDs) external {
        uint arrayLength = optionIDs.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            unlock(optionIDs[i]);
        }
    }

    /// @notice Returns true if this contract implements the interface defined by interfaceId. See the corresponding EIP section to learn more about how these ids are created.
    /// @param interfaceId interface to be checked
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    /// @notice Update the protocol fee sent to the protocolFeeRecipient
    /// @param value Change the value to
    function setProtocolFee(uint value) external IsDefaultAdmin {
        emit SetGlobalInt(_msgSender(),SetVariableType.ProtocolFee, protocolFee, value);
        protocolFee = value;
    }

    /// @notice Update the address who will receive the protocol fee
    /// @param value Change the value to
    function setProtocolFeeRecipient(address value) external IsDefaultAdmin  {
        require(value != address(0), "OptionsERC721: protocolFeeRecipient address is zero");
        emit SetGlobalAddress(_msgSender(),SetVariableType.ProtocolFeeRecipient, address(protocolFeeRecipient), address(value));
        protocolFeeRecipient = value;
    }

    /// @notice Change the address that implements the protocol fees function
    /// @param value Change the value to
    function setProtocolFeeCalc(IFeeCalcs value) external IsDefaultAdmin {
        emit SetGlobalAddress(_msgSender(),SetVariableType.ProtocolFeeCalc, address(protocolFeeCalcs), address(value));
        protocolFeeCalcs = value;
    }

    /// @notice Change the address that implements the option health check function
    /// @param value Change the value to
    function setReferrals(IReferrals value) external IsDefaultAdmin  {
        emit SetGlobalAddress(_msgSender(),SetVariableType.Referrals, address(referrals), address(value));
        referrals = value;
    }

    /// @notice Change the address that implements the option health check function
    /// @param value Change the value to
    function setOptionHealthCheck(IOptionsHealthCheck value) external IsDefaultAdmin {
        emit SetGlobalAddress(_msgSender(),SetVariableType.OptionsHealthCheck, address(healthCheck), address(value));
        healthCheck = value;
    }

    /// @notice The time in seconds before expiry that an option can be exercised by anyone
    /// @param value Change the value to
    function setAutoExercisePeriod(uint256 value) external IsDefaultAdmin  {
        require(value<=30 minutes,"OptionsERC721: value<=30 minutes");
        emit SetGlobalInt(_msgSender(),SetVariableType.AutoExercisePeriod, autoExercisePeriod, value);
        autoExercisePeriod = value;
    }

    /// modifiers

    /// @notice A modifer that checks if the caller holds the DEFAULT_ADMIN_ROLE role on the options nft contract
    modifier IsDefaultAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "OptionsERC721: must have admin role");
        _;
    }

}