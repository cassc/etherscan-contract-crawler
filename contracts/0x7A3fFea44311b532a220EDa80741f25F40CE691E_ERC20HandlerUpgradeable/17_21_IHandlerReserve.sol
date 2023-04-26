// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IHandlerReserve {
    function fundERC20(
        address tokenAddress,
        address owner,
        uint256 amount
    ) external;

    function lockERC20(
        address tokenAddress,
        address owner,
        address recipient,
        uint256 amount
    ) external;

    function releaseERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function mintERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function burnERC20(
        address tokenAddress,
        address owner,
        uint256 amount
    ) external;

    function safeTransferETH(address to, uint256 value) external;

    function deductFee(
        address feeTokenAddress,
        address depositor,
        // uint256 providedFee,
        uint256 requiredFee,
        // address _ETH,
        bool _isFeeEnabled,
        address _feeManager
    ) external;

    function mintWrappedERC20(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external;

    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount,
        address WETH
    ) external;

    function giveAllowance(
        address token,
        address spender,
        uint256 amount
    ) external;

    function getStakedRecord(address account, address tokenAddress) external view returns (uint256);

    function withdrawWETH(address WETH, uint256 amount) external;

    function _setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) external;

    function _setLiquidityPool(address contractAddress, address lpAddress) external returns (address);

    // function _setLiquidityPool(
    //     string memory name,
    //     string memory symbol,
    //     uint8 decimals,
    //     address contractAddress,
    //     address lpAddress
    // ) external returns (address);

    function swapMulti(
        address oneSplitAddress,
        address[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx
    ) external returns (uint256 returnAmount);

    function swap(
        address oneSplitAddress,
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx
    ) external returns (uint256 returnAmount);

    function feeManager() external returns (address);

    function _lpToContract(address token) external returns (address);

    function _contractToLP(address token) external returns (address);
}