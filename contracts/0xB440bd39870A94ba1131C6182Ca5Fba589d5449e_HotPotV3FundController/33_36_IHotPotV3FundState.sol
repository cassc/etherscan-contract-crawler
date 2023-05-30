// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Hotpot V3 状态变量及只读函数
interface IHotPotV3FundState {
    /// @notice 控制器合约地址
    function controller() external view returns (address);

    /// @notice 基金经理地址
    function manager() external view returns (address);

    /// @notice 基金本币地址
    function token() external view returns (address);

    /// @notice 32 bytes 基金经理 + 任意长度的简要描述
    function descriptor() external view returns (bytes memory);

    /// @notice 基金锁定期
    function lockPeriod() external view returns (uint);

    /// @notice 基金经理收费基线
    function baseLine() external view returns (uint);

    /// @notice 基金经理收费比例
    function managerFee() external view returns (uint);

    /// @notice 基金存入截止时间
    function depositDeadline() external view returns (uint);

    /// @notice 获取最新存入时间
    /// @param account 目标地址
    /// @return 最新存入时间
    function lastDepositTime(address account) external view returns (uint);

    /// @notice 总投入数量
    function totalInvestment() external view returns (uint);

    /// @notice owner的投入数量
    /// @param owner 用户地址
    /// @return 投入本币的数量
    function investmentOf(address owner) external view returns (uint);

    /// @notice 指定头寸的资产数量
    /// @param poolIndex 池子索引号
    /// @param positionIndex 头寸索引号
    /// @return 以本币计价的头寸资产数量
    function assetsOfPosition(uint poolIndex, uint positionIndex) external view returns(uint);

    /// @notice 指定pool的资产数量
    /// @param poolIndex 池子索引号
    /// @return 以本币计价的池子资产数量
    function assetsOfPool(uint poolIndex) external view returns(uint);

    /// @notice 总资产数量
    /// @return 以本币计价的总资产数量
    function totalAssets() external view returns (uint);

    /// @notice 基金本币->目标代币 的购买路径
    /// @param _token 目标代币地址
    /// @return 符合uniswap v3格式的目标代币购买路径
    function buyPath(address _token) external view returns (bytes memory);

    /// @notice 目标代币->基金本币 的购买路径
    /// @param _token 目标代币地址
    /// @return 符合uniswap v3格式的目标代币销售路径
    function sellPath(address _token) external view returns (bytes memory);

    /// @notice 获取池子地址
    /// @param index 池子索引号
    /// @return 池子地址
    function pools(uint index) external view returns(address);

    /// @notice 头寸信息
    /// @dev 由于基金需要遍历头寸，所以用二维动态数组存储头寸
    /// @param poolIndex 池子索引号
    /// @param positionIndex 头寸索引号
    /// @return isEmpty 是否空头寸，tickLower 价格刻度下届，tickUpper 价格刻度上届
    function positions(uint poolIndex, uint positionIndex) 
        external 
        view 
        returns(
            bool isEmpty,
            int24 tickLower,
            int24 tickUpper 
        );

    /// @notice pool数组长度
    function poolsLength() external view returns(uint);

    /// @notice 指定池子的头寸数组长度
    /// @param poolIndex 池子索引号
    /// @return 头寸数组长度
    function positionsLength(uint poolIndex) external view returns(uint);
}