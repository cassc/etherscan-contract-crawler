// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Elixir is Ownable, ERC20 {
    bool public transferable = false;
    uint256 public constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    bool public saleOpen = false;
    mapping(address => bool) private _elixirMerchant;

    constructor() ERC20('Elixir', 'ELX') {}

    function mint(address to, uint256 quantity) external payable {
        if (_msgSender() != owner()) {
            require(saleOpen, "Sale has not started");
            if (quantity == 1) {
                require(msg.value == 0.039 ether, "Not enough eth for elixir");
                _mint(to, 1e18);
            } else if (quantity == 5) {
                require(msg.value == 0.195 ether, "Not enough eth for elixir");
                _mint(to, 6*1e18);
            } else if (quantity == 10) {
                require(msg.value == 0.39 ether, "Not enough eth for elixir");
                _mint(to, 13*1e18);
            }
        } else {
            _mint(to, quantity*1e18);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (!_elixirMerchant[_msgSender()]) {
            uint256 currentAllowance = allowance(sender, _msgSender());
            require(currentAllowance >= amount, 'Transfer amount exceeds allowance');
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function burn(address _owner, uint256 _amount) external onlyElixirMerchant {
        _burn(_owner, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (_msgSender() != owner() && !_elixirMerchant[_msgSender()] && from != address(0)) {
            require(transferable, 'Cannot transfer if false');
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        if (_elixirMerchant[spender]) {
            return MAX_INT;
        }

        return super.allowance(owner, spender);
    }

    function addElixirMerchant(address elixirMerchant) public onlyOwner {
        _elixirMerchant[elixirMerchant] = true;
    }

    function removeElixirMerchant(address elixirMerchant) public onlyOwner {
        _elixirMerchant[elixirMerchant] = false;
    }

    function setTransferable(bool _transferable) public onlyOwner {
        transferable = _transferable;
    }

    function setSale(bool hasSaleStarted) public onlyOwner {
        saleOpen = hasSaleStarted;
    }

    modifier onlyElixirMerchant() {
        require(_elixirMerchant[_msgSender()], 'Caller is not an elixir merchant');
        _;
    }
}