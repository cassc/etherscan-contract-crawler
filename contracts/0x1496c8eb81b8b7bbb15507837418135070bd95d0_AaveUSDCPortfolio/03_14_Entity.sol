//SPDX-License-Identifier: BSD 3-Clause
pragma solidity >=0.8.0;
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./lib/ReentrancyGuard.sol";

import { Registry } from  "./Registry.sol";
import { ISwapWrapper } from "./interfaces/ISwapWrapper.sol";
import { EndaomentAuth } from "./lib/auth/EndaomentAuth.sol";
import { Portfolio } from "./Portfolio.sol";
import { Math } from "./lib/Math.sol";

error EntityInactive();
error PortfolioInactive();
error InsufficientFunds();
error InvalidAction();
error BalanceMismatch();
error CallFailed(bytes response);

/**
 * @notice Entity contract inherited by Org and Fund contracts (and all future kinds of Entities).
 */
abstract contract Entity is EndaomentAuth, ReentrancyGuard {
    using Math for uint256;
    using SafeTransferLib for ERC20;

    /// @notice The base registry to which the entity is connected.
    Registry public registry;

    /// @notice The entity's manager.
    address public manager;

    // @notice The base token used for tracking the entity's fund balance.
    ERC20 public baseToken;

    /// @notice The current balance for the entity, denominated in the base token's units.
    uint256 public balance;

    /// @notice Placeholder address used in swapping method to denote usage of ETH instead of a token.
    address public constant ETH_PLACEHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Emitted when manager is set.
    event EntityManagerSet(address indexed oldManager, address indexed newManager);

    /// @notice Emitted when a donation is made.
    event EntityDonationReceived(
        address indexed from,
        address indexed to,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 amountReceived,
        uint256 amountFee
    );

    /// @notice Emitted when a payout is made from an entity.
    event EntityValuePaidOut(address indexed from, address indexed to, uint256 amountSent, uint256 amountFee);

    /// @notice Emitted when a transfer is made between entities.
    event EntityValueTransferred(address indexed from, address indexed to, uint256 amountReceived, uint256 amountFee);

    /// @notice Emitted when a base token reconciliation completes
    event EntityBalanceReconciled(address indexed entity, uint256 amountReceived, uint256 amountFee);

    /// @notice Emitted when a base token balance is used to correct the internal contract balance.
    event EntityBalanceCorrected(address indexed entity, uint256 newBalance);

    /// @notice Emitted when a portfolio deposit is made.
    event EntityDeposit(address indexed portfolio, uint256 baseTokenDeposited, uint256 sharesReceived);

    /// @notice Emitted when a portfolio share redemption is made.
    event EntityRedeem(address indexed portfolio, uint256 sharesRedeemed, uint256 baseTokenReceived);

    /**
     * @notice Modifier for methods that require auth and that the manager can access.
     * @dev Uses the same condition as `requiresAuth` but with added manager access.
     */
    modifier requiresManager {
        if(msg.sender != manager && !isAuthorized(msg.sender, msg.sig)) revert Unauthorized();
        _;
    }

    /// @notice Each entity will implement this function to allow a caller to interrogate what kind of entity it is.
    function entityType() public pure virtual returns (uint8);

    /**
     * @notice One time method to be called at deployment to configure the contract. Required so Entity
     * contracts can be deployed as minimal proxies (clones).
     * @param _registry The registry to host the Entity.
     * @param _manager The address of the Entity's manager.
     */
    function __initEntity(Registry _registry, address _manager) internal {
        // Call to EndaomentAuth's initialize function ensures that this can't be called again
        __initEndaomentAuth(_registry, bytes20(bytes.concat("entity", bytes1(entityType()))));
        __initReentrancyGuard();
        registry = _registry;
        manager = _manager;
        baseToken = _registry.baseToken();
    }

    /**
     * @notice Set a new manager for this entity.
     * @param _manager Address of new manager.
     * @dev Callable by current manager or permissioned role.
     */
    function setManager(address _manager) external virtual requiresManager {
        emit EntityManagerSet(manager, _manager);
        manager = _manager;
    }

    /**
     * @notice Receives a donated amount of base tokens to be added to the entity's balance. Transfers default fee to treasury.
     * @param _amount Amount donated in base token.
     * @dev Reverts if the donation fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function donate(uint256 _amount) external virtual {
        uint32 _feeMultiplier = registry.getDonationFee(this);
        _donateWithFeeMultiplier(_amount, _feeMultiplier);
    }

    /**
     * @notice Receives a donated amount of base tokens to be added to the entity's balance. Transfers default or overridden fee to treasury.
     * @param _amount Amount donated in base token.
     * @dev Reverts if the donation fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function donateWithOverrides(uint256 _amount) external virtual {
        uint32 _feeMultiplier = registry.getDonationFeeWithOverrides(this);
        _donateWithFeeMultiplier(_amount, _feeMultiplier);
    }

    /**
     * @notice Receives a donated amount of base tokens to be added to the entity's balance.
     * This method can be called by permissioned actors to make a donation with a manually specified fee.
     * @param _amount Amount donated in base token.
     * @param _feeOverride Fee percentage as zoc.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     */
    function donateWithAdminOverrides(uint256 _amount, uint32 _feeOverride) requiresAuth external virtual {
        _donateWithFeeMultiplier(_amount, _feeOverride);
    }

    /**
     * @notice Receives a donated amount of base tokens to be added to the entity's balance. Transfers fee calculated by fee multiplier to treasury.
     * @param _amount Amount donated in base token.
     * @param _feeMultiplier Value indicating the percentage of the Endaoment donation fee to go to the Endaoment treasury.
     * @dev Reverts if the donation fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function _donateWithFeeMultiplier(uint256 _amount, uint32 _feeMultiplier) internal virtual {

        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amount, _feeMultiplier);
        baseToken.safeTransferFrom(msg.sender, registry.treasury(), _fee);
        baseToken.safeTransferFrom(msg.sender, address(this), _netAmount);

        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            balance += _netAmount;
        }
        emit EntityDonationReceived(msg.sender, address(this), address(baseToken), _amount, _amount, _fee);
    }

    /**
     * @notice Receive a donated amount of ETH or ERC20 tokens, swaps them to base tokens, and adds the output to the
     * entity's balance. Fee calculated using default rate and sent to treasury.
     * @param _swapWrapper The swap wrapper to use for the donation. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap and donate, or ETH_PLACEHOLDER if donating ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and donated.
     * @param _data Additional call data required by the ISwapWrapper being used.
     */
    function swapAndDonate(
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) external virtual payable {
        uint32 _feeMultiplier = registry.getDonationFee(this);
        _swapAndDonateWithFeeMultiplier(_swapWrapper, _tokenIn, _amountIn, _data, _feeMultiplier);
    }

    /**
     * @notice Receive a donated amount of ETH or ERC20 tokens, swaps them to base tokens, and adds the output to the
     * entity's balance. Fee calculated using override rate and sent to treasury.
     * @param _swapWrapper The swap wrapper to use for the donation. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap and donate, or ETH_PLACEHOLDER if donating ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and donated.
     * @param _data Additional call data required by the ISwapWrapper being used.
     */
    function swapAndDonateWithOverrides(
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) external virtual payable {
        uint32 _feeMultiplier = registry.getDonationFeeWithOverrides(this);
        _swapAndDonateWithFeeMultiplier(_swapWrapper, _tokenIn, _amountIn, _data, _feeMultiplier);
    }

    /// @dev Internal helper implementing swap and donate functionality for any fee multiplier provided.
    function _swapAndDonateWithFeeMultiplier(
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data,
        uint32 _feeMultiplier
    ) nonReentrant internal virtual {
        if (!registry.isSwapperSupported(_swapWrapper)) revert InvalidAction();

        // THINK: do we need a re-entrancy guard on this method?
        if (_tokenIn != ETH_PLACEHOLDER) {
            ERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
            ERC20(_tokenIn).safeApprove(address(_swapWrapper), 0);
            ERC20(_tokenIn).safeApprove(address(_swapWrapper), _amountIn);
        }

        uint256 _amountOut = _swapWrapper.swap{value: msg.value}(
            _tokenIn,
            address(baseToken),
            address(this),
            _amountIn,
            _data
        );

        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amountOut, _feeMultiplier);

        baseToken.safeTransfer(registry.treasury(), _fee);

        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            balance += _netAmount;
        }

        if(balance > baseToken.balanceOf(address(this))) revert BalanceMismatch();

        emit EntityDonationReceived(msg.sender, address(this), _tokenIn, _amountIn, _amountOut, _fee);
    }

    /**
     * @notice Transfers an amount of base tokens from one entity to another. Transfers default fee to treasury.
     * @param _to The entity to receive the tokens.
     * @param _amount Contains the amount being donated (denominated in the base token's units).
     * @dev Reverts if the entity is inactive or if the token transfer fails.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not the entity manager or a privileged role.
     */
    function transfer(Entity _to, uint256 _amount) requiresManager external virtual {
        uint32 _feeMultiplier = registry.getTransferFee(this, _to);
        _transferWithFeeMultiplier(_to, _amount, _feeMultiplier);
    }

    /**
     * @notice Transfers an amount of base tokens from one entity to another. Transfers default or overridden fee to treasury.
     * @param _to The entity to receive the tokens.
     * @param _amount Contains the amount being donated (denominated in the base token's units).
     * @dev Reverts if the entity is inactive or if the token transfer fails.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not the entity manager or a privileged role.
     */
    function transferWithOverrides(Entity _to, uint256 _amount) requiresManager external virtual {
        uint32 _feeMultiplier = registry.getTransferFeeWithOverrides(this, _to);
        _transferWithFeeMultiplier(_to, _amount, _feeMultiplier);
    }

    /**
     * @notice Transfers an amount of base tokens from one entity to another. Transfers fee specified by a privileged role.
     * @param _to The entity to receive the tokens.
     * @param _amount Contains the amount being donated (denominated in the base token's units).
     * @param _feeOverride Admin override configured by an Admin
     * @dev Reverts if the entity is inactive or if the token transfer fails.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     */
    function transferWithAdminOverrides(Entity _to, uint256 _amount, uint32 _feeOverride) requiresAuth external virtual {
        _transferWithFeeMultiplier(_to, _amount, _feeOverride);
    }

    /**
     * @notice Transfers an amount of base tokens from one entity to another. Transfers fee calculated by fee multiplier to treasury.
     * @param _to The entity to receive the tokens.
     * @param _amount Contains the amount being donated (denominated in the base token's units).
     * @param _feeMultiplier Value indicating the percentage of the Endaoment donation fee to go to the Endaoment treasury.
     * @dev Reverts with 'Inactive' if the entity sending the transfer or the entity receiving the transfer is inactive.
     * @dev Reverts if the transfer fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not the entity manager or a privileged role.
     * @dev Reverts if the token transfer fails.
     */
    function _transferWithFeeMultiplier(Entity _to, uint256 _amount, uint32 _feeMultiplier) internal virtual {
        if (!registry.isActiveEntity(this) || !registry.isActiveEntity(_to)) revert EntityInactive();
        if (balance < _amount) revert InsufficientFunds();

        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amount, _feeMultiplier);
        baseToken.safeTransfer(registry.treasury(), _fee);
        baseToken.safeTransfer(address(_to), _netAmount);

        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            balance -= _amount;
            _to.receiveTransfer(_netAmount);
        }
        emit EntityValueTransferred(address(this), address(_to), _amount, _fee);
    }

    /**
     * @notice Updates the receiving entity balance on a transfer.
     * @param _transferAmount The amount being received on the transfer.
     * @dev This function is external, but is restricted such that it can only be called by other entities.
     */
     function receiveTransfer(uint256 _transferAmount) external virtual {
         if (!registry.isActiveEntity(Entity(msg.sender))) revert EntityInactive();
         unchecked {
             // Cannot overflow with realistic balances.
             balance += _transferAmount;
         }
     }

     /**
     * @notice Deposits an amount of Entity's `baseToken` into an Endaoment-approved Portfolio.
     * @param _portfolio An Endaoment-approved portfolio.
     * @param _amount Amount of `baseToken` to deposit into the portfolio.
     * @param _data Data required by a portfolio to deposit.
     * @return _shares Amount of portfolio share tokens Entity received as a result of this deposit.
     */
    function portfolioDeposit(Portfolio _portfolio, uint256 _amount, bytes calldata _data) external virtual requiresManager returns (uint256) {
        if(!registry.isActivePortfolio(_portfolio)) revert PortfolioInactive();
        balance -= _amount;
        baseToken.safeApprove(address(_portfolio), _amount);
        uint256 _shares = _portfolio.deposit(_amount, _data);
        emit EntityDeposit(address(_portfolio), _amount, _shares);
        return _shares;
    }

    /**
     * @notice Redeems an amount of Entity's portfolio shares for an amount of `baseToken`.
     * @param _portfolio An Endaoment-approved portfolio.
     * @param _shares Amount of share tokens to redeem.
     * @param _data Data required by a portfolio to redeem.
     * @return _received Amount of `baseToken` Entity received as a result of this redemption.
     */
    function portfolioRedeem(Portfolio _portfolio, uint256 _shares, bytes calldata _data) external virtual requiresManager returns (uint256) {
        if(!registry.isActivePortfolio(_portfolio)) revert PortfolioInactive();
        uint256 _received = _portfolio.redeem(_shares, _data);
        // unchecked: a realistic balance can never overflow a uint256
        unchecked {
            balance += _received;
        }
        emit EntityRedeem(address(_portfolio), _shares, _received);
        return _received;
    }

    /**
     * @notice This method should be called to reconcile the Entity's internal baseToken accounting with the baseToken contract's accounting.
     * There are a 2 situations where calling this method is appropriate:
     * 1. To process amounts of baseToken that arrived at this Entity through methods besides Entity:donate or Entity:transfer. For example,
     * if this Entity receives a normal ERC20 transfer of baseToken, the amount received will be unavailable for Entity use until this method
     * is called to adjust the balance and process fees. OrgFundFactory.sol:_donate makes use of this method to do this as well.
     * 2. Unusually, the Entity's perspective of balance could be lower than `baseToken.balanceOf(this)`. This could happen if
     * Entity:callAsEntity is used to transfer baseToken. In this case, this method provides a way of correcting the Entity's internal balance.
     */
    function reconcileBalance() external virtual {
        uint256 _tokenBalance = baseToken.balanceOf(address(this));

        if (_tokenBalance >= balance) {
            uint256 _sweepAmount = _tokenBalance - balance;
            uint32 _feeMultiplier = registry.getDonationFeeWithOverrides(this);
            (uint256 _netAmount, uint256 _fee) = _calculateFee(_sweepAmount, _feeMultiplier);

            baseToken.safeTransfer(registry.treasury(), _fee);
            unchecked {
                balance += _netAmount;
            }
            emit EntityBalanceReconciled(address(this), _sweepAmount, _fee);
        } else {
            // Handle abnormal scenario where _tokenBalance < balance (see method docs)
            balance = _tokenBalance;
            emit EntityBalanceCorrected(address(this), _tokenBalance);
        }
     }

    /**
     * @notice Takes stray tokens or ETH sent directly to this Entity, swaps them for base token, then adds them to the
     * Entity's balance after paying the appropriate fee to the treasury.
     * @param _swapWrapper The swap wrapper to use to convert the assets. Must be whitelisted on the Registry.
     * @param _tokenIn The address of the ERC20 token to swap, or ETH_PLACEHOLDER if ETH.
     * @param _amountIn The amount of tokens or ETH being swapped and added to the balance.
     * @param _data Additional call data required by the ISwapWrapper being used.
     */
    function swapAndReconcileBalance(
        ISwapWrapper _swapWrapper,
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata _data
    ) nonReentrant external virtual requiresManager {
        if (!registry.isSwapperSupported(_swapWrapper)) revert InvalidAction();

        uint32 _feeMultiplier = registry.getDonationFeeWithOverrides(this);

        if (_tokenIn != ETH_PLACEHOLDER) {
            ERC20(_tokenIn).safeApprove(address(_swapWrapper), 0);
            ERC20(_tokenIn).safeApprove(address(_swapWrapper), _amountIn);
        }

        // Send value only if token in is ETH
        uint256 _value = _tokenIn == ETH_PLACEHOLDER ? _amountIn : 0;

        uint256 _amountOut = _swapWrapper.swap{value: _value}(
            _tokenIn,
            address(baseToken),
            address(this),
            _amountIn,
            _data
        );

        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amountOut, _feeMultiplier);
        baseToken.safeTransfer(registry.treasury(), _fee);

        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            balance += _netAmount;
        }

        if(balance > baseToken.balanceOf(address(this))) revert BalanceMismatch();

        emit EntityBalanceReconciled(address(this), _amountOut, _fee);
    }

    /**
     * @notice Permissioned method that allows Endaoment admin to make arbitrary calls acting as this Entity.
     * @param _target The address to which the call will be made.
     * @param _value The ETH value that should be forwarded with the call.
     * @param _data The calldata that will be sent with the call.
     * @return _return The data returned by the call.
     */
    function callAsEntity(
        address _target,
        uint256 _value,
        bytes memory _data
    ) external virtual payable requiresAuth returns (bytes memory) {
        (bool _success, bytes memory _response) = payable(_target).call{value: _value}(_data);
        if (!_success) revert CallFailed(_response);
        return _response;
    }

    /**
     * @notice Pays out an amount of base tokens from the entity to an address. Transfers the fee calculated by the
     * default fee multiplier to the treasury.
     * @param _to The address to receive the tokens.
     * @param _amount Amount donated in base token.
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     * @dev Reverts if the fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function payout(address _to, uint256 _amount) external virtual requiresAuth {
        uint32 _feeMultiplier = registry.getPayoutFee(this);
        _payoutWithFeeMultiplier(_to, _amount, _feeMultiplier);
    }

    /**
     * @notice Pays out an amount of base tokens from the entity to an address. Transfers the fee calculated by the
     * default fee multiplier to the treasury.
     * @param _amount Amount donated in base token.
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     * @dev Reverts if the fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function payoutWithOverrides(address _to, uint256 _amount) external virtual requiresAuth {
        uint32 _feeMultiplier = registry.getPayoutFeeWithOverrides(this);
        _payoutWithFeeMultiplier(_to, _amount, _feeMultiplier);
    }

     /**
     * @notice Pays out an amount of base tokens from the entity to an address. Transfers fee specified by a privileged role.
     * @param _amount Amount donated in base token.
     * @param _feeOverride Payout override configured by an Admin
     * @dev Reverts with `Unauthorized` if the `msg.sender` is not a privileged role.
     * @dev Reverts if the fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     * @dev Reverts if the token transfer fails.
     */
    function payoutWithAdminOverrides(address _to, uint256 _amount, uint32 _feeOverride) external virtual requiresAuth {
        _payoutWithFeeMultiplier(_to, _amount, _feeOverride);
    }

    /**
     * @notice Pays out an amount of base tokens from the entity to an address. Transfers the fee calculated by fee multiplier to the treasury.
     * @param _to The address to receive the tokens.
     * @param _amount Contains the amount being paid out (denominated in the base token's units).
     * @param _feeMultiplier Value indicating the percentage of the Endaoment fee to go to the Endaoment treasury.
     * @dev Reverts if the token transfer fails.
     * @dev Reverts if the fee percentage is larger than 100% (equal to 1e4 when represented as a zoc).
     */
    function _payoutWithFeeMultiplier(address _to, uint256 _amount, uint32 _feeMultiplier) internal virtual {
        if (balance < _amount) revert InsufficientFunds();

        (uint256 _netAmount, uint256 _fee) = _calculateFee(_amount, _feeMultiplier);
        baseToken.safeTransfer(registry.treasury(), _fee);
        baseToken.safeTransfer(address(_to), _netAmount);

        unchecked {
            // unchecked because we've already validated that amount is less than or equal to the balance
            balance -= _amount;
        }
        emit EntityValuePaidOut(address(this), _to, _amount, _fee);
    }

    /// @dev Internal helper method to calculate the fee on a base token amount for a given fee multiplier.
    function _calculateFee(
        uint256 _amount,
        uint256 _feeMultiplier
    ) internal virtual pure returns (uint256 _netAmount, uint256 _fee) {
        if (_feeMultiplier > Math.ZOC) revert InvalidAction();
        unchecked {
            // unchecked as no possibility of overflow with baseToken precision
            _fee = _amount.zocmul(_feeMultiplier);
            // unchecked as the _feeMultiplier check with revert above protects against overflow
            _netAmount = _amount - _fee;
        }
    }
}