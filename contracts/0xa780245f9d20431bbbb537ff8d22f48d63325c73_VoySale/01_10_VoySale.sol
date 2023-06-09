// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IVesting {
    function addUser(address _userAddress, uint256 _amount) external;
}

/**
 * VoySale contract in the Ethereum network
 */
contract VoySale is Ownable, Pausable {
    enum Assets { USDT, WBTC, ETH }

    //Equivalent to USD 0.12
    uint256 public priceEth = 94000000000000;
    uint256 public priceUsdt = 120000;
    uint256 public priceWBtc = 580;

    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    mapping(address=>bool) public whitelist;

    address public voyToken;
    address public vesting;

    constructor(address _voyToken, address _vesting) {
        voyToken = _voyToken;
        vesting = _vesting;

        setWhitelist(msg.sender, true);
    }

    event Purchase(address indexed user, uint256 amount, Assets _asset);

    function buy(uint256 _amount, Assets _asset) public payable whenNotPaused {
        require(whitelist[msg.sender], "Not whitelisted");
        require(_amount >= 1e18, "Invalid amount");

        if (_asset == Assets.ETH) {
            require(msg.value == getPrice(_amount, _asset), "Invalid value");
        }
        else if(_asset == Assets.USDT) {
            SafeERC20.safeTransferFrom(IERC20(USDT), msg.sender, address(this), getPrice(_amount, _asset));
        }
        else if(_asset == Assets.WBTC) {
            SafeERC20.safeTransferFrom(IERC20(WBTC), msg.sender, address(this), getPrice(_amount, _asset));
        }
        else {
            revert();
        }

        SafeERC20.safeTransferFrom(IERC20(voyToken), owner(), address(vesting), _amount);
        IVesting(vesting).addUser(msg.sender, _amount);

        emit Purchase(msg.sender, _amount, _asset);
    }

    function setWhitelist(address _who, bool _enabled) public onlyOwner {
        whitelist[_who] = _enabled;
    }

    function setMultiWhitelist(address[] memory _who, bool _enabled) public onlyOwner {
        for(uint i=0; i<_who.length;i++) {
            whitelist[_who[i]] = _enabled;
        }
    }

    function recoverTokens(uint256 _amount, address _token) public onlyOwner {
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, _amount); 
    }

    function recoverETH(uint256 _amount) public onlyOwner {
         (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getPrice(uint256 _amount, Assets _asset) public view returns(uint256) {
        uint256 price;

        if (_asset == Assets.ETH) {
            price = priceEth;
        }
        else if(_asset == Assets.USDT) {
            price = priceUsdt;
        }
        else if(_asset == Assets.WBTC) {
            price = priceWBtc;
        }
        else {
            revert();
        }

        return price * _amount / 1e18;
    }

    function updatePrice(uint256 _priceEth, uint256 _priceUsdt, uint256 _priceWBtc) public onlyOwner {
        priceEth = _priceEth;
        priceUsdt = _priceUsdt;
        priceWBtc = _priceWBtc;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}