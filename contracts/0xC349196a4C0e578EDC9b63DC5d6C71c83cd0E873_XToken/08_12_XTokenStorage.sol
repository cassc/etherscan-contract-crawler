// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./interface/IInterestRateModel.sol";
import "./interface/IP2Controller.sol";

contract ERC20Storage{

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    mapping (address => mapping (address => uint256)) internal transferAllowances;

    mapping (address => uint256) internal accountTokens;
}

contract XTokenStorage is ERC20Storage {
    
    uint256 internal constant borrowRateMax = 0.0005e16;

    uint256 internal constant reserveFactorMax = 1e18;

    address payable public admin;
    
    address payable public pendingAdmin;

    bool internal _notEntered;

    IInterestRateModel public interestRateModel;

    uint256 internal initialExchangeRate;

    uint256 public reserveFactor;

    uint256 public totalBorrows;

    uint256 public totalReserves;

    uint256 public borrowIndex;

    uint256 public accrualBlockNumber;

    uint256 public totalCash;

    IP2Controller public controller;

    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    //order id => borrow snapshot
    mapping(uint256 => BorrowSnapshot) public orderBorrows;
    // orderId => liquidated or not

    struct LiquidateState{
        bool liquidated;
        address liquidator;
        uint256 liquidatedPrice;
    }
    mapping(uint256 => LiquidateState) public liquidatedOrders;

    address public underlying;

    address internal constant ADDRESS_ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    uint256 public constant ONE = 1e18;

    uint256 public transferEthGasCost;
}