// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface CarbonCoinI {
    function isAddressInBlackList (address) external view returns (bool);
    function balanceOf (address) external view returns (uint);
    function transfer (address, uint) external returns (bool);
    function redeemDebit (address, uint) external returns (bool);
}

contract CarbonCoinProxy is ERC20 {
    address private _owner;
    address private _admin;
    address private _gcxTokenAddress;
    address private exchangeCollector;
    address private exchangeFeeCollector;
    address private redeemFeeCollector;
    uint public exchangeFee;
    uint private redeemFee;
    IERC20 public exchangeableToken;
    uint public certIndex;
    uint private exchangeRate;
    bool private allowExchange;
    uint public _totalSupply;
    CarbonCoinI private gcxToken;

    struct Cert{
        uint256 name;
        address recipient;
        uint datetime;
        uint quantity; 
        uint256 email;
    }

    Cert[] public cert;
    
    constructor(address gcxTokenAddress, address gcxRateUpdateAddress) ERC20("Green Carbon Proxy", "GCXProxy") {
        exchangeableToken = IERC20(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD);
        allowExchange = true;
        exchangeRate = 220000;
        certIndex = 0;
        _owner = msg.sender;
        _admin = gcxRateUpdateAddress;
        _gcxTokenAddress = gcxTokenAddress;
        gcxToken = CarbonCoinI(gcxTokenAddress);
        exchangeFee = 1000;
        redeemFee = 1000000000000000;
        exchangeCollector = 0xE3D8f9063A4527ae2c4d33157fc145bAD63cdE53;
        exchangeFeeCollector = 0xE3D8f9063A4527ae2c4d33157fc145bAD63cdE53;
        redeemFeeCollector = 0xE3D8f9063A4527ae2c4d33157fc145bAD63cdE53;
    }
    
    function exchangeToken (uint amount) external returns (bool) {
        require(allowExchange, 'Service unavailable');
        require(!gcxToken.isAddressInBlackList(msg.sender), 'Address is in Black List');
        uint fee = 0;
        if (fee > 0) {
            fee = amount / exchangeFee;
        }
        require(amount + fee <= exchangeableToken.balanceOf(msg.sender), 'Insufficient token');
        require(1 <= amount, 'Invalid amount');
        uint token = (amount * exchangeRate) / 1000000;
        require(gcxToken.balanceOf(address(this)) >= token, 'Insufficient balance');
        exchangeableToken.transferFrom(msg.sender, address(this), amount + fee);
        exchangeableToken.transfer(exchangeCollector, amount);
        if (fee > 0) {
            exchangeableToken.transfer(exchangeFeeCollector, amount);
        }
        gcxToken.transfer(msg.sender, uint(token));
        return true;
    }

    function redeem (uint256 name, uint quantity, uint256 email) external payable returns (uint) {
        require(gcxToken.balanceOf(msg.sender) >= quantity, 'Insufficient balance');
        require(msg.value == redeemFee, 'Insufficient to cover fees');
        payable(redeemFeeCollector).transfer(redeemFee);
        Cert memory userCert = Cert(name, msg.sender, block.timestamp, quantity, email);
        cert.push(userCert);
        certIndex += 1;
        gcxToken.redeemDebit(msg.sender, quantity);
        return quantity;
    }

    function updateExchangeRate (uint rate) external {
        require(msg.sender == _admin || msg.sender == _owner);
        require(rate > 0);
        exchangeRate = rate;
    }

    function transferToken (address token, uint amount) external {
        require(msg.sender == _owner);
        require(amount > 0);
        IERC20 tokenContract = IERC20(token);
        tokenContract.transfer(_owner, amount);        
    }
    
    function updateOwner (address newOwner) external {
        require(msg.sender == _owner);
        _owner = newOwner;
    }
    
    function updateAdmin (address newAdmin) external {
        require(msg.sender == _owner);
        _admin = newAdmin;
    }

    function updateExchangeTokenAllow (bool allow) external {
        require(msg.sender == _owner);
        allowExchange = allow;
    }

    function updateExchangeTokenAddress (address newAddress) external {
        require(msg.sender == _owner);
        exchangeableToken = IERC20(newAddress);
    }
    
    function updateExchangeFee(uint fee) external {
        require(msg.sender == _owner);
        exchangeFee = fee;
    }
    
    function updateRedeemFee(uint fee) external {
        require(msg.sender == _owner);
        redeemFee = fee;
    }
    
    function updateExchangeCollector(address collector) external {
        require(msg.sender == _owner);
        exchangeCollector = collector;
    }
    
    function updateExchangeFeeCollector(address collector) external {
        require(msg.sender == _owner);
        exchangeFeeCollector = collector;
    }
    
    function updateRedeemFeeCollector(address collector) external {
        require(msg.sender == _owner);
        redeemFeeCollector = collector;
    }

    function getExchangeRate() public view returns (uint) {
        return exchangeRate;
    }

    function listCert (uint index) public view returns(uint256, address, uint, uint, uint256) {
        require(index < certIndex);
        return (cert[index].name, cert[index].recipient, cert[index].datetime ,cert[index].quantity, cert[index].email);
    }

    function getCertIndex() public view returns (uint) {
        return certIndex;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function getAdmin() public view returns (address) {
        return _admin;
    }
    
    function getExchangeTokenAllow() public view returns (bool) {
        return allowExchange;
    }
    
    function getExchangeTokenAddress() public view returns (address) {
        return address(exchangeableToken);
    }
    
    function getExchangeFee() public view returns (uint) {
        return exchangeFee;
    }
    
    function getRedeemFee() public view returns (uint) {
        return redeemFee;
    }
    
    function getExchangeCollector() public view returns (address) {
        return exchangeCollector;
    }
    
    function getExchangeFeeCollector() public view returns (address) {
        return exchangeFeeCollector;
    }
    
    function getRedeemFeeCollector() public view returns (address) {
        return redeemFeeCollector;
    }
}