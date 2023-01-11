pragma solidity >=0.5.0;

interface IRouter02 {
    function factory() external pure returns (address);

    function bDeployer() external pure returns (address);

    function cDeployer() external pure returns (address);

    function WETH() external pure returns (address);

    function mint(
        address poolToken,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 tokens);

    function mintETH(
        address poolToken,
        address to,
        uint256 deadline
    ) external payable returns (uint256 tokens);

    function mintCollateral(
        address poolToken,
        uint256 amount,
        address to,
        uint256 deadline,
        bytes calldata permitData
    ) external returns (uint256 tokens);

    function redeem(
        address poolToken,
        uint256 tokens,
        address to,
        uint256 deadline,
        bytes calldata permitData
    ) external returns (uint256 amount);

    function redeemETH(
        address poolToken,
        uint256 tokens,
        address to,
        uint256 deadline,
        bytes calldata permitData
    ) external returns (uint256 amountETH);

    function borrow(
        address borrowable,
        uint256 amount,
        address to,
        uint256 deadline,
        bytes calldata permitData
    ) external;

    function borrowETH(
        address borrowable,
        uint256 amountETH,
        address to,
        uint256 deadline,
        bytes calldata permitData
    ) external;

    function repay(
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline
    ) external returns (uint256 amount);

    function repayETH(
        address borrowable,
        address borrower,
        uint256 deadline
    ) external payable returns (uint256 amountETH);

    function liquidate(
        address borrowable,
        uint256 amountMax,
        address borrower,
        address to,
        uint256 deadline
    ) external returns (uint256 amount, uint256 seizeTokens);

    function liquidateETH(
        address borrowable,
        address borrower,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountETH, uint256 seizeTokens);

    function leverage(
        address uniswapV2Pair,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bytes calldata permitDataA,
        bytes calldata permitDataB
    ) external;

    function deleverage(
        address uniswapV2Pair,
        uint256 redeemTokens,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline,
        bytes calldata permitData
    ) external;

    function isVaultToken(address underlying) external view returns (bool);

    function getUniswapV2Pair(address underlying)
        external
        view
        returns (address);

    function getBorrowable(address uniswapV2Pair, uint8 index)
        external
        view
        returns (address borrowable);

    function getCollateral(address uniswapV2Pair)
        external
        view
        returns (address collateral);

    function getLendingPool(address uniswapV2Pair)
        external
        view
        returns (
            address collateral,
            address borrowableA,
            address borrowableB
        );
}