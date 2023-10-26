/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
 * */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./libraries/math/PayoutMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ISilicaV2_1} from "./interfaces/silica/ISilicaV2_1.sol";
import {SilicaV2_1Types} from "./libraries/SilicaV2_1Types.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SilicaV2_1Storage} from "./storage/SilicaV2_1Storage.sol";


/**
 * @title  Alkimiya AbstractSilicaV2_1
 * @author Alkimiya Team
 * @notice This is the base to be inherited & implemented by Silica contracts
 * */
abstract contract AbstractSilicaV2_1 is ERC20, Initializable, ISilicaV2_1, SilicaV2_1Storage {
    
    /*///////////////////////////////////////////////////////////////
                                 Constants
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of days between deploymentDay and firstDueDay
    uint256 internal constant DAYS_BETWEEN_DD_AND_FDD = 2;

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
            _tryDefaultContract();
        }
        _;
    }

    modifier onlyFinished() {
        if (finishDay == 0) {
            _tryFinishContract();
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

    /** 
     * @notice Initialize a new SilicaV2_1
     * @dev Sets the state of the new SilicaV2_1 clone
     * @param initializeData The struct to which to set the Silica's state
    */
    function initialize(InitializeData calldata initializeData) external initializer {
        require(
            initializeData.rewardTokenAddress != address(0) &&
                initializeData.paymentTokenAddress != address(0) &&
                initializeData.oracleRegistry != address(0) &&
                initializeData.sellerAddress != address(0),
            "Invalid Address"
        );
        require(initializeData.lastDueDay >= initializeData.dayOfDeployment + DAYS_BETWEEN_DD_AND_FDD, "Invalid lastDueDay");

        rewardToken = initializeData.rewardTokenAddress;
        paymentToken = initializeData.paymentTokenAddress;
        oracleRegistry = initializeData.oracleRegistry;

        owner = initializeData.sellerAddress;
        lastDueDay = uint32(initializeData.lastDueDay);
        firstDueDay = uint32(initializeData.dayOfDeployment + DAYS_BETWEEN_DD_AND_FDD);

        resourceAmount = initializeData.resourceAmount;

        reservedPrice = _calculateReservedPrice(
            initializeData.unitPrice,
            initializeData.lastDueDay - initializeData.dayOfDeployment - 1,
            decimals(),
            initializeData.resourceAmount
        );
        require(reservedPrice > 0, "reservedPrice = 0");

        initialCollateral = initializeData.collateralAmount;
    }

    /**
     * @notice Calculate the Reserved Price of the silica
     * @param unitPrice The price per unit 
     * @param numDeposits The number of payments to be made during contract
     * @param _decimals The number of decimals of the SilicaV2_1
     * @param _resourceAmount The quantity of the underlying resource
     */
    function _calculateReservedPrice(
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

    /// @notice Returns the status of the contract
    /// @return SilicaV2_1Types.Status The current state of the Silica
    function getStatus() public view returns (SilicaV2_1Types.Status) {
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
    /// @return bool: True is contract status is open state
    function isOpen() public view returns (bool) {
        return (_getLastIndexedDay() == firstDueDay - DAYS_BETWEEN_DD_AND_FDD);
    }

    /// @notice Check if contract is in expired state
    /// @return bool: True is contract status is expired state
    function isExpired() public view returns (bool) {
        return (defaultDay == 0 && finishDay == 0 && totalSupply() == 0 && _getLastIndexedDay() >= firstDueDay - 1);
    }

    /// @notice Check if contract is in defaulted state
    /// @return bool: True is contract status is defaulted state
    function isDefaulted() public view returns (bool) {
        return (getDayOfDefault() > 0);
    }

    /**
     * @notice Returns the day of default
     * @dev If X is returned, then the contract has paid X - firstDueDay payments. 
     * @return uint256: Day of default (if defaulted)
     * */ 
    function getDayOfDefault() public view returns (uint256) {
        
        if (finishDay > 0) revert("contract not defaulted");
        if (defaultDay > 0) return defaultDay;

        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, _getLastIndexedDay());
        uint256 numDaysRequired = lastDayContractOwesReward < firstDueDayMem ? 0 : lastDayContractOwesReward + 1 - firstDueDayMem;

        // Contract hasn't progressed enough to default
        if (numDaysRequired == 0) return 0;

        (uint256 numDays, ) = _getDaysAndRewardFulfilled(
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
    /// @dev If the contract is not defaulted, revert
    function _tryDefaultContract() internal {
        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, _getLastIndexedDay());
        uint256 numDaysRequired = lastDayContractOwesReward < firstDueDayMem ? 0 : lastDayContractOwesReward + 1 - firstDueDayMem;

        // Contract hasn't progressed enough to default
        require(numDaysRequired > 0, "Not Defaulted");

        (uint256 numDays, uint256 totalRewardDelivered) = _getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        // The rewardBalance is insufficient to cover numDaysRequired, hence defaulted
        if (numDays < numDaysRequired) {
            uint256 dayOfDefaultMem = firstDueDayMem + numDays;
            _defaultContract(dayOfDefaultMem, IERC20(rewardToken).balanceOf(address(this)), totalRewardDelivered);
        } else {
            revert("Not Defaulted");
        }
    }

    /**
     * @notice Snapshots variables necessary to perform default settlements.
     * @dev This tx should only happen once in the Silica's lifetime.
     * @param _dayOfDefault The day on which default conditions were met
     * @param silicaRewardBalance The balance of reward tokens in the Silica
     * @param _totalRewardDelivered The total amount of reward that was deilivered
     *  */  
    function _defaultContract(
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
    /// @return bool: True if the contract status is Running
    function isRunning() public view returns (bool) {
        if (!isOpen() && !isExpired() && defaultDay == 0 && finishDay == 0) {
            uint256 firstDueDayMem = firstDueDay;
            uint256 lastDueDayMem = lastDueDay;
            uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, _getLastIndexedDay());

            if (lastDayContractOwesReward < firstDueDayMem) return true;

            (uint256 numDays, ) = _getDaysAndRewardFulfilled(
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
    /// @return bool: True if the contract status is Finished
    function isFinished() public view returns (bool) {
        if (finishDay != 0) return true;

        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, _getLastIndexedDay());

        (uint256 numDays, ) = _getDaysAndRewardFulfilled(
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
    function _tryFinishContract() internal {
        uint256 firstDueDayMem = firstDueDay;
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, _getLastIndexedDay());

        (uint256 numDays, uint256 totalRewardDelivered) = _getDaysAndRewardFulfilled(
            IERC20(rewardToken).balanceOf(address(this)),
            firstDueDayMem,
            lastDayContractOwesReward
        );

        if (numDays == lastDueDayMem + 1 - firstDueDayMem) {
            // Set finishDay to non-zero value. Subsequent calls to onlyFinished functions should skip this function all together
            _finishContract(lastDueDayMem, IERC20(rewardToken).balanceOf(address(this)), totalRewardDelivered);
        } else {
            revert("Not Finished");
        }
    }

    /// @notice Snapshots variables necessary to perform settlements
    /// @dev This tx should only happen once in the Silica's lifetime
    /// @param _finishDay Day on which the contract finish conditions were met
    /// @param silicaRewardBalance The reward token balance of the Silica
    /// @param _totalRewardDelivered The amount of reward which was deilivered
    function _finishContract(
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

    /// @notice Function to get the last day fulfilled and reward delivered
    /// @return lastDayFulfilled The final day on which rewards were deilvered
    /// @return rewardDelivered The amount of balance of the reward token that has been deilvered by the seller
    function getDaysAndRewardFulfilled() external view returns (uint256 lastDayFulfilled, uint256 rewardDelivered) {
        uint256 lastDueDayMem = lastDueDay;
        uint256 lastIndexedDayMem = _getLastIndexedDay();
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDayMem, lastIndexedDayMem);

        uint256 rewardFulfilled = rewardDelivered == 0 ? IERC20(rewardToken).balanceOf(address(this)) : rewardDelivered;
        return _getDaysAndRewardFulfilled(rewardFulfilled, firstDueDay, lastDayContractOwesReward);
    }

    /// @notice Returns the number of days N fulfilled by this contract, as well as the reward delivered for all N days
    /// @param  _rewardBalance Reward token balance
    /// @param _firstDueDay Day from which reward deposits have been required
    /// @param _lastDayContractOwesReward Final day reward deposits are due
    /// @return lastDayFulfilled The final day on which rewards were deilvered
    /// @return rewardDelivered The amount of balance of the reward token that has been deilvered by the seller
    function _getDaysAndRewardFulfilled(
        uint256 _rewardBalance,
        uint256 _firstDueDay,
        uint256 _lastDayContractOwesReward
    ) internal view returns (uint256 lastDayFulfilled, uint256 rewardDelivered) {
        if (_lastDayContractOwesReward < _firstDueDay) {
            return (0, 0); 
        }

        uint256 totalDue;

        uint256[] memory rewardDueArray = _getRewardDueInRange(_firstDueDay, _lastDayContractOwesReward);
        for (uint256 i; i < rewardDueArray.length; ) {
            uint256 curDay = _firstDueDay + i;

            if (_rewardBalance < totalDue + rewardDueArray[i] + _getCollateralLocked(curDay)) {
                return (i, totalDue + _getCollateralLocked(curDay));
            }
            totalDue += rewardDueArray[i];

            unchecked {
                ++i;
            }
        }

        // Otherwise, contract delivered up to last day that it owes reward
        return (rewardDueArray.length, totalDue + _getCollateralLocked(_lastDayContractOwesReward));
    }

    /*///////////////////////////////////////////////////////////////
                    Contract settlement and updates
    //////////////////////////////////////////////////////////////*/

    /// @notice Function returns the accumulative rewards delivered
    /// @return uint256: Accumulative rewards delivered
    function getRewardDeliveredSoFar() external view returns (uint256) {
        if (rewardDelivered == 0) {
            (, uint256 totalRewardDelivered) = _getDaysAndRewardFulfilled(
                IERC20(rewardToken).balanceOf(address(this)),
                firstDueDay,
                getLastDayContractOwesReward(lastDueDay, _getLastIndexedDay())
            );
            return totalRewardDelivered;
        } else {
            return rewardDelivered;
        }
    }

    /// @notice Function returns the last day contract needs to deliver rewards
    /// @param _lastDueDay The Final day reward deposits are due
    /// @param lastIndexedDay The most recent day that has oracle data
    /// @return uint256: The last day reward deposits are due
    function getLastDayContractOwesReward(uint256 _lastDueDay, uint256 lastIndexedDay) public pure returns (uint256) {
        // Silica always owes up to DayX-1 in rewards
        return lastIndexedDay - 1 <= _lastDueDay ? lastIndexedDay - 1 : _lastDueDay;
    }

    /// @notice Function returns the Collateral Locked on the day inputed
    /// @param  day The day for which to query the collateral value
    /// @return uint256: Collateral Locked on the day inputed
    function _getCollateralLocked(uint256 day) internal view returns (uint256) {
        uint256 firstDueDayMem = firstDueDay;
        uint256 initialCollateralAfterRelease = _getInitialCollateralAfterRelease();
        if (day <= firstDueDayMem) {
            return initialCollateralAfterRelease;
        }

        (uint256 initCollateralReleaseDay, uint256 finalCollateralReleaseDay) = _getCollateralUnlockDays(firstDueDayMem);

        if (day >= finalCollateralReleaseDay) {
            return (0);
        }
        if (day >= initCollateralReleaseDay) {
            return ((initialCollateralAfterRelease * 3) / 4);
        }
        return (initialCollateralAfterRelease);
    }

    /// @notice Function that calculate the collateral based on purchased amount after contract starts
    function _getInitialCollateralAfterRelease() internal view returns (uint256) {
        return (totalSupply() * initialCollateral) / resourceAmount;
    }

    /// @notice Function that calculates the dates collateral gets partial release
    /// @param _firstDueDay The first day on which reward deposits were required
    /// @return initCollateralReleaseDay The first day collateral is released
    /// @return finalCollateralReleaseDay The last day collateral is released 
    function _getCollateralUnlockDays(uint256 _firstDueDay)
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
    /// @return rewardDueNextOracleUpdate Reward amount due to be deposited at next Oracle write operation
    function getRewardDueNextOracleUpdate() external view returns (uint256 rewardDueNextOracleUpdate) {

        if (finishDay > 0 || defaultDay > 0) return 0;

        uint256 nextIndexedDay = _getLastIndexedDay() + 1;
        uint256 firstDueDayMem = firstDueDay;
        if (nextIndexedDay < firstDueDayMem) {
            return (0);
        }
        uint256 lastDayContractOwesReward = getLastDayContractOwesReward(lastDueDay, nextIndexedDay);
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        uint256[] memory rewardDueArray = _getRewardDueInRange(firstDueDayMem, lastDayContractOwesReward);
        uint256 totalDue;
        uint256 balanceNeeded;

        for (uint256 i; i < rewardDueArray.length;) {
            uint256 curDay = firstDueDayMem + i;
            totalDue += rewardDueArray[i];

            if (balanceNeeded < totalDue + _getCollateralLocked(curDay)) {
                balanceNeeded = totalDue + _getCollateralLocked(curDay);
            }

            unchecked {
                ++i;
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
     * @param amountSpecified The amount to deposit
     * @return mintAmount The amount of Silica tokens that were minted
     */
    function deposit(uint256 amountSpecified) external onlyOpen returns (uint256 mintAmount) {
        require(amountSpecified > 0, "Invalid Value");

        mintAmount = _deposit(msg.sender, msg.sender, totalSupply(), amountSpecified);
        _mint(msg.sender, mintAmount);
    }

    /**
     * @notice Processes a buyer's upfront payment to purchase hashpower/staking using paymentTokens.
     * Silica is minted proportional to purchaseAmount and transfered to the address specified _to.
     * @dev Confirms the buyer's payment, mint the Silicas and transfer the tokens.
     * @param _to The address to send the minted Silica to
     * @param amountSpecified The amount to deposit
     * @return mintAmount The amount of Silica tokens that were minted
     */
    function proxyDeposit(address _to, uint256 amountSpecified) external onlyOpen returns (uint256 mintAmount) {
        require(_to != address(0), "Invalid Address");
        require(amountSpecified > 0, "Invalid Value");

        mintAmount = _deposit(msg.sender, _to, totalSupply(), amountSpecified);
        _mint(_to, mintAmount);
    }

    /// @notice Internal function to process buyer's deposit
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param _totalSupply Current amount of Silica
    /// @param amountSpecified The amount to transfer
    /// @return mintAmount The amount of Silica tokens minted
    function _deposit(
        address from,
        address to,
        uint256 _totalSupply,
        uint256 amountSpecified
    ) internal returns (uint256 mintAmount) {
        mintAmount = _getMintAmount(resourceAmount, amountSpecified, reservedPrice);

        require(_totalSupply + mintAmount <= resourceAmount, "Insufficient Supply");

        emit Deposit(to, amountSpecified, mintAmount);

        _transferPaymentTokenFrom(from, address(this), amountSpecified);
    }

    /// @notice Function that returns the minted Silica amount from purchase amount
    /// @param consensusResource The amount ofunderlying resource of the contract
    /// @param purchaseAmount The amount purchased
    /// @param _reservedPrice The calculated rerserved price, see _calculateReservedPrice()
    function _getMintAmount(
        uint256 consensusResource,
        uint256 purchaseAmount,
        uint256 _reservedPrice
    ) internal pure returns (uint256) {
        return (consensusResource * purchaseAmount) / _reservedPrice;
    }

    /// @notice Internal function to safely transfer payment token
    /// @param from The sender address
    /// @param to The recipient address
    /// @param amount The amount of payment token to transfer
    function _transferPaymentTokenFrom(
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(paymentToken), from, to, amount);
    }

    /// @notice Function that buyer calls to collect reward when silica is finished
    function buyerCollectPayout() external onlyFinished onlyBuyers returns (uint256 rewardPayout) {
        uint256 buyerBalance = balanceOf(msg.sender);

        _burn(msg.sender, buyerBalance);

        return _transferBuyerPayoutOnFinish(msg.sender, buyerBalance);
    }

    /// @notice Internal function to process rewards to Buyer when contract is Finished
    /// @dev    Uses PayoutMath library
    /// @param  buyerAddress The address of the resource buyer
    /// @param  buyerBalance The amount of Silica the buyer holds
    /// @param  rewardPayout The amount of reward token send to the buyer
    function _transferBuyerPayoutOnFinish(address buyerAddress, uint256 buyerBalance) internal returns (uint256 rewardPayout) {
        rewardPayout = PayoutMath._getBuyerRewardPayout(rewardDelivered, buyerBalance, resourceAmount);

        emit BuyerCollectPayout(rewardPayout, 0, buyerAddress, buyerBalance);

        _transferRewardToken(buyerAddress, rewardPayout);
    }

    /// @notice Internal function to safely transfer rewards to Buyer
    /// @param  to The address of the recipient of the reward tokens
    /// @param  amount The number of reward tokens to send 
    function _transferRewardToken(address to, uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(rewardToken), to, amount);
    }

    /// @notice Function that buyer calls to settle defaulted contract
    /// @dev    This function can only be called by the buyers when the contract is in the defaulted state
    /// @return rewardPayout The amount of reward tokens sent to buyer
    /// @return paymentPayout The amount of payment tokens sent to buyer
    function buyerCollectPayoutOnDefault()
        external
        onlyDefaulted
        onlyBuyers
        returns (uint256 rewardPayout, uint256 paymentPayout)
    {
        uint256 buyerBalance = balanceOf(msg.sender);

        _burn(msg.sender, buyerBalance);

        return _transferBuyerPayoutOnDefault(msg.sender, buyerBalance);
    }

    /// @notice Internal funtion to process rewards and payment return to Buyer when contract is default
    /// @return rewardPayout The amount of reward tokens sent to buyer
    /// @return paymentPayout The amount of payment tokens sent to buyer
    function _transferBuyerPayoutOnDefault(address buyerAddress, uint256 buyerBalance)
        internal
        returns (uint256 rewardPayout, uint256 paymentPayout)
    {
        rewardPayout = PayoutMath._getRewardTokenPayoutToBuyerOnDefault(buyerBalance, rewardDelivered, resourceAmount); //rewardDelivered in the case of a default represents the rewardTokenBalance of the contract at default

        uint256 firstDueDayMem = firstDueDay;
        uint256 numOfDepositsRequired = lastDueDay + 1 - firstDueDayMem;

        paymentPayout = PayoutMath._getPaymentTokenPayoutToBuyerOnDefault(
            buyerBalance,
            totalUpfrontPayment,
            resourceAmount,
            PayoutMath._getHaircut(defaultDay - firstDueDayMem, numOfDepositsRequired)
        );

        emit BuyerCollectPayout(rewardPayout, paymentPayout, buyerAddress, buyerBalance);

        _transferRewardToken(buyerAddress, rewardPayout);

        if (paymentPayout > 0) {
            _transferPaymentToken(buyerAddress, paymentPayout);
        }
    }

    /// @notice Internal funtion to safely transfer payment return to Buyer
    /// @param to The address of the recipient of the payment token transfer
    /// @param amount The amount of payment tokens to transfer to the to address
    function _transferPaymentToken(address to, uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(paymentToken), to, amount);
    }

    /// @notice Gets the owner of silica
    function getOwner() external view override returns (address) {
        return owner;
    }

    /// @notice Gets reward token address
    function getRewardToken() external view override returns (address) {
        return address(rewardToken);
    }

    /// @notice Gets the Payment token address
    function getPaymentToken() external view override returns (address) {
        return address(paymentToken);
    }

    /// @notice Returns the last day of reward the seller is selling with this contract
    /// @return uint32: The last day of reward the seller is selling with this contract
    function getLastDueDay() external view override returns (uint32) {
        return lastDueDay;
    }

    /// @notice Function seller calls to settle finished silica
    /// @dev    Only the owner(seller) can call this function when the contract is in the finished state
    /// @dev    This function can only be called once
    /// @return paymentTokenPayout The nunber of payment tokens transferred to the seller address
    /// @return rewardTokenExcess The number of reward tokens left in the contract transferred to the seller address
    function sellerCollectPayout()
        external
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

    /// @notice Function seller calls to settle defaulted contract
    /// @dev    Only the owner(seller) can call this function when the contract is in the defaulted state
    /// @dev    This function can only be called once
    /// @return paymentTokenPayout The nunber of payment tokens transferred to the seller address
    /// @return rewardTokenExcess The number of reward tokens left in the contract transferred to the seller address
    function sellerCollectPayoutDefault()
        external
        onlyOwner
        onlyDefaulted
        onlyOnePayout
        returns (uint256 paymentTokenPayout, uint256 rewardTokenExcess)
    {
        uint256 firstDueDayMem = firstDueDay;
        uint256 numOfDepositsRequired = lastDueDay + 1 - firstDueDayMem;
        uint256 haircut = PayoutMath._getHaircut(defaultDay - firstDueDayMem, numOfDepositsRequired);
        paymentTokenPayout = PayoutMath._getRewardPayoutToSellerOnDefault(totalUpfrontPayment, haircut);
        rewardTokenExcess = rewardExcess;

        emit SellerCollectPayout(paymentTokenPayout, rewardTokenExcess);
        _transferPaymentToSeller(paymentTokenPayout);
        if (rewardTokenExcess > 0) {
            _transferRewardToSeller(rewardTokenExcess);
        }
    }

    /// @notice Function seller calls to settle expired contract
    /// @dev    only the owner(seller) can call this function when the contract is in the expired state
    /// @dev This function can only be called once
    /// @return rewardTokenPayout The nunber of payment tokens transferred to the seller address
    function sellerCollectPayoutExpired() external onlyExpired onlyOwner returns (uint256 rewardTokenPayout) {
        rewardTokenPayout = IERC20(rewardToken).balanceOf(address(this));

        _transferRewardToSeller(rewardTokenPayout);
        emit SellerCollectPayout(0, rewardTokenPayout);
    }

    /// @notice Internal funtion to safely transfer payment to Seller
    /// @param  amount The number of payment tokens to transfer to Seller
    function _transferPaymentToSeller(uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(paymentToken), owner, amount);
    }

    /// @notice Internal funtion to safely transfer excess reward to Seller
    /// @param  amount The number of reward tokens to transfer to Seller
    function _transferRewardToSeller(uint256 amount) internal {
        SafeERC20.safeTransfer(IERC20(rewardToken), owner, amount);
    }

    /// @notice Function to return the reward due on a given day
    /// @dev    This function is to be overridden by derived Silica contracts
    /// @param _day The day to query the reward due on 
    function _getRewardDueOnDay(uint256 _day) internal view virtual returns (uint256);

    /// @notice Function to return the last day silica is synced with Oracle
    /// @dev    This function is to be overridden by derived Silica contracts
    /// @return uint32: Last day for which there is Oracle data
    function _getLastIndexedDay() internal view virtual returns (uint32);

    /// @notice Function to return total rewards due between _firstday (inclusive) and _lastday (inclusive)
    /// @dev    This function is to be overridden by derived Silica contracts
    /// @param _firstDay The start day to query from
    /// @param _lastDay The end day to query until 
    function _getRewardDueInRange(uint256 _firstDay, uint256 _lastDay) internal view virtual returns (uint256[] memory);

    /// @notice Function to return contract reserved price
    /// @return uint256: The reserved price 
    function getReservedPrice() external view returns (uint256) {
        return reservedPrice;
    }
}