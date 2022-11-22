// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./BasicBrewlabsBridge.sol";
import "./components/common/GasLimitManager.sol";
import "./components/common/InterestConnector.sol";
import "./modules/fee_manager/BrewlabsBridgeFeeManagerConnector.sol";
import "../libraries/SafeMint.sol";

/**
 * @title ForeignBrewlabsBridge
 * @dev Foreign side implementation for multi-token mediator intended to work on top of AMB bridge.
 * It is designed to be used as an implementation contract of EternalStorageProxy contract.
 */
contract ForeignBrewlabsBridge is 
    BasicBrewlabsBridge, 
    BrewlabsBridgeFeeManagerConnector, 
    GasLimitManager, 
    InterestConnector 
{
    using SafeERC20 for IERC677;
    using SafeMint for IBurnableMintableERC677Token;
    using SafeMath for uint256;

    constructor() {
        treasury = 0x408c4aDa67aE1244dfeC7D609dea3c232843189A;
        performanceFee = 0.03 ether;
    }

    /**
     * @dev Stores the initial parameters of the mediator.
     * @param _bridgeContract the address of the AMB bridge contract.
     * @param _mediatorContract the address of the mediator contract on the other network.
     * @param _dailyLimitMaxPerTxMinPerTxArray array with limit values for the assets to be bridged to the other network.
     *   [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
     * @param _executionDailyLimitExecutionMaxPerTxArray array with limit values for the assets bridged from the other network.
     *   [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
     * @param _requestGasLimit the gas limit for the message execution.
     * @param _owner address of the owner of the mediator contract.
     * @param _feeManager address of the BrewlabsBridgeFeeManager contract that will be used for fee distribution.
     */
    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        uint256[3] calldata _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = _dailyLimit, 1 = _maxPerTx, 2 = _minPerTx ]
        uint256[2] calldata _executionDailyLimitExecutionMaxPerTxArray, // [ 0 = _executionDailyLimit, 1 = _executionMaxPerTx ]
        uint256 _requestGasLimit,
        address _owner,
        address _feeManager
    ) external onlyRelevantSender returns (bool) {
        require(!isInitialized());

        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        _setLimits(address(0), _dailyLimitMaxPerTxMinPerTxArray);
        _setExecutionLimits(address(0), _executionDailyLimitExecutionMaxPerTxArray);
        _setRequestGasLimit(_requestGasLimit);
        _setOwner(_owner);
        _setFeeManager(_feeManager);

        setInitialize();

        return isInitialized();
    }

    /**
     * @dev Handles the bridged tokens.
     * Checks that the value is inside the execution limits and invokes the Mint or Unlock accordingly.
     * @param _token token contract address on this side of the bridge.
     * @param _isNative true, if given token is native to this chain and Unlock should be used.
     * @param _recipient address that will receive the tokens.
     * @param _value amount of tokens to be received.
     */
    function _handleTokens(
        address _token,
        bool _isNative,
        address _recipient,
        uint256 _value
    ) internal override {
        // prohibit withdrawal of tokens during other bridge operations (e.g. relayTokens)
        // such reentrant withdrawal can lead to an incorrect balanceDiff calculation
        require(!lock());

        require(withinExecutionLimit(_token, _value));
        addTotalExecutedPerDay(_token, getCurrentDay(), _value);

        uint256 valueToBridge = _value;
        uint256 fee = _distributeFee(HOME_TO_FOREIGN_FEE, _isNative, address(0), _token, valueToBridge);
        bytes32 _messageId = messageId();
        if (fee > 0) {
            emit FeeDistributed(fee, _token, _messageId);
            valueToBridge = valueToBridge.sub(fee);
        }

        _releaseTokens(_isNative, _token, _recipient, valueToBridge, _value);

        emit TokensBridged(_token, _recipient, valueToBridge, messageId());
    }

    /**
     * @dev Executes action on deposit of bridged tokens
     * @param _token address of the token contract
     * @param _from address of tokens sender
     * @param _receiver address of tokens receiver on the other side
     * @param _value requested amount of bridged tokens
     * @param _data additional transfer data to be used on the other side
     */
    function bridgeSpecificActionsOnTokenTransfer(
        address _token,
        address _from,
        address _receiver,
        uint256 _value,
        bytes memory _data
    ) internal virtual override {
        require(_receiver != address(0) && _receiver != mediatorContractOnOtherSide());

        // native unbridged token
        if (!isTokenRegistered(_token)) {
            uint8 decimals = TokenReader.readDecimals(_token);
            _initializeTokenBridgeLimits(_token, decimals);
        }

        require(withinLimit(_token, _value));
        addTotalSpentPerDay(_token, getCurrentDay(), _value);

        address nativeToken = nativeTokenAddress(_token);
        uint256 fee = _distributeFee(FOREIGN_TO_HOME_FEE, nativeToken == address(0) || bridgeIsLiquidityMode(_token), _from, _token, _value);
        uint256 valueToBridge = _value.sub(fee);

        bytes memory data = _prepareMessage(nativeToken, _token, _receiver, valueToBridge, _data);
        bytes32 _messageId = _passMessage(data, true);
        _recordBridgeOperation(_messageId, _token, _from, valueToBridge);
        if (fee > 0) {
            emit FeeDistributed(fee, _token, _messageId);
        }
    }

    /**
     * Internal function for unlocking some amount of tokens.
     * @param _isNative true, if token is native w.r.t. to this side of the bridge.
     * @param _token address of the token contract.
     * @param _recipient address of the tokens receiver.
     * @param _value amount of tokens to unlock.
     * @param _balanceChange amount of balance to subtract from the mediator balance.
     */
    function _releaseTokens(
        bool _isNative,
        address _token,
        address _recipient,
        uint256 _value,
        uint256 _balanceChange
    ) internal override {
        if (_isNative || bridgeIsLiquidityMode(_token)) {
            // There are two edge cases related to withdrawals on the foreign side of the bridge.
            // 1) Minting of extra STAKE tokens, if supply on the Home side exceeds total bridge amount on the Foreign side.
            // 2) Withdrawal of the invested tokens back from the Compound-like protocol, if currently available funds are insufficient.
            // Most of the time, these cases do not intersect. However, in case STAKE tokens are also invested (e.g. via EasyStaking),
            // the situation can be the following:
            // - 20 STAKE are bridged through the OB. 15 STAKE of which are invested into EasyStaking, and 5 STAKE are locked directly on the bridge.
            // - 5 STAKE are mistakenly locked on the bridge via regular transfer, they are not accounted in mediatorBalance(STAKE)
            // - User requests withdrawal of 30 STAKE from the Home side.
            // Correct sequence of actions should be the following:
            // - Mint new STAKE tokens (value - mediatorBalance(STAKE) = 30 STAKE - 20 STAKE = 10 STAKE)
            // - Set local variable balance to 30 STAKE
            // - Withdraw all invested STAKE tokens (value - (balance - investedAmount(STAKE)) = 30 STAKE - (30 STAKE - 15 STAKE) = 15 STAKE)

            uint256 balance = mediatorBalance(_token);
            IInterestImplementation impl = interestImplementation(_token);
            // can be used instead of Address.isContract(address(impl)),
            // since _setInterestImplementation guarantees that impl is either a contract or zero address
            // and interest implementation does not contain any selfdestruct opcode
            if (address(impl) != address(0)) {
                uint256 availableBalance = balance.sub(impl.investedAmount(_token));
                if (_value > availableBalance) {
                    impl.withdraw(_token, (_value - availableBalance).add(minCashThreshold(_token)));
                }
            }

            _setMediatorBalance(_token, balance.sub(_balanceChange));
            IERC677(_token).safeTransfer(_recipient, _value);
        } else {
            _getMinterFor(_token).safeMint(_recipient, _value);
        }
    }

    /**
     * @dev Internal function for sending an AMB message to the mediator on the other side.
     * @param _data data to be sent to the other side of the bridge.
     * @param _useOracleLane always true, not used on this side of the bridge.
     * @return id of the sent message.
     */
    function _passMessage(bytes memory _data, bool _useOracleLane) internal override returns (bytes32) {
        (_useOracleLane);

        return bridgeContract().requireToPassMessage(mediatorContractOnOtherSide(), _data, requestGasLimit());
    }

    /**
     * @dev Internal function for counting excess balance which is not tracked within the bridge.
     * Represents the amount of forced tokens on this contract.
     * @param _token address of the token contract.
     * @return amount of excess tokens.
     */
    function _unaccountedBalance(address _token) internal view override returns (uint256) {
        IInterestImplementation impl = interestImplementation(_token);
        uint256 invested = Address.isContract(address(impl)) ? impl.investedAmount(_token) : 0;
        return IERC677(_token).balanceOf(address(this)).sub(mediatorBalance(_token).sub(invested));
    }

    /**
     * @dev Internal function for getting minter proxy address.
     * Returns the token address itself, expect for the case with bridged STAKE token.
     * For bridged STAKE token, returns the hardcoded TokenMinter contract address.
     * @param _token address of the token to mint.
     * @return address of the minter contract that should be used for calling mint(address,uint256)
     */
    function _getMinterFor(address _token)
        internal
        pure
        override(BasicBrewlabsBridge, BrewlabsBridgeFeeManagerConnector)
        returns (IBurnableMintableERC677Token)
    {
        return IBurnableMintableERC677Token(_token);
    }
}