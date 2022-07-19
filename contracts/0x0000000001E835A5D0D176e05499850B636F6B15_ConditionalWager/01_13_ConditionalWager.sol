//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./BartrrBase.sol";

/// @title Bartrr Conditional Wager Contract
/// @notice This contract is used to manage conditional wagers for the Bartrr protocol.
contract ConditionalWager is BartrrBase {
    using SafeERC20 for IERC20;

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

    Wager[] public wagers; // array of wagers

    /// @notice Get all wagers
    /// @return All created wagers
    function getAllWagers() public view returns (Wager[] memory) {
        return wagers;
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
        require(isInitialized, "Contract is not initialized");
        require(wagerTokens[_wagerToken] && refundableTimestamp[_wagerToken].refundable <= refundableTimestamp[_wagerToken].nonrefundable, "Token not allowed to be wagered on");
        require(paymentTokens[_paymentToken], "Token not allowed for payment");
        require(
            _duration >= MIN_WAGER_DURATION,
            "Wager duration must be at least one 1 day"
        );
        require(_wagerPriceA != _wagerPriceB, "Prices must be different");

        uint256 feeUserA = 0;

        if (_paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) { // ETH
            require(
                msg.value == _amountUserA,
                "ETH wager must be equal to msg.value"
            );
            if (_userB == address(0)) { // p2m
                feeUserA = _calculateFee(_amountUserA, _paymentToken);
                _amountUserA = _amountUserA - feeUserA;
                _transfer(payable(feeAddress), feeUserA);
            }
        } else { // Tokens
            if (_userB != address(0)) { // p2p
                IERC20(_paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amountUserA
                );
            } else { // p2m
                feeUserA = _calculateFee(_amountUserA, _paymentToken);
                _amountUserA = _amountUserA - feeUserA;

                IERC20(_paymentToken).safeTransferFrom(
                    msg.sender,
                    feeAddress,
                    feeUserA
                );

                IERC20(_paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amountUserA
                );
            }
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

        require(!wager.isFilled, "Wager already filled");
        require(refundableTimestamp[wager.wagerToken].refundable <= refundableTimestamp[wager.wagerToken].nonrefundable, "wager token not allowed");
        require(msg.sender != wager.userA, "Cannot fill own wager");

        if (wager.userB != address(0)) { // p2p
            require(msg.sender == wager.userB, "p2p restricted");
            if (wager.paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) { // ETH
                require(
                    msg.value == wager.amountUserB,
                    "ETH wager must be equal to msg.value"
                );
                uint256 feeUserA = _calculateFee(wager.amountUserA, wager.paymentToken);
                wager.amountUserA = wager.amountUserA - feeUserA;

                uint256 feeUserB = _calculateFee(wager.amountUserB, wager.paymentToken);
                wager.amountUserB = wager.amountUserB - feeUserB;

                _transfer(payable(feeAddress), feeUserA + feeUserB);
            } else {
                uint256 feeUserA = _calculateFee(wager.amountUserA, wager.paymentToken);
                wager.amountUserA = wager.amountUserA - feeUserA;

                IERC20(wager.paymentToken).safeTransfer(
                    feeAddress,
                    feeUserA
                );
                
                uint256 feeUserB = _calculateFee(wager.amountUserB, wager.paymentToken);
                wager.amountUserB = wager.amountUserB - feeUserB;

                IERC20(wager.paymentToken).safeTransferFrom(
                    msg.sender,
                    feeAddress,
                    feeUserB
                );

                IERC20(wager.paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    wager.amountUserB
                );
            }  
        } else { // p2m
            require(block.timestamp < createdTimes[_wagerId] + 30 days, "wager expired");
            wager.userB = msg.sender;
            if (wager.paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                require(msg.value == wager.amountUserB, "ETH wager must be equal to msg.value");
                uint256 feeUserB = _calculateFee(wager.amountUserB, wager.paymentToken);
                wager.amountUserB = wager.amountUserB - feeUserB;
                _transfer(payable(feeAddress), feeUserB);
            } else {
                uint256 feeUserB = _calculateFee(wager.amountUserB, wager.paymentToken);
                wager.amountUserB = wager.amountUserB - feeUserB;

                IERC20(wager.paymentToken).safeTransferFrom(
                    msg.sender,
                    feeAddress,
                    feeUserB
                );

                IERC20(wager.paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    wager.amountUserB
                );
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
        require(msg.sender == wager.userA || msg.sender == wager.userB, "Only userA or UserB can cancel the wager");
        require(!wager.isFilled, "Wager has already been filled");

        wagers[_wagerId].isClosed = true;

        if (wager.paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            _transfer(payable(wager.userA), wager.amountUserA);
        } else {
            IERC20(wager.paymentToken).safeTransfer(wager.userA, wager.amountUserA);
        }
        emit WagerCancelled(_wagerId, msg.sender);
    }

    /// @notice Redeems a wager
    /// @param _wagerId id of the wager
    function redeem(uint256 _wagerId) external nonReentrant {
        Wager memory wager = wagers[_wagerId];
        require(wager.isFilled, "Wager has not been filled");
        require(!wager.isClosed, "Wager has already been closed");
        uint256 refundable = refundableTimestamp[wager.wagerToken].refundable;
        uint256 nonrefundable = refundableTimestamp[wager.wagerToken].nonrefundable;
        if (refundable > 0 && // token has been marked refundable at least once
        endTimes[_wagerId] > refundable && // wager wasn't complete when marked refundable
        (refundable > nonrefundable || nonrefundable > createdTimes[_wagerId]) || // wager was created before token was marked nonrefundable
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
    function checkWinner(uint256 _wagerId)
        public
        view
        returns (address winner)
    {
        Wager memory wager = wagers[_wagerId];
        require(wager.isFilled, "Wager has not been filled");
        uint256 endTime = endTimes[_wagerId];
        require(endTime <= block.timestamp, "wager not complete");

        AggregatorV2V3Interface feed = AggregatorV2V3Interface(oracles[wager.wagerToken]);

        uint80 roundId = getRoundId(feed, endTime);

        if (roundId == 0) {
            return address(0);
        }

        (int256 price,,) = _getHistoricalPrice(roundId, wager.wagerToken);

        if (wager.wagerPriceA > wager.wagerPriceB) { // User A bets above
            if (price >= wager.wagerPriceA) {
                winner = wager.userA; // User A wins
            } else if (price <= wager.wagerPriceB) {
                winner = wager.userB; // User B wins
            } else {
                winner = address(0); // Draw
            }
        } else if (wager.wagerPriceA < wager.wagerPriceB) { // User A bets below
            if (price <= wager.wagerPriceA) {
                winner = wager.userA; // User A wins
            } else if (price >= wager.wagerPriceB) {
                winner = wager.userB; // User B wins
            } else {
                winner = address(0);
            }
        }
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
        emit WagerCreated(idCounter, _userA, _userB, _wagerToken, _wagerPriceA, _wagerPriceB);
        idCounter++;
    }

    function _refundWager(uint256 _wagerId) internal {
        Wager memory wager = wagers[_wagerId];
        if (msg.sender == wager.userA) {
            require(!refundUserA[_wagerId], "UserA has already been refunded");
            refundUserA[_wagerId] = true;
            if (wager.paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                _transfer(payable(wager.userA), wager.amountUserA);
            } else {
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userA,
                    wager.amountUserA
                );
            }
            emit WagerRefunded(_wagerId, msg.sender, wager.paymentToken, wager.amountUserA);
        } else if (msg.sender == wager.userB) {
            require(!refundUserB[_wagerId], "UserB has already been refunded");
            refundUserB[_wagerId] = true;
            if (wager.paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                _transfer(payable(wager.userB), wager.amountUserB);
            } else {
                IERC20(wager.paymentToken).safeTransfer(
                    wager.userB,
                    wager.amountUserB
                );
            }
            emit WagerRefunded(_wagerId, msg.sender, wager.paymentToken, wager.amountUserB);
        }
    }

    function _redeemWager(uint256 _wagerId) internal {
        Wager memory wager = wagers[_wagerId];
        require(endTimes[_wagerId] <= block.timestamp, "wager not complete");
        uint256 winningSum = wager.amountUserA + wager.amountUserB;
        address winner = checkWinner(_wagerId);

        wagers[_wagerId].isClosed = true;

        if (winner == address(0)) { // draw
            if (wager.paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
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
            if (wager.paymentToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                _transfer(payable(winner), winningSum);
            } else {
                IERC20(wager.paymentToken).safeTransfer(
                    winner,
                    winningSum
                );
            }
        }
        emit WagerRedeemed(_wagerId, winner, wager.paymentToken, winningSum);
    }
}