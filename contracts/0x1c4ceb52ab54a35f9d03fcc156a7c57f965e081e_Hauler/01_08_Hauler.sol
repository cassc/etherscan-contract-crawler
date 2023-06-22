/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../library/AddArrayLib.sol";

import "../interfaces/ITradeExecutor.sol";
import "../interfaces/IHauler.sol";


contract Hauler is IHauler, ERC20 {

    using AddrArrayLib for AddrArrayLib.Addresses;

    // TODO Define this arbitrary limit
    uint constant BLOCK_LIMIT = 50;
    uint constant DUST_LIMIT = 10**6;

    AddrArrayLib.Addresses tradeExecutorsList;

    address public immutable override wantToken;
    uint8 private immutable tokenDecimals;
    bool public batcherOnlyDeposit;

    address public override keeper;
    address public override governance;
    address public batcher;
    address pendingGovernance;
    


    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _wantToken, address _keeper, address _governance) ERC20(_name, _symbol) {
        tokenDecimals = _decimals;
        wantToken = _wantToken;
        keeper = _keeper;
        governance = _governance;
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }


    function deposit(uint amountIn, address receiver) public onlyBatcher override returns (uint256 shares) {
        require(amountIn > 0);
        require(receiver != address(0));

        if (totalSupply() > 0) {
            shares = totalSupply() * amountIn / totalHaulerFunds();
        } else {
            shares = amountIn;
        }

        IERC20(wantToken).transferFrom(receiver, address(this), amountIn);
        _mint(receiver, shares);
    }

    function withdraw(uint sharesIn, address receiver) public override returns (uint256 amountOut) {
        require(sharesIn > 0);
        require(receiver != address(0));

        amountOut = sharesIn * totalHaulerFunds() / totalSupply();
        _burn(receiver, sharesIn);
        IERC20(wantToken).transfer(receiver, amountOut);
    }



    function totalHaulerFunds() public view returns (uint) {
        return IERC20(wantToken).balanceOf(address(this)) + totalExecutorFunds();
    }

    function depositIntoExecutor(address _executor, uint _amount) public isActiveExecutor(_executor) onlyKeeper {
        require(_amount > 0);
        IERC20(wantToken).transfer(_executor, _amount);
    }

    function withdrawFromExecutor(address _executor, uint _amount) public isActiveExecutor(_executor) onlyKeeper {
        require(_amount > 0);
        IERC20(wantToken).transferFrom(_executor, address(this), _amount);
    }


    function totalExecutors() public view returns (uint) {
        return tradeExecutorsList.size();
    }

    function executorByIndex(uint _index) public view returns (address) {
        require(_index < totalExecutors(), 'Index out of bounds');
        return tradeExecutorsList.getAddressAtIndex(_index);
    }

    function totalExecutorFunds() public view returns (uint) {
        uint totalFunds = 0;
        for (uint i = 0; i < totalExecutors(); i++) {
            address executor = executorByIndex(i);
            (uint executorFunds, uint blockUpdated) = ITradeExecutor(executor).totalFunds();
            require (block.number <= blockUpdated + BLOCK_LIMIT, 'Executor funds are not up to date');
            totalFunds += executorFunds;

        }
        return totalFunds;
    }


    /// EXECUTOR MANAGEMENT ///
    function addExecutor(address _tradeExecutor) public isValidAddress(_tradeExecutor) onlyKeeper {
        tradeExecutorsList.pushAddress(_tradeExecutor);
    }

    function removeExecutor(address _tradeExecutor) public isValidAddress(_tradeExecutor) onlyKeeper {
        (uint executorFunds, uint blockUpdated) = ITradeExecutor(_tradeExecutor).totalFunds();
        require (block.number <= blockUpdated + BLOCK_LIMIT, 'Executor funds are not up to date');
        require (executorFunds < DUST_LIMIT, 'Executor not empty');
        tradeExecutorsList.removeAddress(_tradeExecutor);
    }

    function setBatcher(address _batcher) public onlyGovernance {
        batcher = _batcher;
    }

    function setBatcherOnlyDeposit(bool _batcherOnlyDeposit) public onlyGovernance {
        batcherOnlyDeposit = _batcherOnlyDeposit;
    }

    function setGovernance(address _governance) public onlyGovernance{
        pendingGovernance = _governance;
    }

    function acceptGovernance() public {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
    }

    function setKeeper(address _keeper) public onlyGovernance {
        keeper = _keeper;
    }

    modifier onlyGovernance {
        require(msg.sender == governance, "Only governance call");
        _;
    }

    modifier onlyKeeper {
        require(msg.sender == keeper, "Only keeper call");
        _;
    }

    modifier onlyBatcher {
        if (batcherOnlyDeposit) {
            require(msg.sender == batcher, "Only batcher call");
        }
        _;
    }

    modifier isValidAddress(address _tradeExecutor) {
        require(_tradeExecutor!= address(0), 'Invalid address');
        _;
    }

    modifier isActiveExecutor(address _tradeExecutor) {
        require(tradeExecutorsList.exists(_tradeExecutor), "Executor is not active or doesnt exist");
        _;
    }

    

}