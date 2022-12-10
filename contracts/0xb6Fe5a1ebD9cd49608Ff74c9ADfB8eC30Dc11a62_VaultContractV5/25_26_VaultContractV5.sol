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

contract VaultContractV5 is IERC721Receiver, Initializable {
    address public Owner;
    address public GasWallet;
    uint256 public sharesTotalSupply;
    uint256 public vaultBalance;
    uint8 public ownerCommission;
    bool public freezeWithdrawal;
    address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    mapping(address => uint) public investorShare;
    mapping(address => uint) public investorAmountInit;
    mapping(address => string) public investorAffiliate;
    address constant swapRouterAddress =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant swapRouterAddressV2 =
        0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant nonfungiblePositionManagerAddress =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address constant Ilendingpool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    function initializeV5() external reinitializer(5) {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        vaultBalance = 0;
        ownerCommission = 5;
        freezeWithdrawal = false;
    }

    function openPosition(
        bytes[] calldata mintData,
        uint256 mintAmount
    ) public {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        // Mint Position
        mintPosition(mintData, mintAmount);

        //Freeze Withdrawal
        freezeWithdrawal = true;
    }

    function closePosition(
        uint256 rmLiquidityTokenId,
        uint24 swapPoolFee
    ) public {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        uint24 fee = swapPoolFee;

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

        IERC20 token = IERC20(wethAddress);
        uint256 wethBalance = token.balanceOf(address(this));
        //IERC20 investorToken = IERC20(usdc);

        // Swap weth into usdc
        wethBalance = token.balanceOf(address(this));
        swapExactInputSingle(wethAddress, usdcAddress, fee, wethBalance, 0);
        
        // Mantain Freeze the withdrawal
        freezeWithdrawal = true;
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

    //Amount of USDC needed in Deribit, we do the swap to ETH and then send the funds
    function swapAndTransfer(
        uint256 _amountusdc,
        uint24 swapPoolFee
        ) public {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");    
        uint24 fee = swapPoolFee;

        //Swap usdc to eth 
        swapExactInputSingle(usdc, weth, fee, _amountusdc, 0);

        //Recalculate the total amount of eth in the contract
        IERC20 EthFunds = IERC20(weth);
        uint256 wethBalance = EthFunds.balanceOf(address(this));

        //Transfer Funds to Deribit
        transferFunds(wethBalance);

    }

    function transferFunds(uint _amount) public {
        require(msg.sender == GasWallet, "Gas Wallet Incorrect");
        IERC20 ethFunds = IERC20(weth);

        address addrProtocol = 0x596043d669E51482B7a93bf2Bd47456ef2Dff423;

        ethFunds.transfer(addrProtocol, _amount);
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
        investorAmountInit[msg.sender] += _amount;
    }

    function investorWithdraw(uint _amount) external {
        require(freezeWithdrawal == false, "Withdrawal Freezed");

        IERC20 investorToken = IERC20(usdc);
        uint shares = (_amount * sharesTotalSupply) / vaultBalance;
        require(investorShare[msg.sender] >= shares, "Not enough shares");

        //Send comision to owner
        //See if the user has more funds that when he deposit
        if(investorBalance(msg.sender) > investorAmountInit[msg.sender]) //If true
        {
            //Owner has a comission over the gains
            uint256 commission = ((investorBalance(msg.sender) - investorAmountInit[msg.sender]) * ownerCommission) / 100;
            investorToken.transfer(Owner, commission);
            investorBurn(msg.sender, shares);
            uint amountAfterComission = _amount - commission;
            investorToken.transfer(msg.sender, amountAfterComission);
            vaultBalance = vaultBalance - amountAfterComission;
        } 
        else //If false
        {
            //Owner has no comission
            investorBurn(msg.sender, shares);
            investorToken.transfer(msg.sender, _amount);
            vaultBalance = vaultBalance - _amount;
        }
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