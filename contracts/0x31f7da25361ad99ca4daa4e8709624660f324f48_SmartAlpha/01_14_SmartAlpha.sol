// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "./interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./OwnableERC20.sol";
import "./interfaces/ISeniorRateModel.sol";
import "./Governed.sol";

/// @title SMART Alpha
/// @notice This contract implements the main logic of the system.
contract SmartAlpha is Governed {
    using SafeERC20 for IERC20;

    uint256 constant public scaleFactor = 10 ** 18;

    bool public initialized;

    IERC20 public poolToken;

    OwnableERC20 public juniorToken;
    OwnableERC20 public seniorToken;

    uint256 public epoch1Start;
    uint256 public epochDuration;

    /// epoch accounting
    uint256 public epoch;
    uint256 public epochSeniorLiquidity;
    uint256 public epochJuniorLiquidity;
    uint256 public epochUpsideExposureRate;
    uint256 public epochDownsideProtectionRate;
    uint256 public epochEntryPrice;

    uint256 public queuedJuniorsUnderlyingIn;
    uint256 public queuedJuniorsUnderlyingOut;
    uint256 public queuedJuniorTokensBurn;

    uint256 public queuedSeniorsUnderlyingIn;
    uint256 public queuedSeniorsUnderlyingOut;
    uint256 public queuedSeniorTokensBurn;

    /// history management
    mapping(uint256 => uint256) public history_epochJuniorTokenPrice;
    mapping(uint256 => uint256) public history_epochSeniorTokenPrice;

    // a user can have only one queue position at a time
    // if they try a new deposit while there's a queue position redeemable, it will be automatically redeemed
    struct QueuePosition {
        uint256 epoch;
        uint256 amount;
    }

    mapping(address => QueuePosition) public juniorEntryQueue;
    mapping(address => QueuePosition) public juniorExitQueue;
    mapping(address => QueuePosition) public seniorEntryQueue;
    mapping(address => QueuePosition) public seniorExitQueue;

    constructor (address _dao, address _guardian) Governed(_dao, _guardian) {}

    /// @notice Initialize the SmartAlpha system
    /// @dev Junior and Senior tokens must be owner by this contract or the function will revert.
    /// @param poolTokenAddr Address of the pool token
    /// @param oracleAddr Address of the price oracle for the pool token
    /// @param seniorRateModelAddr Address of the senior rate model (used to calculate upside exposure and downside protection rates)
    /// @param accountingModelAddr Address of the accounting model (used to determine the junior or senior losses for an epoch)
    /// @param juniorTokenAddr Address of the junior token (ERC20)
    /// @param seniorTokenAddr Address of the senior token (ERC20)
    /// @param _epoch1Start Timestamp at which the first epoch begins
    /// @param _epochDuration Duration of the epoch in seconds
    function initialize(
        address poolTokenAddr,
        address oracleAddr,
        address seniorRateModelAddr,
        address accountingModelAddr,
        address juniorTokenAddr,
        address seniorTokenAddr,
        uint256 _epoch1Start,
        uint256 _epochDuration
    ) public {
        require(!initialized, "contract already initialized");
        initialized = true;

        enforceCallerDAO();
        setPriceOracle(oracleAddr);
        setSeniorRateModel(seniorRateModelAddr);
        setAccountingModel(accountingModelAddr);

        require(poolTokenAddr != address(0), "pool token can't be 0x0");
        require(juniorTokenAddr != address(0), "junior token can't be 0x0");
        require(seniorTokenAddr != address(0), "senior token can't be 0x0");

        poolToken = IERC20(poolTokenAddr);

        juniorToken = OwnableERC20(juniorTokenAddr);
        require(juniorToken.owner() == address(this), "junior token owner must be SA");

        seniorToken = OwnableERC20(seniorTokenAddr);
        require(seniorToken.owner() == address(this), "senior token owner must be SA");

        epoch1Start = _epoch1Start;
        epochDuration = _epochDuration;
    }

    /// @notice Advance/finalize an epoch
    /// @dev Epochs are automatically advanced/finalized if there are user interactions with the contract.
    /// @dev If there are no interactions for one or multiple epochs, they will be skipped and the materializing of
    /// @dev profits and losses will only happen as if only one epoch passed. We call this "elastic epochs".
    /// @dev This function may also be called voluntarily by any party (including bots).
    function advanceEpoch() public {
        uint256 currentEpoch = getCurrentEpoch();

        if (epoch >= currentEpoch) {
            return;
        }

        // finalize the current epoch and take the fee from the side that made profits this epoch
        uint256 seniorProfits = getCurrentSeniorProfits();
        uint256 juniorProfits = getCurrentJuniorProfits();
        if (seniorProfits > 0) {
            uint256 fee = seniorProfits * feesPercentage / scaleFactor;
            epochJuniorLiquidity = epochJuniorLiquidity - seniorProfits;
            epochSeniorLiquidity = epochSeniorLiquidity + (seniorProfits - fee);
        } else if (juniorProfits > 0) {
            uint256 fee = juniorProfits * feesPercentage / scaleFactor;
            epochSeniorLiquidity = epochSeniorLiquidity - juniorProfits;
            epochJuniorLiquidity = epochJuniorLiquidity + (juniorProfits - fee);
        }

        emit EpochEnd(epoch, juniorProfits, seniorProfits);

        // set the epoch entry price to the current price, effectively resetting profits and losses to 0
        epochEntryPrice = priceOracle.getPrice();

        uint256 juniorUnderlyingOut = _processJuniorQueues();
        uint256 seniorUnderlyingOut = _processSeniorQueues();

        // move the liquidity from the entry queue to the epoch balance & the exited liquidity from the epoch to the exit queue
        epochSeniorLiquidity = epochSeniorLiquidity - seniorUnderlyingOut + queuedSeniorsUnderlyingIn;
        queuedSeniorsUnderlyingOut += seniorUnderlyingOut;
        queuedSeniorsUnderlyingIn = 0;

        epochJuniorLiquidity = epochJuniorLiquidity - juniorUnderlyingOut + queuedJuniorsUnderlyingIn;
        queuedJuniorsUnderlyingOut += juniorUnderlyingOut;
        queuedJuniorsUnderlyingIn = 0;

        // reset the queue of tokens to burn
        queuedJuniorTokensBurn = 0;
        queuedSeniorTokensBurn = 0;

        // update the upside exposure and downside protection rates based on the new pool composition (after processing the entry and exit queues)
        (epochUpsideExposureRate, epochDownsideProtectionRate) = seniorRateModel.getRates(epochJuniorLiquidity, epochSeniorLiquidity);

        // set the stored epoch to the current epoch
        epoch = currentEpoch;
    }

    /// @notice Signal the entry into the pool as a junior
    /// @dev If the user already has a position in the queue, they can increase the amount by calling this function again
    /// @dev If a user is in the queue, they cannot exit it
    /// @param amount The amount of underlying the user wants to increase his queue position with
    function depositJunior(uint256 amount) public {
        enforceSystemNotPaused();
        advanceEpoch();

        require(amount > 0, "amount must be greater than 0");
        require(poolToken.allowance(msg.sender, address(this)) >= amount, "not enough allowance");

        QueuePosition storage pos = juniorEntryQueue[msg.sender];

        // if the user already has a position for an older epoch that was not redeemed, do it automatically
        // after this operation, pos.amount would be set to 0
        if (pos.amount > 0 && pos.epoch < epoch) {
            redeemJuniorTokens();
        }

        // update the stored position's epoch to the current one
        if (pos.epoch < epoch) {
            pos.epoch = epoch;
        }

        // add the amount to the queue to be converted into junior tokens when the epoch ends
        queuedJuniorsUnderlyingIn += amount;

        uint256 newBalance = pos.amount + amount;
        pos.amount = newBalance;

        poolToken.safeTransferFrom(msg.sender, address(this), amount);

        emit JuniorJoinEntryQueue(msg.sender, epoch, amount, newBalance);
    }

    /// @notice Redeem the junior tokens generated for a user that participated in the queue at a specific epoch
    /// @dev User will receive an amount of junior tokens corresponding to his underlying balance converted at the price the epoch was finalized
    /// @dev This only works for past epochs and will revert if called for current or future epochs.
    function redeemJuniorTokens() public {
        advanceEpoch();

        QueuePosition storage pos = juniorEntryQueue[msg.sender];
        require(pos.epoch < epoch, "not redeemable yet");

        uint256 underlyingAmount = pos.amount;
        require(underlyingAmount > 0, "nothing to redeem");

        pos.amount = 0;

        uint256 price = history_epochJuniorTokenPrice[pos.epoch];
        uint256 amountJuniorTokensDue = underlyingAmount * scaleFactor / price;

        juniorToken.transfer(msg.sender, amountJuniorTokensDue);

        emit JuniorRedeemTokens(msg.sender, pos.epoch, amountJuniorTokensDue);
    }

    /// @notice Signal the entry into the pool as a senior
    /// @dev If the user already has a position in the queue, they can increase the amount by calling this function again
    /// @dev If a user is in the queue, they cannot exit it
    /// @param amount The amount of underlying the user wants to increase his queue position with
    function depositSenior(uint256 amount) public {
        enforceSystemNotPaused();
        advanceEpoch();

        require(amount > 0, "amount must be greater than 0");
        require(poolToken.allowance(msg.sender, address(this)) >= amount, "not enough allowance");

        QueuePosition storage pos = seniorEntryQueue[msg.sender];

        if (pos.amount > 0 && pos.epoch < epoch) {
            redeemSeniorTokens();
        }

        if (pos.epoch < epoch) {
            pos.epoch = epoch;
        }

        queuedSeniorsUnderlyingIn += amount;

        uint256 newBalance = pos.amount + amount;
        pos.amount = newBalance;

        poolToken.safeTransferFrom(msg.sender, address(this), amount);

        emit SeniorJoinEntryQueue(msg.sender, epoch, amount, newBalance);
    }

    /// @notice Redeem the senior tokens generated for a user that participated in the queue at a specific epoch
    /// @dev User will receive an amount of senior tokens corresponding to his underlying balance converted at the price the epoch was finalized
    /// @dev This only works for past epochs and will revert if called for current or future epochs.
    function redeemSeniorTokens() public {
        advanceEpoch();

        QueuePosition storage pos = seniorEntryQueue[msg.sender];
        require(pos.epoch < epoch, "not redeemable yet");

        uint256 underlyingAmount = pos.amount;
        require(underlyingAmount > 0, "nothing to redeem");

        pos.amount = 0;

        uint256 price = history_epochSeniorTokenPrice[pos.epoch];
        uint256 amountSeniorTokensDue = underlyingAmount * scaleFactor / price;

        seniorToken.transfer(msg.sender, amountSeniorTokensDue);

        emit SeniorRedeemTokens(msg.sender, pos.epoch, amountSeniorTokensDue);
    }

    /// @notice Signal the intention to leave the pool as a junior
    /// @dev User will join the exit queue and his junior tokens will be transferred back to the pool.
    /// @dev Their tokens will be burned when the epoch is finalized and the underlying due will be set aside.
    /// @dev Users can increase their queue amount but can't exit the queue
    /// @param amountJuniorTokens The amount of tokens the user wants to exit with
    function exitJunior(uint256 amountJuniorTokens) public {
        advanceEpoch();

        uint256 balance = juniorToken.balanceOf(msg.sender);
        require(balance >= amountJuniorTokens, "not enough balance");

        queuedJuniorTokensBurn += amountJuniorTokens;

        QueuePosition storage pos = juniorExitQueue[msg.sender];
        if (pos.amount > 0 && pos.epoch < epoch) {
            redeemJuniorUnderlying();
        }

        if (pos.epoch < epoch) {
            pos.epoch = epoch;
        }

        uint256 newBalance = pos.amount + amountJuniorTokens;
        pos.amount = newBalance;

        juniorToken.transferAsOwner(msg.sender, address(this), amountJuniorTokens);

        emit JuniorJoinExitQueue(msg.sender, epoch, amountJuniorTokens, newBalance);
    }

    /// @notice Redeem the underlying for an exited epoch
    /// @dev Only works if the user signaled the intention to exit the pool by entering the queue for that epoch.
    /// @dev Can only be called for a previous epoch and will revert for current and future epochs.
    /// @dev At this point, the junior tokens were burned by the contract and the underlying was set aside.
    function redeemJuniorUnderlying() public {
        advanceEpoch();

        QueuePosition storage pos = juniorExitQueue[msg.sender];
        require(pos.epoch < epoch, "not redeemable yet");

        uint256 juniorTokenAmount = pos.amount;
        require(juniorTokenAmount > 0, "nothing to redeem");

        pos.amount = 0;

        uint256 price = history_epochJuniorTokenPrice[pos.epoch];
        uint256 underlyingDue = juniorTokenAmount * price / scaleFactor;

        queuedJuniorsUnderlyingOut -= underlyingDue;

        poolToken.safeTransfer(msg.sender, underlyingDue);

        emit JuniorRedeemUnderlying(msg.sender, pos.epoch, underlyingDue);
    }

    /// @notice Signal the intention to leave the pool as a senior
    /// @dev User will join the exit queue and his senior tokens will be transferred back to the pool.
    /// @dev Their tokens will be burned when the epoch is finalized and the underlying due will be set aside.
    /// @dev Users can increase their queue amount but can't exit the queue
    /// @param amountSeniorTokens The amount of tokens the user wants to exit with
    function exitSenior(uint256 amountSeniorTokens) public {
        advanceEpoch();

        uint256 balance = seniorToken.balanceOf(msg.sender);
        require(balance >= amountSeniorTokens, "not enough balance");

        queuedSeniorTokensBurn += amountSeniorTokens;

        QueuePosition storage pos = seniorExitQueue[msg.sender];
        if (pos.amount > 0 && pos.epoch < epoch) {
            redeemSeniorUnderlying();
        }

        if (pos.epoch < epoch) {
            pos.epoch = epoch;
        }

        uint256 newBalance = pos.amount + amountSeniorTokens;
        pos.amount = newBalance;

        seniorToken.transferAsOwner(msg.sender, address(this), amountSeniorTokens);

        emit SeniorJoinExitQueue(msg.sender, epoch, amountSeniorTokens, newBalance);
    }

    /// @notice Redeem the underlying for an exited epoch
    /// @dev Only works if the user signaled the intention to exit the pool by entering the queue for that epoch.
    /// @dev Can only be called for a previous epoch and will revert for current and future epochs.
    /// @dev At this point, the senior tokens were burned by the contract and the underlying was set aside.
    function redeemSeniorUnderlying() public {
        advanceEpoch();

        QueuePosition storage pos = seniorExitQueue[msg.sender];
        require(pos.epoch < epoch, "not redeemable yet");

        uint256 seniorTokenAmount = pos.amount;
        require(seniorTokenAmount > 0, "nothing to redeem");

        pos.amount = 0;

        uint256 price = history_epochSeniorTokenPrice[pos.epoch];
        uint256 underlyingDue = seniorTokenAmount * price / scaleFactor;

        queuedSeniorsUnderlyingOut -= underlyingDue;

        poolToken.safeTransfer(msg.sender, underlyingDue);

        emit SeniorRedeemUnderlying(msg.sender, pos.epoch, underlyingDue);
    }

    /// @notice Transfer the accrued fees to the fees owner
    /// @dev Anyone can call but fees are transferred to fees owner. Reverts if no fees accrued.
    function transferFees() public {
        uint256 amount = feesAccrued();
        require(amount > 0, "no fees");
        require(feesOwner != address(0), "no fees owner");

        // assumption: if there are fees accrued, it means there was an owner at some point
        // since the percentage cannot be set without an owner and the owner can't be set to address(0) later
        poolToken.safeTransfer(feesOwner, amount);

        emit FeesTransfer(msg.sender, feesOwner, amount);
    }

    /// @notice Calculates the current epoch based on the start of the first epoch and the epoch duration
    /// @return The id of the current epoch
    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return (block.timestamp - epoch1Start) / epochDuration + 1;
    }

    /// @notice Calculates the junior profits based on current pool conditions
    /// @dev It always returns 0 if the price went down.
    /// @return The amount, in pool tokens, that is considered profit for the juniors
    function getCurrentJuniorProfits() public view returns (uint256) {
        uint256 currentPrice = priceOracle.getPrice();

        return accountingModel.calcJuniorProfits(
            epochEntryPrice,
            currentPrice,
            epochUpsideExposureRate,
            epochSeniorLiquidity,
            epochBalance()
        );
    }

    /// @notice Calculates the junior losses (in other words, senior profits) based on the current pool conditions
    /// @dev It always returns 0 if the price went up.
    /// @return The amount, in pool tokens, that is considered loss for the juniors
    function getCurrentSeniorProfits() public view returns (uint256) {
        uint256 currentPrice = priceOracle.getPrice();

        return accountingModel.calcSeniorProfits(
            epochEntryPrice,
            currentPrice,
            epochDownsideProtectionRate,
            epochSeniorLiquidity,
            epochBalance()
        );
    }

    /// @notice Calculate the epoch balance
    /// @return epoch balance
    function epochBalance() public view returns (uint256) {
        return epochJuniorLiquidity + epochSeniorLiquidity;
    }

    /// @notice Return the total amount of underlying in the queues
    /// @return amount of underlying in the queues
    function underlyingInQueues() public view returns (uint256) {
        return queuedJuniorsUnderlyingIn + queuedSeniorsUnderlyingIn + queuedJuniorsUnderlyingOut + queuedSeniorsUnderlyingOut;
    }

    /// @notice Calculate the total fees accrued
    /// @dev We consider fees any amount of underlying that is not accounted for in the epoch balance & queues
    function feesAccrued() public view returns (uint256) {
        return poolToken.balanceOf(address(this)) - epochBalance() - underlyingInQueues();
    }

    /// @notice Return the price of the junior token for the current epoch
    /// @dev If there's no supply, it returns 1 (scaled by scaleFactor).
    /// @dev It does not take into account the current profits and losses.
    /// @return The price of a junior token in pool tokens
    function getEpochJuniorTokenPrice() public view returns (uint256) {
        uint256 supply = juniorToken.totalSupply();

        if (supply == 0) {
            return scaleFactor;
        }

        return epochJuniorLiquidity * scaleFactor / supply;
    }

    /// @notice Return the price of the senior token for the current epoch
    /// @dev If there's no supply, it returns 1 (scaled by scaleFactor).
    /// @dev It does not take into account the current profits and losses.
    /// @return The price of a senior token in pool tokens
    function getEpochSeniorTokenPrice() public view returns (uint256) {
        uint256 supply = seniorToken.totalSupply();

        if (supply == 0) {
            return scaleFactor;
        }

        return epochSeniorLiquidity * scaleFactor / supply;
    }

    /// @notice Return the senior liquidity taking into account the current, unrealized, profits and losses
    /// @return The estimated senior liquidity
    function estimateCurrentSeniorLiquidity() public view returns (uint256) {
        uint256 seniorProfits = getCurrentSeniorProfits();
        if (seniorProfits > 0) {
            uint256 fee = seniorProfits * feesPercentage / scaleFactor;
            seniorProfits -= fee;
        }

        uint256 juniorProfits = getCurrentJuniorProfits();

        return epochSeniorLiquidity + seniorProfits - juniorProfits;
    }

    /// @notice Return the junior liquidity taking into account the current, unrealized, profits and losses
    /// @return The estimated junior liquidity
    function estimateCurrentJuniorLiquidity() public view returns (uint256) {
        uint256 seniorProfits = getCurrentSeniorProfits();

        uint256 juniorProfits = getCurrentJuniorProfits();
        if (juniorProfits > 0) {
            uint256 fee = juniorProfits * feesPercentage / scaleFactor;
            juniorProfits -= fee;
        }

        return epochJuniorLiquidity - seniorProfits + juniorProfits;
    }

    /// @notice Return the current senior token price taking into account the current, unrealized, profits and losses
    /// @return The estimated senior token price
    function estimateCurrentSeniorTokenPrice() public view returns (uint256) {
        uint256 supply = seniorToken.totalSupply();

        if (supply == 0) {
            return scaleFactor;
        }

        return estimateCurrentSeniorLiquidity() * scaleFactor / supply;
    }

    /// @notice Return the current junior token price taking into account the current, unrealized, profits and losses
    /// @return The estimated junior token price
    function estimateCurrentJuniorTokenPrice() public view returns (uint256) {
        uint256 supply = juniorToken.totalSupply();

        if (supply == 0) {
            return scaleFactor;
        }

        return estimateCurrentJuniorLiquidity() * scaleFactor / supply;
    }

    /// @notice Process the junior entry and exit queues
    /// @dev It saves the junior token price valid for the stored epoch to storage for further reference.
    /// @dev It optimizes gas usage by re-using some of the tokens it already has minted which leads to only one of the {mint, burn} actions to be executed.
    /// @dev All queued positions will be converted into junior tokens or underlying at the same price.
    /// @return The amount of underlying (pool tokens) that should be set aside
    function _processJuniorQueues() internal returns (uint256){
        uint256 juniorTokenPrice = getEpochJuniorTokenPrice();
        history_epochJuniorTokenPrice[epoch] = juniorTokenPrice;

        uint256 juniorTokensToMint = queuedJuniorsUnderlyingIn * scaleFactor / juniorTokenPrice;
        uint256 juniorTokensToBurn = queuedJuniorTokensBurn;

        uint256 juniorUnderlyingOut = juniorTokensToBurn * juniorTokenPrice / scaleFactor;

        if (juniorTokensToMint > juniorTokensToBurn) {
            uint256 diff = juniorTokensToMint - juniorTokensToBurn;
            juniorToken.mint(address(this), diff);
        } else if (juniorTokensToBurn > juniorTokensToMint) {
            uint256 diff = juniorTokensToBurn - juniorTokensToMint;
            juniorToken.burn(address(this), diff);
        } else {
            // nothing to mint or burn
        }

        return juniorUnderlyingOut;
    }

    /// @notice Process the senior entry and exit queues
    /// @dev It saves the senior token price valid for the stored epoch to storage for further reference.
    /// @dev It optimizes gas usage by re-using some of the tokens it already has minted which leads to only one of the {mint, burn} actions to be executed.
    /// @dev All queued positions will be converted into senior tokens or underlying at the same price.
    /// @return The amount of underlying (pool tokens) that should be set aside
    function _processSeniorQueues() internal returns (uint256) {
        uint256 seniorTokenPrice = getEpochSeniorTokenPrice();
        history_epochSeniorTokenPrice[epoch] = seniorTokenPrice;

        uint256 seniorTokensToMint = queuedSeniorsUnderlyingIn * scaleFactor / seniorTokenPrice;
        uint256 seniorTokensToBurn = queuedSeniorTokensBurn;

        uint256 seniorUnderlyingOut = seniorTokensToBurn * seniorTokenPrice / scaleFactor;

        if (seniorTokensToMint > seniorTokensToBurn) {
            uint256 diff = seniorTokensToMint - seniorTokensToBurn;
            seniorToken.mint(address(this), diff);
        } else if (seniorTokensToBurn > seniorTokensToMint) {
            uint256 diff = seniorTokensToBurn - seniorTokensToMint;
            seniorToken.burn(address(this), diff);
        } else {
            // nothing to mint or burn
        }

        return seniorUnderlyingOut;
    }
}