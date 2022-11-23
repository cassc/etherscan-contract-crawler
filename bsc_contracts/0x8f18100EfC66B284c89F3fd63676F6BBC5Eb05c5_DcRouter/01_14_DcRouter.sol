// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./integrations/layerzero/NonBlockingNonUpgradableBaseApp.sol";

/**
 * @author DeCommas team
 * @title Implementation of the basic multiChain DeCommasStrategyRouter.
 * @dev Originally based on code by Pillardev: https://github.com/Pillardevelopment
 * @dev Original idea on architecture by Loggy: https://miro.com/app/board/uXjVOZbZQQI=/?fromRedirect=1
 */
contract DcRouter is NonBlockingNonUpgradableBaseApp {
    struct UserPosition {
        uint256 deposit; // [1e6]
        uint256 shares; // [1e6]
    }

    struct UserAction {
        address user;
        uint256 amount;
    }

    /// deCommas address of Building block contract for lost funds
    address private _deCommasTreasurer;

    mapping(uint256 => uint256) public pendingStrategyDeposits;
    mapping(uint256 => uint256) public pendingStrategyWithdrawals;

    // @dev Aware of user's total deposit and amount of shares.
    mapping(address => mapping(uint256 => UserPosition)) public userPosition;

    // @dev (strategyId => depositId => UserDeposit)
    mapping(uint256 => mapping(uint256 => UserAction))
        public pendingDepositsById;
    mapping(uint256 => uint256) public lastPendingDepositId;
    mapping(uint256 => uint256) public maxProcessedDepositId;

    mapping(uint256 => mapping(uint256 => UserAction))
        public pendingWithdrawalsById;
    mapping(uint256 => uint256) public lastPendingWithdrawalId;
    mapping(uint256 => uint256) public maxProcessedWithdrawalId;

    event Deposited(address indexed user, uint256 indexed id, uint256 amount);
    event DepositTransferred(
        address indexed user,
        uint256 indexed strategyId,
        uint256 amount
    );
    event RequestedWithdraw(
        address indexed user,
        uint256 indexed id,
        uint256 amount
    );
    event Withdrawn(address indexed user, uint256 indexed id, uint256 amount);
    event CancelWithdrawn(
        address indexed user,
        uint256 indexed id,
        uint256 amount
    );

    /**
     * @notice DcRouter for Users
     * @param _deCommasTreasurerAddress - address of Treasurer
     * @param _nativeLZEndpoint - - native LZEndpoint, see more:
     *       (https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses)
     * @param _USDC - native stableToken(USDT,USDC,DAI...)
     * @dev See {_setURI}.
     */
    constructor(
        address _deCommasTreasurerAddress,
        uint16 _nativeId,
        address _nativeLZEndpoint,
        address _USDC,
        address _actionPoolDcRouter,
        uint16 _actionPoolNativeId
    ) {
        _deCommasTreasurer = _deCommasTreasurerAddress;
        _nativeChainId = _nativeId;
        lzEndpoint = ILayerZeroEndpoint(_nativeLZEndpoint);
        _currentUSDCToken = _USDC;
        trustedRemoteLookup[_actionPoolNativeId] = abi.encodePacked(
            abi.encode(_actionPoolDcRouter),
            address(this)
        );
        _actionPool = _actionPoolDcRouter;
        _transferOwnership(_msgSender());
    }

    /**
     * @notice User can to deposit his stable Token, after Approve
     * @param _strategyId - strategy number by which it will be identified
     * @param _stableAmount - decimals amount is blockchain specific
     * @dev If user want ERC20, He can to mint in special contract -
     */
    function deposit(uint256 _strategyId, uint256 _stableAmount) external {
        uint256 newId = ++lastPendingDepositId[_strategyId];
        pendingDepositsById[_strategyId][newId] = UserAction(
            _msgSender(),
            _stableAmount
        );
        pendingStrategyDeposits[_strategyId] += _stableAmount;

        require(
            IERC20(_currentUSDCToken).transferFrom(
                _msgSender(),
                address(this),
                _stableAmount
            ),
            "Router/transfer failed"
        );

        emit Deposited(_msgSender(), _strategyId, _stableAmount);
    }

    /**
     * @notice User submits a request to withdraw his tokens
     * @param _strategyId - strategy number by which it will be identified
     * @param _stableAmount - how many of ERC-1155 deTokens user would withdraw
     * @dev 18 decimals
     */
    function initiateWithdraw(uint256 _strategyId, uint256 _stableAmount)
        external
    {
        uint256 newId = ++lastPendingWithdrawalId[_strategyId];
        pendingWithdrawalsById[_strategyId][newId] = UserAction(
            _msgSender(),
            _stableAmount
        );
        pendingStrategyWithdrawals[_strategyId] += _stableAmount;
        emit RequestedWithdraw(_msgSender(), _strategyId, _stableAmount);
    }

    /**
     * @notice Get deCommas Treasurer address
     * @return address - address of deCommas deCommasTreasurer
     */
    function getDeCommasTreasurer() external view returns (address) {
        return _deCommasTreasurer;
    }

    function getCurrentStableToken() external view returns (address) {
        return _currentUSDCToken;
    }

    function getNativeChainId() external view returns (uint16) {
        return _nativeChainId;
    }

    function nativeBridge(
        address _nativeStableToken,
        uint256 _stableAmount,
        uint16 _receiverLZId,
        address _receiverAddress,
        address _destinationStableToken
    ) public payable onlySelf {
        _bridge(
            _nativeStableToken,
            _stableAmount,
            _receiverLZId,
            _receiverAddress,
            _destinationStableToken,
            msg.value,
            ""
        );
    }

    // @dev Calculate user shares based on strategy TVL. Tvl should be provided by relayers
    function _updateUserShares(
        uint256 _tvl,
        uint256 _strategyId,
        UserAction memory userDeposit
    ) internal {
        userPosition[userDeposit.user][_strategyId].deposit += userDeposit
            .amount;
        if (_tvl == 0) {
            // special case when BB is empty. Calculate shares as 1:1 deposit
            userPosition[userDeposit.user][_strategyId].shares += userDeposit
                .amount;
        } else {
            // amount / tvl is the share of the one token. Multiply it by amount to get total shares
            userPosition[userDeposit.user][_strategyId].shares +=
                (userDeposit.amount * userDeposit.amount) /
                _tvl;
        }
    }

    // @dev transfer deposits from this router to the BB
    // payload contains users which deposits are eligible for transfer
    function transferDeposits(bytes memory _payload) public onlySelf {
        uint256 pendingTotal;
        (
            uint16[] memory receiverLzId,
            address[] memory receivers,
            uint256[] memory amounts,
            address[] memory destinationTokens,
            uint256 strategyId,
            uint256 strategyTvl
        ) = abi.decode(
                _payload,
                (uint16[], address[], uint256[], address[], uint256, uint256)
            );
        require(
            maxProcessedDepositId[strategyId] <
                lastPendingDepositId[strategyId],
            "DcRouter: no deposit to process"
        );
        for (
            uint256 i = maxProcessedDepositId[strategyId] + 1;
            i <= lastPendingDepositId[strategyId];
            i++
        ) {
            UserAction memory pendingUserDeposit = pendingDepositsById[
                strategyId
            ][i]; //save gas on sload
            pendingTotal += pendingUserDeposit.amount;
            pendingStrategyDeposits[strategyId] -= pendingUserDeposit.amount;
            _updateUserShares(strategyTvl, strategyId, pendingUserDeposit);

            emit DepositTransferred(
                pendingUserDeposit.user,
                strategyId,
                pendingUserDeposit.amount
            );
        }
        maxProcessedDepositId[strategyId] = lastPendingDepositId[strategyId];

        uint256 amountsSum;
        for (uint256 i = 0; i < amounts.length; i++) {
            amountsSum += amounts[i];
        }
        require(pendingTotal == amountsSum, "Dc Router: users amount mismatch");

        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                _bridge(
                    _currentUSDCToken,
                    amounts[i],
                    receiverLzId[i],
                    receivers[i],
                    destinationTokens[i],
                    0, // msg.value
                    "" // payload
                );
            }
        }
    }

    /**
     * @notice Rescuing Lost Tokens
     * @param _token - address of the erroneously submitted token to extrication
     * @dev use only ActionPool
     */
    function pullOutLossERC20(address _token) public {
        require(
            _token == _currentUSDCToken,
            "DcRouter:try other token address"
        );
        IERC20(_token).transfer(
            _deCommasTreasurer,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function withdrawLostETH() public {
        payable(_deCommasTreasurer).transfer(address(this).balance);
    }

    function approveWithdraw(
        uint256 _stableDeTokenPrice,
        uint256 _strategyId,
        uint256 _withdrawalId
    ) public onlySelf returns (bool) {
        require(
            _withdrawalId == maxProcessedWithdrawalId[_strategyId] + 1,
            "DcRouter: invalid request id"
        );
        uint256 stableWithdraw = (pendingWithdrawalsById[_strategyId][
            _withdrawalId
        ].amount * _stableDeTokenPrice) / 1e18;
        pendingStrategyWithdrawals[_strategyId] -= pendingWithdrawalsById[
            _strategyId
        ][_withdrawalId].amount;
        maxProcessedWithdrawalId[_strategyId]++;

        IERC20(_currentUSDCToken).transfer(
            pendingWithdrawalsById[_strategyId][_withdrawalId].user,
            stableWithdraw
        );
        emit Withdrawn(
            pendingWithdrawalsById[_strategyId][_withdrawalId].user,
            _strategyId,
            stableWithdraw
        );
        return true;
    }

    /**
     * @notice ActionPool address cancel withdraw request
     * @param _withdrawalId -
     * @param _strategyId -
     * @dev only ActionPool address
     */
    function cancelWithdraw(uint256 _withdrawalId, uint256 _strategyId)
        public
        onlySelf
        returns (bool)
    {
        require(
            _withdrawalId == maxProcessedWithdrawalId[_strategyId] + 1,
            "DcRouter: invalid request id"
        );
        pendingStrategyWithdrawals[_strategyId] -= pendingWithdrawalsById[
            _strategyId
        ][_withdrawalId].amount;
        maxProcessedWithdrawalId[_strategyId]++;

        emit CancelWithdrawn(
            pendingWithdrawalsById[_strategyId][_withdrawalId].user,
            _strategyId,
            pendingWithdrawalsById[_strategyId][_withdrawalId].amount
        );
        return true;
    }
}