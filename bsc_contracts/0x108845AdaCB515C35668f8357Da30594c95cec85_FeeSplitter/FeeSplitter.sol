/**
 *Submitted for verification at BscScan.com on 2023-02-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IOwned {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
    function claimOwnership() external;
}

abstract contract Owned is IOwned {
    address public override owner = msg.sender;
    address internal pendingOwner;

    modifier ownerOnly() {
        require (msg.sender == owner, "Owner only");
        _;
    }

    function transferOwnership(address newOwner) public override ownerOnly() {
        pendingOwner = newOwner;
    }

    function claimOwnership() public override {
        require (pendingOwner == msg.sender);
        pendingOwner = address(0);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
    }
}

contract Whitelist is Owned {

    modifier onlyWhitelisted() {
        if(active){
            require(whitelist[msg.sender], 'not whitelisted');
        }
        _;
    }

    bool active = true;

    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    function activateDeactivateWhitelist() public ownerOnly() {
        active = !active;
    }

    function addAddressToWhitelist(address addr) public ownerOnly() returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function addAddressesToWhitelist(address[] calldata addrs) public ownerOnly() returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    function removeAddressFromWhitelist(address addr) ownerOnly() public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    function removeAddressesFromWhitelist(address[] calldata addrs) ownerOnly() public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}

contract FeeSplitter is Whitelist {
    using SafeMath for uint256;

    /////////////////////////////////
    // CONFIGURABLES AND VARIABLES //
    /////////////////////////////////

    mapping (IERC20 => address[]) public feeCollectors;
    mapping (IERC20 => uint256[]) public feeRates;

    //////////////////////////////
    // CONSTRUCTOR AND FALLBACK //
    //////////////////////////////

    constructor(address _dev) {
        transferOwnership(_dev);
    }

    // FALLBACK FUNCTION: PAYABLE
    receive () external payable {

    }

    // Distribute collected fees between all set collectors, at set rates
    function distribute(IERC20 token) public {
        uint256 balance = token.balanceOf(address(this));
        require (balance > 0, "Nothing to pay");

        address[] memory collectors = feeCollectors[token];
        uint256[] memory rates = feeRates[token];

        for (uint256 i = 0; i < collectors.length; i++) {
            address collector = collectors[i];
            uint256 rate = rates[i];

            if (rate > 0) {
                uint256 feeAmount = rate * balance / 10000;
                token.transfer(collector, feeAmount);
            }
        }
    }

    ////////////////////////////////////////////////
    // FUNCTIONS RESTRICTED TO THE CONTRACT OWNER //
    ////////////////////////////////////////////////

    // Set collectors and rates for a token
    function setDistribution(IERC20 token, address[] memory collectors, uint256[] memory rates) onlyWhitelisted() public {
        uint256 totalRate;

        for (uint256 i = 0; i < rates.length; i++) {
            totalRate = totalRate + rates[i];
        }

        require (totalRate == 10000, "Total fee rate must be 100%");

        if (token.balanceOf(address(this)) > 0) {
            distribute(token);
        }

        feeCollectors[token] = collectors;
        feeRates[token] = rates;
    }
}