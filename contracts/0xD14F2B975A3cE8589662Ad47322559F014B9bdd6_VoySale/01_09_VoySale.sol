// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IVesting {
    function addUser(address _userAddress, uint256 _amount) external;
}

interface IVoyToken {
    function mint(address to, uint256 amount) external;
}

contract VoySale is Ownable {
    enum Assets { USDT, WBTC, ETH }

    //Equivalent to USD 0.12
    uint256 constant PRICE_ETH = 98000000000000;
    uint256 constant PRICE_USDT = 120000;
    uint256 constant PRICE_WBTC = 680;

    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    mapping(address=>bool) public whitelist;

    address public voyToken;
    address public vesting;

    uint256 privateSaleStarts;
    uint256 publicSaleStarts;

    constructor(address _voyToken, address _vesting) {
        voyToken = _voyToken;
        vesting = _vesting;
    }

    function setWhitelist(address _who, bool _enabled) public onlyOwner {
        whitelist[_who] = _enabled;
    }

    function recoverTokens(uint256 _amount, address _token) public onlyOwner {
        SafeERC20.safeTransfer(IERC20(_token), msg.sender, _amount); 
    }

    function recoverETH(uint256 _amount) public onlyOwner {
         (bool sent, bytes memory data) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getPrice(uint256 _amount, Assets _asset) public pure returns(uint256) {
        uint256 price;

        if (_asset == Assets.ETH) {
            price = PRICE_ETH;
        }
        else if(_asset == Assets.USDT) {
            price = PRICE_USDT;
        }
        else if(_asset == Assets.WBTC) {
            price = PRICE_WBTC;
        }
        else {
            revert();
        }

        return price * _amount / 1e18;
    }

    function buy(uint256 _amount, Assets _asset) public payable {
        require(block.timestamp > publicSaleStarts || (block.timestamp > privateSaleStarts && whitelist[msg.sender]), "Cannot purchase");

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

        IVoyToken(voyToken).mint(address(vesting), _amount);
        IVesting(vesting).addUser(msg.sender, _amount);
    }
}