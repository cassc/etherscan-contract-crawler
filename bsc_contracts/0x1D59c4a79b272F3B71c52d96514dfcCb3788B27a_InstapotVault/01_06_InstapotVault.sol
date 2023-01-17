// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InstapotVault is OwnableUpgradeable {

    using SafeMath for uint256;

    uint256 public vaultBalance;
    uint256 public maxPayout24h;
   
    address public lmsWallet;
    address internal busdAddress;

    IERC20 internal busd;
    address internal operator;

    mapping(address => _userStats) public userStats;
    mapping(address => uint256) public userBalance;

    modifier onlyOperator {
        require( msg.sender == operator || msg.sender == owner() );
        _;
    }

    struct _userStats {
        uint256 depositTotal;
        uint256 payoutTotal;
        uint256 payout24h;
        uint256 last24hPeriodStart;
    }

    bool public enabled;

    event LmsWalletSet(address wallet);
    event BUSDAddressSet(address tokenAddress);
    event OperatorSet(address operator);
    event DepositDone(address player, uint256 amount);
    event LmsFeePaid(address wallet, uint256 amount);
    event WithdrawDone(address player, uint256 amount);
    
    
    function initialize() external initializer {
        __Ownable_init();

        operator = address(0xB4431491dF7E047B0212f579D4937389bA4b4522);
        setlmsWallet(address(0xC0DbD2E9CF0622828173D946D3793Df4c90e0f2f));
        //setBUSDAddress(address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7)); // TESTNET
        setBUSDAddress(address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56)); // MAINNET
        maxPayout24h = 10000 ether;
    } 

    // *************** Configuration *****************

    function setlmsWallet(address wallet) public onlyOwner {
        require(wallet != address(0), "Set a valid Dev Wallet address");
        lmsWallet = wallet;
        emit LmsWalletSet(lmsWallet);
    }

    function getBUSDAddress() public view returns (address) {
        return busdAddress;
    }
    function setBUSDAddress(address address_) public onlyOwner {
        require(address_ != address(0), "Set a valid BUSD address");
        busdAddress = address_;
        busd = IERC20(address_);
        emit BUSDAddressSet(address_);
    }

    function getOperator() public view returns (address) {
        return operator;
    }
    function setOperator(address wallet) external onlyOwner {
        require(wallet != address(0), "Set a valid address");
        operator = wallet;
        emit OperatorSet(wallet);
    }

    function getBUSDAllowanceWallet(address wallet) public view returns (uint256) {
        return busd.allowance(wallet, address(this));
    }

    function setEnabled(bool _enabled) external onlyOperator {
        enabled = _enabled;
    }


    function deposit(uint256 amount) public returns (bool) {

        require(enabled, "not enabled");
        address _addr = msg.sender;
        require(amount > 0, "Amount should be more than 0");

        // BUSD transfer
        require(busd.transferFrom(_addr, address(this), amount), "BUSD Deposit was failed");

        vaultBalance += amount;
        //userBalance[_addr] += amount; // only the operator is able to set this
        userStats[_addr].depositTotal += amount;

        // Emit the event
        emit DepositDone(_addr, amount);
        return true;
    }

    function lmsFeePayment(uint256 amount) onlyOperator public returns (bool)  {
        require(amount > 0, "Amount should be bigger than 0");
        
        vaultBalance -= amount;

        // Transfer the BUSD to the Dev Wallet
        require(busd.transfer(lmsWallet, amount), "lmsFee transfer failed");

        emit LmsFeePaid(lmsWallet, amount);
        return true;
    }

    function payout(address _addr, uint256 amount) onlyOperator public returns (bool) {
        require(enabled, "not enabled");
        require(amount > 0, "Amount should be bigger than 0");
        require(_addr != address(0), "Player wallet invalid");
        require(userBalance[_addr] >= amount, "insufficient balance");

        vaultBalance -= amount;
        userBalance[_addr] -= amount;
        userStats[_addr].payoutTotal += amount;

        // track the timestamp for a new 24h period
        if(userStats[_addr].last24hPeriodStart == 0 || userStats[_addr].last24hPeriodStart < block.timestamp.sub(24 hours)){
            userStats[_addr].last24hPeriodStart = block.timestamp;
            userStats[_addr].payout24h = amount;
        }else{
            userStats[_addr].payout24h += amount;
        }

        require(userStats[_addr].payout24h <= maxPayout24h, "maximum payout reached");

        // Withdraw the amount to the player wallet
        require(busd.transfer(_addr, amount), "BUSD Withdraw transfer failed");

        emit WithdrawDone(_addr, amount);
        return true;
    }

    /*function claim(uint256 amount) public returns (bool) {
        address _addr = msg.sender;

        require(amount > 0, "Amount should be bigger than 0");
        require(userBalance[_addr] >= amount, "insufficient balance");

        vaultBalance -= amount;
        userBalance[_addr] -= amount;
        userStats[_addr].payoutTotal += amount;

        // track the timestamp for a new 24h period
        if(userStats[_addr].last24hPeriodStart == 0 || userStats[_addr].last24hPeriodStart < block.timestamp.sub(24 hours)){
            userStats[_addr].last24hPeriodStart = block.timestamp;
            userStats[_addr].payout24h = amount;
        }else{
            userStats[_addr].payout24h += amount;
        }

        require(userStats[_addr].payout24h <= maxPayout24h, "maximum payout reached");

        // Withdraw the amount to the player wallet
        require(busd.transfer(_addr, amount), "BUSD Withdraw transfer failed");

        emit WithdrawDone(_addr, amount);
        return true;
    }*/

    function setPlayerBalances(address[] calldata _players, uint256[] calldata _values) external onlyOperator {
        require(_players.length == _values.length, "invalid data");
		for(uint256 i = 0; i < _players.length; i++) {
			userBalance[_players[i]] = _values[i];
		}

	}
   
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
   */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
   */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /* @dev Subtracts two numbers, else returns zero */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    /**
     * @dev Adds two numbers, throws on overflow.
   */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}