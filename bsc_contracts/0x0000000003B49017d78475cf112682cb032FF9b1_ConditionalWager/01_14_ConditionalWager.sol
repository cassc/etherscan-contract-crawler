//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BartrrBase.sol";

error Uninitialized();
error WagerAlreadyClosed();
error WagerAlreadyFilled();
error UserAlreadyRefunded();
error WagerNotFilled();
error InvalidValue();
error InvalidDuration();
error InvalidPrices();
error UnauthorizedSender();
error WagerIncomplete();
error WagerExpired();
error TokenNotApproved();
error TransferFailed();
error SelfWager();
error RestrictedP2P();

/// @title Bartrr Conditional Wager Contract
/// @notice This contract is used to manage conditional wagers for the Bartrr protocol.
contract ConditionalWager is BartrrBase {
    using SafeERC20 for IERC20;
    struct Wager {
        bool isFilled; // true if wager is filled
        bool isClosed; // true if the wager has been closed (redeemed or cancelled)
        address userA; // address of userA
        address userB; // address of userB (0x0 if p2m)
        address wagerToken; // token to be used for wager
        address paymentToken; // payment token is the token that is used to pay the wager
        int256 wagerPriceA; // UserA bet price
        int256 wagerPriceB; // UserB bet price
        uint256 amountUserA; // amount userA wagered
        uint256 amountUserB; // amount userB wagered
        uint256 duration; // duration of the wager
    }

    /// Array of wagers
    Wager[] public wagers;

    /// @notice Emitted when a wager is created
    /// @param wagerId The wager id
    /// @param userA The user who created the wager
    /// @param userB The user who will fill the wager (zero address if the wager is open for anyone to fill)
    /// @param wagerPriceA The wagered price of wagerToken by userA
    /// @param wagerPriceB The wagered price of wagerToken by userB
    event WagerCreated(
        uint256 indexed wagerId,
        address indexed userA,
        address userB,
        address wagerToken,
        int256 wagerPriceA,
        int256 wagerPriceB
    );

    /// @notice Emitted when a wager is filled by the second party
    /// @param wagerId The wager id
    /// @param userA The user who created the wager
    /// @param userB The user who filled the wager
    /// @param wagerToken The token whose price was wagered
    /// @param wagerPriceA The wagered price of wagerToken by userA
    /// @param wagerPriceB The wagered price of wagerToken by userB
    event WagerFilled(
        uint256 indexed wagerId,
        address indexed userA,
        address indexed userB,
        address wagerToken,
        int256 wagerPriceA,
        int256 wagerPriceB
    );

    constructor() {
        _transferOwnership(tx.origin);
    }

    /// @notice Creates a new wager
    /// @param _userB address of userB (0x0 if p2m)
    /// @param _wagerToken address of token to be wagered on
    /// @param _paymentToken address of token to be paid with
    /// @param _wagerPriceA UserA bet price -- USD price + 8 decimals
    /// @param _wagerPriceB UserB bet price -- USD price + 8 decimals
    /// @param _amountUserA amount userA wagered
    /// @param _amountUserB amount userB wagered
    /// @param _duration duration of the wager
    function createWager(
        address _userB,
        address _wagerToken,
        address _paymentToken, // Zero address if ETH
        int256 _wagerPriceA,
        int256 _wagerPriceB,
        uint256 _amountUserA,
        uint256 _amountUserB,
        uint256 _duration
    ) external payable nonReentrant {
        if (!isInitialized) revert Uninitialized();
        if (
            !wagerTokens[_wagerToken] ||
            refundableTimestamp[_wagerToken].nonrefundable <
            refundableTimestamp[_wagerToken].refundable
        ) {
            revert TokenNotApproved();
        }
        if (!paymentTokens[_paymentToken]) revert TokenNotApproved();
        if (_duration < MIN_WAGER_DURATION) revert InvalidDuration();
        if (_userB == msg.sender) revert SelfWager();
        if (_wagerPriceA == _wagerPriceB) revert InvalidPrices();

        uint256 feeUserA = _calculateFee(_amountUserA, _paymentToken);

        if (
            _paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            // ETH
            if (msg.value != _amountUserA) revert InvalidValue();
            if (_userB == address(0)) {
                // p2m
                _amountUserA = _amountUserA - feeUserA;
                _transfer(payable(feeAddress), feeUserA);
            }
        } else {
            // Tokens
            uint256 balanceBefore = IERC20(_paymentToken).balanceOf(
                address(this)
            );

            IERC20(_paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amountUserA
            );

            if (_userB == address(0)) {
                // p2m - userA fees paid immediately
                IERC20(_paymentToken).safeTransfer(feeAddress, feeUserA);
            }
            uint256 balanceAfter = IERC20(_paymentToken).balanceOf(
                address(this)
            );

            _amountUserA = balanceAfter - balanceBefore;
        }

        _createWager(
            msg.sender,
            _userB,
            _wagerToken,
            _paymentToken,
            _wagerPriceA,
            _wagerPriceB,
            _amountUserA,
            _amountUserB,
            _duration
        );
    }

    /// @notice Fills a wager and starts the wager countdown
    /// @param _wagerId id of the wager
    function fillWager(uint256 _wagerId) external payable nonReentrant {
        Wager memory wager = wagers[_wagerId];

        if (wager.isFilled) revert WagerAlreadyFilled();
        if (wager.isClosed) revert WagerAlreadyClosed();
        if (
            refundableTimestamp[wager.wagerToken].nonrefundable <
            refundableTimestamp[wager.wagerToken].refundable
        ) {
            revert TokenNotApproved();
        }
        if (msg.sender == wager.userA) revert SelfWager();

        uint256 feeUserB = _calculateFee(wager.amountUserB, wager.paymentToken);

        if (wager.userB != address(0)) {
            // p2p
            if (msg.sender != wager.userB) revert RestrictedP2P();

            // UserA fees have not been paid yet
            uint256 feeUserA = _calculateFee(
                wager.amountUserA,
                wager.paymentToken
            );

            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                // ETH
                if (msg.value != wager.amountUserB) revert InvalidValue();

                wager.amountUserA -= feeUserA;
                wager.amountUserB -= feeUserB;

                _transfer(payable(feeAddress), feeUserA + feeUserB);
            } else {
                uint256 balanceBefore = IERC20(wager.paymentToken).balanceOf(
                    address(this)
                );
                IERC20(wager.paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    wager.amountUserB
                );
                uint256 balanceAfter = IERC20(wager.paymentToken).balanceOf(
                    address(this)
                );

                wager.amountUserB = balanceAfter - balanceBefore;

                wager.amountUserA -= feeUserA;
                wager.amountUserB -= feeUserB;

                IERC20(wager.paymentToken).safeTransfer(
                    feeAddress,
                    feeUserA + feeUserB
                );
            }
        } else {
            // p2m
            if (createdTimes[_wagerId] + 30 days <= block.timestamp) {
                revert WagerExpired();
            }
            wager.userB = msg.sender;
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                if (msg.value != wager.amountUserB) revert InvalidValue();
                wager.amountUserB -= feeUserB;
                _transfer(payable(feeAddress), feeUserB);
            } else {
                uint256 balanceBefore = IERC20(wager.paymentToken).balanceOf(
                    address(this)
                );
                IERC20(wager.paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    wager.amountUserB
                );
                IERC20(wager.paymentToken).safeTransfer(feeAddress, feeUserB);
                uint256 balanceAfter = IERC20(wager.paymentToken).balanceOf(
                    address(this)
                );

                wager.amountUserB = balanceAfter - balanceBefore;
            }
        }

        endTimes[_wagerId] = wager.duration + block.timestamp;
        wager.isFilled = true;

        wagers[_wagerId] = wager; // update wager to storage

        emit WagerFilled(
            _wagerId,
            wager.userA,
            wager.userB,
            wager.wagerToken,
            wager.wagerPriceA,
            wager.wagerPriceB
        );
    }

    /// @notice Cancels a wager that has not been filled
    /// @dev Fee is not refunded if wager was created as p2m
    /// @param _wagerId id of the wager
    function cancelWager(uint256 _wagerId) external nonReentrant {
        Wager memory wager = wagers[_wagerId];
        if (wager.isClosed) revert WagerAlreadyClosed();
        if (msg.sender != wager.userA && msg.sender != wager.userB)
            revert UnauthorizedSender();
        if (wager.isFilled) revert WagerAlreadyFilled();

        wagers[_wagerId].isClosed = true;

        if (
            wager.paymentToken ==
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            _transfer(payable(wager.userA), wager.amountUserA);
        } else {
            IERC20(wager.paymentToken).safeTransfer(
                wager.userA,
                wager.amountUserA
            );
        }
        emit WagerCancelled(_wagerId, msg.sender);
    }

    /// @notice Redeems a wager
    /// @param _wagerId id of the wager
    function redeem(uint256 _wagerId) external nonReentrant {
        Wager memory wager = wagers[_wagerId];
        if (!wager.isFilled) revert WagerNotFilled();
        if (wager.isClosed) revert WagerAlreadyClosed();
        uint256 refundable = refundableTimestamp[wager.wagerToken].refundable;
        uint256 nonrefundable = refundableTimestamp[wager.wagerToken]
            .nonrefundable;
        if (
            (refundable > 0 &&
                endTimes[_wagerId] > refundable &&
                (refundable > nonrefundable ||
                    nonrefundable > createdTimes[_wagerId])) || // token has been marked refundable at least once // wager wasn't complete when marked refundable // wager was created before token was marked nonrefundable
            refundUserA[_wagerId] ||
            refundUserB[_wagerId]
        ) {
            _refundWager(_wagerId);
        } else {
            _redeemWager(_wagerId);
        }
    }

    /// @notice Returns the winner of the wager once it is completed
    /// @param _wagerId id of the wager
    /// @return winner The winner of the wager (or the zero address if it is a draw)
    function checkWinner(uint256 _wagerId) public view returns (address) {
        Wager memory wager = wagers[_wagerId];
        if (!wager.isFilled) revert WagerNotFilled();
        uint256 endTime = endTimes[_wagerId];
        if (block.timestamp < endTime) revert WagerIncomplete();

        AggregatorV2V3Interface feed = AggregatorV2V3Interface(
            oracles[wager.wagerToken]
        );

        uint80 roundId = roundIdFetcher.getRoundId(feed, endTime);

        if (roundId == 0) {
            return address(0);
        }

        (int256 price, , ) = _getHistoricalPrice(roundId, wager.wagerToken);

        if (wager.wagerPriceA > wager.wagerPriceB) {
            // User A bets above
            if (price >= wager.wagerPriceA) {
                return wager.userA; // User A wins
            } else if (price <= wager.wagerPriceB) {
                return wager.userB; // User B wins
            }
        } else if (wager.wagerPriceA < wager.wagerPriceB) {
            // User A bets below
            if (price <= wager.wagerPriceA) {
                return wager.userA; // User A wins
            } else if (price >= wager.wagerPriceB) {
                return wager.userB; // User B wins
            }
        }
        return address(0); // Draw
    }

    /// @notice Get all wagers
    /// @return All created wagers
    function getAllWagers() public view returns (Wager[] memory) {
        return wagers;
    }

    function _createWager(
        address _userA,
        address _userB,
        address _wagerToken,
        address _paymentToken,
        int256 _wagerPriceA,
        int256 _wagerPriceB,
        uint256 _amountUserA,
        uint256 _amountUserB,
        uint256 _duration
    ) internal {
        Wager memory wager = Wager(
            false,
            false,
            _userA,
            _userB,
            _wagerToken,
            _paymentToken,
            _wagerPriceA,
            _wagerPriceB,
            _amountUserA,
            _amountUserB,
            _duration
        );
        wagers.push(wager);
        createdTimes[idCounter] = block.timestamp;
        emit WagerCreated(
            idCounter,
            _userA,
            _userB,
            _wagerToken,
            _wagerPriceA,
            _wagerPriceB
        );
        idCounter++;
    }

    function _refundWager(uint256 _wagerId) internal {
        Wager memory wager = wagers[_wagerId];
        if (msg.sender == wager.userA) {
            if (refundUserA[_wagerId]) revert UserAlreadyRefunded();
            refundUserA[_wagerId] = true;
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                _transfer(payable(wager.userA), wager.amountUserA);
            } else {
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userA,
                    wager.amountUserA
                );
            }
            emit WagerRefunded(
                _wagerId,
                msg.sender,
                wager.paymentToken,
                wager.amountUserA
            );
        } else if (msg.sender == wager.userB) {
            if (refundUserB[_wagerId]) revert UserAlreadyRefunded();
            refundUserB[_wagerId] = true;
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                _transfer(payable(wager.userB), wager.amountUserB);
            } else {
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userB,
                    wager.amountUserB
                );
            }
            emit WagerRefunded(
                _wagerId,
                msg.sender,
                wager.paymentToken,
                wager.amountUserB
            );
        }
    }

    function _redeemWager(uint256 _wagerId) internal {
        Wager memory wager = wagers[_wagerId];
        if (block.timestamp < endTimes[_wagerId]) revert WagerIncomplete();
        uint256 winningSum = wager.amountUserA + wager.amountUserB;
        address winner = checkWinner(_wagerId);

        wagers[_wagerId].isClosed = true;

        if (winner == address(0)) {
            // draw
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                _transfer(payable(wager.userA), wager.amountUserA);
                _transfer(payable(wager.userB), wager.amountUserB);
            } else {
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userA,
                    wager.amountUserA
                );
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userB,
                    wager.amountUserB
                );
            }
        } else {
            if (
                wager.paymentToken ==
                address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ) {
                _transfer(payable(winner), winningSum);
            } else {
                IERC20(wager.paymentToken).safeTransfer(winner, winningSum);
            }
        }
        emit WagerRedeemed(_wagerId, winner, wager.paymentToken, winningSum);
    }
}