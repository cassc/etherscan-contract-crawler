//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ISpotStorage} from "src/spot/interfaces/ISpotStorage.sol";

interface ISpot is ISpotStorage {
    event InitializeSpot(
        uint256 _maxFundraisingPeriod,
        uint256 _mFee,
        uint256 _pFee,
        address indexed _owner,
        address indexed _admin,
        address indexed _treasury
    );
    event NewFundCreated(
        address indexed baseToken,
        address indexed depositToken,
        uint256 fundraisingPeriod,
        address indexed manager,
        bytes32 salt,
        uint256 chainId,
        uint96 capacity
    );
    event BaseTokenUpdate(address indexed baseToken, bool isBaseToken);
    event DepositTokenUpdate(address indexed depositToken, bool isDepositToken);
    event StfxSwapUpdate(address indexed swap);
    event StfxTradeUpdate(address indexed trade);
    event PluginUpdate(address indexed plugin, bool _isPlugin);
    event DepositIntoFund(address indexed investor, uint256 amount, bytes32 indexed salt);
    event FundraisingClosed(bytes32 stf);
    event Claimed(address indexed investor, uint256 amount, bytes32 indexed salt);
    event CancelVault(bytes32 indexed salt);
    event TokenCapacityUpdate(address indexed baseToken, address indexed depositToken, uint96 capacity);
    event MinInvestmentAmountChanged(address indexed depositToken, uint96 minAmount);
    event MaxFundraisingPeriodChanged(uint40 maxFundraisingPeriod);
    event ManagerFeeChanged(uint96 managerFee);
    event ProtocolFeeChanged(uint96 protocolFee);
    event OwnerChanged(address indexed newOwner);
    event FundDeadlineChanged(bytes32 indexed salt, uint256 fundDeadline);
    event AdminChanged(address indexed admin);
    event TreasuryChanged(address indexed treasury);
    event ManagingFundUpdate(address indexed manager, bool isManaging);
    event TradeMappingUpdate(address indexed baseToken, address indexed stfxTrade);
    event Withdraw(address indexed token, uint96 amount, address indexed to);

    function owner() external view returns (address);

    function managerCurrentStf(address) external returns (bytes32);

    function managerFee() external view returns (uint96);

    function protocolFee() external view returns (uint96);

    function admin() external view returns (address);

    function treasury() external view returns (address);

    function getTradeMapping(address _baseToken) external view returns (address);

    function getManagerCurrentStfInfo(address) external returns (StfSpotInfo memory);

    function getStfInfo(bytes32) external returns (StfSpotInfo memory);

    function createNewStf(StfSpot calldata _fund) external returns (bytes32);

    function closeFundraising() external;

    function transferToken(address token, uint256 amount) external;

    function openSpot(uint96 amount, uint96 received, bytes32 salt) external;

    function closeSpot(uint96 remaining, bytes32 salt) external;

    function claimableAmount(bytes32 salt, address investor) external view returns (uint256);

    function claim(bytes32) external;

    function cancelVault(bytes32) external;

    function addMinInvestmentAmount(address _token, uint96 _amount) external;

    function setManagerFee(uint96 _managerFee) external;

    function setProtocolFee(uint96 _protocolFee) external;

    function setOwner(address _owner) external;

    function setFundDeadline(bytes32 salt, uint40 _fundDeadline) external;

    function setIsManagingFund(address _manager, bool _isManaging) external;
}