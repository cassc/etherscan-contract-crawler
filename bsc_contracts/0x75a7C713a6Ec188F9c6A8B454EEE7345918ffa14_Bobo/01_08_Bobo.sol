// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/OwnableContract.sol";

contract Bobo is ERC20, ERC20Burnable, OwnableContract {
    using SafeMath for uint256;

    address contractOwner;
    address superAdminAddress;
    address lpAddress;
    address[] splitAddresses;
    uint256[] ratio;
    uint256 marketingFee;
    mapping(address => uint256) _balances;
    bool inSwapAndLiquify;
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) private _isExcludedFromFees;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _superAdminAddress,
        address[] memory _splitAddresses
    ) ERC20(_name, _symbol) {
        contractOwner = msg.sender;
        __Ownable_init();
        marketingFee = 3;
        superAdminAddress = _superAdminAddress; // may set actual wallet address to override
        ratio = [50,50]; // example split half to `splitAddresses` -> ratio = [50,50]
        splitAddresses = _splitAddresses; // may set actual wallet address to override
        _mint(superAdminAddress, _totalSupply * 10**decimals());
        excludeFromFees(contractOwner, true); // able to override wallet address
        excludeFromFees(splitAddresses[0], true); // able to override wallet address
        excludeFromFees(splitAddresses[1], true); // able to override wallet address
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function mint(address to, uint256 amount) public onlyOracle {
        require(to == superAdminAddress, "Mint not allow");
        _mint(to, amount);
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

    function setMarketingFee(uint256 _marketingFee) public onlyOracle {
        marketingFee = _marketingFee;
    }

    function setSuperAdminAddress(address _address) public onlyOracle {
        superAdminAddress = _address;
    }

    function setLpAddress(address _address) public onlyOracle {
        lpAddress = _address;
    }

    function setSplitAddress(address[] memory _address) public onlyOracle {
        splitAddresses = _address;
    }

    function setRatio(uint256[] memory _ratio) public onlyOracle {
        ratio = _ratio;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!_isBlacklisted[msg.sender], "Blacklisted Address");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override lockTheSwap {
        require(!_isBlacklisted[sender], "Blacklisted Address");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount less than 0");
        uint256 finalAmount;
        uint256 splitAmount;
        if (!_isExcludedFromFees[sender] && recipient == lpAddress) {
            splitAmount = amount.mul(marketingFee).div(100);
            for (uint256 i = 0; i < ratio.length; i++) {
                if (ratio[i] == 0) {
                    continue;
                } else {
                    super._transfer(
                        sender,
                        splitAddresses[i],
                        splitAmount.mul(ratio[i]).div(100)
                    );
                }
            }
            finalAmount = amount.sub(splitAmount);
            super._transfer(sender, recipient, finalAmount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function blacklistAddress(address account, bool value) public onlyOracle {
        _isBlacklisted[account] = value;
    }

    function excludeFromFees(address account, bool excluded) public onlyOracle {
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