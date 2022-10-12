// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IuHGT is IERC20{
    function claim(address to, bytes calldata signature, uint256 amount) external;
}

interface IPancakeRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function factory() external pure returns (address);
}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract uHGTSwapRouter is Ownable{
    using SafeERC20 for IERC20;
    using SafeERC20 for IuHGT;

    address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    IPancakeRouter public _pancakeRouter;
    IuHGT public _uHGT;
    IERC20 public _BUSD;
    address immutable public _pairAddress;
    address public _BUSDReceivingAddress;

    event Swap(uint amountIn, uint amountOutMin, address[] path, address to, uint deadline);
    event TransferToDigitalWallet(address indexed to, uint amount, uint time);
    event SetBUSDReceivingAddress(address BUSDReceivingAddress);

    constructor(address uHGT,address BUSDReceivingAddress) {
        _pancakeRouter = IPancakeRouter(PANCAKE_ROUTER);
        _BUSD = IERC20(BUSD);
        _uHGT = IuHGT(uHGT);
        _BUSDReceivingAddress = BUSDReceivingAddress;

        //_pairAddress and the address of uHGTSwapRouter will be added to the identified of the uHGToken.
        IPancakeFactory factory = IPancakeFactory(_pancakeRouter.factory());
        _pairAddress = factory.createPair(uHGT,BUSD);
    }

    function setBUSDReceivingAddress(address BUSDReceivingAddress) public onlyOwner {
        _BUSDReceivingAddress = BUSDReceivingAddress;
        emit SetBUSDReceivingAddress(BUSDReceivingAddress);
    }

    function swap(uint256 amountIn) public returns(uint256) {
        require(amountIn > 0, "Amount must bigger than 0");
        _uHGT.safeTransferFrom(msg.sender, address(this), amountIn);
        _uHGT.approve(address(_pancakeRouter), amountIn);
        address[] memory path = new address[](2);
        path[0] = address(_uHGT);
        path[1] = address(_BUSD);
        uint256 amountOutMin = _pancakeRouter.getAmountsOut(amountIn, path)[1] * 99 / 100;
        uint[] memory amounts = _pancakeRouter.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp);
        emit Swap(amountIn, amountOutMin, path, msg.sender, block.timestamp);
        return amounts[1];
    }

    function swapAndWithdrawToDigitalWallet(uint256 amountIn) public {
        uint256 amountOut = swap(amountIn);
        _BUSD.safeTransferFrom(msg.sender, _BUSDReceivingAddress, amountOut);
        emit TransferToDigitalWallet(msg.sender, amountOut, block.timestamp);
    }

    function claimAndTransfer(bytes calldata signature, uint256 amount) public {
        _uHGT.claim(msg.sender, signature, amount);
        swapAndWithdrawToDigitalWallet(amount);
    }

    function getAmountsOut(uint256 amountIn) public view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = address(_uHGT);
        path[1] = address(_BUSD);
        uint256 amountOut = _pancakeRouter.getAmountsOut(amountIn, path)[1];
        return amountOut;
    }

}