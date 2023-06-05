// SPDX-License-Identifier: CC0
pragma solidity 0.8.17;

contract CLPCData {
    uint256 internal _totalSupply;

    string public constant currency = "CLP";
    uint public version;

    mapping(address => uint256) private _balanceOf;
    mapping(address => uint256) private _burnAmountOf;
    mapping(address => mapping(address => uint256)) private _allowancesOf;
    mapping(bytes4 => bool) internal _supportsInterface;

    uint256 private _burnAmount;

    function initData(uint _version) internal {
        version = _version;
    }

    function getAllowanceOf(
        address owner,
        address spender
    ) internal view returns (uint256 remaining) {
        return _allowancesOf[owner][spender];
    }

    function allowanceCheck(address owner, address spender) private pure {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
    }

    function increaseAllowanceOf(
        address owner,
        address spender,
        uint256 allowanceToAdd
    ) internal returns (bool) {
        allowanceCheck(owner, spender);

        _allowancesOf[owner][spender] += allowanceToAdd;

        return true;
    }

    function decreaseAllowanceOf(
        address owner,
        address spender,
        uint256 allowanceToSustract
    ) internal returns (bool) {
        allowanceCheck(owner, spender);

        require(
            _allowancesOf[owner][spender] >= allowanceToSustract,
            "CLPCData: decreased allowance below zero"
        );

        unchecked {
            _allowancesOf[owner][spender] -= allowanceToSustract;
        }

        return true;
    }

    function getBalanceOf(address who) internal view returns (uint256 balance) {
        return _balanceOf[who];
    }

    function getBurnBalanceOf(address who) internal view returns (uint256) {
        return _burnAmountOf[who];
    }

    function getTotalBurnBalance() internal view returns (uint256) {
        return _burnAmount;
    }

    function decreaseBalanceOf(
        address who,
        uint256 balanceToSustract
    ) internal returns (uint256 newBalance) {
        uint256 fromBalance = _balanceOf[who];

        require(
            fromBalance >= balanceToSustract,
            "CLPCData: decrease amount below 0"
        );

        unchecked {
            _balanceOf[who] -= balanceToSustract;
        }

        return _balanceOf[who];
    }

    function increaseBalanceOf(
        address who,
        uint256 balanceToAdd
    ) internal returns (uint256 newBalance) {
        _balanceOf[who] += balanceToAdd;

        return _balanceOf[who];
    }

    function increaseBurnBalanceOf(
        address who,
        uint256 balanceToAdd
    ) internal returns (uint256 newBurnBalance) {
        _burnAmountOf[who] += balanceToAdd;

        return _burnAmountOf[who];
    }

    function increaseTotalBurnBalance(
        uint256 balanceToAdd
    ) internal returns (uint256 newBurnBalance) {
        _burnAmount += balanceToAdd;

        return _burnAmount;
    }

    function increaseTotalSuply(
        uint256 balanceToAdd
    ) internal returns (uint256 newTotalSupply) {
        _totalSupply += balanceToAdd;

        return _totalSupply;
    }

    function decreaseTotalSuply(
        uint256 balanceToSustract
    ) internal returns (uint256 newTotalSupply) {
        _totalSupply -= balanceToSustract;

        return _totalSupply;
    }
}