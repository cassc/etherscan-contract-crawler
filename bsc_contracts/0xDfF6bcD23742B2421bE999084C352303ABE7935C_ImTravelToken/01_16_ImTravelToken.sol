// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IImTravelToken.sol";

contract ImTravelToken is ERC20Upgradeable, OwnableUpgradeable, IImTravelToken {
    using SafeMath for uint256;

    address public swapAddress;
    uint256 public tax;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) private _isExcludedFromFees;

    event UpdateUniswapV2Address(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    function initialize(
        address[2] memory addrs, // [0] = owner, [1] = router
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 tax_
    ) external override initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init();

        tax = tax_;
        swapAddress = addrs[1];

        excludeFromFees(addrs[0], true);
        excludeFromFees(address(this), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(addrs[0], totalSupply_);
        transferOwnership(addrs[0]);
    }

    receive() external payable {}

    function updateUniswapV2Address(address newAddress) public onlyOwner {
        require(
            newAddress != swapAddress,
            "ImTravelToken: The router already has that address"
        );

        swapAddress = newAddress;
        emit UpdateUniswapV2Address(newAddress, swapAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "ImTravelToken: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        _isBlacklisted[account] = value;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool takeFee = false;

        if (from == swapAddress || to == swapAddress) {
            takeFee = true;
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = amount.mul(tax).div(100);
            amount = amount.sub(fees);

            _burn(from, fees);
        }

        super._transfer(from, to, amount);
    }
}