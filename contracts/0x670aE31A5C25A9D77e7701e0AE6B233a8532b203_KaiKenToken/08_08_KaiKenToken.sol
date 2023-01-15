//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external;
}

interface IUniswapV2Pair {
    function price0CumulativeLast() external view returns (uint256);
}

contract KaiKenToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant totalSupply_ = 100_000_000_000 ether;
    IAntisnipe public antisnipe;
    bool public antisnipeDisable;

    uint16 public buyTax;
    uint16 public sellTax;
    uint16 public transferTax;

    address public taxRecipient;

    mapping(address => bool) public taxExcluded;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            from == address(0) ||
            to == address(0) ||
            from == address(this) ||
            to == address(this) ||
            to == taxRecipient
        ) return;
        if (!antisnipeDisable && address(antisnipe) != address(0))
            antisnipe.assureCanTransfer(msg.sender, from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            from == address(0) ||
            from == address(this) ||
            to == address(this) ||
            to == taxRecipient
        ) {
            return;
        }
        if (taxExcluded[to] || taxExcluded[from]) {
            return;
        }

        uint256 tax;

        if (_isPair(from)) {
            // buy
            tax = (amount * buyTax) / 100;
        } else if (_isPair(to)) {
            // sell
            tax = (amount * sellTax) / 100;
        } else {
            // transfer
            tax = (amount * transferTax) / 100;
        }

        _transfer(to, taxRecipient, tax);
    }

    /// @dev Returns true if the address is a Uniswap V2-like pair.
    function _isPair(address user) internal view returns (bool) {
        if (user.code.length == 0) return false;
        try IUniswapV2Pair(user).price0CumulativeLast() returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }

    function setTaxExcluded(address[] memory addrs, bool excluded) external onlyOwner {
        uint256 length = addrs.length;
        for (uint256 i = 0; i < length; ++i) {
            address addr = addrs[i];
            require(addr != address(0) && addr != address(this));
            taxExcluded[addr] = excluded;
        }
    }

    function setBuyTax(uint16 buyTax_) external onlyOwner {
        require(buyTax_ < 100, 'buy tax too high');
        buyTax = buyTax_;
    }

    function setSellTax(uint16 sellTax_) external onlyOwner {
        require(sellTax_ < 100, 'sell tax too high');
        sellTax = sellTax_;
    }

    function setTransferTax(uint16 transferTax_) external onlyOwner {
        require(transferTax_ < 100, 'transfer tax too high');
        transferTax = transferTax_;
    }

    function setTaxRecipient(address addr) external onlyOwner {
        require(addr != address(0) && addr != address(this));
        taxRecipient = addr;
    }

    function setAntisnipeDisable() external onlyOwner {
        require(!antisnipeDisable);
        antisnipeDisable = true;
    }

    function setAntisnipeAddress(address addr) external onlyOwner {
        antisnipe = IAntisnipe(addr);
    }

    constructor(
        uint256 buyTax_,
        uint256 sellTax_,
        uint256 transferTax_,
        address taxRecipient_
    ) ERC20('KaiKen', 'KKF') {
        require(buyTax_ < 100, 'buy tax too high');
        require(sellTax_ < 100, 'sell tax too high');
        require(transferTax_ < 100, 'transfer tax too high');
        require(
            taxRecipient_ != address(0) && taxRecipient_ != address(this),
            'bad recipient'
        );

        buyTax = uint16(buyTax_);
        sellTax = uint16(sellTax_);
        transferTax = uint16(transferTax_);

        taxRecipient = taxRecipient_;

        _mint(msg.sender, totalSupply_);
    }
}