// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "./EUSD.sol";
import "./Governable.sol";

interface Ilido {
    function submit(address _referral) external payable returns (uint256 StETH);

    function withdraw(address _to) external returns (uint256 ETH);

    function balanceOf(address _account) external view returns (uint256);

    function transfer(address _recipient, uint256 _amount)
        external
        returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);
}

interface LbrStakingPool {
    function notifyRewardAmount(uint256 amount) external;
}

interface esLBRMinter {
    function refreshReward(address user) external;
}

interface IPriceFeed {
    function fetchPrice() external returns (uint256);
}

contract Lybra is EUSD, Governable {
    uint256 public totalDepositedEther;
    uint256 public lastReportTime;
    uint256 public totalEUSDCirculation;
    uint256 year = 86400 * 365;

    uint256 public mintFeeApy = 150;
    uint256 public safeCollateralRate = 160 * 1e18;
    uint256 public immutable badCollateralRate = 150 * 1e18;
    uint256 public redemptionFee = 50;
    uint8 public keeperRate = 1;

    mapping(address => uint256) public depositedEther;
    mapping(address => uint256) borrowed;
    mapping(address => bool) redemptionProvider;
    uint256 public feeStored;

    Ilido lido = Ilido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    esLBRMinter public eslbrMinter;
    LbrStakingPool public serviceFeePool;

    event BorrowApyChanged(uint256 newApy);
    event SafeCollateralRateChanged(uint256 newRatio);
    event KeeperRateChanged(uint256 newSlippage);
    event RedemptionFeeChanged(uint256 newSlippage);
    event DepositEther(
        address sponsor,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 timestamp
    );
    event WithdrawEther(
        address sponsor,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 timestamp
    );
    event Mint(
        address sponsor,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 timestamp
    );
    event Burn(
        address sponsor,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 timestamp
    );
    event LiquidationRecord(
        address provider,
        address keeper,
        address indexed onBehalfOf,
        uint256 eusdamount,
        uint256 LiquidateEtherAmount,
        uint256 keeperReward,
        bool superLiquidation,
        uint256 timestamp
    );
    event LSDistribution(
        uint256 stETHAdded,
        uint256 payoutEUSD,
        uint256 timestamp
    );
    event RedemptionProvider(address user, bool status);
    event RigidRedemption(
        address indexed caller,
        address indexed provider,
        uint256 eusdAmount,
        uint256 etherAmount,
        uint256 timestamp
    );
    event FeeDistribution(
        address indexed feeAddress,
        uint256 feeAmount,
        uint256 timestamp
    );
    event ServiceFeePoolChanged(address pool, uint256 timestamp);
    event ESLBRMinterChanged(address pool, uint256 timestamp);

    constructor() {
        gov = msg.sender;
    }

    function setBorrowApy(uint256 newApy) external onlyGov {
        require(newApy <= 150, "Borrow APY cannot exceed 1.5%");
        _saveReport();
        mintFeeApy = newApy;
        emit BorrowApyChanged(newApy);
    }

    /**
     * @notice  safeCollateralRate can be decided by DAO,starts at 160%
     */
    function setSafeCollateralRate(uint256 newRatio) external onlyGov {
        require(
            newRatio >= 160 * 1e18,
            "Safe CollateralRate should more than 160%"
        );
        safeCollateralRate = newRatio;
        emit SafeCollateralRateChanged(newRatio);
    }

    /**
     * @notice KeeperRate can be decided by DAO,1 means 1% of revenue
     */
    function setKeeperRate(uint8 newRate) external onlyGov {
        require(newRate <= 5, "Max Keeper reward is 5%");
        keeperRate = newRate;
        emit KeeperRateChanged(newRate);
    }

    /**
     * @notice DAO sets RedemptionFee, 100 means 1%
     */
    function setRedemptionFee(uint8 newFee) external onlyGov {
        require(newFee <= 500, "Max Redemption Fee is 5%");
        redemptionFee = newFee;
        emit RedemptionFeeChanged(newFee);
    }

    function setLbrStakingPool(address addr) external onlyGov {
        serviceFeePool = LbrStakingPool(addr);
        emit ServiceFeePoolChanged(addr, block.timestamp);
    }

    function setESLBRMinter(address addr) external onlyGov {
        eslbrMinter = esLBRMinter(addr);
        emit ESLBRMinterChanged(addr, block.timestamp);
    }

    /**
     * @notice User chooses to become a Redemption Provider
     */
    function becomeRedemptionProvider(bool _bool) external {
        eslbrMinter.refreshReward(msg.sender);
        redemptionProvider[msg.sender] = _bool;
        emit RedemptionProvider(msg.sender, _bool);
    }

    /**
     * @notice Deposit ETH on behalf of an address, update the interest distribution and deposit record the this address, can mint EUSD directly
     *
     * Emits a `DepositEther` event.
     *
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `mintAmount` Send 0 if doesn't mint EUSD
     * - msg.value Must be higher than 0.
     *
     * @dev Record the deposited ETH in the ratio of 1:1 and convert it into stETH.
     */
    function depositEtherToMint(address onBehalfOf, uint256 mintAmount)
        external
        payable
    {
        require(onBehalfOf != address(0), "DEPOSIT_TO_THE_ZERO_ADDRESS");
        require(msg.value >= 1 ether, "Deposit should not be less than 1 ETH.");

        //convert to steth
        uint256 sharesAmount = lido.submit{value: msg.value}(gov);
        require(sharesAmount > 0, "ZERO_DEPOSIT");

        totalDepositedEther += msg.value;
        depositedEther[onBehalfOf] += msg.value;

        if (mintAmount > 0) {
            _mintEUSD(onBehalfOf, onBehalfOf, mintAmount);
        }

        emit DepositEther(msg.sender, onBehalfOf, msg.value, block.timestamp);
    }

    /**
     * @notice Deposit stETH on behalf of an address, update the interest distribution and deposit record the this address, can mint EUSD directly
     * Emits a `DepositEther` event.
     *
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `stETHamount` Must be higher than 0.
     * - `mintAmount` Send 0 if doesn't mint EUSD
     * @dev Record the deposited stETH in the ratio of 1:1.
     */
    function depositStETHToMint(
        address onBehalfOf,
        uint256 stETHamount,
        uint256 mintAmount
    ) external {
        require(onBehalfOf != address(0), "DEPOSIT_TO_THE_ZERO_ADDRESS");
        require(stETHamount >= 1 ether, "Deposit should not be less than 1 stETH.");
        lido.transferFrom(msg.sender, address(this), stETHamount);

        totalDepositedEther += stETHamount;
        depositedEther[onBehalfOf] += stETHamount;
        if (mintAmount > 0) {
            _mintEUSD(onBehalfOf, onBehalfOf, mintAmount);
        }
        emit DepositEther(msg.sender, onBehalfOf, stETHamount, block.timestamp);
    }

    /**
     * @notice Withdraw collateral assets to an address
     * Emits a `WithdrawEther` event.
     *
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `amount` Must be higher than 0.
     *
     * @dev Withdraw stETH. Check user’s collateral rate after withdrawal, should be higher than `safeCollateralRate`
     */
    function withdraw(address onBehalfOf, uint256 amount) external {
        require(onBehalfOf != address(0), "WITHDRAW_TO_THE_ZERO_ADDRESS");
        require(amount > 0, "ZERO_WITHDRAW");
        require(depositedEther[msg.sender] >= amount, "Insufficient Balance");
        totalDepositedEther -= amount;
        depositedEther[msg.sender] -= amount;

        lido.transfer(onBehalfOf, amount);
        if (borrowed[msg.sender] > 0) {
            _checkHealth(msg.sender);
        }
        emit WithdrawEther(msg.sender, onBehalfOf, amount, block.timestamp);
    }

    /**
     * @notice The mint amount number of EUSD is minted to the address
     * Emits a `Mint` event.
     *
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `amount` Must be higher than 0. Individual mint amount shouldn't surpass 10% when the circulation reaches 10_000_000
     */
    function mint(address onBehalfOf, uint256 amount) public {
        require(onBehalfOf != address(0), "MINT_TO_THE_ZERO_ADDRESS");
        require(amount > 0, "ZERO_MINT");
        _mintEUSD(msg.sender, onBehalfOf, amount);
        if (
            (borrowed[msg.sender] * 100) / totalSupply() > 10 &&
            totalSupply() > 10_000_000 * 1e18
        ) revert("Mint Amount cannot be more than 10% of total circulation");
    }

    /**
     * @notice Burn the amount of EUSD and payback the amount of minted EUSD
     * Emits a `Burn` event.
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `amount` Must be higher than 0.
     * @dev Calling the internal`_repay`function.
     */
    function burn(address onBehalfOf, uint256 amount) external {
        require(onBehalfOf != address(0), "BURN_TO_THE_ZERO_ADDRESS");
        _repay(msg.sender, onBehalfOf, amount);
    }

    /**
     * @notice When overallCollateralRate is above 150%, Keeper liquidates borrowers whose collateral rate is below badCollateralRate, using EUSD provided by Liquidation Provider.
     *
     * Requirements:
     * - onBehalfOf Collateral Rate should be below badCollateralRate
     * - etherAmount should be less than 50% of collateral
     * - provider should authorize Lybra to utilize EUSD
     * @dev After liquidation, borrower's debt is reduced by etherAmount * etherPrice, collateral is reduced by the etherAmount corresponding to 110% of the value. Keeper gets keeperRate / 110 of Liquidation Reward and Liquidator gets the remaining stETH.
     */
    function liquidation(
        address provider,
        address onBehalfOf,
        uint256 etherAmount
    ) external {
        uint256 etherPrice = _etherPrice();
        uint256 onBehalfOfCollateralRate = (depositedEther[onBehalfOf] *
            etherPrice *
            100) / borrowed[onBehalfOf];
        require(
            onBehalfOfCollateralRate < badCollateralRate,
            "Borrowers collateral rate should below badCollateralRate"
        );

        require(
            etherAmount * 2 <= depositedEther[onBehalfOf],
            "a max of 50% collateral can be liquidated"
        );
        uint256 eusdAmount = (etherAmount * etherPrice) / 1e18;
        require(
            allowance(provider, address(this)) >= eusdAmount,
            "provider should authorize to provide liquidation EUSD"
        );

        _repay(provider, onBehalfOf, eusdAmount);
        uint256 reducedEther = (etherAmount * 11) / 10;
        totalDepositedEther -= reducedEther;
        depositedEther[onBehalfOf] -= reducedEther;
        uint256 reward2keeper;
        if (provider == msg.sender) {
            lido.transfer(msg.sender, reducedEther);
        } else {
            reward2keeper = (reducedEther * keeperRate) / 110;
            lido.transfer(provider, reducedEther - reward2keeper);
            lido.transfer(msg.sender, reward2keeper);
        }
        emit LiquidationRecord(
            provider,
            msg.sender,
            onBehalfOf,
            eusdAmount,
            reducedEther,
            reward2keeper,
            false,
            block.timestamp
        );
    }

    /**
     * @notice When overallCollateralRate is below badCollateralRate, borrowers with collateralRate below 125% could be fully liquidated.
     * Emits a `LiquidationRecord` event.
     *
     * Requirements:
     * - Current overallCollateralRate should be below badCollateralRate
     * - `onBehalfOf`collateralRate should be below 125%
     * @dev After Liquidation, borrower's debt is reduced by etherAmount * etherPrice, deposit is reduced by etherAmount * borrower's collateralRate. Keeper gets a liquidation reward of `keeperRate / borrower's collateralRate
     */
    function superLiquidation(
        address provider,
        address onBehalfOf,
        uint256 etherAmount
    ) external {
        uint256 etherPrice = _etherPrice();
        require(
            (totalDepositedEther * etherPrice * 100) / totalSupply() <
                badCollateralRate,
            "overallCollateralRate should below 150%"
        );
        uint256 onBehalfOfCollateralRate = (depositedEther[onBehalfOf] *
            etherPrice *
            100) / borrowed[onBehalfOf];
        require(
            onBehalfOfCollateralRate < 125 * 1e18,
            "borrowers collateralRate should below 125%"
        );
        require(
            etherAmount <= depositedEther[onBehalfOf],
            "total of collateral can be liquidated at most"
        );
        uint256 eusdAmount = (etherAmount * etherPrice) / 1e18;
        if (onBehalfOfCollateralRate >= 1e20) {
            eusdAmount = (eusdAmount * 1e20) / onBehalfOfCollateralRate;
        }
        require(
            allowance(provider, address(this)) >= eusdAmount,
            "provider should authorize to provide liquidation EUSD"
        );

        _repay(provider, onBehalfOf, eusdAmount);

        totalDepositedEther -= etherAmount;
        depositedEther[onBehalfOf] -= etherAmount;
        uint256 reward2keeper;
        if (
            msg.sender != provider &&
            onBehalfOfCollateralRate >= 1e20 + keeperRate * 1e18
        ) {
            reward2keeper =
                ((etherAmount * keeperRate) * 1e18) /
                onBehalfOfCollateralRate;
            lido.transfer(msg.sender, reward2keeper);
        }
        lido.transfer(provider, etherAmount - reward2keeper);

        emit LiquidationRecord(
            provider,
            msg.sender,
            onBehalfOf,
            eusdAmount,
            etherAmount,
            reward2keeper,
            true,
            block.timestamp
        );
    }

    /**
     * @notice When stETH balance increases through LSD or other reasons, the excess income is sold for EUSD, allocated to EUSD holders through rebase mechanism.
     * Emits a `LSDistribution` event.
     *
     * *Requirements:
     * - stETH balance in the contract cannot be less than totalDepositedEther after exchange.
     * @dev Income is used to cover accumulated Service Fee first.
     */
    function excessIncomeDistribution(uint256 payAmount) external {
        uint256 payoutEther = (payAmount * 1e18) / _etherPrice();
        require(
            payoutEther <=
                lido.balanceOf(address(this)) - totalDepositedEther &&
                payoutEther > 0,
            "Only LSD excess income can be exchanged"
        );

        uint256 income = feeStored + _newFee();

        if (payAmount > income) {
            _transfer(msg.sender, address(serviceFeePool), income);
            serviceFeePool.notifyRewardAmount(income);

            uint256 sharesAmount = getSharesByMintedEUSD(payAmount - income);
            if (sharesAmount == 0) {
                //EUSD totalSupply is 0: assume that shares correspond to EUSD 1-to-1
                sharesAmount = payAmount - income;
            }
            //Income is distributed to LBR staker.
            _burnShares(msg.sender, sharesAmount);
            feeStored = 0;
            emit FeeDistribution(
                address(serviceFeePool),
                income,
                block.timestamp
            );
        } else {
            _transfer(msg.sender, address(serviceFeePool), payAmount);
            serviceFeePool.notifyRewardAmount(payAmount);
            feeStored = income - payAmount;
            emit FeeDistribution(
                address(serviceFeePool),
                payAmount,
                block.timestamp
            );
        }

        lastReportTime = block.timestamp;
        lido.transfer(msg.sender, payoutEther);

        emit LSDistribution(payoutEther, payAmount, block.timestamp);
    }

    /**
     * @notice Choose a Redemption Provider, Rigid Redeem `eusdAmount` of EUSD and get 1:1 value of stETH
     * Emits a `RigidRedemption` event.
     *
     * *Requirements:
     * - `provider` must be a Redemption Provider
     * - `provider`debt must equal to or above`eusdAmount`
     * @dev Service Fee for rigidRedemption `redemptionFee` is set to 0.5% by default, can be revised by DAO.
     */
    function rigidRedemption(address provider, uint256 eusdAmount) external {
        require(
            redemptionProvider[provider],
            "provider is not a RedemptionProvider"
        );
        require(
            borrowed[provider] >= eusdAmount,
            "eusdAmount cannot surpass providers debt"
        );
        uint256 etherPrice = _etherPrice();
        uint256 providerCollateralRate = (depositedEther[provider] *
            etherPrice *
            100) / borrowed[provider];
        require(
            providerCollateralRate >= 100 * 1e18,
            "provider's collateral rate should more than 100%"
        );
        _repay(msg.sender, provider, eusdAmount);
        uint256 etherAmount = (((eusdAmount * 1e18) / etherPrice) *
            (10000 - redemptionFee)) / 10000;
        depositedEther[provider] -= etherAmount;
        totalDepositedEther -= etherAmount;
        lido.transfer(msg.sender, etherAmount);
        emit RigidRedemption(
            msg.sender,
            provider,
            eusdAmount,
            etherAmount,
            block.timestamp
        );
    }

    /**
     * @dev Refresh LBR reward before adding providers debt. Refresh Lybra generated service fee before adding totalEUSDCirculation. Check providers collateralRate cannot below `safeCollateralRate`after minting.
     */
    function _mintEUSD(
        address _provider,
        address _onBehalfOf,
        uint256 _amount
    ) internal {
        uint256 sharesAmount = getSharesByMintedEUSD(_amount);
        if (sharesAmount == 0) {
            //EUSD totalSupply is 0: assume that shares correspond to EUSD 1-to-1
            sharesAmount = _amount;
        }
        eslbrMinter.refreshReward(_provider);
        borrowed[_provider] += _amount;

        _mintShares(_onBehalfOf, sharesAmount);

        _saveReport();
        totalEUSDCirculation += _amount;
        _checkHealth(_provider);
        emit Mint(msg.sender, _onBehalfOf, _amount, block.timestamp);
    }

    /**
     * @notice Burn _provideramount EUSD to payback minted EUSD for _onBehalfOf.
     *
     * @dev Refresh LBR reward before reducing providers debt. Refresh Lybra generated service fee before reducing totalEUSDCirculation.
     */
    function _repay(
        address _provider,
        address _onBehalfOf,
        uint256 _amount
    ) internal {
        require(
            borrowed[_onBehalfOf] >= _amount,
            "Repaying Amount Surpasses Borrowing Amount"
        );

        uint256 sharesAmount = getSharesByMintedEUSD(_amount);
        _burnShares(_provider, sharesAmount);

        eslbrMinter.refreshReward(_onBehalfOf);

        borrowed[_onBehalfOf] -= _amount;
        _saveReport();
        totalEUSDCirculation -= _amount;

        emit Burn(_provider, _onBehalfOf, _amount, block.timestamp);
    }

    function _saveReport() internal {
        feeStored += _newFee();
        lastReportTime = block.timestamp;
    }

    /**
     * @dev Get USD value of current collateral asset and minted EUSD through price oracle / Collateral asset USD value must higher than safe Collateral Rate.
     */
    function _checkHealth(address user) internal {
        if (
            ((depositedEther[user] * _etherPrice() * 100) / borrowed[user]) <
            safeCollateralRate
        ) revert("collateralRate is Below safeCollateralRate");
    }

    /**
     * @dev Return USD value of current ETH through Liquity PriceFeed Contract.
     * https://etherscan.io/address/0x4c517D4e2C851CA76d7eC94B805269Df0f2201De#code
     */
    function _etherPrice() internal returns (uint256) {
        return
            IPriceFeed(0x4c517D4e2C851CA76d7eC94B805269Df0f2201De).fetchPrice();
    }

    function _newFee() internal view returns (uint256) {
        return
            (totalEUSDCirculation *
                mintFeeApy *
                (block.timestamp - lastReportTime)) /
            year /
            10000;
    }

    /**
     * @dev total circulation of EUSD
     */
    function _getTotalMintedEUSD() internal view override returns (uint256) {
        return totalEUSDCirculation;
    }

    function getBorrowedOf(address user) external view returns (uint256) {
        return borrowed[user];
    }

    function isRedemptionProvider(address user) external view returns (bool) {
        return redemptionProvider[user];
    }
}