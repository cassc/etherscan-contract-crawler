// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./TransferHelper.sol";
import "./IERC721Receiver.sol";
import "./INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IMulticall.sol";
import "./ERC20.sol";
import "hardhat/console.sol";
import "./ILendingPool.sol";

contract VaultContractV2 is IERC721Receiver, Initializable {
    address public Owner;
    address public GasWallet;
    uint256 public sharesTotalSupply;
    uint256 public vaultBalance;
    uint8 public ownerCommission;
    bool public freezeWithdrawal;
    mapping(address => uint) public investorShare;
    address constant swapRouterAddress =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant swapRouterAddressV2 =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant nonfungiblePositionManagerAddress =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address constant Ilendingpool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    function initializeV2() external reinitializer(2) {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        vaultBalance = 0;
        ownerCommission = 5;
        freezeWithdrawal = false;
    }

    function openPosition(
        bytes[] calldata mintData,
        uint24 poolFee,
        uint256 mintAmount,
        address depositAsset,
        uint256 depositAmount,
        address borrowAsset,
        uint256 borrowAmount,
        uint256 borrowInterestRateMode
    ) public {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        // Mint Position
        mintPosition(mintData, mintAmount);
        // Deposit to Aave
        depositToAave(depositAsset, depositAmount);
        // Borrow From Aave
        borrowFromAave(
            borrowAsset,
            borrowAmount,
            borrowInterestRateMode // 1
        );

        // Swap to USDC
        swapExactInputSingle(borrowAsset, usdc, poolFee, borrowAmount, 0);
        freezeWithdrawal = true;
    }

    function closePosition(
        uint256 rmLiquidityTokenId,
        uint24 swapPoolFee,
        uint256 repayRateMode
    ) public {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        uint24 fee = swapPoolFee;
        ILendingPool aaveV2PoolContract = ILendingPool(Ilendingpool);

        uint256 amount0;
        uint256 amount1;
        // Remove the liquidity from the position
        (amount0, amount1) = removeLiquidity(rmLiquidityTokenId);

        INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(
                nonfungiblePositionManagerAddress
            );
        // Get Token 0 and 1 address from position information
        (
            ,
            ,
            address usdcAddress,
            address wethAddress,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(rmLiquidityTokenId);

        // Swap Addresses if token0 is not USDC
        if (usdcAddress != usdc) {
            wethAddress = usdcAddress;
            usdcAddress = usdc;
        }
        // Get the Total Debt
        uint256 totalDebt;
        (, totalDebt, , , , ) = aaveV2PoolContract.getUserAccountData(
            address(this)
        );

        IERC20 token = IERC20(wethAddress);
        uint256 wethBalance = token.balanceOf(address(this));
        IERC20 investorToken = IERC20(usdc);

        if (wethBalance > totalDebt) {
            // Repay the borrowed amount
            repayToAave(wethAddress, totalDebt, repayRateMode);
            // Withdraw the deposited amount
            withdrawFromAave(usdcAddress, type(uint).max, address(this));
            // Swap to remaining weth to USDC
            wethBalance = token.balanceOf(address(this));
            swapExactInputSingle(wethAddress, usdcAddress, fee, wethBalance, 0);
        } else {
            // Calculate the AMount Needed for Repayment
            uint256 amountNeeded = (totalDebt - wethBalance);
            swapExactOutputSingle(
                usdcAddress,
                wethAddress,
                fee,
                amountNeeded,
                type(uint).max
            );
            // Repay the borrowed amount
            repayToAave(wethAddress, totalDebt, repayRateMode);
            // Withdraw the deposited amount
            withdrawFromAave(usdcAddress, type(uint).max, address(this));
        }
        // Send Commission to Owner
        uint256 vaultcurretnBalance = investorToken.balanceOf(address(this));
        if (vaultcurretnBalance > vaultBalance) {
            uint256 commission = ((vaultcurretnBalance - vaultBalance) *
                ownerCommission) / 100;
            investorToken.transfer(Owner, commission);
        }
        // Set investor Total Balance
        vaultBalance = investorToken.balanceOf(address(this));
        // unFreeze the withdrawal
        freezeWithdrawal = false;
    }

    function depositToAave(address asset, uint256 amount) public {
        require(msg.sender == GasWallet, "Not the True Owner");
        ILendingPool aaveV2PoolContract = ILendingPool(Ilendingpool);
        // IERC20 Token Object
        IERC20 token = IERC20(asset);
        // Approve the amount
        token.approve(address(aaveV2PoolContract), amount);
        // Deposit the amount of asset on aave
        aaveV2PoolContract.deposit(address(asset), amount, address(this), 0);
    }

    function borrowFromAave(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) public {
        require(msg.sender == GasWallet, "Not the True Owner");
        ILendingPool aaveV2PoolContract = ILendingPool(Ilendingpool);
        // IERC20 Token Object
        IERC20 token = IERC20(asset);
        // Approve the amount
        token.approve(address(aaveV2PoolContract), amount);
        // Call Borrow function
        aaveV2PoolContract.borrow(
            asset,
            amount,
            interestRateMode,
            0,
            address(this)
        );
    }

    function repayToAave(
        address asset,
        uint256 amount,
        uint256 rateMode
    ) public {
        require(msg.sender == GasWallet, "Not the True Owner");
        ILendingPool aaveV2PoolContract = ILendingPool(Ilendingpool);
        // IERC20 Token Object
        IERC20 token = IERC20(asset);
        // Approve the amount
        token.approve(address(aaveV2PoolContract), amount);
        // Repay to Aave
        aaveV2PoolContract.repay(asset, amount, rateMode, address(this));
    }

    function withdrawFromAave(
        address asset,
        uint256 amount,
        address to
    ) public {
        require(msg.sender == GasWallet, "Not the True Owner");
        ILendingPool aaveV2PoolContract = ILendingPool(Ilendingpool);
        // IERC20 Token Object
        IERC20 token = IERC20(asset);
        // Approve the amount
        token.approve(address(aaveV2PoolContract), amount);

        aaveV2PoolContract.withdraw(asset, amount, to);
    }

    function mintPosition(bytes[] calldata data, uint256 amount)
        public
        payable
        returns (bytes[] memory results)
    {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        TransferHelper.safeApprove(usdc, swapRouterAddressV2, amount);
        results = IMulticall(swapRouterAddressV2).multicall(data);
        return results;
    }

    function swapExactInputSingle(
        address token_In,
        address token_Out,
        uint24 poolFee,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public returns (uint256 amountOut) {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        ISwapRouter swapRouter = ISwapRouter(swapRouterAddress);
        TransferHelper.safeApprove(token_In, swapRouterAddress, amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token_In,
                tokenOut: token_Out,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap
        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountOut,
        uint256 amountInMaximum
    ) public returns (uint256 amountIn) {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        ISwapRouter swapRouter = ISwapRouter(swapRouterAddress);

        TransferHelper.safeApprove(
            tokenIn,
            swapRouterAddress,
            amountInMaximum
        );
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap
        amountIn = swapRouter.exactOutputSingle(params);
    }

    /// @notice Collects the fees associated with provided liquidity
    /// @dev The contract must hold the erc721 token before it can collect fees
    function collectAllFees(uint256 tokenId)
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        // Caller must own the ERC721 position, meaning it must be a deposit
        INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(
                nonfungiblePositionManagerAddress
            );
        INonfungiblePositionManager.CollectParams
            memory params = INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // send collected feed back to owner
    }

    function removeLiquidity(uint256 tokenId)
        public
        returns (uint256 amount0, uint256 amount1)
    {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");

        INonfungiblePositionManager nonfungiblePositionManager = INonfungiblePositionManager(
                nonfungiblePositionManagerAddress
            );

        // Get the Position Liquidity from Position Manager
        uint128 liquidity;
        (, , , , , , , liquidity, , , , ) = nonfungiblePositionManager
            .positions(tokenId);

        // Set the Params of the transaction
        INonfungiblePositionManager.DecreaseLiquidityParams
            memory params = INonfungiblePositionManager
                .DecreaseLiquidityParams({
                    tokenId: tokenId,
                    liquidity: liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                });
        // Decrease the Desired Liquidity
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            params
        );
        // Collect the Fee Rewards
        collectAllFees(tokenId);
    }

    function changeGasWallet(address newGasWallet) public {
        require(msg.sender == Owner, "Invalid Owner");
        GasWallet = newGasWallet;
    }

    function transferOwnership(address newOwnerWallet) public {
        require(msg.sender == Owner, "Invalid Owner");
        Owner = newOwnerWallet;
    }

    function emergencyWithdraw(address tokenAddress) external {
        require(msg.sender == Owner, "Invalid Owner");

        ERC20 token = ERC20(tokenAddress);

        TransferHelper.safeTransfer(
            tokenAddress,
            Owner,
            token.balanceOf(address(this))
        );
    }

    // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function investorMint(address _to, uint _shares) private {
        sharesTotalSupply += _shares;
        investorShare[_to] += _shares;
    }

    function investorBurn(address _from, uint _shares) private {
        sharesTotalSupply -= _shares;
        investorShare[_from] -= _shares;
    }

    function investorDeposit(uint _amount) external {
        IERC20 investorToken = IERC20(usdc);
        uint shares;
        if (sharesTotalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * sharesTotalSupply) / vaultBalance;
        }
        investorMint(msg.sender, shares);
        investorToken.transferFrom(msg.sender, address(this), _amount);
        vaultBalance = vaultBalance + _amount;
    }

    function investorWithdraw(uint _amount) external {
        require(freezeWithdrawal == false, "Withdrawal Freezed");
        
        IERC20 investorToken = IERC20(usdc);
        uint shares = (_amount * sharesTotalSupply) / vaultBalance;
        require(investorShare[msg.sender] >= shares, "Not enough shares");
        investorBurn(msg.sender, shares);
        investorToken.transfer(msg.sender, _amount);
        vaultBalance = vaultBalance - _amount;
    }

    function investorBalance(address investor) public view returns (uint) {
        require(vaultBalance != 0, "No Balance in the Contract, Deposit First");
        uint share = investorShare[investor];
        uint amount = (share * vaultBalance) / sharesTotalSupply;
        return amount;
    }

    function toggleFreezeWithdraw() public {
        require(msg.sender == GasWallet, "Invalid Gas Wallet");
        if(freezeWithdrawal == false) {
            freezeWithdrawal = true;
        } else {
            IERC20 usdcToken = IERC20(usdc);
            require(vaultBalance == usdcToken.balanceOf(address(this)));
            freezeWithdrawal = false;
        }
    }

    function setownerCommission(uint8 newCommission) public {
        require(msg.sender == Owner, "Invalid Owner");
        ownerCommission = newCommission;
    }
}