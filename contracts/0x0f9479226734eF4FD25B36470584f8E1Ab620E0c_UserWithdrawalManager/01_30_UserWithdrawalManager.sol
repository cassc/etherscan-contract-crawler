// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './ETHx.sol';
import './interfaces/IStaderConfig.sol';
import './interfaces/IStaderOracle.sol';
import './interfaces/IStaderStakePoolManager.sol';
import './interfaces/IUserWithdrawalManager.sol';

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

contract UserWithdrawalManager is
    IUserWithdrawalManager,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Math for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IStaderConfig public staderConfig;
    uint256 public override nextRequestIdToFinalize;
    uint256 public override nextRequestId;
    uint256 public override finalizationBatchLimit;
    uint256 public override ethRequestedForWithdraw;
    //upper cap on user non redeemed withdraw request count
    uint256 public override maxNonRedeemedUserRequestCount;

    /// @notice user withdrawal requests
    mapping(uint256 => UserWithdrawInfo) public override userWithdrawRequests;

    mapping(address => uint256[]) public override requestIdsByUserAddress;

    /// @notice structure representing a user request for withdrawal.
    struct UserWithdrawInfo {
        address payable owner; // address that can claim eth on behalf of this request
        uint256 ethXAmount; //amount of ethX share locked for withdrawal
        uint256 ethExpected; //eth requested according to given share and exchangeRate
        uint256 ethFinalized; // final eth for claiming according to finalize exchange rate
        uint256 requestBlock; // block number of withdraw request
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);
        __AccessControl_init_unchained();
        __Pausable_init();
        __ReentrancyGuard_init();
        staderConfig = IStaderConfig(_staderConfig);
        nextRequestIdToFinalize = 1;
        nextRequestId = 1;
        finalizationBatchLimit = 50;
        maxNonRedeemedUserRequestCount = 1000;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    receive() external payable {
        emit ReceivedETH(msg.value);
    }

    /**
     * @notice update the finalizationBatchLimit value
     * @dev only `Manager` can call
     * @param _finalizationBatchLimit value of finalizationBatchLimit
     */
    function updateFinalizationBatchLimit(uint256 _finalizationBatchLimit) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        finalizationBatchLimit = _finalizationBatchLimit;
        emit UpdatedFinalizationBatchLimit(_finalizationBatchLimit);
    }

    //update the address of staderConfig
    function updateStaderConfig(address _staderConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    /**
     * @notice put a withdrawal request
     * @param _ethXAmount amount of ethX shares to withdraw
     * @param _owner owner of withdraw request to redeem
     */
    function requestWithdraw(uint256 _ethXAmount, address _owner) external override whenNotPaused returns (uint256) {
        if (_owner == address(0)) revert ZeroAddressReceived();
        uint256 assets = IStaderStakePoolManager(staderConfig.getStakePoolManager()).previewWithdraw(_ethXAmount);
        if (assets < staderConfig.getMinWithdrawAmount() || assets > staderConfig.getMaxWithdrawAmount()) {
            revert InvalidWithdrawAmount();
        }
        if (requestIdsByUserAddress[_owner].length + 1 > maxNonRedeemedUserRequestCount) {
            revert MaxLimitOnWithdrawRequestCountReached();
        }
        IERC20Upgradeable(staderConfig.getETHxToken()).safeTransferFrom(msg.sender, (address(this)), _ethXAmount);
        ethRequestedForWithdraw += assets;
        userWithdrawRequests[nextRequestId] = UserWithdrawInfo(payable(_owner), _ethXAmount, assets, 0, block.number);
        requestIdsByUserAddress[_owner].push(nextRequestId);
        emit WithdrawRequestReceived(msg.sender, _owner, nextRequestId, _ethXAmount, assets);
        nextRequestId++;
        return nextRequestId - 1;
    }

    /**
     * @notice finalize user requests
     * @dev check for safeMode to finalizeRequest
     */
    function finalizeUserWithdrawalRequest() external override nonReentrant whenNotPaused {
        if (IStaderOracle(staderConfig.getStaderOracle()).safeMode()) {
            revert UnsupportedOperationInSafeMode();
        }
        if (!IStaderStakePoolManager(staderConfig.getStakePoolManager()).isVaultHealthy()) {
            revert ProtocolNotHealthy();
        }
        address poolManager = staderConfig.getStakePoolManager();
        uint256 DECIMALS = staderConfig.getDecimals();
        uint256 exchangeRate = IStaderStakePoolManager(poolManager).getExchangeRate();
        uint256 maxRequestIdToFinalize = Math.min(nextRequestId, nextRequestIdToFinalize + finalizationBatchLimit) - 1;
        uint256 lockedEthXToBurn;
        uint256 ethToSendToFinalizeRequest;
        uint256 requestId;
        uint256 pooledETH = poolManager.balance;
        for (requestId = nextRequestIdToFinalize; requestId <= maxRequestIdToFinalize; ) {
            UserWithdrawInfo memory userWithdrawInfo = userWithdrawRequests[requestId];
            uint256 requiredEth = userWithdrawInfo.ethExpected;
            uint256 lockedEthX = userWithdrawInfo.ethXAmount;
            uint256 minEThRequiredToFinalizeRequest = Math.min(requiredEth, (lockedEthX * exchangeRate) / DECIMALS);
            if (
                (ethToSendToFinalizeRequest + minEThRequiredToFinalizeRequest > pooledETH) ||
                (userWithdrawInfo.requestBlock + staderConfig.getMinBlockDelayToFinalizeWithdrawRequest() >
                    block.number)
            ) {
                break;
            }
            userWithdrawRequests[requestId].ethFinalized = minEThRequiredToFinalizeRequest;
            ethRequestedForWithdraw -= requiredEth;
            lockedEthXToBurn += lockedEthX;
            ethToSendToFinalizeRequest += minEThRequiredToFinalizeRequest;
            unchecked {
                ++requestId;
            }
        }
        // at here, upto (requestId-1) is finalized
        if (requestId > nextRequestIdToFinalize) {
            nextRequestIdToFinalize = requestId;
            ETHx(staderConfig.getETHxToken()).burnFrom(address(this), lockedEthXToBurn);
            IStaderStakePoolManager(poolManager).transferETHToUserWithdrawManager(ethToSendToFinalizeRequest);
            emit FinalizedWithdrawRequest(requestId);
        }
    }

    /**
     * @notice transfer the eth of finalized request to recipient and delete the request
     * @param _requestId request id to redeem
     */
    function claim(uint256 _requestId) external override nonReentrant {
        if (_requestId >= nextRequestIdToFinalize) {
            revert requestIdNotFinalized(_requestId);
        }
        UserWithdrawInfo memory userRequest = userWithdrawRequests[_requestId];
        if (msg.sender != userRequest.owner) {
            revert CallerNotAuthorizedToRedeem();
        }
        // below is a default entry as no userRequest will be found for a redeemed request.
        if (userRequest.ethExpected == 0) {
            revert RequestAlreadyRedeemed(_requestId);
        }
        uint256 etherToTransfer = userRequest.ethFinalized;
        deleteRequestId(_requestId, userRequest.owner);
        sendValue(userRequest.owner, etherToTransfer);
        emit RequestRedeemed(msg.sender, userRequest.owner, etherToTransfer);
    }

    /// @notice return the list of ongoing withdraw requestIds for a user
    function getRequestIdsByUser(address _owner) external view override returns (uint256[] memory) {
        return requestIdsByUserAddress[_owner];
    }

    /**
     * @dev Triggers stopped state.
     * Contract must not be paused
     */
    function pause() external {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Contract must be paused
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // delete entry from userWithdrawRequests mapping and in requestIdsByUserAddress mapping
    function deleteRequestId(uint256 _requestId, address _owner) internal {
        delete (userWithdrawRequests[_requestId]);
        uint256 userRequestCount = requestIdsByUserAddress[_owner].length;
        uint256[] storage requestIds = requestIdsByUserAddress[_owner];
        for (uint256 i; i < userRequestCount; ) {
            if (_requestId == requestIds[i]) {
                requestIds[i] = requestIds[userRequestCount - 1];
                requestIds.pop();
                return;
            }
            unchecked {
                ++i;
            }
        }
        revert CannotFindRequestId();
    }

    function sendValue(address payable _recipient, uint256 _amount) internal {
        if (address(this).balance < _amount) {
            revert InSufficientBalance();
        }

        //slither-disable-next-line arbitrary-send-eth
        (bool success, ) = _recipient.call{value: _amount}('');
        if (!success) {
            revert ETHTransferFailed();
        }
    }
}