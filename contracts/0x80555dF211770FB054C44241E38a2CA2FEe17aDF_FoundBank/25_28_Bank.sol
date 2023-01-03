// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC1155.sol";

abstract contract Bank is ERC1155 {
    uint private _supply;

    mapping(uint => uint) _supplies;
    mapping(address => mapping(address => mapping(uint => uint))) private _allowances;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint indexed coinId,
        uint value
    );

    function nameOf(uint coinId) virtual public view returns (string memory);

    function symbolOf(uint coinId) virtual public view returns (string memory);

    function decimals() virtual public view returns (uint8);

    function totalSupply() public view returns (uint) {
        return _supply;
    }

    function totalSupplyOf(uint coinId) public view returns (uint) {
        return _supplies[coinId];
    }

    function allowance(
        address owner,
        address spender,
        uint coinId
    ) external view returns (uint) {
        return _allowances[owner][spender][coinId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) public override {
        _transferFrom(msg.sender, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) public override {
        uint length = ids.length;

        require(
            length == amounts.length,
            "Bank: ids and amounts length mismatch"
        );

        bool approved = isApprovedForAll(from, msg.sender);

        if (!approved && from != msg.sender) {
            for (uint i = 0; i < length; i += 1) {
                _spendAllowance(from, msg.sender, ids[i], amounts[i]);
            }
        }

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function approve(
        address spender,
        uint coinId,
        uint amount
    ) external {
        _approve(msg.sender, spender, coinId, amount);
    }

    function approveBatch(
        address spender,
        uint[] memory amounts,
        uint[] memory coins
    ) external {
        uint length = amounts.length;

        require(
            length == coins.length,
            "Bank: Mismatch between amounts and coins lengths"
        );

        for (uint i = 0; i < length; i += 1) {
            _approve(msg.sender, spender, coins[i], amounts[i]);
        }
    }

    function _transferFrom(
        address operator,
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) internal {
        bool approved = isApprovedForAll(from, operator);

        if (!approved && from != operator) {
            _spendAllowance(from, operator, id, amount);
        }

        _safeTransferFrom(from, to, id, amount, data);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint coinId,
        uint amount
    ) internal virtual {
        uint currentAllowance = _allowances[owner][spender][coinId];
        if (currentAllowance != type(uint).max) {
            require(currentAllowance >= amount, "Bank: insufficient allowance");
            _approve(owner, spender, coinId, currentAllowance - amount);
        }
    }

    function _approve(
        address owner,
        address spender,
        uint coinId,
        uint amount
    ) internal {
        require(owner != address(0), "Bank: Cannot approve from the zero address");
        require(spender != address(0), "Bank: Cannot approve to the zero address");
        _allowances[owner][spender][coinId] = amount;
        emit Approval(owner, spender, coinId, amount);
    }

    function _afterTokenTransfer(
        address,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory
    ) internal override {
        uint length = ids.length;

        if (from == address(0)) {
            for (uint i = 0; i < length; i++) {
                _supplies[ids[i]] += amounts[i];
                _supply += amounts[i];
            }
        } else if (to == address(0)) {
            for (uint i = 0; i < length; i++) {
                _supplies[ids[i]] -= amounts[i];
                _supply -= amounts[i];
            }
        }
    }

    constructor(string memory baseURI_) ERC1155(baseURI_) {}
}