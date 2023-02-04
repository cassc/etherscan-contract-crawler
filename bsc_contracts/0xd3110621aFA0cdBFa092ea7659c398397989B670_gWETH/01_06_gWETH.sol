// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './IgWETH.sol';

contract gWETH is ERC20, IgWETH {
    mapping(address => bool) _withoutAllowance;
    address _owner;

    constructor() ERC20('GigaSwap Wrapped Ethereum', 'gWETH') {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'only for owner');
        _;
    }

    receive() external payable {
        _mint(msg.sender, msg.value);
    }

    function owner() external view virtual returns (address) {
        return _owner;
    }

    function setWithoutAllowance(
        address[] calldata addrs,
        bool isWithoutAllowance
    ) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; ++i) {
            _withoutAllowance[addrs[i]] = isWithoutAllowance;
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (_withoutAllowance[spender])
            return
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        return super.allowance(owner, spender);
    }

    function mint() external payable {
        _mint(msg.sender, msg.value);
    }

    function mintTo(address account) external payable {
        _mint(account, msg.value);
    }

    function unwrap(uint256 amount) external {
        _burn(msg.sender, amount);
        (bool sent, ) = payable(msg.sender).call{ value: amount }('');
        require(sent, 'unwrap error: ether is not sent');
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        if (_withoutAllowance[spender]) return;

        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                'ERC20: insufficient allowance'
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (to == address(this)) {
            _burn(address(this), amount);
            (bool sent, ) = payable(from).call{ value: amount }('');
            require(sent, 'sent ether error: ether is not sent');
        }
    }
}