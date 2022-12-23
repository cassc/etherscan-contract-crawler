// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IDepositExecute.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IOneSplitWrap.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERC20Upgradeable.sol";
import "./HandlerHelpersUpgradeable.sol";
import "../interfaces/IUsdcDepositAndBurn.sol";

/// @title Handles ERC20 deposits and deposit executions.
/// @author Router Protocol.
/// @notice This contract is intended to be used with the Bridge contract.
contract ERC20HandlerUpgradeable is
    Initializable,
    ContextUpgradeable,
    IDepositExecute,
    HandlerHelpersUpgradeable,
    ILiquidityPool
{
    using SafeMathUpgradeable for uint256;

    struct DepositRecord {
        uint8 _destinationChainID;
        address _srcTokenAddress;
        address _stableTokenAddress;
        uint256 _stableTokenAmount;
        address _destStableTokenAddress;
        uint256 _destStableTokenAmount;
        address _destinationTokenAdress;
        uint256 _destinationTokenAmount;
        bytes32 _resourceID;
        address _destinationRecipientAddress;
        address _depositer;
        uint256 _srcTokenAmount;
        address _feeTokenAddress;
        uint256 _feeAmount;
        uint256 _isDestNative;
    }

    // destId => depositNonce => Deposit Record
    mapping(uint8 => mapping(uint64 => DepositRecord)) private _depositRecords;

    // token contract address => chainId => decimals
    mapping(address => mapping(uint8 => uint8)) public tokenDecimals;

    mapping(uint256 => mapping(uint64 => uint256)) public executeRecord;

    address public _sequencerAddress;

    bytes32 public constant SEQUENCER_ROLE = keccak256("SEQUENCER_ROLE");

    IUsdcDepositAndBurn public _usdcBurnerContract;

    // destId => if USDC is burnable and mintable
    mapping(uint8 => bool) public _isUsdcBurnableMintable;

    // destId => depositNonce => usdcNonce if usdc was burnt else 0
    mapping(uint8 => mapping(uint64 => uint64)) private _usdcBurnData;
    address private _usdc;

    modifier onlyBridgeOrSequencer() {
        require(hasRole(BRIDGE_ROLE, msg.sender) || hasRole(SEQUENCER_ROLE, msg.sender), "Unauthorized transaction");
        _;
    }

    function __ERC20HandlerUpgradeable_init(
        address bridgeAddress,
        address ETH,
        address WETH,
        bytes32[] memory initialResourceIDs,
        address[] memory initialContractAddresses,
        address[] memory burnableContractAddresses
    ) internal initializer {
        __Context_init_unchained();
        __HandlerHelpersUpgradeable_init();

        require(initialResourceIDs.length == initialContractAddresses.length, "array length mismatch");

        _bridgeAddress = bridgeAddress;
        _ETH = ETH;
        _WETH = WETH;

        uint256 initialResourceCount = initialResourceIDs.length;
        for (uint256 i = 0; i < initialResourceCount; i++) {
            _setResource(initialResourceIDs[i], initialContractAddresses[i]);
        }

        uint256 burnableCount = burnableContractAddresses.length;
        for (uint256 i = 0; i < burnableCount; i++) {
            _setBurnable(burnableContractAddresses[i], true);
        }
    }

    function __ERC20HandlerUpgradeable_init_unchained() internal initializer {}

    /**
        @param bridgeAddress Contract address of previously deployed Bridge.
        // Resource IDs are used to identify a specific contract address.
        // These are the Resource IDs this contract will initially support.
        // These are the addresses the {initialResourceIDs} will point to,
        // and are the contracts that will be called to perform various deposit calls.
        @param burnableContractAddresses These addresses will be set as burnable and when {deposit} is called,
        the deposited token will be burned.
        When {executeProposal} is called, new tokens will be minted.

        @dev {initialResourceIDs} and {initialContractAddresses} must have the same length
        (one resourceID for every address).
        Also, these arrays must be ordered in the way that {initialResourceIDs}[0] is the
        intended resourceID for {initialContractAddresses}[0].
     */
    function initialize(
        address bridgeAddress,
        address ETH,
        address WETH,
        bytes32[] memory initialResourceIDs,
        address[] memory initialContractAddresses,
        address[] memory burnableContractAddresses
    ) external initializer {
        __ERC20HandlerUpgradeable_init(
            bridgeAddress,
            ETH,
            WETH,
            initialResourceIDs,
            initialContractAddresses,
            burnableContractAddresses
        );
    }

    receive() external payable {}

    /// @notice Function to set the bridge address
    /// @dev Can only be called by default admin
    /// @param _bridge address of the bridge
    function setBridge(address _bridge) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _bridgeAddress = _bridge;
    }

    /// @notice Function to set the sequencer address
    /// @dev Can only be called by default admin
    /// @param _sequencer address of the sequencer
    function setSequencer(address _sequencer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _sequencerAddress = _sequencer;
        grantRole(SEQUENCER_ROLE, _sequencer);
    }

    /// @notice Function to set token decimals on target chain.
    /// @dev Can only be called by resource setter.
    /// @param  tokenAddress address of the token.
    /// @param  destinationChainID chainId for destination chain.
    /// @param  decimals decimals for the token.
    function setTokenDecimals(
        address[] calldata tokenAddress,
        uint8[] calldata destinationChainID,
        uint8[] calldata decimals
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            tokenAddress.length == destinationChainID.length && tokenAddress.length == decimals.length,
            "Array length mismatch"
        );
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            require(_contractWhitelist[tokenAddress[i]], "provided contract not whitelisted");
            tokenDecimals[tokenAddress[i]][destinationChainID[i]] = decimals[i];
        }
    }

    /// @notice Function to change precision of a token
    /// @param  token address of the token
    /// @param  chainId chainId for destination chain
    /// @param  tokenAmount amount of token
    function changePrecision(
        address token,
        uint8 chainId,
        uint256 tokenAmount
    ) public view returns (uint256) {
        IERC20Upgradeable srcToken = IERC20Upgradeable(token);
        require(tokenDecimals[token][chainId] > 0, "Decimals not set");
        uint8 srcDecimal = srcToken.decimals();
        uint8 destDecimal = tokenDecimals[token][chainId];
        if (srcDecimal == destDecimal) return tokenAmount;
        if (srcDecimal > destDecimal) {
            uint256 factor = (10**(srcDecimal - destDecimal));
            return tokenAmount / factor;
        } else {
            uint256 factor = (10**(destDecimal - srcDecimal));
            return tokenAmount * factor;
        }
    }

    /// @notice Function to set execute record
    /// @param  chainId chainId for destination chain
    /// @param  nonce nonce for the transaction
    function setExecuteRecord(uint256 chainId, uint64 nonce) internal {
        executeRecord[chainId][nonce] = block.number;
    }

    /// @notice Function used to fetch deposit record
    /// @param depositNonce This ID will have been generated by the Bridge contract
    /// @param destId ID of chain deposit will be bridged to
    /// @return DepositRecord
    function getDepositRecord(uint64 depositNonce, uint8 destId) public view virtual returns (DepositRecord memory) {
        return _depositRecords[destId][depositNonce];
    }

    /// @notice Function used to fetch usdc burn data
    /// @param depositNonce This ID will have been generated by the Bridge contract
    /// @param destId ID of chain deposit will be bridged to
    /// @return USDC Burn data()
    /// (abi.encode(uint8 destChainId,uint32 usdcDomainId,address destReserveHandlerAddress,address usdc,address destCallerAddress,uint256 usdcNonce))
    function getUsdcBurnData(uint64 depositNonce, uint8 destId) public view virtual returns (uint64) {
        return _usdcBurnData[destId][depositNonce];
    }

    /// @notice Function used to fetch usdc address
    function getUsdcAddress() public view returns (address) {
        return _usdc;
    }

    /// @notice Function used to set reserve handler
    /// @param reserve address of the reserve handler
    function setReserve(IHandlerReserve reserve) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _reserve = reserve;
    }

    /// @notice Function used to set usdc address
    /// @param  usdc address
    function setUsdcAddress(address usdc) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _usdc = usdc;
    }

    function setUsdcBurnerContract(address _usdcBurner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _usdcBurnerContract = IUsdcDepositAndBurn(_usdcBurner);
    }

    function setUsdcBurnableAndMintable(uint8[] memory _destChainID, bool[] memory _setTrue)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_destChainID.length == _setTrue.length, "Array length mismatch");
        for (uint8 i = 0; i < _destChainID.length; i++) {
            require(_destChainID[i] != 0, "Chain Id != 0");

            _isUsdcBurnableMintable[_destChainID[i]] = _setTrue[i];
        }
    }

    /// @notice A deposit is initiatied by making a deposit in the Bridge contract
    /// @dev Depending if the corresponding {tokenAddress} for the parsed {resourceID} is
    /// marked true in {_burnList}, deposited tokens will be burned, if not, they will be locked.
    /// @param resourceID Resource ID for the token
    /// @param destinationChainID Chain ID of chain tokens are expected to be bridged to
    /// @param depositNonce This value is generated as an ID by the Bridge contract
    /// @param swapDetails Swap details struct required for the deposit
    function deposit(
        bytes32 resourceID,
        uint8 destinationChainID,
        uint64 depositNonce,
        SwapInfo memory swapDetails
    ) public virtual override onlyBridgeOrSequencer {
        uint256 feeAmount;
        swapDetails.srcStableTokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(_contractWhitelist[swapDetails.srcStableTokenAddress], "provided token is not whitelisted");

        if (address(swapDetails.srcTokenAddress) == swapDetails.srcStableTokenAddress) {
            require(swapDetails.srcStableTokenAmount == swapDetails.srcTokenAmount, "Invalid token amount");
            if (swapDetails.feeTokenAddress == address(0)) {
                swapDetails.feeTokenAddress = swapDetails.srcStableTokenAddress;
            }
            (uint256 transferFee, , uint256 widgetFeeAmount) = getBridgeFee(
                destinationChainID,
                swapDetails.feeTokenAddress,
                swapDetails.widgetID
            );

            feeAmount = transferFee + widgetFeeAmount;
            // Fees of stable token address
            _reserve.deductFee(
                swapDetails.feeTokenAddress,
                swapDetails.depositer,
                // swapDetails.providedFee,
                feeAmount,
                // _ETH,
                _isFeeEnabled,
                address(feeManager)
            );

            if (widgetFeeAmount > 0) {
                feeManager.depositWidgetFee(swapDetails.widgetID, swapDetails.feeTokenAddress, widgetFeeAmount);
            }

            // if (_usdc == swapDetails.srcStableTokenAddress && _isUsdcBurnableMintable[destinationChainID]) {
            //     // Burn USDC
            //     handleUsdcBurn(swapDetails.depositer, swapDetails.srcTokenAmount, destinationChainID, depositNonce);
            // } else {
            // just deposit
            handleDepositForReserveToken(depositNonce, destinationChainID, swapDetails);
            // }
        } else if (_reserve._contractToLP(swapDetails.srcStableTokenAddress) == address(swapDetails.srcTokenAddress)) {
            require(swapDetails.srcStableTokenAmount == swapDetails.srcTokenAmount, "Invalid token amount");
            feeAmount = deductFeeAndHandleDepositForLPToken(swapDetails, destinationChainID);
        } else {
            if (swapDetails.feeTokenAddress != address(0)) {
                (, uint256 exchangeFee, uint256 widgetFeeAmount) = getBridgeFee(
                    destinationChainID,
                    swapDetails.feeTokenAddress,
                    swapDetails.widgetID
                );

                feeAmount = exchangeFee + widgetFeeAmount;
                // Fees of stable token address

                _reserve.deductFee(
                    swapDetails.feeTokenAddress,
                    swapDetails.depositer,
                    // swapDetails.providedFee,
                    feeAmount,
                    // _ETH,
                    _isFeeEnabled,
                    address(feeManager)
                );

                if (widgetFeeAmount > 0) {
                    feeManager.depositWidgetFee(swapDetails.widgetID, swapDetails.feeTokenAddress, widgetFeeAmount);
                }
            }

            _reserve.lockERC20(
                address(swapDetails.srcTokenAddress),
                swapDetails.depositer,
                _oneSplitAddress,
                swapDetails.srcTokenAmount
            );
            handleDepositForNonReserveToken(swapDetails);

            if (swapDetails.feeTokenAddress == address(0)) {
                (, uint256 exchangeFee, uint256 widgetFeeAmount) = getBridgeFee(
                    destinationChainID,
                    swapDetails.srcStableTokenAddress,
                    swapDetails.widgetID
                );

                feeAmount = exchangeFee + widgetFeeAmount;
                swapDetails.feeTokenAddress = swapDetails.srcStableTokenAddress;
                require(swapDetails.srcStableTokenAmount >= feeAmount, "provided fee is < amount");
                swapDetails.srcStableTokenAmount = swapDetails.srcStableTokenAmount - feeAmount;
                _reserve.releaseERC20(swapDetails.feeTokenAddress, address(feeManager), feeAmount);
                feeManager.depositWidgetFee(swapDetails.widgetID, swapDetails.feeTokenAddress, widgetFeeAmount);
            }

            if (_burnList[address(swapDetails.srcStableTokenAddress)]) {
                _reserve.burnERC20(
                    address(swapDetails.srcStableTokenAddress),
                    address(_reserve),
                    swapDetails.srcStableTokenAmount
                );
            } else if (swapDetails.srcStableTokenAddress == _usdc && _isUsdcBurnableMintable[destinationChainID]) {
                // Burn USDC
                handleUsdcBurn(swapDetails.srcStableTokenAmount, destinationChainID, depositNonce);
            }
        }

        uint256 destStableTokenAmount = changePrecision(
            address(swapDetails.srcStableTokenAddress),
            destinationChainID,
            swapDetails.srcStableTokenAmount
        );

        require(destStableTokenAmount > 0, "Transfer amount too low");
        _depositRecords[destinationChainID][depositNonce] = DepositRecord(
            destinationChainID,
            address(swapDetails.srcTokenAddress),
            swapDetails.srcStableTokenAddress,
            swapDetails.srcStableTokenAmount,
            address(swapDetails.destStableTokenAddress),
            destStableTokenAmount,
            address(swapDetails.destTokenAddress),
            swapDetails.destTokenAmount,
            resourceID,
            swapDetails.recipient,
            swapDetails.depositer,
            swapDetails.srcTokenAmount,
            swapDetails.feeTokenAddress,
            feeAmount,
            swapDetails.isDestNative ? 1 : 0
        );
    }

    /// @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
    /// by a relayer on the deposit's destination chain
    /// @notice Data passed into the function should be constructed as follows:
    ///    amount                                 uint256     bytes  0 - 32
    ///    destinationRecipientAddress length     uint256     bytes  32 - 64
    ///    destinationRecipientAddress            bytes       bytes  64 - END
    /// @param  swapDetails swapInfo struct required for the transaction
    /// @param  resourceID resourceId for the token
    /// @return settlementToken and settlementAmount
    function executeProposal(SwapInfo memory swapDetails, bytes32 resourceID)
        public
        virtual
        override
        onlyBridgeOrSequencer
        returns (address settlementToken, uint256 settlementAmount)
    {
        swapDetails.destStableTokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(_contractWhitelist[swapDetails.destStableTokenAddress], "provided token is not whitelisted");

        if (address(swapDetails.destTokenAddress) == swapDetails.destStableTokenAddress) {
            // just release destStable tokens
            (settlementToken, settlementAmount) = handleExecuteForReserveToken(swapDetails);
            setExecuteRecord(swapDetails.index, swapDetails.depositNonce);
        } else if (
            _reserve._contractToLP(swapDetails.destStableTokenAddress) == address(swapDetails.destTokenAddress)
        ) {
            // release LP is destToken is LP of destStableToken
            handleExecuteForLPToken(swapDetails);
            settlementToken = address(swapDetails.destTokenAddress);
            settlementAmount = swapDetails.destStableTokenAmount;
            setExecuteRecord(swapDetails.index, swapDetails.depositNonce);
        } else {
            // exchange destStable to destToken and release tokens
            (settlementToken, settlementAmount) = handleExecuteForNonReserveToken(swapDetails);
            setExecuteRecord(swapDetails.index, swapDetails.depositNonce);
        }
    }

    /// @notice Used to manually release ERC20 tokens from ERC20Safe
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount The amount of ERC20 tokens to release.
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.releaseERC20(tokenAddress, recipient, amount);
    }

    /// @notice Used to manually release ERC20 tokens from FeeManager
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount The amount of ERC20 tokens to release.
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        feeManager.withdrawFee(tokenAddress, recipient, amount);
    }

    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.stake(depositor, tokenAddress, amount);
    }

    /// @notice Staking should be done by using bridge contract
    /// @param depositor address of the depositor
    /// @param tokenAddress address of the token for which lp needs to be added
    /// @param amount amount of the token
    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        require(IWETH(_WETH).transfer(address(_reserve), amount));
        _reserve.stakeETH(depositor, tokenAddress, amount);
    }

    /// @notice Unstake token from LP
    /// @param unstaker removes liquidity from the pool.
    /// @param tokenAddress staking token of which liquidity needs to be removed.
    /// @param amount Amount that needs to be unstaked.
    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.unstake(unstaker, tokenAddress, amount);
    }

    /// @notice Unstake ETH from LP
    /// @param unstaker removes liquidity from the pool.
    /// @param tokenAddress staking token of which liquidity needs to be removed.
    /// @param amount Amount that needs to be unstaked.
    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.unstakeETH(unstaker, tokenAddress, amount, _WETH);
    }

    /// @notice Function to fetch the staked record
    /// @param  account Address of the account who has staked
    /// @param  tokenAddress staking token address
    function getStakedRecord(address account, address tokenAddress) public view virtual returns (uint256) {
        return _reserve.getStakedRecord(account, tokenAddress);
    }

    /// @notice Function to handle USDC burn and sets the details in the _usdcBurnData
    /// @param  amount amount to be burnt
    /// @param  destChainId Router destination chainId
    function handleUsdcBurn(
        uint256 amount,
        uint8 destChainId,
        uint64 depositNonce
    ) internal {
        IUsdcDepositAndBurn usdcBurnerContract = _usdcBurnerContract;
        require(address(usdcBurnerContract) != address(0), "USDC Burner Contract not set");

        _reserve.giveAllowance(_usdc, address(usdcBurnerContract), amount);
        uint64 usdcNonce = usdcBurnerContract.depositAndBurnUsdc(address(_reserve), amount, destChainId);
        _usdcBurnData[destChainId][depositNonce] = usdcNonce;
    }

    /// @notice Function to handle deposit for reserve tokens
    /// @param  swapDetails swapInfo struct for the swap details
    function handleDepositForReserveToken(
        uint64 depositNonce,
        uint8 destinationChainID,
        SwapInfo memory swapDetails
    ) internal {
        if (_burnList[address(swapDetails.srcTokenAddress)]) {
            _reserve.burnERC20(address(swapDetails.srcTokenAddress), swapDetails.depositer, swapDetails.srcTokenAmount);
        } else {
            _reserve.lockERC20(
                address(swapDetails.srcTokenAddress),
                swapDetails.depositer,
                address(_reserve),
                swapDetails.srcTokenAmount
            );
            if (_usdc == swapDetails.srcStableTokenAddress && _isUsdcBurnableMintable[destinationChainID]) {
                // Burn USDC
                handleUsdcBurn(swapDetails.srcTokenAmount, destinationChainID, depositNonce);
            }
        }
    }

    /// @notice Deducts fee and handles deposit for LP tokens
    /// @param swapDetails swapInfo struct for the swap details
    /// @param destinationChainID chainId for destination chain
    /// @return transferFee
    function deductFeeAndHandleDepositForLPToken(SwapInfo memory swapDetails, uint8 destinationChainID)
        internal
        returns (uint256)
    {
        uint256 widgetFeeAmount;
        uint256 transferFee;

        if (swapDetails.feeTokenAddress == address(0)) {
            swapDetails.feeTokenAddress = address(swapDetails.srcTokenAddress);
            (transferFee, , widgetFeeAmount) = getBridgeFee(
                destinationChainID,
                swapDetails.srcStableTokenAddress,
                swapDetails.widgetID
            );
        } else {
            (transferFee, , widgetFeeAmount) = getBridgeFee(
                destinationChainID,
                swapDetails.feeTokenAddress,
                swapDetails.widgetID
            );
        }

        // Fees of stable token address
        _reserve.deductFee(
            swapDetails.feeTokenAddress,
            swapDetails.depositer,
            // swapDetails.providedFee,
            transferFee + widgetFeeAmount,
            // _ETH,
            _isFeeEnabled,
            address(feeManager)
        );
        _reserve.burnERC20(address(swapDetails.srcTokenAddress), swapDetails.depositer, swapDetails.srcTokenAmount);

        if (widgetFeeAmount > 0) {
            feeManager.depositWidgetFee(swapDetails.widgetID, swapDetails.feeTokenAddress, widgetFeeAmount);
            return (widgetFeeAmount + transferFee);
        }

        return transferFee;
    }

    /// @notice Handles deposit for non-reserve tokens
    /// @param swapDetails swapInfo struct for the swap details
    function handleDepositForNonReserveToken(SwapInfo memory swapDetails) internal {
        uint256 pathLength = swapDetails.path.length;
        if (pathLength > 2) {
            //swapMulti
            require(swapDetails.path[pathLength - 1] == swapDetails.srcStableTokenAddress);
            swapDetails.srcStableTokenAmount = _reserve.swapMulti(
                _oneSplitAddress,
                swapDetails.path,
                swapDetails.srcTokenAmount,
                swapDetails.srcStableTokenAmount,
                swapDetails.flags,
                swapDetails.dataTx
            );
        } else {
            swapDetails.srcStableTokenAmount = _reserve.swap(
                _oneSplitAddress,
                address(swapDetails.srcTokenAddress),
                swapDetails.srcStableTokenAddress,
                swapDetails.srcTokenAmount,
                swapDetails.srcStableTokenAmount,
                swapDetails.flags[0],
                swapDetails.dataTx[0]
            );
        }
    }

    /// @notice Handles execution of transfer for reserve tokens
    /// @param swapDetails swapInfo struct for the swap details
    /// @return destinationStableTokenAddress and destinationStableTokenAmount
    function handleExecuteForReserveToken(SwapInfo memory swapDetails) internal returns (address, uint256) {
        if (_burnList[address(swapDetails.destTokenAddress)]) {
            _reserve.mintERC20(
                address(swapDetails.destTokenAddress),
                swapDetails.recipient,
                swapDetails.destStableTokenAmount
            );
        } else {
            uint256 reserveBalance = IERC20(address(swapDetails.destStableTokenAddress)).balanceOf(address(_reserve));
            if (reserveBalance < swapDetails.destStableTokenAmount) {
                _reserve.mintWrappedERC20(
                    address(swapDetails.destStableTokenAddress),
                    swapDetails.recipient,
                    swapDetails.destStableTokenAmount
                );
                return (
                    _reserve._contractToLP(address(swapDetails.destStableTokenAddress)),
                    swapDetails.destStableTokenAmount
                );
            } else {
                if (address(swapDetails.destStableTokenAddress) == _WETH && swapDetails.isDestNative) {
                    _reserve.withdrawWETH(_WETH, swapDetails.destStableTokenAmount);
                    _reserve.safeTransferETH(swapDetails.recipient, swapDetails.destStableTokenAmount);
                } else {
                    _reserve.releaseERC20(
                        address(swapDetails.destStableTokenAddress),
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    );
                }
            }
        }
        return (address(swapDetails.destStableTokenAddress), swapDetails.destStableTokenAmount);
    }

    /// @notice Handles execution of transfer for LP tokens
    /// @param swapDetails swapInfo struct for the swap details
    function handleExecuteForLPToken(SwapInfo memory swapDetails) internal {
        _reserve.mintWrappedERC20(
            address(swapDetails.destStableTokenAddress),
            swapDetails.recipient,
            swapDetails.destStableTokenAmount
        );
    }

    /// @notice Handles execution of transfer for non-reserve tokens
    /// @param swapDetails swapInfo struct for the swap details
    /// @return destinationStableTokenAddress and destinationStableTokenAmount
    function handleExecuteForNonReserveToken(SwapInfo memory swapDetails) internal returns (address, uint256) {
        if (_burnList[swapDetails.destStableTokenAddress]) {
            if (
                (swapDetails.path.length > 2) &&
                (swapDetails.path[swapDetails.path.length - 1] != address(swapDetails.destTokenAddress))
            ) {
                _reserve.mintERC20(
                    swapDetails.destStableTokenAddress,
                    swapDetails.recipient,
                    swapDetails.destStableTokenAmount
                );
                return (swapDetails.destStableTokenAddress, swapDetails.destStableTokenAmount);
            }
            _reserve.mintERC20(swapDetails.destStableTokenAddress, _oneSplitAddress, swapDetails.destStableTokenAmount);
        } else {
            uint256 reserveBalance = IERC20(address(swapDetails.destStableTokenAddress)).balanceOf(address(_reserve));
            if (reserveBalance < swapDetails.destStableTokenAmount) {
                _reserve.mintWrappedERC20(
                    address(swapDetails.destStableTokenAddress),
                    swapDetails.recipient,
                    swapDetails.destStableTokenAmount
                );
                return (
                    _reserve._contractToLP(address(swapDetails.destStableTokenAddress)),
                    swapDetails.destStableTokenAmount
                );
            } else {
                if (
                    (swapDetails.path.length > 2) &&
                    (swapDetails.path[swapDetails.path.length - 1] != address(swapDetails.destTokenAddress))
                ) {
                    _reserve.releaseERC20(
                        swapDetails.destStableTokenAddress,
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    );
                    return (swapDetails.destStableTokenAddress, swapDetails.destStableTokenAmount);
                }
                _reserve.releaseERC20(
                    swapDetails.destStableTokenAddress,
                    _oneSplitAddress,
                    swapDetails.destStableTokenAmount
                );
            }
        }
        if (swapDetails.path.length > 2) {
            //solhint-disable avoid-low-level-calls
            (bool success, bytes memory returnData) = address(_reserve).call(
                abi.encodeWithSelector(
                    0x2214e13b, // swapMulti(address,address[],uint256,uint256,uint256[],bytes[])
                    _oneSplitAddress,
                    swapDetails.path,
                    swapDetails.destStableTokenAmount,
                    swapDetails.destTokenAmount,
                    swapDetails.flags,
                    swapDetails.dataTx
                )
            );
            if (success) {
                swapDetails.returnAmount = abi.decode(returnData, (uint256));
            } else {
                require(
                    IOneSplitWrap(_oneSplitAddress).withdraw(
                        swapDetails.destStableTokenAddress,
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    )
                );
                return (address(swapDetails.destStableTokenAddress), swapDetails.destStableTokenAmount);
            }
        } else {
            (bool success, bytes memory returnData) = address(_reserve).call(
                abi.encodeWithSelector(
                    0xda041a85, //swap(address,address,address,uint256,uint256,uint256,bytes)
                    _oneSplitAddress,
                    swapDetails.destStableTokenAddress,
                    address(swapDetails.destTokenAddress),
                    swapDetails.destStableTokenAmount,
                    swapDetails.destTokenAmount,
                    swapDetails.flags[0],
                    swapDetails.dataTx[0]
                )
            );
            if (success) {
                swapDetails.returnAmount = abi.decode(returnData, (uint256));
            } else {
                require(
                    IOneSplitWrap(_oneSplitAddress).withdraw(
                        swapDetails.destStableTokenAddress,
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    )
                );
                return (address(swapDetails.destStableTokenAddress), swapDetails.destStableTokenAmount);
            }
        }
        if (address(swapDetails.destTokenAddress) == _WETH && swapDetails.isDestNative) {
            _reserve.withdrawWETH(_WETH, swapDetails.returnAmount);
            _reserve.safeTransferETH(swapDetails.recipient, swapDetails.returnAmount);
        } else {
            _reserve.releaseERC20(
                address(swapDetails.destTokenAddress),
                swapDetails.recipient,
                swapDetails.returnAmount
            );
        }
        return (address(swapDetails.destTokenAddress), swapDetails.returnAmount);
    }

    function withdrawNative(
        address recipient,
        uint256 amount,
        bool withdrawAll
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 bal = address(this).balance;
        bool success;
        if (withdrawAll) {
            (success, ) = recipient.call{ value: bal }("");
        } else {
            require(bal >= amount, "Insufficient balance");
            (success, ) = recipient.call{ value: amount }("");
        }
        require(success, "Transaction failed");
    }

    uint256[50] public gap;
}