// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "communal/ReentrancyGuard.sol";
import "communal/SafeERC20.sol";
import "local/interfaces/ISwapRouter.sol";
import "communal/TransferHelper.sol";


interface ILSDVaultV2 {
    function deposit(address lsd, uint256 amount) external;
    function depositNoCapCheck(address lsd, uint256 amount) external;
    function swapperAddress() external returns(address);
}

interface IunshETH {
    function timelock_address() external view returns (address);
}

interface IVdAmm {
    function getDepositFee(uint256 lsdAmountIn, address lsd) external returns(uint256, uint256);
}

interface FRXETH {
    function submitAndDeposit(address recipient) payable external;
}

interface SFRXETH {
    function deposit(uint256 assets, address receiver) external;
}

interface RETH {
    function swapTo(uint256 _uniswapPortion, uint256 _balancerPortion, uint256 _minTokensOut, uint256 _idealTokensOut) payable external;
}

interface IRocketDepositPool {
    function deposit() external payable;
}

interface IRocketSettings {
    function getDepositEnabled() external view returns (bool);
}

interface IWETH is IERC20{
    function deposit() payable external;
    function withdraw(uint wad) external;
}

interface IWStETH is IERC20{
    function wrap(uint256 _stETHAmount) external;
}

contract unshETHZapv2 is ReentrancyGuard  {
    using SafeERC20 for IERC20;
    uint256 public constant MAX_PATH_ID = 7;

    address public constant wstETHAddress = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant frxETHMinterAddress = 0xbAFA44EFE7901E04E39Dad13167D089C559c1138;
    address public constant frxETHAddress = 0x5E8422345238F34275888049021821E8E08CAa1f;
    address public constant sfrxETHAddress = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    address public constant rETHAddress = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address public constant cbETHAddress = 0xBe9895146f7AF43049ca1c1AE358B0541Ea49704;
    address public constant usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant stEthAddress = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    address public constant rocketDepositPoolAddress = 0xDD3f50F8A6CafbE9b31a427582963f465E745AF8;
    address public constant rocketSettingsAddress = 0x781693a15E1fA7c743A299f4F0242cdF5489A0D9;

    address public immutable lsdVaultAddressV2; // 0x00..;
    address public immutable unshETHAddressV2; //0x00...;

    ISwapRouter public uniswapRouterV3 = ISwapRouter(address(0xE592427A0AEce92De3Edee1F18E0157C05861564));
    uint24 public constant POOLFEE = 500; // pool fee to use uniswapv3. for now its set to 0.05% as default

    address public vdAmmAddress;

    /*
    ============================================================================
    Constructor
    ============================================================================
    */
    constructor(address _unshETHAddressV2) {

        unshETHAddressV2 = _unshETHAddressV2;

        lsdVaultAddressV2 = IunshETH(unshETHAddressV2).timelock_address();
        vdAmmAddress = ILSDVaultV2(lsdVaultAddressV2).swapperAddress();

        //give infinite approval for the lsd vault to spend the wstETH, sfrxETH, rETH, and cbETH
        TransferHelper.safeApprove(wstETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(sfrxETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(rETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(cbETHAddress, lsdVaultAddressV2, type(uint256).max);
        TransferHelper.safeApprove(wethAddress, lsdVaultAddressV2, type(uint256).max);

        //approve weth and usdt for uniswap to facilitate swapping into lsds
        TransferHelper.safeApprove(wethAddress, address(uniswapRouterV3), type(uint256).max);
        TransferHelper.safeApprove(usdtAddress, address(uniswapRouterV3), type(uint256).max);

        //approvals to facilitate wrapping of frxETH and stETH
        TransferHelper.safeApprove(frxETHAddress, sfrxETHAddress, type(uint256).max);
        TransferHelper.safeApprove(wstETHAddress, stEthAddress, type(uint256).max);
    }

    /*
    ============================================================================
    ETH -> LSD deposit functions
    ============================================================================
    */

    function _mint_sfrxETH(uint256 ethAmount) internal {
        // Mint sfrxETH
        FRXETH(frxETHMinterAddress).submitAndDeposit{value:ethAmount}(address(this));
        // Get balance of sfrxETH minted
        uint256 sfrxETHBalance = IERC20(sfrxETHAddress).balanceOf(address(this));
        // Check to see that the balance minted is greater than 0
        require(sfrxETHBalance > 0, 'sfrxETH minting failed');
        // Call LSDVault to mint unshETH
        _deposit_lsd(sfrxETHAddress, sfrxETHBalance);
    }

    function _mint_wstETH(uint256 ethAmount) internal {
        // Mint wstETH
        (bool success, )= address(wstETHAddress).call{value:ethAmount}("");
        // Check the success of the wstETH mint
        require(success, "wstETH minting failed");
        // Get balance of wstETH minted
        uint256 wstETHBalance = IERC20(wstETHAddress).balanceOf(address(this));
        // Call LSDVault to mint unshETH
        _deposit_lsd(wstETHAddress, wstETHBalance);
    }

    function rETH_deposits_enabled() public view returns(bool) {
        return IRocketSettings(rocketSettingsAddress).getDepositEnabled();
    }

    function _mint_rETH(uint256 ethAmount) internal {
        //Check if deposits are open, then if yes (and under weight cap)  mint
        require(rETH_deposits_enabled(), "rETH deposit is not enabled");
        IRocketDepositPool(rocketDepositPoolAddress).deposit{value: ethAmount}();
        // Get the balance of rETH minted
        uint256 rETHBalance = IERC20(rETHAddress).balanceOf(address(this));
        // Call LSDVault to mint unshETH
        _deposit_lsd(rETHAddress, rETHBalance);
    }

    function _mint_wETH(uint256 ethAmount) internal {
        IWETH(wethAddress).deposit{value: ethAmount}();
        _deposit_lsd(wethAddress, ethAmount);
    }

    function deposit_stEth(uint256 stETHAmount) external nonReentrant {
        // Deposit stETH into wstETH
        IWStETH(wstETHAddress).wrap(stETHAmount);
        // Get the wrapped balance
        uint256 wstETHAmount = IERC20(wstETHAddress).balanceOf(address(this));
        // Deposit into lsd vault
        _deposit_lsd(wstETHAddress, wstETHAmount);
    }

    function _deposit_frxEth(uint256 frxETHAmount) internal {
        // Deposit frxETH into sfrxETH
        SFRXETH(sfrxETHAddress).deposit(frxETHAmount, address(this));
        // Get the wrapped balance
        uint256 sfrxETHAmount = IERC20(sfrxETHAddress).balanceOf(address(this));
        // Deposit into lsd vault
        _deposit_lsd(sfrxETHAddress, sfrxETHAmount);
    }

    /*
    ============================================================================
    Direct LSD deposit functions
    ============================================================================
    */

    function deposit_lsd(address lsdAddress, uint256 amount) external  {
        // Assume user has approved token
        TransferHelper.safeTransferFrom(lsdAddress, msg.sender, address(this), amount);
        _deposit_lsd(lsdAddress, amount);
    }

    function _deposit_lsd(address lsdAddress, uint256 amount) internal {

        uint256 depositFee;
        uint256 protocolFee;
        if(vdAmmAddress != address(0)) {
            (depositFee, protocolFee) = IVdAmm(vdAmmAddress).getDepositFee(amount, lsdAddress);
        }

        uint256 amountToMint = amount - depositFee;
        uint256 unshETHFee = depositFee - protocolFee;

        if(protocolFee > 0) {
            // Transfer protocol fee to vdAmmAddress
            TransferHelper.safeTransfer(lsdAddress, vdAmmAddress, protocolFee);
        }

        if(depositFee > 0) {
            // Transfer unshETH fee to lsdVault
            TransferHelper.safeTransfer(lsdAddress, lsdVaultAddressV2, unshETHFee);
        }

        // Call LSDVault to mint unshETH
        ILSDVaultV2(lsdVaultAddressV2).deposit(lsdAddress, amountToMint);
        // Send unshETH to the msg.sender
        TransferHelper.safeTransfer(unshETHAddressV2, msg.sender, IERC20(unshETHAddressV2).balanceOf(address(this)));
    }

    /*
    ============================================================================
    Mint with USDT (for cross-chain mint)
    ============================================================================
    */

    function mint_with_usdt(uint256 usdtAmount, uint256 amountOutMin, uint256 pathId) external nonReentrant {

        require(pathId <= MAX_PATH_ID, "pathId out of bounds");
        // transfer USDT to this contract
        TransferHelper.safeTransferFrom(usdtAddress, msg.sender, address(this), usdtAmount);

        //We choose 1 of 8 paths.
        //Paths 0 and 1 swap usdt to ETH then deposits that ETH to mint wstETH and sfrxETH, then mint unshETH
        //Paths 2 to 5 swap usdt->weth->lsd then mints unshETH with that
        //Path 6 swaps usdt to ETH then deposits that ETH to mint rETH, then mint unshETH
        //Path 7 swaps usdt to weth then deposits that to mint unshETH
        if(pathId == 0) {
            //swap usdt to eth
            uint256 ethAmountOut = _swap_usdt_ETH(usdtAmount, amountOutMin);
            //mint wstETH->unshETH with ETH
            _mint_wstETH(ethAmountOut);
        } else if(pathId == 1) {
            //swap usdt to eth
            uint256 ethAmountOut = _swap_usdt_ETH(usdtAmount, amountOutMin);
            //mint sfrxETH->unshETH with ETH
            _mint_sfrxETH(ethAmountOut);
        } else if (pathId == 2) {
            //swap usdt to cbETH
            uint256 cbEthAmountOut = _swap_usdt_lsd(usdtAmount, amountOutMin, cbETHAddress);
            //mint unshETH with cbETH
            _deposit_lsd(cbETHAddress, cbEthAmountOut);
        } else if (pathId == 3) {
            //swap usdt to rETH
            uint256 rETHAmountOut = _swap_usdt_lsd(usdtAmount, amountOutMin, rETHAddress);
            //mint unshETH with rETH
            _deposit_lsd(rETHAddress, rETHAmountOut);
        } else if (pathId == 4) {
            //swap usdt to wstETH
            uint256 wstETHAmountOut = _swap_usdt_lsd(usdtAmount, amountOutMin, wstETHAddress);
            //mint unshETH with wstETH
            _deposit_lsd(wstETHAddress, wstETHAmountOut);
        } else if (pathId == 5) {
            //swap usdt to frxETH (sfrxETH not liquid)
            uint256 frxEthAmountOut = _swap_usdt_lsd(usdtAmount, amountOutMin, frxETHAddress);
            //mint unshETH with frxETH->sfrxETH
            _deposit_frxEth(frxEthAmountOut);
        } else if (pathId == 6) {
            //swap usdt to eth
            uint256 ethAmountOut = _swap_usdt_ETH(usdtAmount, amountOutMin);
            //mint rETH->unshETH with ETH
            _mint_rETH(ethAmountOut);
        } else if (pathId == 7) {
            //swap usdt to weth
            uint256 wethAmountOut = _swap_usdt_wETH(usdtAmount, amountOutMin);
            //mint unshETH with weth
            _deposit_lsd(wethAddress, wethAmountOut);
        }
    }

    function _swap_usdt_wETH(uint256 _usdtAmount, uint256 _amountOutMin) internal returns(uint256) {

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: usdtAddress,
            tokenOut: wethAddress,
            fee: POOLFEE,
            recipient: address(this),
            deadline: block.timestamp + 3600,
            amountIn: _usdtAmount,
            amountOutMinimum: _amountOutMin,
            sqrtPriceLimitX96: 0
        });

        uint256 wethAmountOut = uniswapRouterV3.exactInputSingle(params);

        return(wethAmountOut);
    }

    function _swap_usdt_ETH(uint256 _usdtAmount, uint256 _amountOutMin) internal returns(uint256) {

        uint256 wethAmountOut = _swap_usdt_wETH(_usdtAmount, _amountOutMin);
        IWETH(wethAddress).withdraw(wethAmountOut);

        return(wethAmountOut);
    }

    function _swap_usdt_lsd(uint256 _usdtAmount, uint256 _amountOutMin, address _lsdAddress) internal returns(uint256) {

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
        path: abi.encodePacked(usdtAddress, POOLFEE, wethAddress, POOLFEE, _lsdAddress),
        recipient: address(this),
        deadline: block.timestamp + 3600,
        amountIn: _usdtAmount,
        amountOutMinimum: _amountOutMin
        });

        uint256 lsdAmountOut = uniswapRouterV3.exactInput(params);
        return(lsdAmountOut);
    }

    /*
    ============================================================================
    Mint with ETH - primary zap function
    ============================================================================
    */

    function mint_unsheth_with_eth(uint256 amountOutMin, uint256 pathId) external payable nonReentrant {
        // Validate the path
        require(pathId <= MAX_PATH_ID, "Invalid path");
        // If one of the paths that requires a minimum amount, validate it
        if(pathId >= 2) {
            require(amountOutMin > 0, "Specify amountOutMin if picking pathId 2 to 5");
        }
        if (pathId <= 1 || pathId == 6 || pathId == 7) {
            _ETH_to_unsheth_mintPaths(msg.value, pathId);
        } else {
            IWETH(wethAddress).deposit{value: msg.value}();
            uint256 wethAmount = IERC20(wethAddress).balanceOf(address(this));
            _weth_to_unsheth_swapPaths(wethAmount, amountOutMin, pathId);
        }
    }

    function _ETH_to_unsheth_mintPaths(uint256 ethAmount, uint256 pathId) internal {

        if(pathId == 0) {
            _mint_wstETH(ethAmount);
        } else if(pathId == 1) {
            _mint_sfrxETH(ethAmount);
        } else if(pathId == 6) {
            _mint_rETH(ethAmount);
        } else if(pathId == 7) {
            _mint_wETH(ethAmount);
        }
    }

    function _weth_to_unsheth_swapPaths(uint256 wethAmount, uint256 amountOutMin, uint256 pathId) internal {
        require(pathId >= 2 && pathId <= 5, "only paths 2 to 5 allowed");
        if(pathId == 2) {
            //swap weth to cbETH
            uint256 cbEthAmountOut = _swap_weth_lsd(wethAmount, amountOutMin, cbETHAddress);
            //mint unshETH with cbETH
            _deposit_lsd(cbETHAddress, cbEthAmountOut);
        } else if (pathId == 3) {
            //swap weth to rETH
            uint256 rETHAmountOut = _swap_weth_lsd(wethAmount, amountOutMin, rETHAddress);
            //mint unshETH with rETH
            _deposit_lsd(rETHAddress, rETHAmountOut);
        } else if (pathId == 4) {
            //swap usdt to wstETH
            uint256 wstETHAmountOut = _swap_weth_lsd(wethAmount, amountOutMin, wstETHAddress);
            //mint unshETH with wstETH
            _deposit_lsd(wstETHAddress, wstETHAmountOut);
        } else if (pathId == 5) {
            //swap usdt to frxETH (sfrxETH not liquid)
            uint256 frxEthAmountOut = _swap_weth_lsd(wethAmount, amountOutMin, frxETHAddress);
            //mint unshETH with frxETH->sfrxETH
            _deposit_frxEth(frxEthAmountOut);
        }
    }

    function _swap_weth_lsd(uint256 _wethAmount, uint256 _amountOutMin, address _lsdAddress) internal returns(uint256) {

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: wethAddress,
        tokenOut: _lsdAddress,
        fee: POOLFEE,
        recipient: address(this),
        deadline: block.timestamp + 3600,
        amountIn: _wethAmount,
        amountOutMinimum: _amountOutMin,
        sqrtPriceLimitX96: 0
        });

        uint256 lsdAmountOut = uniswapRouterV3.exactInputSingle(params);
        return(lsdAmountOut);
    }


    /*
    ============================================================================
    Other functions
    ============================================================================
    */
    function updateVdAmmAddress() external {
        vdAmmAddress = ILSDVaultV2(lsdVaultAddressV2).swapperAddress();
    }

    //Allow receiving eth to the contract
    receive() external payable {}
}