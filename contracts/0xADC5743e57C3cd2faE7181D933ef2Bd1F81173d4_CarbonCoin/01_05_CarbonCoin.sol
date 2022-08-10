// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface CarbonCoinProxyI {
    function updateExchangeRate (uint rate) external;
    function exchangeToken (uint amount) external returns (uint);
    function redeem (uint256, uint, uint256, address) external returns (uint);
    function listCert (uint index) external view returns (uint256, address, uint, uint, uint256);
    function getExchangeRate() external view returns (uint);
    function getExchangeTokenAllow() external view returns (bool);
    function getExchangeTokenAddress() external view returns (address);
    function getOwner() external view returns (address);
    function getAdmin() external view returns (address);
    function getExchangeCollector() external view returns (address);
    function getExchangeFeeCollector() external view returns (address);
    function getRedeemCollector() external view returns (address);
    function getRedeemFeeCollector() external view returns (address);
    function getExchangeFee() external view returns (uint);
}

contract CarbonCoin is ERC20 {
    mapping(address => uint256) public _balances;
    mapping(address => bool) public blackList;

    address private _owner;
    address private _proxy;
    uint public _totalSupply;
    CarbonCoinProxyI public gcxProxy;
    
    constructor(address gcxProxyAddress) ERC20("Green Carbon Coin", "GCX") {
        _owner = msg.sender;
        _proxy = gcxProxyAddress;
        _totalSupply = 100000000000000;
        _balances[_proxy] = _totalSupply;
        gcxProxy = CarbonCoinProxyI(_proxy);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address holder) public view virtual override returns (uint balance) {
        return _balances[holder];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address from = _msgSender();
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blackList[to]);
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] -= amount;
        }

        address[6] memory bypassAddress = [
            gcxProxy.getOwner(),
            gcxProxy.getAdmin(),
            gcxProxy.getExchangeCollector(),
            gcxProxy.getExchangeFeeCollector(),
            gcxProxy.getRedeemCollector(),
            gcxProxy.getRedeemFeeCollector()
        ];

        bool bypass = false;
        for (uint i=0; i<bypassAddress.length; i++) {
            if (bypassAddress[i] == from || bypassAddress[i] == to) {
                bypass = true;
            }
        }

        if (bypass) {
            _balances[to] += amount;
        } else {
            uint charge = gcxProxy.getExchangeFee();
            uint fee = amount / charge;
            _balances[to] += amount - fee;
            _balances[bypassAddress[5]] += fee;
        }
        return true;
    }
    
    function updateProxy (address proxy) external {
        require(msg.sender == _owner);
        _proxy = proxy;
    }

    function updateBlackListAddress (address newAddress, bool isBlocked) external {
        require(msg.sender == _owner);
        blackList[newAddress] = isBlocked;
    }

    function updateExchangeRate (uint rate) external {
        gcxProxy.updateExchangeRate(rate);
    }

    function redeemDebit (address from, uint amount) external returns (bool) {
        require(msg.sender == _proxy);
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] -= amount;
        _balances[msg.sender] += amount;
        return true;
    }

    function listCert (uint index) public view returns(uint256, address, uint, uint, uint256) {
        return gcxProxy.listCert(index);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function getProxy() public view returns (address) {
        return _proxy;
    }

    function getExchangeRate() public view returns (uint) {
        return gcxProxy.getExchangeRate();
    }
    
    function getExchangeTokenAllow() public view returns (bool) {
        return gcxProxy.getExchangeTokenAllow();
    }
    
    function getExchangeTokenAddress() public view returns (address) {
        return gcxProxy.getExchangeTokenAddress();
    }
    
    function isAddressInBlackList(address lookupAddress) public view returns (bool) {
        return blackList[lookupAddress];
    }
}