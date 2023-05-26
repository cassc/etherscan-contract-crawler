pragma solidity 0.5.17;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./PeakDeFiStorage.sol";
import "./derivatives/CompoundOrderFactory.sol";

/**
 * @title Part of the functions for PeakDeFiFund
 * @author Zefram Lou (Zebang Liu)
 */
contract PeakDeFiLogic is
    PeakDeFiStorage,
    Utils(address(0), address(0), address(0))
{
    /**
     * @notice Executes function only during the given cycle phase.
     * @param phase the cycle phase during which the function may be called
     */
    modifier during(CyclePhase phase) {
        require(cyclePhase == phase);
        if (cyclePhase == CyclePhase.Intermission) {
            require(isInitialized);
        }
        _;
    }

    /**
     * @notice Returns the length of the user's investments array.
     * @return length of the user's investments array
     */
    function investmentsCount(address _userAddr)
        public
        view
        returns (uint256 _count)
    {
        return userInvestments[_userAddr].length;
    }

    /**
     * @notice Burns the RepToken balance of a manager who has been inactive for a certain number of cycles
     * @param _deadman the manager whose RepToken balance will be burned
     */
    function burnDeadman(address _deadman)
        public
        nonReentrant
        during(CyclePhase.Intermission)
    {
        require(_deadman != address(this));
        require(
            cycleNumber.sub(lastActiveCycle(_deadman)) > INACTIVE_THRESHOLD
        );
        uint256 balance = cToken.balanceOf(_deadman);
        require(cToken.destroyTokens(_deadman, balance));
        emit BurnDeadman(_deadman, balance);
    }

    /**
     * @notice Creates a new investment for an ERC20 token. Backwards compatible.
     * @param _tokenAddress address of the ERC20 token contract
     * @param _stake amount of RepTokens to be staked in support of the investment
     * @param _maxPrice the maximum price for the trade
     */
    function createInvestment(
        address _tokenAddress,
        uint256 _stake,
        uint256 _maxPrice
    ) public {
        bytes memory nil;
        createInvestmentV2(
            msg.sender,
            _tokenAddress,
            _stake,
            _maxPrice,
            nil,
            true
        );
    }

    function createInvestmentWithSignature(
        address _tokenAddress,
        uint256 _stake,
        uint256 _maxPrice,
        bytes calldata _calldata,
        bool _useKyber,
        address _manager,
        uint256 _salt,
        bytes calldata _signature
    ) external {
        require(!hasUsedSalt[_manager][_salt]);
        bytes32 naiveHash = keccak256(
            abi.encodeWithSelector(
                this.createInvestmentWithSignature.selector,
                abi.encode(
                    _tokenAddress,
                    _stake,
                    _maxPrice,
                    _calldata,
                    _useKyber
                ),
                "|END|",
                _salt,
                address(this)
            )
        );
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(naiveHash);
        address recoveredAddress = ECDSA.recover(msgHash, _signature);
        require(recoveredAddress == _manager);

        // Signature valid, record use of salt
        hasUsedSalt[_manager][_salt] = true;

        this.createInvestmentV2(
            _manager,
            _tokenAddress,
            _stake,
            _maxPrice,
            _calldata,
            _useKyber
        );
    }

    /**
     * @notice Called by user to sell the assets an investment invested in. Returns the staked RepToken plus rewards/penalties to the user.
     *         The user can sell only part of the investment by changing _tokenAmount. Backwards compatible.
     * @dev When selling only part of an investment, the old investment would be "fully" sold and a new investment would be created with
     *   the original buy price and however much tokens that are not sold.
     * @param _investmentId the ID of the investment
     * @param _tokenAmount the amount of tokens to be sold.
     * @param _minPrice the minimum price for the trade
     */
    function sellInvestmentAsset(
        uint256 _investmentId,
        uint256 _tokenAmount,
        uint256 _minPrice
    ) public {
        bytes memory nil;
        sellInvestmentAssetV2(
            msg.sender,
            _investmentId,
            _tokenAmount,
            _minPrice,
            nil,
            true
        );
    }

    function sellInvestmentWithSignature(
        uint256 _investmentId,
        uint256 _tokenAmount,
        uint256 _minPrice,
        bytes calldata _calldata,
        bool _useKyber,
        address _manager,
        uint256 _salt,
        bytes calldata _signature
    ) external {
        require(!hasUsedSalt[_manager][_salt]);
        bytes32 naiveHash = keccak256(
            abi.encodeWithSelector(
                this.sellInvestmentWithSignature.selector,
                abi.encode(
                    _investmentId,
                    _tokenAmount,
                    _minPrice,
                    _calldata,
                    _useKyber
                ),
                "|END|",
                _salt,
                address(this)
            )
        );
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(naiveHash);
        address recoveredAddress = ECDSA.recover(msgHash, _signature);
        require(recoveredAddress == _manager);

        // Signature valid, record use of salt
        hasUsedSalt[_manager][_salt] = true;

        this.sellInvestmentAssetV2(
            _manager,
            _investmentId,
            _tokenAmount,
            _minPrice,
            _calldata,
            _useKyber
        );
    }

    /**
     * @notice Creates a new investment for an ERC20 token.
     * @param _tokenAddress address of the ERC20 token contract
     * @param _stake amount of RepTokens to be staked in support of the investment
     * @param _maxPrice the maximum price for the trade
     * @param _calldata calldata for 1inch trading
     * @param _useKyber true for Kyber Network, false for 1inch
     */
    function createInvestmentV2(
        address _sender,
        address _tokenAddress,
        uint256 _stake,
        uint256 _maxPrice,
        bytes memory _calldata,
        bool _useKyber
    )
        public
        during(CyclePhase.Manage)
        nonReentrant
        isValidToken(_tokenAddress)
    {
        require(msg.sender == _sender || msg.sender == address(this));
        require(_stake > 0);
        require(isKyberToken[_tokenAddress]);

        // Verify user peak stake
        uint256 peakStake = peakStaking.userStakeAmount(_sender);
        require(peakStake >= peakManagerStakeRequired);

        // Collect stake
        require(cToken.generateTokens(address(this), _stake));
        require(cToken.destroyTokens(_sender, _stake));

        // Add investment to list
        userInvestments[_sender].push(
            Investment({
                tokenAddress: _tokenAddress,
                cycleNumber: cycleNumber,
                stake: _stake,
                tokenAmount: 0,
                buyPrice: 0,
                sellPrice: 0,
                buyTime: now,
                buyCostInUSDC: 0,
                isSold: false
            })
        );

        // Invest
        uint256 investmentId = investmentsCount(_sender).sub(1);
        __handleInvestment(
            _sender,
            investmentId,
            0,
            _maxPrice,
            true,
            _calldata,
            _useKyber
        );

        // Update last active cycle
        _lastActiveCycle[_sender] = cycleNumber;

        // Emit event
        __emitCreatedInvestmentEvent(_sender, investmentId);
    }

    /**
     * @notice Called by user to sell the assets an investment invested in. Returns the staked RepToken plus rewards/penalties to the user.
     *         The user can sell only part of the investment by changing _tokenAmount.
     * @dev When selling only part of an investment, the old investment would be "fully" sold and a new investment would be created with
     *   the original buy price and however much tokens that are not sold.
     * @param _investmentId the ID of the investment
     * @param _tokenAmount the amount of tokens to be sold.
     * @param _minPrice the minimum price for the trade
     */
    function sellInvestmentAssetV2(
        address _sender,
        uint256 _investmentId,
        uint256 _tokenAmount,
        uint256 _minPrice,
        bytes memory _calldata,
        bool _useKyber
    ) public nonReentrant during(CyclePhase.Manage) {
        require(msg.sender == _sender || msg.sender == address(this));
        Investment storage investment = userInvestments[_sender][_investmentId];
        require(
            investment.buyPrice > 0 &&
                investment.cycleNumber == cycleNumber &&
                !investment.isSold
        );
        require(_tokenAmount > 0 && _tokenAmount <= investment.tokenAmount);

        // Create new investment for leftover tokens
        bool isPartialSell = false;
        uint256 stakeOfSoldTokens = investment.stake.mul(_tokenAmount).div(
            investment.tokenAmount
        );
        if (_tokenAmount != investment.tokenAmount) {
            isPartialSell = true;

            __createInvestmentForLeftovers(
                _sender,
                _investmentId,
                _tokenAmount
            );

            __emitCreatedInvestmentEvent(
                _sender,
                investmentsCount(_sender).sub(1)
            );
        }

        // Update investment info
        investment.isSold = true;

        // Sell asset
        (
            uint256 actualDestAmount,
            uint256 actualSrcAmount
        ) = __handleInvestment(
            _sender,
            _investmentId,
            _minPrice,
            uint256(-1),
            false,
            _calldata,
            _useKyber
        );

        __sellInvestmentUpdate(
            _sender,
            _investmentId,
            stakeOfSoldTokens,
            actualDestAmount
        );
    }

    function __sellInvestmentUpdate(
        address _sender,
        uint256 _investmentId,
        uint256 stakeOfSoldTokens,
        uint256 actualDestAmount
    ) internal {
        Investment storage investment = userInvestments[_sender][_investmentId];

        // Return staked RepToken
        uint256 receiveRepTokenAmount = getReceiveRepTokenAmount(
            stakeOfSoldTokens,
            investment.sellPrice,
            investment.buyPrice
        );
        __returnStake(receiveRepTokenAmount, stakeOfSoldTokens);

        // Record risk taken in investment
        __recordRisk(_sender, investment.stake, investment.buyTime);

        // Update total funds
        totalFundsInUSDC = totalFundsInUSDC.sub(investment.buyCostInUSDC).add(
            actualDestAmount
        );

        // Emit event
        __emitSoldInvestmentEvent(
            _sender,
            _investmentId,
            receiveRepTokenAmount,
            actualDestAmount
        );
    }

    function __emitSoldInvestmentEvent(
        address _sender,
        uint256 _investmentId,
        uint256 _receiveRepTokenAmount,
        uint256 _actualDestAmount
    ) internal {
        Investment storage investment = userInvestments[_sender][_investmentId];
        emit SoldInvestment(
            cycleNumber,
            _sender,
            _investmentId,
            investment.tokenAddress,
            _receiveRepTokenAmount,
            investment.sellPrice,
            _actualDestAmount
        );
    }

    function __createInvestmentForLeftovers(
        address _sender,
        uint256 _investmentId,
        uint256 _tokenAmount
    ) internal {
        Investment storage investment = userInvestments[_sender][_investmentId];

        uint256 stakeOfSoldTokens = investment.stake.mul(_tokenAmount).div(
            investment.tokenAmount
        );

        // calculate the part of original USDC cost attributed to the sold tokens
        uint256 soldBuyCostInUSDC = investment
            .buyCostInUSDC
            .mul(_tokenAmount)
            .div(investment.tokenAmount);

        userInvestments[_sender].push(
            Investment({
                tokenAddress: investment.tokenAddress,
                cycleNumber: cycleNumber,
                stake: investment.stake.sub(stakeOfSoldTokens),
                tokenAmount: investment.tokenAmount.sub(_tokenAmount),
                buyPrice: investment.buyPrice,
                sellPrice: 0,
                buyTime: investment.buyTime,
                buyCostInUSDC: investment.buyCostInUSDC.sub(soldBuyCostInUSDC),
                isSold: false
            })
        );

        // update the investment object being sold
        investment.tokenAmount = _tokenAmount;
        investment.stake = stakeOfSoldTokens;
        investment.buyCostInUSDC = soldBuyCostInUSDC;
    }

    function __emitCreatedInvestmentEvent(address _sender, uint256 _id)
        internal
    {
        Investment storage investment = userInvestments[_sender][_id];
        emit CreatedInvestment(
            cycleNumber,
            _sender,
            _id,
            investment.tokenAddress,
            investment.stake,
            investment.buyPrice,
            investment.buyCostInUSDC,
            investment.tokenAmount
        );
    }

    function createCompoundOrderWithSignature(
        bool _orderType,
        address _tokenAddress,
        uint256 _stake,
        uint256 _minPrice,
        uint256 _maxPrice,
        address _manager,
        uint256 _salt,
        bytes calldata _signature
    ) external {
        require(!hasUsedSalt[_manager][_salt]);
        bytes32 naiveHash = keccak256(
            abi.encodeWithSelector(
                this.createCompoundOrderWithSignature.selector,
                abi.encode(
                    _orderType,
                    _tokenAddress,
                    _stake,
                    _minPrice,
                    _maxPrice
                ),
                "|END|",
                _salt,
                address(this)
            )
        );
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(naiveHash);
        address recoveredAddress = ECDSA.recover(msgHash, _signature);
        require(recoveredAddress == _manager);

        // Signature valid, record use of salt
        hasUsedSalt[_manager][_salt] = true;

        this.createCompoundOrder(
            _manager,
            _orderType,
            _tokenAddress,
            _stake,
            _minPrice,
            _maxPrice
        );
    }

    function sellCompoundOrderWithSignature(
        uint256 _orderId,
        uint256 _minPrice,
        uint256 _maxPrice,
        address _manager,
        uint256 _salt,
        bytes calldata _signature
    ) external {
        require(!hasUsedSalt[_manager][_salt]);
        bytes32 naiveHash = keccak256(
            abi.encodeWithSelector(
                this.sellCompoundOrderWithSignature.selector,
                abi.encode(_orderId, _minPrice, _maxPrice),
                "|END|",
                _salt,
                address(this)
            )
        );
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(naiveHash);
        address recoveredAddress = ECDSA.recover(msgHash, _signature);
        require(recoveredAddress == _manager);

        // Signature valid, record use of salt
        hasUsedSalt[_manager][_salt] = true;

        this.sellCompoundOrder(_manager, _orderId, _minPrice, _maxPrice);
    }

    function repayCompoundOrderWithSignature(
        uint256 _orderId,
        uint256 _repayAmountInUSDC,
        address _manager,
        uint256 _salt,
        bytes calldata _signature
    ) external {
        require(!hasUsedSalt[_manager][_salt]);
        bytes32 naiveHash = keccak256(
            abi.encodeWithSelector(
                this.repayCompoundOrderWithSignature.selector,
                abi.encode(_orderId, _repayAmountInUSDC),
                "|END|",
                _salt,
                address(this)
            )
        );
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(naiveHash);
        address recoveredAddress = ECDSA.recover(msgHash, _signature);
        require(recoveredAddress == _manager);

        // Signature valid, record use of salt
        hasUsedSalt[_manager][_salt] = true;

        this.repayCompoundOrder(_manager, _orderId, _repayAmountInUSDC);
    }

    /**
     * @notice Creates a new Compound order to either short or leverage long a token.
     * @param _orderType true for a short order, false for a levarage long order
     * @param _tokenAddress address of the Compound token to be traded
     * @param _stake amount of RepTokens to be staked
     * @param _minPrice the minimum token price for the trade
     * @param _maxPrice the maximum token price for the trade
     */
    function createCompoundOrder(
        address _sender,
        bool _orderType,
        address _tokenAddress,
        uint256 _stake,
        uint256 _minPrice,
        uint256 _maxPrice
    )
        public
        during(CyclePhase.Manage)
        nonReentrant
        isValidToken(_tokenAddress)
    {
        require(msg.sender == _sender || msg.sender == address(this));
        require(_minPrice <= _maxPrice);
        require(_stake > 0);
        require(isCompoundToken[_tokenAddress]);

        // Verify user peak stake
        uint256 peakStake = peakStaking.userStakeAmount(_sender);
        require(peakStake >= peakManagerStakeRequired);

        // Collect stake
        require(cToken.generateTokens(address(this), _stake));
        require(cToken.destroyTokens(_sender, _stake));

        // Create compound order and execute
        uint256 collateralAmountInUSDC = totalFundsInUSDC.mul(_stake).div(
            cToken.totalSupply()
        );
        CompoundOrder order = __createCompoundOrder(
            _orderType,
            _tokenAddress,
            _stake,
            collateralAmountInUSDC
        );
        usdc.safeApprove(address(order), 0);
        usdc.safeApprove(address(order), collateralAmountInUSDC);
        order.executeOrder(_minPrice, _maxPrice);

        // Add order to list
        userCompoundOrders[_sender].push(address(order));

        // Update last active cycle
        _lastActiveCycle[_sender] = cycleNumber;

        __emitCreatedCompoundOrderEvent(
            _sender,
            address(order),
            _orderType,
            _tokenAddress,
            _stake,
            collateralAmountInUSDC
        );
    }

    function __emitCreatedCompoundOrderEvent(
        address _sender,
        address order,
        bool _orderType,
        address _tokenAddress,
        uint256 _stake,
        uint256 collateralAmountInUSDC
    ) internal {
        // Emit event
        emit CreatedCompoundOrder(
            cycleNumber,
            _sender,
            userCompoundOrders[_sender].length - 1,
            address(order),
            _orderType,
            _tokenAddress,
            _stake,
            collateralAmountInUSDC
        );
    }

    /**
     * @notice Sells a compound order
     * @param _orderId the ID of the order to be sold (index in userCompoundOrders[msg.sender])
     * @param _minPrice the minimum token price for the trade
     * @param _maxPrice the maximum token price for the trade
     */
    function sellCompoundOrder(
        address _sender,
        uint256 _orderId,
        uint256 _minPrice,
        uint256 _maxPrice
    ) public during(CyclePhase.Manage) nonReentrant {
        require(msg.sender == _sender || msg.sender == address(this));
        // Load order info
        require(userCompoundOrders[_sender][_orderId] != address(0));
        CompoundOrder order = CompoundOrder(
            userCompoundOrders[_sender][_orderId]
        );
        require(order.isSold() == false && order.cycleNumber() == cycleNumber);

        // Sell order
        (uint256 inputAmount, uint256 outputAmount) = order.sellOrder(
            _minPrice,
            _maxPrice
        );

        // Return staked RepToken
        uint256 stake = order.stake();
        uint256 receiveRepTokenAmount = getReceiveRepTokenAmount(
            stake,
            outputAmount,
            inputAmount
        );
        __returnStake(receiveRepTokenAmount, stake);

        // Record risk taken
        __recordRisk(_sender, stake, order.buyTime());

        // Update total funds
        totalFundsInUSDC = totalFundsInUSDC.sub(inputAmount).add(outputAmount);

        // Emit event
        emit SoldCompoundOrder(
            cycleNumber,
            _sender,
            userCompoundOrders[_sender].length - 1,
            address(order),
            order.orderType(),
            order.compoundTokenAddr(),
            receiveRepTokenAmount,
            outputAmount
        );
    }

    /**
     * @notice Repys debt for a Compound order to prevent the collateral ratio from dropping below threshold.
     * @param _orderId the ID of the Compound order
     * @param _repayAmountInUSDC amount of USDC to use for repaying debt
     */
    function repayCompoundOrder(
        address _sender,
        uint256 _orderId,
        uint256 _repayAmountInUSDC
    ) public during(CyclePhase.Manage) nonReentrant {
        require(msg.sender == _sender || msg.sender == address(this));
        // Load order info
        require(userCompoundOrders[_sender][_orderId] != address(0));
        CompoundOrder order = CompoundOrder(
            userCompoundOrders[_sender][_orderId]
        );
        require(order.isSold() == false && order.cycleNumber() == cycleNumber);

        // Repay loan
        order.repayLoan(_repayAmountInUSDC);

        // Emit event
        emit RepaidCompoundOrder(
            cycleNumber,
            _sender,
            userCompoundOrders[_sender].length - 1,
            address(order),
            _repayAmountInUSDC
        );
    }

    function emergencyExitCompoundTokens(
        address _sender,
        uint256 _orderId,
        address _tokenAddr,
        address _receiver
    ) public during(CyclePhase.Intermission) nonReentrant {
        CompoundOrder order = CompoundOrder(userCompoundOrders[_sender][_orderId]);
        order.emergencyExitTokens(_tokenAddr, _receiver);
    }

    function getReceiveRepTokenAmount(
        uint256 stake,
        uint256 output,
        uint256 input
    ) public pure returns (uint256 _amount) {
        if (output >= input) {
            // positive ROI, simply return stake * (1 + ROI)
            return stake.mul(output).div(input);
        } else {
            // negative ROI
            uint256 absROI = input.sub(output).mul(PRECISION).div(input);
            if (absROI <= ROI_PUNISH_THRESHOLD) {
                // ROI better than -10%, no punishment
                return stake.mul(output).div(input);
            } else if (
                absROI > ROI_PUNISH_THRESHOLD && absROI < ROI_BURN_THRESHOLD
            ) {
                // ROI between -10% and -25%, punish
                // return stake * (1 + roiWithPunishment) = stake * (1 + (-(6 * absROI - 0.5)))
                return
                    stake
                        .mul(
                        PRECISION.sub(
                            ROI_PUNISH_SLOPE.mul(absROI).sub(
                                ROI_PUNISH_NEG_BIAS
                            )
                        )
                    )
                        .div(PRECISION);
            } else {
                // ROI greater than 25%, burn all stake
                return 0;
            }
        }
    }

    /**
     * @notice Handles and investment by doing the necessary trades using __kyberTrade() or Fulcrum trading
     * @param _investmentId the ID of the investment to be handled
     * @param _minPrice the minimum price for the trade
     * @param _maxPrice the maximum price for the trade
     * @param _buy whether to buy or sell the given investment
     * @param _calldata calldata for 1inch trading
     * @param _useKyber true for Kyber Network, false for 1inch
     */
    function __handleInvestment(
        address _sender,
        uint256 _investmentId,
        uint256 _minPrice,
        uint256 _maxPrice,
        bool _buy,
        bytes memory _calldata,
        bool _useKyber
    ) internal returns (uint256 _actualDestAmount, uint256 _actualSrcAmount) {
        Investment storage investment = userInvestments[_sender][_investmentId];
        address token = investment.tokenAddress;
        // Basic trading
        uint256 dInS; // price of dest token denominated in src token
        uint256 sInD; // price of src token denominated in dest token
        if (_buy) {
            if (_useKyber) {
                (
                    dInS,
                    sInD,
                    _actualDestAmount,
                    _actualSrcAmount
                ) = __kyberTrade(
                    usdc,
                    totalFundsInUSDC.mul(investment.stake).div(
                        cToken.totalSupply()
                    ),
                    ERC20Detailed(token)
                );
            } else {
                // 1inch trading
                (
                    dInS,
                    sInD,
                    _actualDestAmount,
                    _actualSrcAmount
                ) = __oneInchTrade(
                    usdc,
                    totalFundsInUSDC.mul(investment.stake).div(
                        cToken.totalSupply()
                    ),
                    ERC20Detailed(token),
                    _calldata
                );
            }
            require(_minPrice <= dInS && dInS <= _maxPrice);
            investment.buyPrice = dInS;
            investment.tokenAmount = _actualDestAmount;
            investment.buyCostInUSDC = _actualSrcAmount;
        } else {
            if (_useKyber) {
                (
                    dInS,
                    sInD,
                    _actualDestAmount,
                    _actualSrcAmount
                ) = __kyberTrade(
                    ERC20Detailed(token),
                    investment.tokenAmount,
                    usdc
                );
            } else {
                (
                    dInS,
                    sInD,
                    _actualDestAmount,
                    _actualSrcAmount
                ) = __oneInchTrade(
                    ERC20Detailed(token),
                    investment.tokenAmount,
                    usdc,
                    _calldata
                );
            }

            require(_minPrice <= sInD && sInD <= _maxPrice);
            investment.sellPrice = sInD;
        }
    }

    /**
     * @notice Separated from createCompoundOrder() to avoid stack too deep error
     */
    function __createCompoundOrder(
        bool _orderType, // True for shorting, false for longing
        address _tokenAddress,
        uint256 _stake,
        uint256 _collateralAmountInUSDC
    ) internal returns (CompoundOrder) {
        CompoundOrderFactory factory = CompoundOrderFactory(
            compoundFactoryAddr
        );
        uint256 loanAmountInUSDC = _collateralAmountInUSDC
            .mul(COLLATERAL_RATIO_MODIFIER)
            .div(PRECISION)
            .mul(factory.getMarketCollateralFactor(_tokenAddress))
            .div(PRECISION);
        CompoundOrder order = factory.createOrder(
            _tokenAddress,
            cycleNumber,
            _stake,
            _collateralAmountInUSDC,
            loanAmountInUSDC,
            _orderType
        );
        return order;
    }

    /**
     * @notice Returns stake to manager after investment is sold, including reward/penalty based on performance
     */
    function __returnStake(uint256 _receiveRepTokenAmount, uint256 _stake)
        internal
    {
        require(cToken.destroyTokens(address(this), _stake));
        require(cToken.generateTokens(msg.sender, _receiveRepTokenAmount));
    }

    /**
     * @notice Records risk taken in a trade based on stake and time of investment
     */
    function __recordRisk(
        address _sender,
        uint256 _stake,
        uint256 _buyTime
    ) internal {
        _riskTakenInCycle[_sender][cycleNumber] = riskTakenInCycle(
            _sender,
            cycleNumber
        )
            .add(_stake.mul(now.sub(_buyTime)));
    }
}