// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/OwnableContract.sol";

contract DCO is ERC20, ERC20Burnable, OwnableContract {
    using SafeMath for uint256;

    address contractOwner;
    address superAdminAddress;
    address lpAddress;
    address splitAddresses;
    uint256 marketingFee;
    mapping(address => uint256) _balances;
    bool inSwapAndLiquify;
    mapping(address => bool) private _isExcludedFromFees;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        contractOwner = msg.sender;
        __Ownable_init();
        marketingFee = 3;
        superAdminAddress = address(0x6080b14E69157e8dcA7F28aB1CDbb48fd3777363);
        splitAddresses = address(0x1d0a2ec7728E82f19be05E0C682a207D88A8590D);
        _mint(superAdminAddress, _totalSupply * 10**decimals());
        excludeFromFees(contractOwner, true);
        excludeFromFees(splitAddresses, true);
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function bulkTransfer(address[] memory _users, uint256[] memory _value) public returns (bool success) {
        for (uint256 i = 0; i < _users.length; i++) {
            require(
                balanceOf(msg.sender) >= _value[i],
                "Not approved to transfer."
            );
            _transfer(msg.sender, _users[i], _value[i]);
        }
        return true;
    }

    function setLpAddress(address _address) public onlyOwner {
        lpAddress = _address;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override lockTheSwap {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount less than 0");
        uint256 finalAmount;
        uint256 splitAmount;
        if (!_isExcludedFromFees[sender] && recipient == lpAddress) {
            splitAmount = amount.mul(marketingFee).div(100);
            super._transfer(
                    sender,
                    splitAddresses,
                    splitAmount
                );
            finalAmount = amount.sub(splitAmount);
            super._transfer(sender, recipient, finalAmount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account already excluded fee"
        );
        _isExcludedFromFees[account] = excluded;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }
}