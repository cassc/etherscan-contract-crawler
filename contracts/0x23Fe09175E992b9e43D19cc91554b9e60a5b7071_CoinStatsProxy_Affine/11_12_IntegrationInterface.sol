// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

/// @title Protocol Integration Interface
abstract contract IntegrationInterface {
    /**
  @dev The function must deposit assets to the protocol.
  @param entryTokenAddress Token to be transfered to integration contract from caller
  @param entryTokenAmount Token amount to be transferes to integration contract from caller
  @param \ Pool/Vault address to deposit funds
  @param depositTokenAddress Token to be transfered to poolAddress
  @param minExitTokenAmount Min acceptable amount of liquidity/stake tokens to reeive
  @param underlyingTarget Underlying target which will execute swap
  @param targetDepositTokenAddress Token which will be used to deposit fund in target contract
  @param swapTarget Underlying target's swap target
  @param swapData Data for swap
  @param affiliate Affiliate address 
  */

    function deposit(
        address entryTokenAddress,
        uint256 entryTokenAmount,
        address,
        address depositTokenAddress,
        uint256 minExitTokenAmount,
        address underlyingTarget,
        address targetDepositTokenAddress,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable virtual;

    /**
  @dev The function must withdraw assets from the protocol.
  @param \ Pool/Vault address
  @param \ Token amount to be transferes to integration contract
  @param exitTokenAddress Specifies the token which will be send to caller
  @param minExitTokenAmount Min acceptable amount of tokens to reeive
  @param underlyingTarget Underlying target which will execute swap
  @param targetWithdrawTokenAddress Token which will be used to withdraw funds from target contract
  @param swapTarget Underlying target's swap target
  @param swapData Data for swap
  @param affiliate Affiliate address 
  */
    function withdraw(
        address,
        uint256,
        address exitTokenAddress,
        uint256 minExitTokenAmount,
        address underlyingTarget,
        address targetWithdrawTokenAddress,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable virtual;

    /**
    @dev Returns account balance
    @param \ Pool/Vault address
    @param account User account address
    @return balance Returns user current balance
   */
    function getBalance(address, address account) public view virtual returns (uint256 balance);

    /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param \ Pool/Vault address from which liquidity should be removed
    @param [Optional] Token address token to be removed
    @param amount Quantity of LP tokens to remove.
    @return The amount of token removed
  */
    function removeAssetReturn(address, address, uint256 amount) external virtual returns (uint256);
}