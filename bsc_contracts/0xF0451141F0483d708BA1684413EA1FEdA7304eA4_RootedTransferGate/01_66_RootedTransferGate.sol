// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./Address.sol";
import "./IERC20.sol";
import "./ISwapPair.sol";
import "./ILiquidityLockedERC20.sol";
import "./ISwapRouter02.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./TokensRecoverable.sol";
import "./ITransferGate.sol";
import "./AddressRegistry.sol";

contract RootedTransferGate is TokensRecoverable, ITransferGate {   
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ISwapPair public mainPool;
    AddressRegistry public addressRegistry;

    ISwapRouter02 immutable internal swapRouter;
    ILiquidityLockedERC20 immutable internal rootedToken;

    bool public unrestricted;
    bool public tradingEnabled;

    mapping (address => bool) public unrestrictedControllers;
    mapping (address => bool) public feeControllers;
    
    mapping (address => uint256) public poolsTaxRates;
    mapping (address => uint256) public recordedDebt;

    address public override feeSplitter;

    uint256 public transferTaxRate;
    uint256 public dumpTaxStartRate; 
    
    uint256 public dumpTaxDurationInSeconds;
    uint256 public dumpTaxEndTimestamp;

    constructor(ILiquidityLockedERC20 _rootedToken, ISwapRouter02 _swapRouter) {
        rootedToken = _rootedToken;
        swapRouter = _swapRouter;
        tradingEnabled = false;
    }

    function setTradingEnabled(bool _tradingEnabled) public ownerOnly() {
        tradingEnabled = _tradingEnabled;
    }

    function setUnrestrictedController(address unrestrictedController, bool allow) public ownerOnly() {
        unrestrictedControllers[unrestrictedController] = allow;
    }
    
    function setFeeControllers(address feeController, bool allow) public ownerOnly() {
        feeControllers[feeController] = allow;
    }

    function setFreeParticipantController(address freeParticipantController, bool allow) public ownerOnly() {
        addressRegistry.setFreeParticipantController(freeParticipantController, allow);
    }

    function setTrustedWallet(address trustedWallet, bool allow) public ownerOnly() {
        addressRegistry.setTrustedWallet(trustedWallet, allow);
    }

    function setFreeParticipant(address participant, bool free) public {
        require (msg.sender == owner || addressRegistry.freeParticipantControllers(msg.sender), "Not an owner or free participant controller");
        addressRegistry.setFreeParticipant(participant, free);
    }

    function setFeeSplitter(address _feeSplitter) public ownerOnly() {
        feeSplitter = _feeSplitter;
    }

    function setUnrestricted(bool _unrestricted) public {
        require (unrestrictedControllers[msg.sender], "Not an unrestricted controller");
        unrestricted = _unrestricted;
        rootedToken.setLiquidityLock(mainPool, !_unrestricted);
    }

    function setAddressRegistry(AddressRegistry _addressRegistry) public ownerOnly() {
        addressRegistry = _addressRegistry;
    }

    function setMainPool(ISwapPair _mainPool) public ownerOnly() {
        mainPool = _mainPool;
    }

     function setPoolTaxRate(address pool, uint256 taxRate) public ownerOnly() {
        require (taxRate <= 10000, "Fee rate must be less than or equal to 100%");
        poolsTaxRates[pool] = taxRate;        
    }

    function setDumpTax(uint256 startTaxRate, uint256 durationInSeconds) public {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        require (startTaxRate <= 10000, "Dump tax rate must be less than or equal to 100%");

        dumpTaxStartRate = startTaxRate;
        dumpTaxDurationInSeconds = durationInSeconds;
        dumpTaxEndTimestamp = block.timestamp + durationInSeconds;
    }

    function getDumpTaxRate() public view returns (uint256) {
        if (block.timestamp >= dumpTaxEndTimestamp) {
            return 0;
        }
        
        return dumpTaxStartRate*(dumpTaxEndTimestamp - block.timestamp)*1e18/dumpTaxDurationInSeconds/1e18;
    }

    function setFees(uint256 _transferTaxRate) public {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        require (_transferTaxRate <= 10000, "Fee rate must be less than or equal to 100%");
        transferTaxRate = _transferTaxRate;
    }

    function setDebt(address _addr, uint256 _debtAmount) public {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        recordedDebt[_addr] = _debtAmount;
    }

    function batchSetDebts(address[] memory addrs, uint256[] memory amounts) public {
        require (feeControllers[msg.sender] || msg.sender == owner, "Not an owner or fee controller");
        require (addrs.length == amounts.length, "Arrays must be of equal length");
        for (uint256 i = 0; i < addrs.length; i++) {
            recordedDebt[addrs[i]] = amounts[i];
        }
    }

    function handleTransfer(address, address from, address to, uint256 amount) public virtual override returns (uint256 _totalFees) {

        // Get User Debt (tokens owed to the project)
        uint256 userDebt = recordedDebt[from];
        uint256 payableDebt = 0;

        uint256 poolTaxRate = poolsTaxRates[to];
        uint256 dumpTaxRate = getDumpTaxRate();
        uint256 totalTaxRate = 0;

        // If from or to is blacklisted, then the amount is returned as fees.
        if (addressRegistry.blacklist(from) || addressRegistry.blacklist(to)) {
            return amount;
        }

        // If unrestricted, or 'from' or 'to' is a free participant, then no fees are charged.
        if (unrestricted || addressRegistry.freeParticipant(from) || addressRegistry.freeParticipant(to)) {
            return 0;
        }

        require(tradingEnabled, "Trading is not enabled yet");

        // If from or to is a trustedHolder, then dump tax is not in effect
        if (addressRegistry.trustedHolder(from) || addressRegistry.trustedHolder(to)) {
            dumpTaxRate = 0;
        }

        // If 'to' is not the mainPool (not a sell), then dump tax is not in effect
        if (to != address(mainPool)) {
            dumpTaxRate = 0;
        }

        // Collect user debt (if any and if capable)
        // If the transferred amount ('amount') is more than or equal to the user debt, then the user debt is cleared.
        // Else, the user debt is reduced by the payableDebt.
        if (amount >= userDebt) {
            payableDebt = userDebt; // Note how much debt is being paid
            amount -= userDebt; // Reduce the amount by the debt
            recordedDebt[from] = 0; // Clear the debt
        } else {
            payableDebt = amount; // Note how much debt is being paid
            amount -= payableDebt; // Reduce the amount by the debt
            recordedDebt[from] -= payableDebt; // Reduce the debt by the amount paid
        }

        // If poolTaxRate is higher than fee rate, then use the pool tax rate.
        if (poolTaxRate > transferTaxRate) {
            totalTaxRate = dumpTaxRate + poolTaxRate;
            return totalTaxRate >= 10000 ? _totalFees = amount : _totalFees = payableDebt + (amount * totalTaxRate / 10000);
        }

        // Find the total tax rate and return the fee amount (plus any debt due)
        totalTaxRate = dumpTaxRate + transferTaxRate;
        _totalFees = payableDebt + (amount * totalTaxRate / 10000);
    }
}