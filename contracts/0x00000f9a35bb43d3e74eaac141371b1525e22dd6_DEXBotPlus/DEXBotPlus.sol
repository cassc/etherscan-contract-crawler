/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

// SPDX-License-Identifier: MIT

/**
    ____  _______  __ ___    ____   ____  __          
   / __ \/ ____/ |/ //   |  /  _/  / __ \/ /_  _______
  / / / / __/  |   // /| |  / /   / /_/ / / / / / ___/
 / /_/ / /___ /   |/ ___ |_/ /   / ____/ / /_/ (__  ) 
/_____/_____//_/|_/_/  |_/___/  /_/   /_/\__,_/____/  
                    -- Coded DEXAI.Plus by CC.DID.BI

该代码是用于DEXAI+™️机器人核心程序在确保用户资金安全的情况下，调用的交易其接口实现自动化交易的合约。
该代码构造函数中的所有变量在发布后均不可以修改，
管理员权限：
    1.swapFunctionA 和 swapFunctionB 方法发起交易，且兑换所得的目标地址为默认值（即本合约本身的地址）不可以修改。
    2.withdrawToken 按照约定比例分发余额。
特别说明：本合约为 DEXAI.Plus HC团队定制版，withdrawToken的方法于 DEXAI.Plus 通用版存在差异。 

编译参数设置： 
Solidity 版本选择 0.8.0;
Optimization 优化选择 true, 200 runs;
**/
pragma solidity = 0.8.0;

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address src,address dst,uint256 amount) external returns (bool);
    function allowance(address src,address dst) external returns (uint256);
}

interface IThirdPartyContract {
    struct ILiFiBridgeData {
        uint256 minAmount;
        uint256 receivedAmount;
    }

    struct LibSwapSwapData {
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
    }

    struct HopData {
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
        address hopBridge;
    }

    function swapAndStartBridgeTokensViaHopL1ERC20(
        ILiFiBridgeData memory _bridgeData,
        LibSwapSwapData[] calldata _swapData,
        HopData calldata _hopData
    ) external payable;
}

contract DEXBotPlus {
    address public admin;
    address public targetContractAddress; 
    address public addressA;
    address public addressB;
    address public addressC;
    address public swapper;
 

    event TokensSwapped(address indexed tokenA, address indexed tokenB, address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed token, address indexed user, uint256 amount);
    IThirdPartyContract thirdPartyContract;

    //构造函数，该函数只能在发布合约时执行一次。
    constructor() {
        admin = msg.sender;//合约发布者为管理员，管理员由DEXBot Plus核心AI控制，只有向不可篡改的交易聚合器代理地址发起交易。
        targetContractAddress = 0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE;//DEX目标合约，不可以修改。
        thirdPartyContract = IThirdPartyContract(0xbCe268B24155dF2a18982984e9716136278f38d6);//DEX目标合约，不可以修改。
        addressA = 0x0030Bd57c4946F82b7468ba82B746b9859D83919;//分润地址A，不可以修改。
        addressB = 0xf608CFf9b8273714248a4a077A39695d8362bA9B;//分润地址C，不可以修改。
        addressC = 0x78c0F0fF1d9b36F53FEa77312BB4465073399999;//分润地址D，不可以修改。
        swapper  = 0x66F07FaE3161de64B284ab85b1660DDD49CbFf15;//出资人地址，不可以修改。
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "This function only for owner!");
        _;
    }

    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    struct SwapData {
        uint256 minAmount;
        uint256 receivedAmount;
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
        address hopBridge;
    }

    function swapFunctionA(SwapData memory swapData) external payable onlyAdmin {
        // 构造 _bridgeData
        IThirdPartyContract.ILiFiBridgeData memory bridgeData = IThirdPartyContract.ILiFiBridgeData({
            minAmount: swapData.minAmount,
            receivedAmount: swapData.receivedAmount
        });

        // 构造 _swapData
        IThirdPartyContract.LibSwapSwapData[] memory swapArray = new IThirdPartyContract.LibSwapSwapData[](1);
        swapArray[0] = IThirdPartyContract.LibSwapSwapData({
            callTo: swapData.callTo,
            approveTo: swapData.approveTo,
            sendingAssetId: swapData.sendingAssetId,
            receivingAssetId: swapData.receivingAssetId,
            fromAmount: swapData.fromAmount,
            callData: swapData.callData,
            requiresDeposit: swapData.requiresDeposit
        });

        // 构造 _hopData
        IThirdPartyContract.HopData memory hopData = IThirdPartyContract.HopData({
            bonderFee: swapData.bonderFee,
            amountOutMin: swapData.amountOutMin,
            deadline: swapData.deadline,
            destinationAmountOutMin: swapData.destinationAmountOutMin,
            destinationDeadline: swapData.destinationDeadline,
            hopBridge: swapData.hopBridge
        });

        // 调用目标合约的方法
        thirdPartyContract.swapAndStartBridgeTokensViaHopL1ERC20(
            bridgeData,
            swapArray,
            hopData
        );
    }

    function swapFunctionB(
        address _tokenA,
        address _tokenB,
        uint256 _amount 
    ) external onlyAdmin {
        require(ERC20(_tokenA).balanceOf(swapper) >= _amount);
        require(ERC20(_tokenA).allowance(swapper,address(this))>= _amount);
        // 将代币转移到目标合约地址
        require(ERC20(_tokenA).transferFrom(swapper,targetContractAddress,_amount), "Swap failed");
        emit TokensSwapped(_tokenA,_tokenB,swapper, _amount);
    }

    function withdrawToken(address _token, uint256 _cost) external onlyAdmin {
        ERC20 token = ERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require (_cost <= balance);
        uint256 profit  = balance - _cost;
        require (profit <= ( balance * 5)/100);//利润上限制锁；
        uint256 amountToSwapper = (profit * 50) / 100 + _cost;
        uint256 amountA = (profit * 27) / 100;
        uint256 amountB = (profit * 2) / 100;
        uint256 amountC = balance - amountToSwapper - amountA - amountB;

        // 将代币转移到交换地址
        require(token.transfer(swapper, amountToSwapper), "Transfer failed");
        emit TokensWithdrawn(_token, swapper, amountToSwapper);

        // 将代币转移到地址A
        require(token.transfer(addressA, amountA), "Transfer failed");
        emit TokensWithdrawn(_token, addressA, amountA);

        // 将代币转移到地址B
        require(token.transfer(addressB, amountB), "Transfer failed");
        emit TokensWithdrawn(_token, addressB, amountB);

        // 将代币转移到地址C
        require(token.transfer(addressC, amountC), "Transfer failed");
        emit TokensWithdrawn(_token, addressC, amountC);
    }
}