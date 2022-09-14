pragma solidity =0.8.13;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Timed} from "./../../utils/Timed.sol";
import {CoreRef} from "./../../refs/CoreRef.sol";
import {PCVDeposit} from "./../PCVDeposit.sol";
import {RateLimitedV2} from "./../../utils/RateLimitedV2.sol";
import {IERC20Allocator} from "./IERC20Allocator.sol";

/// @notice Contract to remove all excess funds past a target balance from a smart contract
/// and to add funds to that same smart contract when it is under the target balance.
/// First application is allocating funds from a PSM to a yield venue so that liquid reserves are minimized.
/// This contract should never hold PCV, however it has a sweep function, so if tokens get sent to it accidentally,
/// they can still be recovered.

/// This contract stores each PSM and maps it to the target balance and decimals normalizer for that token
/// PCV Deposits can then be linked to these PSM's which allows funds to be pushed and pulled
/// between these PCV deposits and their respective PSM's.
/// This design allows multiple PCV Deposits to be linked to a single PSM.

/// This contract enforces the assumption that all pcv deposits connected to a given PSM share
/// the same underlying token, otherwise the rate limited logic will not work as intended.
/// This assumption is encoded in the create and edit deposit functions as well as the
/// connect deposit function.

/// @author Elliot Friedman
contract ERC20Allocator is IERC20Allocator, CoreRef, RateLimitedV2 {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using SafeCast for *;

    /// @notice container that stores information on all psm's and their respective deposits
    struct PSMInfo {
        /// @notice target token address to send
        address token;
        /// @notice only skim if balance of target is greater than targetBalance
        /// only drip if balance of target is less than targetBalance
        uint248 targetBalance;
        /// @notice decimal normalizer to ensure buffer is updated uniformly across all deposits
        int8 decimalsNormalizer;
    }

    /// @notice map the psm address to the corresponding target balance information
    /// excess tokens past target balance will be pulled from the PSM
    /// if PSM has less than the target balance, tokens will be sent to the PSM
    mapping(address => PSMInfo) public allPSMs;

    /// @notice map the pcv deposit address to a peg stability module
    mapping(address => address) public pcvDepositToPSM;

    /// @notice ERC20 Allocator constructor
    /// @param _core Volt Core for reference
    /// @param _maxRateLimitPerSecond maximum rate limit per second that governance can set
    /// @param _rateLimitPerSecond starting rate limit per second
    /// @param _bufferCap cap on buffer size for this rate limited instance
    constructor(
        address _core,
        uint256 _maxRateLimitPerSecond,
        uint128 _rateLimitPerSecond,
        uint128 _bufferCap
    )
        CoreRef(_core)
        RateLimitedV2(_maxRateLimitPerSecond, _rateLimitPerSecond, _bufferCap)
    {}

    /// ----------- Governor Only API -----------

    /// @notice connect a new PSM
    /// @param psm Peg Stability Module to add
    /// @param targetBalance target amount of tokens for the PSM to hold
    /// @param decimalsNormalizer decimal normalizer to ensure buffer is depleted and replenished properly
    function connectPSM(
        address psm,
        uint248 targetBalance,
        int8 decimalsNormalizer
    ) external override onlyGovernor {
        address token = PCVDeposit(psm).balanceReportedIn();

        require(
            allPSMs[psm].token == address(0),
            "ERC20Allocator: cannot overwrite existing deposit"
        );

        PSMInfo memory newPSM = PSMInfo({
            token: token,
            targetBalance: targetBalance,
            decimalsNormalizer: decimalsNormalizer
        });
        allPSMs[psm] = newPSM;

        emit PSMConnected(psm, token, targetBalance, decimalsNormalizer);
    }

    /// @notice edit an existing PSM
    /// @param psm Peg Stability Module for this deposit
    /// @param targetBalance target amount of tokens for the PSM to hold
    /// cannot manually change the underlying token, as this is pulled from the PSM
    /// underlying token is immutable in both pcv deposit and
    function editPSMTargetBalance(address psm, uint248 targetBalance)
        external
        override
        onlyGovernor
    {
        address token = PCVDeposit(psm).balanceReportedIn();
        address storedToken = allPSMs[psm].token;
        require(
            storedToken != address(0),
            "ERC20Allocator: cannot edit non-existent deposit"
        );
        require(token == storedToken, "ERC20Allocator: psm changed underlying");

        PSMInfo storage psmToEdit = allPSMs[psm];
        psmToEdit.targetBalance = targetBalance;

        emit PSMTargetBalanceUpdated(psm, targetBalance);
    }

    /// @notice disconnect an existing deposit from the allocator
    /// @param psm Peg Stability Module to remove from allocation
    function disconnectPSM(address psm) external override onlyGovernor {
        delete allPSMs[psm];

        emit PSMDeleted(psm);
    }

    /// @notice function to connect deposit to a PSM
    /// this then allows the pulling of funds between the deposit and the PSM permissionlessly
    /// as defined by the target balance set in allPSM's
    /// this function does not check if the pcvDepositToPSM has already been connected
    /// as only the governor can call and create, and overwriting with the same data (no op) is fine
    /// @param psm peg stability module
    /// @param pcvDeposit deposit to connect to psm
    function connectDeposit(address psm, address pcvDeposit)
        external
        override
        onlyGovernor
    {
        address pcvToken = allPSMs[psm].token;

        /// assert pcv deposit and psm share same denomination
        require(
            PCVDeposit(pcvDeposit).balanceReportedIn() == pcvToken,
            "ERC20Allocator: token mismatch"
        );
        require(pcvToken != address(0), "ERC20Allocator: invalid underlying");

        pcvDepositToPSM[pcvDeposit] = psm;

        emit DepositConnected(psm, pcvDeposit);
    }

    /// @notice delete an existing deposit
    /// @param pcvDeposit PCV Deposit to remove connection to PSM
    function deleteDeposit(address pcvDeposit) external override onlyGovernor {
        delete pcvDepositToPSM[pcvDeposit];

        emit DepositDeleted(pcvDeposit);
    }

    /// @notice sweep target token, this shouldn't ever be needed as this contract
    /// does not hold tokens
    /// @param token to sweep
    /// @param to recipient
    /// @param amount of token to be sent
    function sweep(
        address token,
        address to,
        uint256 amount
    ) external onlyGovernor {
        IERC20(token).safeTransfer(to, amount);
    }

    /// ----------- Permissionless PCV Allocation APIs -----------

    /// @notice pull ERC20 tokens from PSM and send to PCV Deposit
    /// if the amount of tokens held in the PSM is above
    /// the target balance.
    /// @param pcvDeposit deposit to send excess funds to
    function skim(address pcvDeposit) external whenNotPaused {
        address psm = pcvDepositToPSM[pcvDeposit];
        require(psm != address(0), "ERC20Allocator: invalid PCVDeposit");

        _skim(psm, pcvDeposit);
    }

    /// helper function that does the skimming
    /// @param psm peg stability module to skim funds from
    /// @param pcvDeposit pcv deposit to send funds to
    function _skim(address psm, address pcvDeposit) internal {
        /// Check

        /// note this check is redundant, as calculating amountToPull will revert
        /// if pullThreshold is greater than the current balance of psm
        /// however, we like to err on the side of verbosity
        require(
            _checkSkimCondition(psm),
            "ERC20Allocator: skim condition not met"
        );

        (uint256 amountToSkim, uint256 adjustedAmountToSkim) = getSkimDetails(
            pcvDeposit
        );

        /// Effects

        _replenishBuffer(adjustedAmountToSkim);

        /// Interactions

        /// pull funds from pull target and send to push target
        /// automatically pulls underlying token
        PCVDeposit(psm).withdraw(pcvDeposit, amountToSkim);

        /// deposit pulled funds into the selected yield venue
        PCVDeposit(pcvDeposit).deposit();

        emit Skimmed(amountToSkim, pcvDeposit);
    }

    /// @notice push ERC20 tokens to PSM by pulling from a PCV deposit
    /// flow of funds: PCV Deposit -> PSM
    /// @param pcvDeposit to pull funds from and send to corresponding PSM
    function drip(address pcvDeposit) external whenNotPaused {
        address psm = pcvDepositToPSM[pcvDeposit];
        require(psm != address(0), "ERC20Allocator: invalid PCVDeposit");

        _drip(psm, PCVDeposit(pcvDeposit));
    }

    /// helper function that does the dripping
    /// @param psm peg stability module to drip to
    /// @param pcvDeposit pcv deposit to pull funds from
    function _drip(address psm, PCVDeposit pcvDeposit) internal {
        /// Check
        require(
            _checkDripCondition(psm, pcvDeposit),
            "ERC20Allocator: drip condition not met"
        );

        (uint256 amountToDrip, uint256 adjustedAmountToDrip) = getDripDetails(
            psm,
            pcvDeposit
        );

        /// Effects

        /// deplete buffer with adjusted amount so that it gets
        /// depleted uniformly across all assets and deposits
        _depleteBuffer(adjustedAmountToDrip);

        /// Interaction

        /// drip amount to pcvDeposit psm so that it has targetBalance amount of tokens
        pcvDeposit.withdraw(psm, amountToDrip);
        emit Dripped(amountToDrip, psm);
    }

    /// @notice does an action if any are available
    /// @param pcvDeposit whose corresponding peg stability module action will be run on
    function doAction(address pcvDeposit) external whenNotPaused {
        address psm = pcvDepositToPSM[pcvDeposit];
        require(psm != address(0), "ERC20Allocator: invalid PCVDeposit");

        /// don't check buffer != 0 as that will happen in drip function on effects
        if (_checkDripCondition(psm, PCVDeposit(pcvDeposit))) {
            _drip(psm, PCVDeposit(pcvDeposit));
        } else if (_checkSkimCondition(psm)) {
            _skim(psm, pcvDeposit);
        }
    }

    /// ----------- PURE & VIEW Only APIs -----------

    /// @notice returns the target balance for a given PSM
    function targetBalance(address psm) external view returns (uint256) {
        return allPSMs[psm].targetBalance;
    }

    /// @notice function to get the adjusted amount out
    /// @param amountToDrip the amount to adjust
    /// @param decimalsNormalizer the amount of decimals to adjust amount by
    function getAdjustedAmount(uint256 amountToDrip, int8 decimalsNormalizer)
        public
        pure
        returns (uint256 adjustedAmountToDrip)
    {
        if (decimalsNormalizer == 0) {
            adjustedAmountToDrip = amountToDrip;
        } else if (decimalsNormalizer > 0) {
            uint256 scalingFactor = 10**decimalsNormalizer.toUint256();
            adjustedAmountToDrip = amountToDrip * scalingFactor;
        } else {
            uint256 scalingFactor = 10**(-1 * decimalsNormalizer).toUint256();
            adjustedAmountToDrip = amountToDrip / scalingFactor;
        }
    }

    /// @notice return the amount that can be skimmed off a given PSM
    /// @param pcvDeposit pcv deposit whose corresponding psm will have skim amount checked
    /// returns amount that can be skimmed, adjusted amount to skim and target to send proceeds
    /// reverts if not skim eligbile
    function getSkimDetails(address pcvDeposit)
        public
        view
        returns (uint256 amountToSkim, uint256 adjustedAmountToSkim)
    {
        address psm = pcvDepositToPSM[pcvDeposit];
        PSMInfo memory toSkim = allPSMs[psm];

        address token = toSkim.token;
        /// underflows when not skim eligble and reverts
        amountToSkim = IERC20(token).balanceOf(psm) - toSkim.targetBalance;

        /// adjust amount to skim based on the decimals normalizer to replenish buffer
        adjustedAmountToSkim = getAdjustedAmount(
            amountToSkim,
            toSkim.decimalsNormalizer
        );
    }

    /// @notice return the amount that can be dripped to a given PSM
    /// @param psm peg stability module to check drip amount on
    /// @param pcvDeposit pcv deposit to drip from
    /// returns amount that can be dripped, adjusted amount to drip and target
    /// reverts if not drip eligbile
    function getDripDetails(address psm, PCVDeposit pcvDeposit)
        public
        view
        returns (uint256 amountToDrip, uint256 adjustedAmountToDrip)
    {
        PSMInfo memory toDrip = allPSMs[psm];

        /// direct balanceOf call is cheaper than calling balance on psm
        /// underflows when not drip eligble and reverts
        uint256 targetBalanceDelta = toDrip.targetBalance -
            IERC20(toDrip.token).balanceOf(psm);

        /// drip min between target drip amount and pcv deposit being pulled from
        /// to prevent edge cases when a venue runs out of liquidity
        /// only drip the lowest between amount and the buffer,
        /// as dripping more than the buffer will result in a revert in the _drip function

        /// example: usdc deposits
        /// decimal normalizer = 12
        /// target balance delta = 10,000e6
        /// pcvDeposit.balance = 5,000e6
        /// buffer = 1,000e18

        /// getAdjustedAmount(1,000e18, -12) = 1,000e6

        /// amountToDrip = 1,000e6

        amountToDrip = Math.min(
            Math.min(targetBalanceDelta, pcvDeposit.balance()),
            /// adjust for decimals here as buffer is 1e18 scaled,
            /// and if token is not scaled by 1e18, then this amountToDrip could be over the buffer
            /// because buffer is 1e18 adjusted, and decimals normalizer is used to adjust up to the buffer
            /// need to invert decimals normalizer for this to work properly
            getAdjustedAmount(buffer(), toDrip.decimalsNormalizer * -1)
        );

        /// adjust amount to drip based on the decimals normalizer to deplete buffer
        adjustedAmountToDrip = getAdjustedAmount(
            amountToDrip,
            toDrip.decimalsNormalizer
        );
    }

    /// @notice function that returns whether the amount of tokens held
    /// are below the target and funds should flow from PCV Deposit -> PSM
    /// returns false when paused
    /// @param pcvDeposit pcv deposit whose corresponding peg stability module to check drip condition
    function checkDripCondition(address pcvDeposit)
        external
        view
        override
        returns (bool)
    {
        /// if paused or buffer empty, cannot drip
        if (paused() == true || buffer() == 0) {
            return false;
        }

        address psm = pcvDepositToPSM[pcvDeposit];
        return _checkDripCondition(psm, PCVDeposit(pcvDeposit));
    }

    /// @notice function that returns whether the amount of tokens held
    /// are above the target and funds should flow from PSM -> PCV Deposit
    /// returns false when paused
    function checkSkimCondition(address pcvDeposit)
        external
        view
        override
        returns (bool)
    {
        if (paused() == true) {
            return false;
        }

        address psm = pcvDepositToPSM[pcvDeposit];
        return _checkSkimCondition(psm);
    }

    /// @notice returns whether an action is allowed
    /// returns false when paused
    function checkActionAllowed(address pcvDeposit)
        external
        view
        override
        returns (bool)
    {
        /// if paused, no actions allowed
        if (paused() == true) {
            return false;
        }

        address psm = pcvDepositToPSM[pcvDeposit];
        /// cannot drip with an empty buffer
        return
            (buffer() != 0 &&
                _checkDripCondition(psm, PCVDeposit(pcvDeposit))) ||
            _checkSkimCondition(psm);
    }

    function _checkDripCondition(address psm, PCVDeposit pcvDeposit)
        internal
        view
        returns (bool)
    {
        /// direct balanceOf call is cheaper than calling balance on psm
        /// also cannot drip if balance in underlying venue is 0
        return
            IERC20(allPSMs[psm].token).balanceOf(psm) <
            allPSMs[psm].targetBalance &&
            pcvDeposit.balance() != 0;
    }

    function _checkSkimCondition(address psm) internal view returns (bool) {
        /// direct balanceOf call is cheaper than calling balance on psm
        return
            IERC20(allPSMs[psm].token).balanceOf(psm) >
            allPSMs[psm].targetBalance;
    }
}