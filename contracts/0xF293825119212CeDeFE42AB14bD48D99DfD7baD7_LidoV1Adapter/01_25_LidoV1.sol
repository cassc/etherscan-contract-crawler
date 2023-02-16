// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
pragma abicoder v1;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AbstractAdapter } from "@gearbox-protocol/core-v2/contracts/adapters/AbstractAdapter.sol";

// INTERFACES
import { IAddressProvider } from "@gearbox-protocol/core-v2/contracts/interfaces/IAddressProvider.sol";
import { IstETH } from "../../integrations/lido/IstETH.sol";
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { ICreditManagerV2 } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditManagerV2.sol";
import { IPoolService } from "@gearbox-protocol/core-v2/contracts/interfaces/IPoolService.sol";

import { ILidoV1Adapter } from "../../interfaces/lido/ILidoV1Adapter.sol";
import { ACLTrait } from "@gearbox-protocol/core-v2/contracts/core/ACLTrait.sol";
import { LidoV1Gateway } from "./LidoV1_WETHGateway.sol";

uint256 constant LIDO_STETH_LIMIT = 20000 ether;

/// @title LidoV1 adapter
/// @dev Implements logic for interacting with the Lido contract through the gateway
contract LidoV1Adapter is
    AbstractAdapter,
    ILidoV1Adapter,
    ACLTrait,
    ReentrancyGuard
{
    /// @dev Address of the Lido contract
    address public immutable stETH;

    /// @dev Address of WETH
    address public immutable weth;

    /// @dev Address of Gearbox treasury
    address public immutable treasury;

    /// @dev The amount of WETH that can be deposited through this adapter
    uint256 public limit;

    AdapterType public constant _gearboxAdapterType = AdapterType.LIDO_V1;
    uint16 public constant _gearboxAdapterVersion = 1;

    /// @dev Constructor
    /// @param _creditManager Address of the Credit manager
    /// @param _lidoGateway Address of the Lido gateway
    constructor(address _creditManager, address _lidoGateway)
        ACLTrait(
            address(
                IPoolService(ICreditManagerV2(_creditManager).poolService())
                    .addressProvider()
            )
        )
        AbstractAdapter(_creditManager, _lidoGateway)
    {
        IAddressProvider ap = IPoolService(
            ICreditManagerV2(_creditManager).poolService()
        ).addressProvider();

        stETH = address(LidoV1Gateway(payable(_lidoGateway)).stETH()); // F:[LDOV1-1]

        weth = ap.getWethToken(); // F:[LDOV1-1]
        treasury = ap.getTreasuryContract(); // F:[LDOV1-1]
        limit = LIDO_STETH_LIMIT; // F:[LDOV1-1]
    }

    /// @dev Sends an order to stake ETH in Lido and receive stETH (sending WETH through the gateway)
    /// - Checks that the transaction isn't over the limit and decreases the limit by the amount
    /// - Executes a safe allowance fast check call to gateway's `submit`, passing the Gearbox treasury as referral
    /// @param amount The amount of ETH to deposit in Lido
    /// @notice Fast check parameters:
    /// Input token: WETH
    /// Output token: stETH
    /// Input token is allowed, since the gateway does a transferFrom for WETH
    /// The input token does not need to be disabled, because this does not spend the entire
    /// balance, generally
    function submit(uint256 amount) external returns (uint256 result) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[LDOV1-2]

        result = _submit(amount, creditAccount, false); // F:[LDOV1-3]
    }

    /// @dev Sends an order to stake ETH in Lido and receive stETH (sending all available WETH through the gateway)
    /// - Checks that the transaction isn't over the limit and decreases the limit by the amount
    /// - Executes a safe allowance fast check call to gateway's `submit`, passing the Gearbox treasury as referral
    /// @notice Fast check parameters:
    /// Input token: WETH
    /// Output token: stETH
    /// Input token is allowed, since the gateway does a transferFrom for WETH
    /// The input token does need to be disabled, because this spends the entire balance
    function submitAll() external returns (uint256 result) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[LDOV1-2]

        uint256 amount = IERC20(weth).balanceOf(creditAccount); // F:[LDOV1-4]

        if (amount > 1) {
            unchecked {
                amount--; // F:[LDOV1-4]
            }

            result = _submit(amount, creditAccount, true); // F:[LDOV1-4]
        }
    }

    function _submit(
        uint256 amount,
        address creditAccount,
        bool disableTokenIn
    ) internal returns (uint256 result) {
        if (amount > limit) revert LimitIsOverException(); // F:[LDOV1-5]

        unchecked {
            limit -= amount; // F:[LDOV1-5]
        }
        result = abi.decode(
            _safeExecuteFastCheck(
                creditAccount,
                weth,
                stETH,
                abi.encodeWithSelector(
                    LidoV1Gateway.submit.selector,
                    amount,
                    treasury
                ),
                true,
                disableTokenIn
            ),
            (uint256)
        ); // F:[LDOV1-3,4]
    }

    /// @dev Set a new deposit limit
    /// @param _limit New value for the limit
    function setLimit(uint256 _limit)
        external
        override
        configuratorOnly // F:[LDOV1-6]
    {
        limit = _limit; // F:[LDOV1-7]
        emit NewLimit(_limit); // F:[LDOV1-7]
    }

    /// @dev Get a number of shares corresponding to the specified ETH amount
    /// @param _ethAmount Amount of ETH to get shares for
    function getSharesByPooledEth(uint256 _ethAmount)
        external
        view
        returns (uint256)
    {
        return IstETH(targetContract).getSharesByPooledEth(_ethAmount);
    }

    /// @dev Get amount of ETH corresponding to the specified number of shares
    /// @param _sharesAmount Number of shares to get ETH amount for
    function getPooledEthByShares(uint256 _sharesAmount)
        external
        view
        returns (uint256)
    {
        return IstETH(targetContract).getPooledEthByShares(_sharesAmount);
    }

    /// @dev Get the total amount of ETH in Lido
    function getTotalPooledEther() external view returns (uint256) {
        return IstETH(targetContract).getTotalPooledEther();
    }

    /// @dev Get the total amount of internal shares in the stETH contract
    function getTotalShares() external view returns (uint256) {
        return IstETH(targetContract).getTotalShares();
    }

    /// @dev Get the fee taken from stETH revenue, in bp
    function getFee() external view returns (uint16) {
        return IstETH(targetContract).getFee();
    }

    /// @dev Get the number of internal stETH shares belonging to a particular account
    /// @param _account Address to get the shares for
    function sharesOf(address _account) external view returns (uint256) {
        return IstETH(targetContract).sharesOf(_account);
    }

    /// @dev Get the ERC20 token name
    function name() external view returns (string memory) {
        return IstETH(targetContract).name();
    }

    /// @dev Get the ERC20 token symbol
    function symbol() external view returns (string memory) {
        return IstETH(targetContract).symbol();
    }

    /// @dev Get the ERC20 token decimals
    function decimals() external view returns (uint8) {
        return IstETH(targetContract).decimals();
    }

    /// @dev Get ERC20 token balance for an account
    /// @param _account The address to get the balance for
    function balanceOf(address _account) external view returns (uint256) {
        return IstETH(targetContract).balanceOf(_account);
    }

    /// @dev Get ERC20 token allowance from owner to spender
    /// @param _owner The address allowing spending
    /// @param _spender The address allowed spending
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return IstETH(targetContract).allowance(_owner, _spender);
    }

    /// @dev Get ERC20 token total supply
    function totalSupply() external view returns (uint256) {
        return IstETH(targetContract).totalSupply();
    }
}