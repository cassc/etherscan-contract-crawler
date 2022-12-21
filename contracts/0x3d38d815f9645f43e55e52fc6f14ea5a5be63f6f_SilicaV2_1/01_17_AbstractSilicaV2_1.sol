// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ISilicaV2_1} from "./interfaces/silica/ISilicaV2_1.sol";
import {SilicaV2_1Storage} from "./storage/SilicaV2_1Storage.sol";
import {SilicaV2_1Types} from "./libraries/SilicaV2_1Types.sol";

import "./libraries/math/PayoutMath.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract AbstractSilicaV2_1 is ERC20, Initializable, ISilicaV2_1, SilicaV2_1Storage {
    /*///////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of days between deploymentDay and firstDueDay
    uint8 internal constant DAYS_BETWEEN_DD_AND_FDD = 2;

    /*///////////////////////////////////////////////////////////////
                                 Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier onlyBuyers() {
        require(balanceOf(msg.sender) != 0, "Not Buyer");
        _;
    }

    modifier onlyOpen() {
        require(isOpen(), "Not Open");
        _;
    }

    modifier onlyExpired() {
        require(isExpired(), "Not Expired");
        _;
    }

    modifier onlyDefaulted() {
        if (defaultDay == 0) {
            tryDefaultContract();
        }
        _;
    }

    modifier onlyFinished() {
        if (finishDay == 0) {
            tryFinishContract();
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyOnePayout() {
        require(!didSellerCollectPayout, "Payout already collected");
        didSellerCollectPayout = true;
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                 Initializer
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize a new SilicaV2_1
    function initialize(InitializeData calldata initializeData) external override initializer {
        _initializeAddresses(
            initializeData.rewardTokenAddress,
            initializeData.paymentTokenAddress,
            initializeData.oracleRegistry,
            initializeData.sellerAddress
        );
        _initializeSilicaState(initializeData.dayOfDeployment, initializeData.lastDueDay);

        resourceAmount = initializeData.resourceAmount;

        reservedPrice = calculateReservedPrice(
            initializeData.unitPrice,
            initializeData.lastDueDay - initializeData.dayOfDeployment - 1,
            decimals(),
            initializeData.resourceAmount
        );
        require(reservedPrice > 0, "reservedPrice = 0");

        initialCollateral = initializeData.collateralAmount;
    }

    /// @notice Set the reward token address, payment token address, oracle Registery address and
    ///         seller address in this Silica
    /// @notice Owner of this silica is the seller
    function _initializeAddresses(
        address rewardTokenAddress,
        address paymentTokenAddress,
        address oracleRegistryAddress,
        address sellerAddress
    ) internal {
        require(
            rewardTokenAddress != address(0) &&
                paymentTokenAddress != address(0) &&
                oracleRegistryAddress != address(0) &&
                sellerAddress != address(0),
            "Invalid Address"
        );

        rewardToken = rewardTokenAddress;
        paymentToken = paymentTokenAddress;
        oracleRegistry = oracleRegistryAddress;
        owner = sellerAddress;
    }

    /// @notice Set last due day and first due day of the Silica contract when contract starts
    /// @dev last due day should always be after first due day
    function _initializeSilicaState(uint256 dayOfDeployment, uint256 _lastDueDay) internal {
        require(_lastDueDay >= dayOfDeployment + DAYS_BETWEEN_DD_AND_FDD, "Invalid lastDueDay");

        lastDueDay = uint32(_lastDueDay);
        firstDueDay = uint32(dayOfDeployment + DAYS_BETWEEN_DD_AND_FDD);
    }

    /// @notice Calculate the Reserved Price of the silica
    function calculateReservedPrice(
        uint256 unitPrice,
        uint256 numDeposits,
        uint256 _decimals,
        uint256 _resourceAmount
    ) internal pure returns (uint256) {
        return (unitPrice * _resourceAmount * numDeposits) / (10**_decimals);
    }

    /*///////////////////////////////////////////////////////////////
                                 Contract states
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the status of the contract
    function getStatus() public view override returns (SilicaV2_1Types.Status) {
        if (isOpen()) {
            return SilicaV2_1Types.Status.Open;
        } else if (isExpired()) {
            return SilicaV2_1Types.Status.Expired;
        } else if (isRunning()) {
            return SilicaV2_1Types.Status.Running;
        } else if (finishDay > 0 || isFinished()) {
            return SilicaV2_1Types.Status.Finished;
        } else if (defaultDay > 0 || isDefaulted()) {
            return SilicaV2_1Types.Status.Defaulted;
        }
    }

    /// @notice Check if contract is in open state
    function isOpen() public view override returns (bool) {
        return (getLastIndexedDay() == firstDueDay - DAYS_BETWEEN_DD_AND_FDD);
    }

    /// @notice Check if contract is in expired state
    function isExpired() public view override returns (bool) {
        return (defaultDay == 0 && finishDay == 0 && totalSupply() == 0 && getLastIndexedDay() >= firstDueDay - 1);
    }

    /// @notice Check if contract is in defaulted state
    function isDefaulted() public view override returns (bool) {
        return (getDayOfDefault() > 0);
    }

    /// @notice Returns the day of default. If X is returned, then the contract has paid X - firstDueDay payments.
    function getDayOfDefault() public view override returns (uint256) {
        if (defaultDay > 0) return defaultDay;

        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, getLastIndexedDay());
        uint256 numDaysRequired = lastDayContractOwesReward < firstDueDayMem ? 0 : lastDayContractOwesReward + 1 - firstDueDayMem;

        // Contract hasn't progressed enough to default
        if (numDaysRequired == 0) return 0;

        (uint256 numDays, ) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        // The rewardBalance is insufficient to cover numDaysRequired, hence defaulted
        if (numDays < numDaysRequired) {
            return firstDueDayMem + numDays;
        } else {
            return 0;
        }
    }

    /// @notice Function to set a contract as default
    ///         If the contract is not defaulted, revert
    function tryDefaultContract() internal {
        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, getLastIndexedDay());
        uint256 numDaysRequired = lastDayContractOwesReward < firstDueDayMem ? 0 : lastDayContractOwesReward + 1 - firstDueDayMem;

        // Contract hasn't progressed enough to default
        require(numDaysRequired > 0, "Not Defaulted");

        (uint256 numDays, uint256 totalRewardDelivered) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        // The rewardBalance is insufficient to cover numDaysRequired, hence defaulted
        if (numDays < numDaysRequired) {
            uint256 dayOfDefaultMem = firstDueDayMem + numDays;
            defaultContract(dayOfDefaultMem, IERC20(rewardToken).balanceOf(address(this)), totalRewardDelivered);
        } else {
            revert("Not Defaulted");
        }
    }

    /// @notice Snapshots variables necessary to perform default settlements.
    /// @dev This tx should only happen once in the Silica's lifetime.
    function defaultContract(
        uint256 _dayOfDefault,
        uint256 silicaRewardBalance,
        uint256 _totalRewardDelivered
    ) internal {
        if (silicaRewardBalance > _totalRewardDelivered) {
            rewardExcess = silicaRewardBalance - _totalRewardDelivered;
        }
        defaultDay = uint32(_dayOfDefault);
        rewardDelivered = _totalRewardDelivered;
        resourceAmount = totalSupply();
        totalUpfrontPayment = IERC20(paymentToken).balanceOf(address(this));

        emit StatusChanged(SilicaV2_1Types.Status.Defaulted);
    }

    /// @notice Check if the contract is in running state
    function isRunning() public view override returns (bool) {
        if (!isOpen() && !isExpired() && defaultDay == 0 && finishDay == 0) {
            uint256 firstDueDayMem = firstDueDay;
            uint256 lastDueDayMem = lastDueDay;
            uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, getLastIndexedDay());

            if (lastDayContractOwesReward < firstDueDayMem) return true;

            (uint256 numDays, ) = getDaysAndRewardFulfilled(
                IERC20(rewardToken).balanceOf(address(this)),
                firstDueDayMem,
                lastDayContractOwesReward
            );

            uint256 contractDurationDays = lastDayContractOwesReward + 1 - firstDueDayMem;
            uint256 maxContractDurationDays = lastDueDayMem + 1 - firstDueDayMem;

            // For contracts that progressed GE firstDueDay
            // Contract is running if it's progressed as far as it can, but not finished
            return numDays == contractDurationDays && numDays != maxContractDurationDays;
        } else {
            return false;
        }
    }

    /// @notice Check if contract is in finished state
    function isFinished() public view override returns (bool) {
        if (finishDay != 0) return true;

        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, getLastIndexedDay());

        (uint256 numDays, ) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        if (numDays == lastDueDayMem + 1 - firstDueDayMem) {
            return true;
        }
        return false;
    }

    /// @notice Function to set a contract status as Finished
    /// @dev If the contract hasn't finished, revert
    function tryFinishContract() internal {
        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, getLastIndexedDay());

        (uint256 numDays, uint256 totalRewardDelivered) = getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        if (numDays == lastDueDayMem + 1 - firstDueDayMem) {
            // Set finishDay to non-zero value. Subsequent calls to onlyFinished functions should skip this function all together
            finishContract(lastDueDayMem, IERC20(rewardToken).balanceOf(address(this)), totalRewardDelivered);
        } else {
            revert("Not Finished");
        }
    }

    /// @notice Snapshots variables necessary to perform settlements.
    /// @dev This tx should only happen once in the Silica's lifetime.
    function finishContract(
        uint256 _finishDay,
        uint256 silicaRewardBalance,
        uint256 _totalRewardDelivered
    ) internal {
        if (silicaRewardBalance > _totalRewardDelivered) {
            rewardExcess = silicaRewardBalance - _totalRewardDelivered;
        }

        finishDay = uint32(_finishDay);
        rewardDelivered = _totalRewardDelivered;
        resourceAmount = totalSupply();

        emit StatusChanged(SilicaV2_1Types.Status.Finished);
    }

    function getDaysAndRewardFulfilled() external view returns (uint256 lastDayFulfilled, uint256 rewardDelivered) {
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastIndexedDayMem = getLastIndexedDay();
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, lastIndexedDayMem);

        uint256 rewardFulfilled = rewardDelivered == 0 ? IERC20(rewardToken).balanceOf(address(this)) : rewardDelivered;
        return getDaysAndRewardFulfilled(rewardFulfilled, firstDueDay, lastDayContractOwesReward);
    }

    /// @notice Returns the number of days N fulfilled by this contract, as well as the reward delivered for all N days
    function getDaysAndRewardFulfilled(
        uint256 _rewardBalance,
        uint256 _firstDueDay,
        uint256 _lastDayContractOwesReward
    ) internal view returns (uint256 lastDayFulfilled, uint256 rewardDelivered) {
        if (_lastDayContractOwesReward < _firstDueDay) {
            return (0, 0); //@ATTN: include collateral
        }

        uint256 totalDue;

        uint256[] memory rewardDueArray = getRewardDueInRange(_firstDueDay, _lastDayContractOwesReward);
        for (uint256 i = 0; i < rewardDueArray.length; i++) {
            uint256 curDay = _firstDueDay + i;

            if (_rewardBalance < totalDue + rewardDueArray[i] + getCollateralLocked(curDay)) {
                return (i, totalDue + getCollateralLocked(curDay));
            }
            totalDue += rewardDueArray[i];
        }

        // Otherwise, contract delivered up to last day that it owes reward
        return (rewardDueArray.length, totalDue + getCollateralLocked(_lastDayContractOwesReward));
    }

    /*///////////////////////////////////////////////////////////////
                            Contract settlement and updates
    //////////////////////////////////////////////////////////////*/

    /// @notice Function returns the accumulative rewards delivered
    function getRewardDeliveredSoFar() external view override returns (uint256) {
        if (rewardDelivered == 0) {
            (, uint256 totalRewardDelivered) = getDaysAndRewardFulfilled(
                IERC20(rewardToken).balanceOf(address(this)),
                firstDueDay,
                getLastDayContractOwesReward(lastDueDay, getLastIndexedDay())
            );
            return totalRewardDelivered;
        } else {
            return rewardDelivered;
        }
    }

    /// @notice Function returns the last day contract needs to deliver rewards
    function getLastDayContractOwesReward(uint256 _lastDueDay, uint256 lastIndexedDay) public pure override returns (uint256) {
        // Silica always owes up to DayX-1 in rewards
        return lastIndexedDay - 1 <= _lastDueDay ? lastIndexedDay - 1 : _lastDueDay;
    }

    /// @notice Function returns the Collateral Locked on the day inputed
    function getCollateralLocked(uint256 day) internal view returns (uint256) {
        uint256 firstDueDayMem = firstDueDay;
        uint256 initialCollateralAfterRelease = getInitialCollateralAfterRelease();
        if (day <= firstDueDayMem) {
            return initialCollateralAfterRelease;
        }

        (uint256 initCollateralReleaseDay, uint256 finalCollateralReleaseDay) = getCollateralUnlockDays(firstDueDayMem);

        if (day >= finalCollateralReleaseDay) {
            return (0);
        }
        if (day >= initCollateralReleaseDay) {
            return ((initialCollateralAfterRelease * 3) / 4);
        }
        return (initialCollateralAfterRelease);
    }

    /// @notice Function that calculate the collateral based on purchased amount after contract starts
    function getInitialCollateralAfterRelease() internal view returns (uint256) {
        return ((totalSupply() * initialCollateral) / resourceAmount);
    }

    /// @notice Function that calculates the dates collateral gets partial release
    function getCollateralUnlockDays(uint256 _firstDueDay)
        internal
        view
        returns (uint256 initCollateralReleaseDay, uint256 finalCollateralReleaseDay)
    {
        uint256 numDeposits = lastDueDay + 1 - _firstDueDay;

        initCollateralReleaseDay = numDeposits % 4 > 0 ? _firstDueDay + 1 + (numDeposits / 4) : _firstDueDay + (numDeposits / 4);
        finalCollateralReleaseDay = numDeposits % 2 > 0 ? _firstDueDay + 1 + (numDeposits / 2) : _firstDueDay + (numDeposits / 2);

        if (numDeposits == 2) {
            finalCollateralReleaseDay += 1;
        }
    }

    /// @notice Function returns the rewards amount the seller needs deliver for next Oracle update
    function getRewardDueNextOracleUpdate() external view override returns (uint256 rewardDueNextOracleUpdate) {
        uint256 nextIndexedDay = getLastIndexedDay() + 1;
        uint256 firstDueDayMem = firstDueDay;
        if (nextIndexedDay < firstDueDayMem) {
            return (0);
        }
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, nextIndexedDay);
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        uint256[] memory rewardDueArray = getRewardDueInRange(firstDueDayMem, lastDayContractOwesReward);
        uint256 totalDue;
        uint256 balanceNeeded;

        for (uint256 i = 0; i < rewardDueArray.length; i++) {
            uint256 curDay = firstDueDayMem + i;
            totalDue += rewardDueArray[i];

            if (balanceNeeded < totalDue + getCollateralLocked(curDay)) {
                balanceNeeded = totalDue + getCollateralLocked(curDay);
            }
        }

        if (balanceNeeded <= rewardBalance) {
            return 0;
        } else {
            return (balanceNeeded - rewardBalance);
        }
    }

    /**
     * @notice Processes a buyer's upfront payment to purchase hashpower/staking using paymentTokens.
     * Silica is minted proportional to purchaseAmount and transfered to buyer.
     * @dev confirms the buyer's payment, mint the Silicas and transfer the tokens.
     */
    function deposit(uint256 amountSpecified) external override onlyOpen returns (uint256 mintAmount) {
        require(amountSpecified > 0, "Invalid Value");

        mintAmount = _deposit(msg.sender, msg.sender, totalSupply(), amountSpecified);
        _mint(msg.sender, mintAmount);
    }

    /**
     * @notice Processes a buyer's upfront payment to purchase hashpower/staking using paymentTokens.
     * Silica is minted proportional to purchaseAmount and transfered to the address specified _to.
     * @dev confirms the buyer's payment, mint the Silicas and transfer the tokens.
     */
    function proxyDeposit(address _to, uint256 amountSpecified) external override onlyOpen returns (uint256 mintAmount) {
        require(_to != address(0), "Invalid Address");
        require(amountSpecified > 0, "Invalid Value");

        mintAmount = _deposit(msg.sender, _to, totalSupply(), amountSpecified);
        _mint(_to, mintAmount);
    }

    /// @notice Internal function to process buyer's deposit
    function _deposit(
        address from,
        address to,
        uint256 _totalSupply,
        uint256 amountSpecified
    ) internal returns (uint256 mintAmount) {
        mintAmount = getMintAmount(resourceAmount, amountSpecified, reservedPrice);

        require(_totalSupply + mintAmount <= resourceAmount, "Insufficient Supply");

        emit Deposit(to, amountSpecified, mintAmount);

        _transferPaymentTokenFrom(from, address(this), amountSpecified);
    }

    /// @notice Function that returns the minted Silica amount from purchase amount
    function getMintAmount(
        uint256 consensusResource,
        uint256 purchaseAmount,
        uint256 _reservedPrice
    ) internal pure returns (uint256) {
        return (consensusResource * purchaseAmount) / _reservedPrice;
    }

    /// @notice Internal function to safely transfer payment token
    function _transferPaymentTokenFrom(
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(paymentToken), from, to, amount);
    }

    /// @notice Function that buyer calls to collect reward when silica is finished
    function buyerCollectPayout() external override onlyFinished onlyBuyers returns (uint256 rewardPayout) {
        uint256 buyerBalance = balanceOf(msg.sender);

        _burn(msg.sender, buyerBalance);

        return _transferBuyerPayoutOnFinish(msg.sender, buyerBalance);
    }

    /// @notice Internal function to process rewards to Buyer when contract is Finished
    function _transferBuyerPayoutOnFinish(address buyerAddress, uint256 buyerBalance) internal returns (uint256 rewardPayout) {
        rewardPayout = PayoutMath.getBuyerRewardPayout(rewardDelivered, buyerBalance, resourceAmount);

        emit BuyerCollectPayout(rewardPayout, 0, buyerAddress, buyerBalance);

        _transferRewardToken(buyerAddress, rewardPayout);
    }

    /// @notice Internal function to safely transfer rewards to Buyer
    function _transferRewardToken(address to, uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(rewardToken), to, amount);
    }

    /// @notice Function that buyer calls to settle defaulted contract
    function buyerCollectPayoutOnDefault()
        external
        override
        onlyDefaulted
        onlyBuyers
        returns (uint256 rewardPayout, uint256 paymentPayout)
    {
        uint256 buyerBalance = balanceOf(msg.sender);

        _burn(msg.sender, buyerBalance);

        return _transferBuyerPayoutOnDefault(msg.sender, buyerBalance);
    }

    /// @notice Internal funtion to process rewards and payment return to Buyer when contract is default
    function _transferBuyerPayoutOnDefault(address buyerAddress, uint256 buyerBalance)
        internal
        returns (uint256 rewardPayout, uint256 paymentPayout)
    {
        rewardPayout = PayoutMath.getRewardTokenPayoutToBuyerOnDefault(buyerBalance, rewardDelivered, resourceAmount); //rewardDelivered in the case of a default represents the rewardTokenBalance of the contract at default

        uint256 firstDueDayMem = firstDueDay;
        uint256 numOfDepositsRequired = lastDueDay + 1 - firstDueDayMem;

        paymentPayout = PayoutMath.getPaymentTokenPayoutToBuyerOnDefault(
            buyerBalance,
            totalUpfrontPayment,
            resourceAmount,
            PayoutMath.getHaircut(defaultDay - firstDueDayMem, numOfDepositsRequired)
        );

        emit BuyerCollectPayout(rewardPayout, paymentPayout, buyerAddress, buyerBalance);

        _transferRewardToken(buyerAddress, rewardPayout);

        if (paymentPayout > 0) {
            _transferPaymentToken(buyerAddress, paymentPayout);
        }
    }

    /// @notice Internal funtion to safely transfer payment return to Buyer
    function _transferPaymentToken(address to, uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(paymentToken), to, amount);
    }

    /// @notice Gets the owner of silica
    function getOwner() external view override returns (address) {
        return owner;
    }

    /// @notice Gets reward type
    function getRewardToken() external view override returns (address) {
        return address(rewardToken);
    }

    /// @notice Gets the Payment type
    function getPaymentToken() external view override returns (address) {
        return address(paymentToken);
    }

    /// @notice Returns the last day of reward the seller is selling with this contract
    /// @return The last day of reward the seller is selling with this contract
    function getLastDueDay() external view override returns (uint32) {
        return lastDueDay;
    }

    /// @notice Function seller calls to settle finished silica
    function sellerCollectPayout()
        external
        override
        onlyOwner
        onlyFinished
        onlyOnePayout
        returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess)
    {
        paymentTokenPayout = IERC20(paymentToken).balanceOf(address(this));
        rewardTokenExcess = rewardExcess;

        emit SellerCollectPayout(paymentTokenPayout, rewardTokenExcess);
        _transferPaymentToSeller(paymentTokenPayout);
        if (rewardTokenExcess > 0) {
            _transferRewardToSeller(rewardTokenExcess);
        }
    }

    /// @notice Function seller calls to settle default contract
    function sellerCollectPayoutDefault()
        external
        override
        onlyOwner
        onlyDefaulted
        onlyOnePayout
        returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess)
    {
        uint256 firstDueDayMem = firstDueDay;
        uint256 numOfDepositsRequired = lastDueDay + 1 - firstDueDayMem;
        uint256 haircut = PayoutMath.getHaircut(defaultDay - firstDueDayMem, numOfDepositsRequired);
        paymentTokenPayout = PayoutMath.getRewardPayoutToSellerOnDefault(totalUpfrontPayment, haircut);
        rewardTokenExcess = rewardExcess;

        emit SellerCollectPayout(paymentTokenPayout, rewardTokenExcess);
        _transferPaymentToSeller(paymentTokenPayout);
        if (rewardTokenExcess > 0) {
            _transferRewardToSeller(rewardTokenExcess);
        }
    }

    /// @notice Function seller calls to settle when contract is
    function sellerCollectPayoutExpired() external override onlyExpired onlyOwner returns (uint256 rewardTokenPayout) {
        rewardTokenPayout = IERC20(rewardToken).balanceOf(address(this));

        _transferRewardToSeller(rewardTokenPayout);
        emit SellerCollectPayout(0, rewardTokenPayout);
    }

    /// @notice Internal funtion to safely transfer payment to Seller
    function _transferPaymentToSeller(uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(paymentToken), owner, amount);
    }

    /// @notice Internal funtion to safely transfer excess reward to Seller
    function _transferRewardToSeller(uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(rewardToken), owner, amount);
    }

    /// @notice Function to return the reward due on a given day
    function getRewardDueOnDay(uint256 _day) internal view virtual returns (uint256);

    /// @notice Function to return the last day silica is synced with Oracle
    function getLastIndexedDay() internal view virtual returns (uint32);

    /// @notice Function to return total rewards due between _firstday (inclusive) and _lastday (inclusive)
    function getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view virtual returns (uint256[] memory);

    /// @notice Function to return contract reserved price
    function getReservedPrice() external view override returns (uint256) {
        return reservedPrice;
    }
}