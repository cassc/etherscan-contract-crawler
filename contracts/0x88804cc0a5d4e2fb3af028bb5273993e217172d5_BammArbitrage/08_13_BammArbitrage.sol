// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FlashLoanSimpleReceiverBase} from "@aave/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/contracts/interfaces/IPoolAddressesProvider.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IBAmm} from "./interfaces/IBAmm.sol";
import {TransferHelper} from "./librairies/TransferHelper.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
* @title BammArbitrage
* @notice This contract is used to arbitrage B.Protocol Chicken Bond Stability Pool via flash loan
* @author @NelsonRodMar.lens
 */
contract BammArbitrage is FlashLoanSimpleReceiverBase {
    using SafeMath for uint256;

    address public constant LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint24 public constant poolFee = 500; // 0.5%
    uint160 public constant MIN_SQRT_RATIO = 4295128739;

    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IBAmm public immutable bamm = IBAmm(0x896d8a30C32eAd64f2e1195C2C8E0932Be7Dc20B);
    IWETH9 public immutable iWETH9 = IWETH9(payable(WETH));

    mapping(address => bool) public isAuthorized;

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "BammArbitrage: not authorized");
        _;
    }

    constructor() FlashLoanSimpleReceiverBase(IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e)) {
        isAuthorized[msg.sender] = true;
    }

    /*
    * This function initiates the flash loan
    */
    function requestFlashLoan() external onlyAuthorized {
        // Calcul the amount of wETH to flash loan
        (, ,uint _amountInLusd) = bamm.getLUSDValue();
        (,uint _feeAmount) = bamm.getSwapEthAmount(_amountInLusd);
        uint _amountInLusdLessFee = _amountInLusd.sub(_feeAmount);
        (uint _amountInwETH,) = bamm.getSwapEthAmount(_amountInLusdLessFee);

        // FlashLoan the wETH
        POOL.flashLoanSimple(
            address(this),
            address(iWETH9),
            _amountInwETH,
            abi.encode(msg.sender, _amountInLusdLessFee),
            0
        );

        emit FlashLoanRequested(WETH, _amountInwETH);
    }


    /*
    * This function is called after the contract has received the flash loaned amount
    */
    function executeOperation(
        address,
        uint256 _amount,
        uint256 _premium,
        address,
        bytes calldata data
    ) external override returns (bool)
    {
        (address payable receiverAddress, uint256 _amountInLusdLessFee) = abi.decode(data, (address,uint256));
        emit FlashLoanReceived(WETH, _amount, _premium);
        // Approve the Aave Pool to repay the loan
        uint256 amountOwing = _amount.add(_premium);
        IERC20(address(iWETH9)).approve(address(POOL), amountOwing);

        // Swap wETH received to LUSD on Uniswap
        TransferHelper.safeApprove(address(iWETH9), address(swapRouter), _amount);
        ISwapRouter.ExactInputParams memory params =
        ISwapRouter.ExactInputParams({
            path : abi.encodePacked(address(iWETH9), poolFee, USDC, poolFee, LUSD),
            recipient : address(this),
            deadline : block.timestamp,
            amountIn : _amount,
            amountOutMinimum : (_amountInLusdLessFee - (_amountInLusdLessFee.mul(50).div(10000))) // 0.5% slippage
        });
        uint256 lusdAmount = swapRouter.exactInput(params);

        // Sell LUSD against ETH on the B.AMM
        IERC20(LUSD).approve(address(bamm), lusdAmount);
        bamm.swap(lusdAmount, amountOwing, payable(address(this)));

        // Wrap ETH to repay the Loan
        iWETH9.deposit{value : amountOwing}();

        // Send the remaining ETH to the owner
        uint256 remaining = address(this).balance;
        (bool sent,) = receiverAddress.call{value : remaining}("");
        require(sent, "Failed to send Ether ");
        emit ProfitSend(receiverAddress, remaining);

        return (true);
    }


    /**
     * @dev Change the authorization of an address
     *
     * @param _address Address to change authorization
     */
    function changeAuthorization(address _address) external onlyAuthorized {
        isAuthorized[_address] = !isAuthorized[_address];
    }

    receive() external payable {}

    // Events
    event FlashLoanRequested(address asset, uint256 amount);
    event FlashLoanReceived(address asset, uint256 amount, uint256 premium);
    event ProfitSend(address to, uint256 amount);
}