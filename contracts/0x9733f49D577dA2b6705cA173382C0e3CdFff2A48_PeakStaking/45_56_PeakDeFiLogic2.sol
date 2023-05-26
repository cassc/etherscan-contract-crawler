pragma solidity 0.5.17;

import "./PeakDeFiStorage.sol";
import "./derivatives/CompoundOrderFactory.sol";
import "@nomiclabs/buidler/console.sol";

/**
 * @title Part of the functions for PeakDeFiFund
 * @author Zefram Lou (Zebang Liu)
 */
contract PeakDeFiLogic2 is
    PeakDeFiStorage,
    Utils(address(0), address(0), address(0))
{
    /**
     * @notice Passes if the fund has not finalized the next smart contract to upgrade to
     */
    modifier notReadyForUpgrade {
        require(hasFinalizedNextVersion == false);
        _;
    }

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
     * Deposit & Withdraw
     */

    function depositEther(address _referrer) public payable {
        bytes memory nil;
        depositEtherAdvanced(true, nil, _referrer);
    }

    /**
     * @notice Deposit Ether into the fund. Ether will be converted into USDC.
     * @param _useKyber true for Kyber Network, false for 1inch
     * @param _calldata calldata for 1inch trading
     * @param _referrer the referrer's address

     */
    function depositEtherAdvanced(
        bool _useKyber,
        bytes memory _calldata,
        address _referrer
    ) public payable nonReentrant notReadyForUpgrade {
        // Buy USDC with ETH
        uint256 actualUSDCDeposited;
        uint256 actualETHDeposited;
        if (_useKyber) {
            (, , actualUSDCDeposited, actualETHDeposited) = __kyberTrade(
                ETH_TOKEN_ADDRESS,
                msg.value,
                usdc
            );
        } else {
            (, , actualUSDCDeposited, actualETHDeposited) = __oneInchTrade(
                ETH_TOKEN_ADDRESS,
                msg.value,
                usdc,
                _calldata
            );
        }

        // Send back leftover ETH
        uint256 leftOverETH = msg.value.sub(actualETHDeposited);
        if (leftOverETH > 0) {
            msg.sender.transfer(leftOverETH);
        }

        // Register investment
        __deposit(actualUSDCDeposited, _referrer);

        // Emit event
        emit Deposit(
            cycleNumber,
            msg.sender,
            address(ETH_TOKEN_ADDRESS),
            actualETHDeposited,
            actualUSDCDeposited,
            now
        );
    }

    /**
     * @notice Deposit USDC Stablecoin into the fund.
     * @param _usdcAmount The amount of USDC to be deposited. May be different from actual deposited amount.
     * @param _referrer the referrer's address
     */
    function depositUSDC(uint256 _usdcAmount, address _referrer)
        public
        nonReentrant
        notReadyForUpgrade
    {
        usdc.safeTransferFrom(msg.sender, address(this), _usdcAmount);

        // Register investment
        __deposit(_usdcAmount, _referrer);

        // Emit event
        emit Deposit(
            cycleNumber,
            msg.sender,
            USDC_ADDR,
            _usdcAmount,
            _usdcAmount,
            now
        );
    }

    function depositToken(
        address _tokenAddr,
        uint256 _tokenAmount,
        address _referrer
    ) public {
        bytes memory nil;
        depositTokenAdvanced(_tokenAddr, _tokenAmount, true, nil, _referrer);
    }

    /**
     * @notice Deposit ERC20 tokens into the fund. Tokens will be converted into USDC.
     * @param _tokenAddr the address of the token to be deposited
     * @param _tokenAmount The amount of tokens to be deposited. May be different from actual deposited amount.
     * @param _useKyber true for Kyber Network, false for 1inch
     * @param _calldata calldata for 1inch trading
     * @param _referrer the referrer's address
     */
    function depositTokenAdvanced(
        address _tokenAddr,
        uint256 _tokenAmount,
        bool _useKyber,
        bytes memory _calldata,
        address _referrer
    ) public nonReentrant notReadyForUpgrade isValidToken(_tokenAddr) {
        require(
            _tokenAddr != USDC_ADDR && _tokenAddr != address(ETH_TOKEN_ADDRESS)
        );

        ERC20Detailed token = ERC20Detailed(_tokenAddr);

        token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        // Convert token into USDC
        uint256 actualUSDCDeposited;
        uint256 actualTokenDeposited;
        if (_useKyber) {
            (, , actualUSDCDeposited, actualTokenDeposited) = __kyberTrade(
                token,
                _tokenAmount,
                usdc
            );
        } else {
            (, , actualUSDCDeposited, actualTokenDeposited) = __oneInchTrade(
                token,
                _tokenAmount,
                usdc,
                _calldata
            );
        }
        // Give back leftover tokens
        uint256 leftOverTokens = _tokenAmount.sub(actualTokenDeposited);
        if (leftOverTokens > 0) {
            token.safeTransfer(msg.sender, leftOverTokens);
        }

        // Register investment
        __deposit(actualUSDCDeposited, _referrer);

        // Emit event
        emit Deposit(
            cycleNumber,
            msg.sender,
            _tokenAddr,
            actualTokenDeposited,
            actualUSDCDeposited,
            now
        );
    }

    function withdrawEther(uint256 _amountInUSDC) external {
        bytes memory nil;
        withdrawEtherAdvanced(_amountInUSDC, true, nil);
    }

    /**
     * @notice Withdraws Ether by burning Shares.
     * @param _amountInUSDC Amount of funds to be withdrawn expressed in USDC. Fixed-point decimal. May be different from actual amount.
     * @param _useKyber true for Kyber Network, false for 1inch
     * @param _calldata calldata for 1inch trading
     */
    function withdrawEtherAdvanced(
        uint256 _amountInUSDC,
        bool _useKyber,
        bytes memory _calldata
    ) public nonReentrant during(CyclePhase.Intermission) {
        // Buy ETH
        uint256 actualETHWithdrawn;
        uint256 actualUSDCWithdrawn;
        if (_useKyber) {
            (, , actualETHWithdrawn, actualUSDCWithdrawn) = __kyberTrade(
                usdc,
                _amountInUSDC,
                ETH_TOKEN_ADDRESS
            );
        } else {
            (, , actualETHWithdrawn, actualUSDCWithdrawn) = __oneInchTrade(
                usdc,
                _amountInUSDC,
                ETH_TOKEN_ADDRESS,
                _calldata
            );
        }

        __withdraw(actualUSDCWithdrawn);

        // Transfer Ether to user
        msg.sender.transfer(actualETHWithdrawn);

        // Emit event
        emit Withdraw(
            cycleNumber,
            msg.sender,
            address(ETH_TOKEN_ADDRESS),
            actualETHWithdrawn,
            actualUSDCWithdrawn,
            now
        );
    }

    /**
     * @notice Withdraws Ether by burning Shares.
     * @param _amountInUSDC Amount of funds to be withdrawn expressed in USDC. Fixed-point decimal. May be different from actual amount.
     */
    function withdrawUSDC(uint256 _amountInUSDC)
        external
        nonReentrant
        during(CyclePhase.Intermission)
    {
        __withdraw(_amountInUSDC);

        // Transfer USDC to user
        usdc.safeTransfer(msg.sender, _amountInUSDC);

        // Emit event
        emit Withdraw(
            cycleNumber,
            msg.sender,
            USDC_ADDR,
            _amountInUSDC,
            _amountInUSDC,
            now
        );
    }

    function withdrawToken(address _tokenAddr, uint256 _amountInUSDC) external {
        bytes memory nil;
        withdrawTokenAdvanced(_tokenAddr, _amountInUSDC, true, nil);
    }

    /**
     * @notice Withdraws funds by burning Shares, and converts the funds into the specified token using Kyber Network.
     * @param _tokenAddr the address of the token to be withdrawn into the caller's account
     * @param _amountInUSDC The amount of funds to be withdrawn expressed in USDC. Fixed-point decimal. May be different from actual amount.
     * @param _useKyber true for Kyber Network, false for 1inch
     * @param _calldata calldata for 1inch trading
     */
    function withdrawTokenAdvanced(
        address _tokenAddr,
        uint256 _amountInUSDC,
        bool _useKyber,
        bytes memory _calldata
    )
        public
        during(CyclePhase.Intermission)
        nonReentrant
        isValidToken(_tokenAddr)
    {
        require(
            _tokenAddr != USDC_ADDR && _tokenAddr != address(ETH_TOKEN_ADDRESS)
        );

        ERC20Detailed token = ERC20Detailed(_tokenAddr);

        // Convert USDC into desired tokens
        uint256 actualTokenWithdrawn;
        uint256 actualUSDCWithdrawn;
        if (_useKyber) {
            (, , actualTokenWithdrawn, actualUSDCWithdrawn) = __kyberTrade(
                usdc,
                _amountInUSDC,
                token
            );
        } else {
            (, , actualTokenWithdrawn, actualUSDCWithdrawn) = __oneInchTrade(
                usdc,
                _amountInUSDC,
                token,
                _calldata
            );
        }

        __withdraw(actualUSDCWithdrawn);

        // Transfer tokens to user
        token.safeTransfer(msg.sender, actualTokenWithdrawn);

        // Emit event
        emit Withdraw(
            cycleNumber,
            msg.sender,
            _tokenAddr,
            actualTokenWithdrawn,
            actualUSDCWithdrawn,
            now
        );
    }

    /**
     * Manager registration
     */

    /**
     * @notice Registers `msg.sender` as a manager, using USDC as payment. The more one pays, the more RepToken one gets.
     *         There's a max RepToken amount that can be bought, and excess payment will be sent back to sender.
     */
    function registerWithUSDC()
        public
        during(CyclePhase.Intermission)
        nonReentrant
    {
        require(!isPermissioned);
        require(managersOnboardedThisCycle < maxNewManagersPerCycle);
        managersOnboardedThisCycle = managersOnboardedThisCycle.add(1);

        uint256 peakStake = peakStaking.userStakeAmount(msg.sender);
        require(peakStake >= peakManagerStakeRequired);

        uint256 donationInUSDC = newManagerRepToken.mul(reptokenPrice).div(PRECISION);
        usdc.safeTransferFrom(msg.sender, address(this), donationInUSDC);
        __register(donationInUSDC);
    }

    /**
     * @notice Registers `msg.sender` as a manager, using ETH as payment. The more one pays, the more RepToken one gets.
     *         There's a max RepToken amount that can be bought, and excess payment will be sent back to sender.
     */
    function registerWithETH()
        public
        payable
        during(CyclePhase.Intermission)
        nonReentrant
    {
        require(!isPermissioned);
        require(managersOnboardedThisCycle < maxNewManagersPerCycle);
        managersOnboardedThisCycle = managersOnboardedThisCycle.add(1);

        uint256 peakStake = peakStaking.userStakeAmount(msg.sender);
        require(peakStake >= peakManagerStakeRequired);

        uint256 receivedUSDC;

        // trade ETH for USDC
        (, , receivedUSDC, ) = __kyberTrade(ETH_TOKEN_ADDRESS, msg.value, usdc);

        // if USDC value is greater than the amount required, return excess USDC to msg.sender
        uint256 donationInUSDC = newManagerRepToken.mul(reptokenPrice).div(PRECISION);
        if (receivedUSDC > donationInUSDC) {
            usdc.safeTransfer(msg.sender, receivedUSDC.sub(donationInUSDC));
            receivedUSDC = donationInUSDC;
        }

        // register new manager
        __register(receivedUSDC);
    }

    /**
     * @notice Registers `msg.sender` as a manager, using tokens as payment. The more one pays, the more RepToken one gets.
     *         There's a max RepToken amount that can be bought, and excess payment will be sent back to sender.
     * @param _token the token to be used for payment
     * @param _donationInTokens the amount of tokens to be used for registration, should use the token's native decimals
     */
    function registerWithToken(address _token, uint256 _donationInTokens)
        public
        during(CyclePhase.Intermission)
        nonReentrant
    {
        require(!isPermissioned);
        require(managersOnboardedThisCycle < maxNewManagersPerCycle);
        managersOnboardedThisCycle = managersOnboardedThisCycle.add(1);

        uint256 peakStake = peakStaking.userStakeAmount(msg.sender);
        require(peakStake >= peakManagerStakeRequired);

        require(
            _token != address(0) &&
                _token != address(ETH_TOKEN_ADDRESS) &&
                _token != USDC_ADDR
        );
        ERC20Detailed token = ERC20Detailed(_token);
        require(token.totalSupply() > 0);

        token.safeTransferFrom(msg.sender, address(this), _donationInTokens);

        uint256 receivedUSDC;

        (, , receivedUSDC, ) = __kyberTrade(token, _donationInTokens, usdc);

        // if USDC value is greater than the amount required, return excess USDC to msg.sender
        uint256 donationInUSDC = newManagerRepToken.mul(reptokenPrice).div(PRECISION);
        if (receivedUSDC > donationInUSDC) {
            usdc.safeTransfer(msg.sender, receivedUSDC.sub(donationInUSDC));
            receivedUSDC = donationInUSDC;
        }

        // register new manager
        __register(receivedUSDC);
    }

    function peakAdminRegisterManager(address _manager, uint256 _reptokenAmount)
        public
        during(CyclePhase.Intermission)
        nonReentrant
        onlyOwner
    {
        require(isPermissioned);

        // mint REP for msg.sender
        require(cToken.generateTokens(_manager, _reptokenAmount));

        // Set risk fallback base stake
        _baseRiskStakeFallback[_manager] = _baseRiskStakeFallback[_manager].add(
            _reptokenAmount
        );

        // Set last active cycle for msg.sender to be the current cycle
        _lastActiveCycle[_manager] = cycleNumber;

        // emit events
        emit Register(_manager, 0, _reptokenAmount);
    }

    /**
     * @notice Sells tokens left over due to manager not selling or KyberNetwork not having enough volume. Callable by anyone. Money goes to developer.
     * @param _tokenAddr address of the token to be sold
     * @param _calldata the 1inch trade call data
     */
    function sellLeftoverToken(address _tokenAddr, bytes calldata _calldata)
        external
        during(CyclePhase.Intermission)
        nonReentrant
        isValidToken(_tokenAddr)
    {
        ERC20Detailed token = ERC20Detailed(_tokenAddr);
        (, , uint256 actualUSDCReceived, ) = __oneInchTrade(
            token,
            getBalance(token, address(this)),
            usdc,
            _calldata
        );
        totalFundsInUSDC = totalFundsInUSDC.add(actualUSDCReceived);
    }

    /**
     * @notice Sells CompoundOrder left over due to manager not selling or KyberNetwork not having enough volume. Callable by anyone. Money goes to developer.
     * @param _orderAddress address of the CompoundOrder to be sold
     */
    function sellLeftoverCompoundOrder(address payable _orderAddress)
        public
        during(CyclePhase.Intermission)
        nonReentrant
    {
        // Load order info
        require(_orderAddress != address(0));
        CompoundOrder order = CompoundOrder(_orderAddress);
        require(order.isSold() == false && order.cycleNumber() < cycleNumber);

        // Sell short order
        // Not using outputAmount returned by order.sellOrder() because _orderAddress could point to a malicious contract
        uint256 beforeUSDCBalance = usdc.balanceOf(address(this));
        order.sellOrder(0, MAX_QTY);
        uint256 actualUSDCReceived = usdc.balanceOf(address(this)).sub(
            beforeUSDCBalance
        );

        totalFundsInUSDC = totalFundsInUSDC.add(actualUSDCReceived);
    }

    /**
     * @notice Registers `msg.sender` as a manager.
     * @param _donationInUSDC the amount of USDC to be used for registration
     */
    function __register(uint256 _donationInUSDC) internal {
        require(
            cToken.balanceOf(msg.sender) == 0 &&
                userInvestments[msg.sender].length == 0 &&
                userCompoundOrders[msg.sender].length == 0
        ); // each address can only join once

        // mint REP for msg.sender
        uint256 repAmount = _donationInUSDC.mul(PRECISION).div(reptokenPrice);
        require(cToken.generateTokens(msg.sender, repAmount));

        // Set risk fallback base stake
        _baseRiskStakeFallback[msg.sender] = repAmount;

        // Set last active cycle for msg.sender to be the current cycle
        _lastActiveCycle[msg.sender] = cycleNumber;

        // keep USDC in the fund
        totalFundsInUSDC = totalFundsInUSDC.add(_donationInUSDC);

        // emit events
        emit Register(msg.sender, _donationInUSDC, repAmount);
    }

    /**
     * @notice Handles deposits by minting PeakDeFi Shares & updating total funds.
     * @param _depositUSDCAmount The amount of the deposit in USDC
     * @param _referrer The deposit referrer
     */
    function __deposit(uint256 _depositUSDCAmount, address _referrer) internal {
        // Register investment and give shares
        uint256 shareAmount;
        if (sToken.totalSupply() == 0 || totalFundsInUSDC == 0) {
            uint256 usdcDecimals = getDecimals(usdc);
            shareAmount = _depositUSDCAmount.mul(PRECISION).div(10**usdcDecimals);
        } else {
            shareAmount = _depositUSDCAmount.mul(sToken.totalSupply()).div(
                totalFundsInUSDC
            );
        }
        require(sToken.generateTokens(msg.sender, shareAmount));
        totalFundsInUSDC = totalFundsInUSDC.add(_depositUSDCAmount);
        totalFundsAtManagePhaseStart = totalFundsAtManagePhaseStart.add(
            _depositUSDCAmount
        );

        // Handle peakReferralToken
        if (peakReward.canRefer(msg.sender, _referrer)) {
            peakReward.refer(msg.sender, _referrer);
        }
        address actualReferrer = peakReward.referrerOf(msg.sender);
        if (actualReferrer != address(0)) {
            require(
                peakReferralToken.generateTokens(actualReferrer, shareAmount)
            );
        }
    }

    /**
     * @notice Handles deposits by burning PeakDeFi Shares & updating total funds.
     * @param _withdrawUSDCAmount The amount of the withdrawal in USDC
     */
    function __withdraw(uint256 _withdrawUSDCAmount) internal {
        // Burn Shares
        uint256 shareAmount = _withdrawUSDCAmount.mul(sToken.totalSupply()).div(
            totalFundsInUSDC
        );
        require(sToken.destroyTokens(msg.sender, shareAmount));
        totalFundsInUSDC = totalFundsInUSDC.sub(_withdrawUSDCAmount);

        // Handle peakReferralToken
        address actualReferrer = peakReward.referrerOf(msg.sender);
        if (actualReferrer != address(0)) {
            uint256 balance = peakReferralToken.balanceOf(actualReferrer);
            uint256 burnReferralTokenAmount = shareAmount > balance
                ? balance
                : shareAmount;
            require(
                peakReferralToken.destroyTokens(
                    actualReferrer,
                    burnReferralTokenAmount
                )
            );
        }
    }
}