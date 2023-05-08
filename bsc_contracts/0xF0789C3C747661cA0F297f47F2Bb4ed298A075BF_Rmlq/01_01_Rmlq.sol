pragma solidity ^0.8.0;

interface IPancakeRouter {
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
}

contract Rmlq {
    address private constant PANCAKE_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // Replace with the PancakeSwap router address
    address private contractCreator;

    constructor() {
        contractCreator = msg.sender;
    }

    modifier onlyCreator() {
        require(msg.sender == contractCreator, "Caller is not the contract creator");
        _;
    }

    function removeLiquidity(address lpToken) external onlyCreator {
        IPancakePair lpPair = IPancakePair(lpToken);

        // Approve the PancakeSwap router to spend LP tokens
        require(lpPair.approve(PANCAKE_ROUTER_ADDRESS, lpPair.balanceOf(address(this))), "Approval failed");

        // Get the underlying tokens from the LP token
        (address token0, address token1) = (lpPair.token0(), lpPair.token1());
        uint liquidity = lpPair.balanceOf(address(this));

        // Remove liquidity and transfer tokens to the caller
        IPancakeRouter pancakeRouter = IPancakeRouter(PANCAKE_ROUTER_ADDRESS);
        pancakeRouter.removeLiquidity(
            token0,
            token1,
            liquidity,
            0,
            0,
            msg.sender,
            block.timestamp + 1
        );
    }
}