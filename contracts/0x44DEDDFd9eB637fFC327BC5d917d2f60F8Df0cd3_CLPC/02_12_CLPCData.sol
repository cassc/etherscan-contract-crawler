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

    function setVersion(uint _version) internal {
        version = _version;
    }

    function getAllowanceOf(
        address owner,
        address spender
    ) internal view returns (uint256 remaining) {
        return _allowancesOf[owner][spender];
    }

    function allowanceCheck(address owner, address spender) private pure {
        require(owner != address(0), "Allowance from the zero address");
        require(spender != address(0), "Allowance to the zero address");
    }

    function setAllowanceOf(
        address owner,
        address spender,
        uint256 allowance
    ) internal returns (bool) {
        allowanceCheck(owner, spender);

        require(allowance >= 0, "Allowance less than 0");

        unchecked {
            _allowancesOf[owner][spender] = allowance;
        }
        
        return true;
    }

    function increaseAllowanceOf(
        address owner,
        address spender,
        uint256 allowanceToAdd
    ) internal returns (uint256 newAllowance) {
        uint256 _newAllowance = getAllowanceOf(owner, spender) + allowanceToAdd;

        setAllowanceOf(
            owner,
            spender,
            _newAllowance
        );

        return _newAllowance;
    }

    function decreaseAllowanceOf(
        address owner,
        address spender,
        uint256 allowanceToSustract
    ) internal returns (uint256 newAllowance) {
        uint256 currentAllowance = getAllowanceOf(owner, spender);

        uint256 _newAllowance = currentAllowance > allowanceToSustract 
                ? currentAllowance - allowanceToSustract
                : 0;

        setAllowanceOf(
            owner,
            spender,
            _newAllowance
        );

        return _newAllowance;
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
        uint256 _newBalance = getBalanceOf(who) - balanceToSustract;

        setBalanceOf(who, _newBalance);

        return _newBalance;
    }

    function increaseBalanceOf(
        address who,
        uint256 balanceToAdd
    ) internal returns (uint256 newBalance) {
        uint256 _newBalance = getBalanceOf(who) + balanceToAdd;

        setBalanceOf(who, _newBalance);

        return _newBalance;
    }

    function setBalanceOf(
        address who,
        uint256 newBalance
    ) internal returns (bool) {
        require(
            newBalance >= 0,
            "Balance amount below 0"
        );

        unchecked {
            _balanceOf[who] = newBalance;
        }

        return true;
    }

    function increaseBurnBalanceOf(
        address who,
        uint256 balanceToAdd
    ) internal returns (uint256 newBurnBalance) {
        unchecked {
            _burnAmountOf[who] += balanceToAdd;
        }

        return _burnAmountOf[who];
    }

    function increaseTotalBurnBalance(
        uint256 balanceToAdd
    ) internal returns (uint256 newBurnBalance) {
        unchecked {
            _burnAmount += balanceToAdd;
        }

        return _burnAmount;
    }

    function increaseTotalSuply(
        uint256 balanceToAdd
    ) internal returns (uint256 newTotalSupply) {
        unchecked {
            _totalSupply += balanceToAdd;
        }

        return _totalSupply;
    }

    function decreaseTotalSuply(
        uint256 balanceToSustract
    ) internal returns (uint256 newTotalSupply) {
        unchecked {
            _totalSupply -= balanceToSustract;
        }

        return _totalSupply;
    }
}