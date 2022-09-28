import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPosiCallback {
    function posiAddLiquidityCallback(
        IERC20 baseToken,
        IERC20 quoteToken,
        uint256 baseAmountUsed,
        uint256 quoteAmountUsed,
        address user
    ) external;
}