/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice Base contract inherited by Portals

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/solmate/utils/SafeTransferLib.sol";
import "../interface/IWETH.sol";
import "../interface/IPortalFactory.sol";
import "../interface/IPortalRegistry.sol";

abstract contract PortalBaseV1_1 is Ownable {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    // Active status of this contract. If false, contract is active (i.e un-paused)
    bool public paused;

    // Fee in basis points (bps)
    uint256 public fee;

    // Address of the Portal Registry
    IPortalRegistry public registry;

    // Address of the exchange used for swaps
    address public immutable exchange;

    // Address of the wrapped network token (e.g. WETH, wMATIC, wFTM, wAVAX, etc.)
    address public immutable wrappedNetworkToken;

    // Circuit breaker
    modifier pausable() {
        require(!paused, "Paused");
        _;
    }

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry _registry,
        address _exchange,
        address _wrappedNetworkToken,
        uint256 _fee
    ) {
        wrappedNetworkToken = _wrappedNetworkToken;
        setFee(_fee);
        exchange = _exchange;
        registry = _registry;
        registry.addPortal(address(this), portalType, protocolId);
        transferOwnership(registry.owner());
    }

    /// @notice Transfers tokens or the network token from the caller to this contract
    /// @param token The address of the token to transfer (address(0) if network token)
    /// @param quantity The quantity of tokens to transfer from the caller
    /// @dev quantity must == msg.value when token == address(0)
    /// @dev msg.value must == 0 when token != address(0)
    /// @return The quantity of tokens or network tokens transferred from the caller to this contract
    function _transferFromCaller(address token, uint256 quantity)
        internal
        virtual
        returns (uint256)
    {
        if (token == address(0)) {
            require(
                msg.value > 0 && msg.value == quantity,
                "Invalid quantity or msg.value"
            );

            return msg.value;
        }

        require(
            quantity > 0 && msg.value == 0,
            "Invalid quantity or msg.value"
        );

        ERC20(token).safeTransferFrom(msg.sender, address(this), quantity);

        return quantity;
    }

    /// @notice Returns the quantity of tokens or network tokens after accounting for the fee
    /// @param quantity The quantity of tokens to subtract the fee from
    /// @param feeBps The fee in basis points (BPS)
    /// @return The quantity of tokens or network tokens to transact with less the fee
    function _getFeeAmount(uint256 quantity, uint256 feeBps)
        internal
        view
        returns (uint256)
    {
        return
            registry.isPortal(msg.sender)
                ? quantity
                : quantity - (quantity * feeBps) / 10000;
    }

    /// @notice Executes swap or portal data at the target address
    /// @param sellToken The sell token
    /// @param sellAmount The quantity of sellToken (in sellToken base units) to send
    /// @param buyToken The buy token
    /// @param target The execution target for the data
    /// @param data The swap or portal data
    /// @return amountBought Quantity of buyToken acquired
    function _execute(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        address target,
        bytes memory data
    ) internal virtual returns (uint256 amountBought) {
        if (sellToken == buyToken) {
            return sellAmount;
        }

        if (sellToken == address(0) && buyToken == wrappedNetworkToken) {
            IWETH(wrappedNetworkToken).deposit{ value: sellAmount }();
            return sellAmount;
        }

        if (sellToken == wrappedNetworkToken && buyToken == address(0)) {
            IWETH(wrappedNetworkToken).withdraw(sellAmount);
            return sellAmount;
        }

        uint256 valueToSend;
        if (sellToken == address(0)) {
            valueToSend = sellAmount;
        } else {
            _approve(sellToken, target, sellAmount);
        }

        uint256 initialBalance = _getBalance(address(this), buyToken);

        require(
            target == exchange || registry.isPortal(target),
            "Unauthorized target"
        );
        (bool success, bytes memory returnData) = target.call{
            value: valueToSend
        }(data);
        require(success, string(returnData));

        amountBought = _getBalance(address(this), buyToken) - initialBalance;

        require(amountBought > 0, "Invalid execution");
    }

    /// @notice Get the token or network token balance of an account
    /// @param account The owner of the tokens or network tokens whose balance is being queried
    /// @param token The address of the token (address(0) if network token)
    /// @return The owner's token or network token balance
    function _getBalance(address account, address token)
        internal
        view
        returns (uint256)
    {
        if (token == address(0)) {
            return account.balance;
        } else {
            return ERC20(token).balanceOf(account);
        }
    }

    /// @notice Approve a token for spending with finite allowance
    /// @param token The ERC20 token to approve
    /// @param spender The spender of the token
    /// @param amount The allowance to grant to the spender
    function _approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        ERC20 _token = ERC20(token);
        _token.safeApprove(spender, 0);
        _token.safeApprove(spender, amount);
    }

    /// @notice Collects tokens or network tokens from this contract
    /// @param tokens An array of the tokens to withdraw (address(0) if network token)
    function collect(address[] calldata tokens) external {
        address collector = registry.collector();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == address(0)) {
                qty = address(this).balance;
                collector.safeTransferETH(qty);
            } else {
                qty = ERC20(tokens[i]).balanceOf(address(this));
                ERC20(tokens[i]).safeTransfer(collector, qty);
            }
        }
    }

    /// @dev Pause or unpause the contract
    function pause() external onlyOwner {
        paused = !paused;
    }

    /// @notice Sets the fee
    /// @param _fee The new fee amount between 0.06-1%
    function setFee(uint256 _fee) public onlyOwner {
        require(_fee >= 6 && _fee <= 100, "Invalid Fee");
        fee = _fee;
    }

    /// @notice Updates the registry
    /// @param _registry The address of the new registry
    function updateRegistry(IPortalRegistry _registry) external onlyOwner {
        registry = _registry;
    }

    /// @notice Reverts if networks tokens are sent directly to this contract
    receive() external payable {
        require(msg.sender != tx.origin);
    }
}