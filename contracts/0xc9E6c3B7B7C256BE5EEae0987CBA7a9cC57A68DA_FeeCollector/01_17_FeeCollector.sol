// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IFeeCollector.sol";
import "./interfaces/IStaking.sol";
import "./tokens/InQubeta.sol";

contract FeeCollector is IFeeCollector, AccessControl {
    using SafeERC20 for IERC20;

    struct Fee {
        uint256 Rewards; // The percentage of the total transaction amount that will be allocated to rewards
        uint256 Liquidity; // The percentage of the total transaction amount that will be allocated to liquidity
        uint256 Marketing; // The percentage of the total transaction amount that will be allocated to marketing
        uint256 Burn; // The percentage of the total transaction amount that will be burned
    }

    /// @notice Access Control InQubeta token ERC20 role hash
    bytes32 public constant INQUBETA_ROLE = keccak256("INQUBETA_ROLE");
    /// @notice Access Control InQubeta token ERC20 role hash
    bytes32 public constant ADMIN_UPDATER_ROLE =
        keccak256("ADMIN_UPDATER_ROLE");
    /// @notice Precision for mathematical calculations with percentages. 100% is equivalent to 1e21
    uint256 private constant PRECISION = 1e21;
    /// @notice Variable indicates whether the contract has been initialized
    bool public isInitialized;

    /// @notice The address of the InQubeta token
    address public immutable inQubetaToken;
    /// @notice The address of the Uniswap router contract
    address public immutable swapRouter;
    /// @notice The address where the marketing fees will be sent
    address public marketingRecipient;
    /// @notice The address of the contract responsible for staking
    address public stakingContract;
    /// @notice The value of the distribution of rewards
    uint256 public rewardsAmount;
    /// @notice The value of the liquidity distribution
    uint256 public liquidityAmount;
    /// @notice The value for transfer to marketing wallet
    uint256 public marketingAmount;
    /// @notice The value that will be burned by the token
    uint256 public burnAmount;
    /// @notice The minimum value at which liquidity percentages are within the allowed range
    uint256 public minLiquidity;
    /// @notice timestamp indicating when the current reward period ends
    uint256 public periodFinish;
    /// @notice The duration of each reward period
    uint256 public periodDuration;
    /// @notice The path to the pair token on the Uniswap exchange
    address[] public pathToPairToken;
    /// @notice Record structure before purchases
    Fee public buyFeeInfo;
    /// @notice Record structure before sell
    Fee public sellFeeInfo;

    /// ================================ Errors ================================ ///

    /// @notice An error thrown when an address doesn't have the required access level to execute a function
    error AccessIsDenied(string err);
    /// @notice An error thrown when a given address is not used for a specific operation
    error AddressNotUsed(string err);
    /// @notice An error thrown when a non-contract address is provided where a contract address is expected
    error IsNotContract(string err);
    ///@notice An error thrown when a function is passed a zero address
    error ZeroAddress(string err);
    ///@notice An error thrown when a function is passed an amount of zero
    error ZeroAmount(string err);
    /// @notice An error thrown when a function is passed a value higher than the maximum allowed
    error HighValue(string err);
    /// @notice An error thrown when a function is passed an address that is already in use
    error ExistsAddress(string err);
    /// @notice An error thrown when indicating an invalid timestamp value
    error TimeError(string err);
    //// @notice An error thrown when an attempt is made to initialize a contract that has already been initialized
    error ContractIsAlreadyInitialized(string err);
    /// @notice An error thrown when the path array has an invalid length.
    error InvalidPathLength(string err);
    /// @notice An error thrown when ETH transfer failed
    error TransferFailed(string err);

    /// ================================ Events ================================ ///

    /// Emitted when after rewards are distributed to various addresses
    event Distribute(
        uint256 rewardsAmount,
        uint256 liquidityAmount,
        uint256 marketingAmount,
        uint256 burnAmount,
        uint256 indexed timestamp
    );
    /// Emitted when after successfully updating the fee distribution
    event UpdateDistAmounts(
        bool indexed isBuyFee,
        uint256 rewardsAmount,
        uint256 liquidityAmount,
        uint256 marketingAmount,
        uint256 burnAmount,
        uint256 indexed timestamp
    );
    /// Emitted when after successfully updating the path of the token pair
    event UpdatePathToPairToken(
        address[] indexed pathToPairToken,
        uint256 indexed timestamp
    );
    /// Emitted when after successfully updating the minimum number of tokens required to collect the fee
    event UpdateMinLiquidity(uint256 minLiquidity, uint256 indexed timestamp);
    /// Emitted when after successfully updating the end time of the current period to collect the fee
    event UpdatePeriodFinish(
        uint256 newPerionFinish,
        uint256 indexed timestamp
    );
    /// Emitted when after successfully updating the duration of the commission collection period
    event UpdatePeriodDuration(
        uint256 newPerionDuration,
        uint256 indexed timestamp
    );
    /// Emitted when after successfully updating the staking contract address
    event UpdateStakingContract(
        address indexed stakingContract,
        uint256 indexed timestamp
    );
    /// Emitted when after successfully updating the marketing recipient address
    event UpdateMarketingRecipient(
        address indexed marketingRecipient,
        uint256 indexed timestamp
    );
    /// Emitted when after successfully updating the address of the contract owner
    event UpdateOwner(address newOwner, uint256 indexed timestamp);
    /// @notice Emitted when certain tokens mistakenly sent to the contract
    event RecoverERC20(
        address indexed tokenAddress,
        uint256 tokenAmount,
        address indexed recipient,
        uint256 indexed timestamp
    );
    /// @notice Emitted when transferring funds from the wallet еther of the selected token contract to the specified wallet
    event Recover(
        address indexed to,
        uint256 amount,
        uint256 indexed timestamp
    );

    constructor(
        address _owner, /// The address of the contract owner
        Fee memory _buyFeeAllocations, // The allocation of fees to various purposes for buy transactions
        Fee memory _sellFeeAccocations, // The allocation of fees to various purposes for sell transactions
        address _inqubetaToken, // The address of the InQubeta token contract
        address _uniRouter, // The address of the Uniswap router contract that will be used for swapping tokens
        address _marketingRecipient, // The address to which the marketing fees will be sent
        uint256 _minLiquidity // The minimum value at which liquidity percentages are within the allowed range
    )
        checkMaxFeeAllocations(_buyFeeAllocations)
        checkMaxFeeAllocations(_sellFeeAccocations)
    {
        if (
            !Address.isContract(_inqubetaToken) ||
            !Address.isContract(_uniRouter)
        ) {
            revert IsNotContract("Address is not a contract");
        }
        if (_owner == address(0) || _marketingRecipient == address(0)) {
            revert ZeroAddress("Zero address");
        }

        marketingRecipient = _marketingRecipient;
        buyFeeInfo = _buyFeeAllocations;
        sellFeeInfo = _sellFeeAccocations;
        inQubetaToken = _inqubetaToken;
        swapRouter = _uniRouter;
        minLiquidity = _minLiquidity;
        periodDuration = 1 days;

        _grantRole(ADMIN_UPDATER_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(INQUBETA_ROLE, _inqubetaToken);
        _makeApprove(IERC20(inQubetaToken), swapRouter);
    }

    receive() external payable {}

    /**
     * @notice The modifier checks if the sum of the four values in a Fee struct exceeds a certain precision value
     * @param _fees The sum of the four values Fee
     */
    modifier checkMaxFeeAllocations(Fee memory _fees) {
        if (
            _fees.Rewards + _fees.Liquidity + _fees.Marketing + _fees.Burn !=
            PRECISION
        ) {
            revert HighValue("Percents sum should equal precision");
        }
        _;
    }

    /**
     * @notice The modifier сhecks whether the given path of tokens is valid for swaps
     * @param path The path of tokens to be used for swaps
     */
    modifier isCheckPathToToken(address[] memory path) {
        if (path.length <= 1) {
            revert("Path must contain at least two elements");
        }
        for (uint256 i; i < path.length; i++) {
            if (!Address.isContract(path[i])) {
                revert IsNotContract("Address is not a contract");
            }
        }
        _;
    }

    /**
     * @notice The modifier checks whether the contract has been initialized
     * Prevents reinitialization
     */
    modifier isInited() {
        if (isInitialized) {
            revert ContractIsAlreadyInitialized("Already initialized");
        }
        _;
    }

    /// ================================ External functions ================================ ///

    /**
     * @notice The function initializes some contracts may not exist at the time of deploying this contract
     * @param _stakingContract The address of the staking contract
     * @param _path An array of addresses representing the path to the pair token
     */
    function initialize(
        address _stakingContract,
        address[] memory _path
    ) external onlyRole(DEFAULT_ADMIN_ROLE) isInited isCheckPathToToken(_path) {
        if (!Address.isContract(_stakingContract)) {
            revert IsNotContract("Address is not a contract");
        }

        stakingContract = _stakingContract;
        pathToPairToken = _path;
        periodFinish = block.timestamp + periodDuration;

        _makeApprove(
            IERC20(pathToPairToken[pathToPairToken.length - 1]),
            swapRouter
        );
        isInitialized = true;
    }

    /**
     * @notice External function the buy fees for the distribution period
     * @param amount Value to write
     */
    function recordBuyFee(
        uint256 amount
    ) external override onlyRole(INQUBETA_ROLE) {
        _updateDistAmounts(amount, buyFeeInfo, true);
    }

    /**
     * @notice External function the sell fees for the distribution period
     * @param amount Value to write
     */
    function recordSellFee(
        uint256 amount
    ) external override onlyRole(INQUBETA_ROLE) {
        _updateDistAmounts(amount, sellFeeInfo, false);
    }

    /**
    * @notice External function is used to distribute the collected fees,
    rewards and liquidity to the respective parties if the distribution period has ended
     */
    function distributeIfNeeded() external override {
        if (block.timestamp >= periodFinish) {
            (
                uint256 rewards,
                uint256 marketing,
                uint256 burn,
                uint256 liquidity
            ) = _distribute();

            periodFinish = block.timestamp + periodDuration;
            emit Distribute(
                rewards,
                liquidity,
                marketing,
                burn,
                block.timestamp
            );
        }
    }

    /**
     * @notice An external function that performs the approval of ERC20 tokens for Swap Router
     */
    function approveErc20ForRouter(
        address token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (token == address(0)) {
            revert ZeroAddress("Zero address");
        }
        _makeApprove(IERC20(token), swapRouter);
    }

    /**
     * @notice External function for certain tokens mistakenly sent to the contract
     * @param tokenAddress The address of the token to be rescued
     * @param tokenAmount The amount of tokens to be rescued
     * @param recipient The address to which the tokens will be sent
     */
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount,
        address recipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == inQubetaToken) {
            revert AddressNotUsed("Sending InQubeta token not allowed");
        }
        if (recipient == address(0) || tokenAddress == address(0)) {
            revert ZeroAddress("Zero address");
        }
        if (tokenAmount == 0) {
            revert ZeroAmount("Cannot rescue 0");
        }
        IERC20(tokenAddress).safeTransfer(recipient, tokenAmount);
        emit RecoverERC20(
            tokenAddress,
            tokenAmount,
            recipient,
            block.timestamp
        );
    }

    /**
     * @notice External function for tokens mistakenly sent to the contract
     * @param to The address to which the tokens will be sent
     * @param amount The amount of tokens to be rescued
     */
    function recover(
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (to == address(0)) {
            revert ZeroAddress("Zero address");
        }
        if (amount == 0) {
            revert ZeroAmount("Cannot rescue 0");
        }

        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert TransferFailed("ETH transfer failed");
        }
        emit Recover(to, amount, block.timestamp);
    }

    /**
     * @notice External function update the pair token path using the specified addresses
     * @param newPath The array of token addresses forming a pair of trades is specified in the correct order
     */
    function updatePathToPairToken(
        address[] memory newPath
    ) external onlyRole(DEFAULT_ADMIN_ROLE) isCheckPathToToken(newPath) {
        pathToPairToken = newPath;
        _makeApprove(IERC20(newPath[newPath.length - 1]), swapRouter);
        emit UpdatePathToPairToken(newPath, block.timestamp);
    }

    /**
     * @notice External function update minimum value at which liquidity percentages are within the allowed range
     * @param newMinLiquidity New value at which liquidity percentages are within the allowed range
     */
    function updateMinLiquidity(
        uint256 newMinLiquidity
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minLiquidity = newMinLiquidity;
        emit UpdateMinLiquidity(newMinLiquidity, block.timestamp);
    }

    /**
     * @notice External function update the end time of the current distribution period
     * @param newPeriodFinish The new end time for the distribution period, in Unix time
     */
    function updatePeriodFinish(
        uint256 newPeriodFinish
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newPeriodFinish < block.timestamp) {
            revert TimeError("Finish period cannot be in the past");
        }
        periodFinish = newPeriodFinish;
        emit UpdatePeriodFinish(newPeriodFinish, block.timestamp);
    }

    /**
     * @notice External function updates the duration of the distribution period for rewards and fees
     * @param newPeriodDuration The duration time for the distribution period, in Unix time
     */
    function updatePeriodDuration(
        uint256 newPeriodDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newPeriodDuration == 0) {
            revert ZeroAmount("Duration cannot that zero");
        }
        periodDuration = newPeriodDuration;
        emit UpdatePeriodDuration(newPeriodDuration, block.timestamp);
    }

    /**
     * @notice External function updates the address of the marketing recipient
     * @param newMarketingRecipient The new address of the marketing recipient
     */
    function updateMarketingRecipient(
        address newMarketingRecipient
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newMarketingRecipient == address(0)) {
            revert ZeroAddress("Zero address");
        }
        if (newMarketingRecipient == marketingRecipient) {
            revert ExistsAddress("No new address specified");
        }

        marketingRecipient = newMarketingRecipient;
        emit UpdateMarketingRecipient(newMarketingRecipient, block.timestamp);
    }

    /**
     * @notice External function updates the address the staking contract
     that is used to distribute rewards to stakers
     * @param newStakingContract The address of the new staking contract
     */
    function updateStakingContract(
        address newStakingContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!Address.isContract(newStakingContract)) {
            revert IsNotContract("Address is not a contract");
        }
        if (newStakingContract == stakingContract) {
            revert ExistsAddress("No new address specified");
        }

        stakingContract = newStakingContract;
        emit UpdateStakingContract(newStakingContract, block.timestamp);
    }

    /**
     * @notice External function update the contract owner
     * @param newOwner Address of the new contract owner
     */
    function updateOwner(
        address newOwner
    ) external onlyRole(ADMIN_UPDATER_ROLE) {
        if (newOwner == address(0)) {
            revert ZeroAddress("Zero address");
        }

        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        emit UpdateOwner(newOwner, block.timestamp);
    }

    /// ================================ Internal functions ================================ ///

    /**
    * @notice Internal function is used to distribute the collected fees,
    rewards and liquidity to the respective parties if the distribution period has ended
     */
    function _distribute()
        internal
        returns (
            uint256 rewards,
            uint256 marketing,
            uint256 burn,
            uint256 liquidity
        )
    {
        if (rewardsAmount > 0) {
            IERC20(inQubetaToken).transfer(stakingContract, rewardsAmount);
            IStaking(stakingContract).notifyRewardAmount(rewardsAmount);
            rewards = rewardsAmount;
            rewardsAmount = 0;
        }
        if (marketingAmount > 0) {
            IERC20(inQubetaToken).transfer(marketingRecipient, marketingAmount);
            marketing = marketingAmount;
            marketingAmount = 0;
        }
        if (burnAmount > 0) {
            InQubeta(inQubetaToken).burn(burnAmount);
            burn = burnAmount;
            burnAmount = 0;
        }
        if (liquidityAmount > minLiquidity) {
            uint256 processAmount = _swapAndAddLiquidity(liquidityAmount);
            liquidity = liquidityAmount - processAmount;
            liquidityAmount = processAmount;
        }
    }

    /**
    * @notice The function is intended for the distribution of fee amounts between different roles
    (the distribution of the fee is carried out according to the transferred Fee object)
    * @param amount The amount of remuneration to be distributed between different roles
     */
    function _updateDistAmounts(
        uint256 amount,
        Fee memory _fees,
        bool isBuyFee
    ) internal {
        rewardsAmount += (amount * _fees.Rewards) / PRECISION;
        liquidityAmount += (amount * _fees.Liquidity) / PRECISION;
        marketingAmount += (amount * _fees.Marketing) / PRECISION;
        burnAmount += (amount * _fees.Burn) / PRECISION;
        emit UpdateDistAmounts(
            isBuyFee,
            rewardsAmount,
            liquidityAmount,
            marketingAmount,
            burnAmount,
            block.timestamp
        );
    }

    /**
     * @notice Internal function is designed to exchange half of the transferred amount
     for a pair of tokens and add the received liquidity to the UniswapV2 pair
     * @param amount The amount of tokens to be exchanged and added to the pair
     */
    function _swapAndAddLiquidity(uint256 amount) internal returns (uint256) {
        InQubeta(inQubetaToken).disableFees();

        uint256 processAmount = amount;

        uint256[] memory amounts = IUniswapV2Router(swapRouter)
            .swapExactTokensForTokens(
                amount / 2,
                0,
                pathToPairToken,
                address(this),
                block.timestamp
            );

        processAmount -= amounts[0];

        (uint256 amountA, , ) = IUniswapV2Router(swapRouter).addLiquidity(
            pathToPairToken[0],
            pathToPairToken[pathToPairToken.length - 1],
            amounts[0],
            amounts[amounts.length - 1],
            1,
            1,
            address(this),
            block.timestamp
        );

        processAmount -= amountA;

        InQubeta(inQubetaToken).enableFees();

        return processAmount;
    }

    /**
     * @notice Internal function is intended to grant permission to spend tokens
     of the specified token to the specified manager of funds
     * @param token The interface of the ERC20 token to be authorized
     * @param spender The address to be granted
     */
    function _makeApprove(IERC20 token, address spender) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < type(uint256).max) {
            token.safeIncreaseAllowance(spender, type(uint256).max - allowance);
        }
    }
}