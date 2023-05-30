// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.9;

import "./base/CoinStatsBaseV1.sol";
import "../integrationInterface/IntegrationInterface.sol";

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

interface ILidoStakingContract {
  function submit(address _referral) external payable returns (uint256);
}

contract LidoIntegration is IntegrationInterface, CoinStatsBaseV1 {
  using SafeERC20 for IERC20;

  ILidoStakingContract public lidoStakingContract;

  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  event Deposit(
    address indexed from,
    address indexed pool,
    uint256 poolTokensReceived,
    address affiliate
  );

  event Withdraw(
    address indexed from,
    address indexed pool,
    uint256 poolTokensReceived,
    address affiliate
  );

  constructor(
    address _lidoStakingContract,
    uint256 _goodwill,
    uint256 _affiliateSplit,
    address _vaultAddress
  ) CoinStatsBaseV1(_goodwill, _affiliateSplit, _vaultAddress) {
    lidoStakingContract = ILidoStakingContract(_lidoStakingContract);

    // 0x exchange
    approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
  }

  /**
    @notice Returns pools total supply
    @param stakingAddress Lido Staking Contract address from which to get supply
   */
  function getTotalSupply(address stakingAddress)
    public
    view
    returns (uint256)
  {
    return IERC20(stakingAddress).totalSupply();
  }

  /**
    @notice Returns account balance from pool
    @param stakingAddress Lido staking/token address from which to get balance
    @param account The account
   */
  function getBalance(address stakingAddress, address account)
    public
    view
    override
    returns (uint256 balance)
  {
    return IERC20(stakingAddress).balanceOf(account);
  }

  /**
    @notice Stake to lido stETH with ETH or ERC20 tokens
    @param entryTokenAddress The token used for entry (address(0) if ETH).
    @param entryTokenAmount The depositTokenAmount of entryTokenAddress to invest
    @param depositTokenAddress Token to be transfered to poolAddress
    @param minExitTokenAmount Min acceptable amount of liquidity/stake tokens to reeive
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
    address,
    address,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable override whenNotPaused {
    // Transfer {entryTokens} to contract
    entryTokenAmount = _pullTokens(entryTokenAddress, entryTokenAmount);

    // Subtract goodwill
    entryTokenAmount -= _subtractGoodwill(
      entryTokenAddress,
      entryTokenAmount,
      affiliate,
      true
    );

    if (entryTokenAddress == address(0)) {
      entryTokenAddress = ETH_ADDRESS;
    }

    // Swap {entryToken} to {depositToken}
    uint256 depositTokenAmount = _fillQuote(
      entryTokenAddress,
      entryTokenAmount,
      depositTokenAddress,
      swapTarget,
      swapData
    );

    _deposit(depositTokenAmount, minExitTokenAmount);

    emit Deposit(
      msg.sender,
      address(lidoStakingContract),
      depositTokenAmount,
      affiliate
    );
  }

  function _deposit(uint256 depositTokenAmount, uint256 minExitTokenAmount)
    internal
  {
    lidoStakingContract.submit{value: depositTokenAmount}(owner());
    uint256 stakedTokensReceived = _getBalance(address(lidoStakingContract));

    require(
      stakedTokensReceived >= minExitTokenAmount,
      "Deposit: High Slippage"
    );

    IERC20(address(lidoStakingContract)).safeTransfer(
      msg.sender,
      stakedTokensReceived
    );
  }

  function _fillQuote(
    address inputTokenAddress,
    uint256 inputTokenAmount,
    address outputTokenAddress,
    address swapTarget,
    bytes memory swapData
  ) internal returns (uint256 outputTokensBought) {
    if (inputTokenAddress == outputTokenAddress) {
      return inputTokenAmount;
    }

    if (swapTarget == WETH) {
      if (
        outputTokenAddress == address(0) || outputTokenAddress == ETH_ADDRESS
      ) {
        IWETH(WETH).withdraw(inputTokenAmount);
        return inputTokenAmount;
      } else {
        IWETH(WETH).deposit{value: inputTokenAmount}();
        return inputTokenAmount;
      }
    }

    uint256 value;
    if (inputTokenAddress == ETH_ADDRESS) {
      value = inputTokenAmount;
    } else {
      _approveToken(inputTokenAddress, swapTarget);
    }

    uint256 initialOutputTokenBalance = _getBalance(outputTokenAddress);

    // solhint-disable-next-line reason-string
    require(approvedTargets[swapTarget], "FillQuote: Target is not approved");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = swapTarget.call{value: value}(swapData);
    require(success, "FillQuote: Failed to swap tokens");

    outputTokensBought =
      _getBalance(outputTokenAddress) -
      initialOutputTokenBalance;

    // solhint-disable-next-line reason-string
    require(outputTokensBought > 0, "FillQuote: Swapped to invalid token");
  }

  /**
    @notice Removes liquidity from Lido contract in ETH or ERC20 tokens
    @param stakedTokensAmount Token amount to be transferes to integration contract
    @param exitTokenAddress Specifies the token which will be send to caller
    @param minExitTokenAmount Min acceptable amount of tokens to reeive
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address to share fees
  */
  function withdraw(
    address,
    uint256 stakedTokensAmount,
    address exitTokenAddress,
    uint256 minExitTokenAmount,
    address,
    address,
    address swapTarget,
    bytes calldata swapData,
    address affiliate
  ) external payable override whenNotPaused {
    // Transfer {liquidityTokens} to contract
    stakedTokensAmount = _pullTokens(
      address(lidoStakingContract),
      stakedTokensAmount
    );

    // Swap to {exitTokenAddress}
    uint256 exitTokenAmount = _fillQuote(
      address(lidoStakingContract),
      stakedTokensAmount,
      exitTokenAddress,
      swapTarget,
      swapData
    );

    require(exitTokenAmount >= minExitTokenAmount, "Withdraw: High Slippage");

    exitTokenAmount -= _subtractGoodwill(
      exitTokenAddress,
      exitTokenAmount,
      affiliate,
      true
    );

    // Transfer tokens to caller
    if (exitTokenAddress == ETH_ADDRESS) {
      Address.sendValue(payable(msg.sender), exitTokenAmount);
    } else {
      IERC20(exitTokenAddress).safeTransfer(msg.sender, exitTokenAmount);
    }

    emit Withdraw(
      msg.sender,
      address(lidoStakingContract),
      exitTokenAmount,
      affiliate
    );
  }

  /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param liquidity Quantity of LP tokens to remove.
    @return Quantity of token removed
    */
  function removeAssetReturn(
    address,
    address,
    uint256 liquidity
  ) external view override returns (uint256) {
    return liquidity;
  }

  /// @notice Updates current lido contract
  /// @param  newLidoContractAddress new lido contract address
  function updateLidoStakingContract(address newLidoContractAddress)
    external
    onlyOwner
  {
    require(
      newLidoContractAddress != address(lidoStakingContract),
      "Already using this address"
    );
    lidoStakingContract = ILidoStakingContract(newLidoContractAddress);
  }
}