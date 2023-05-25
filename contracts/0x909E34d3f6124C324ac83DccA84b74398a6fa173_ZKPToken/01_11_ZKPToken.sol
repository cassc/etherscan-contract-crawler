// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "./interfaces/Constants.sol";

contract ZKPToken is ERC20Permit, Constants {
    string private constant _name = "$ZKP Token";
    string private constant _symbol = "$ZKP";

    address public minter;

    constructor(address _minter) ERC20(_name, _symbol) ERC20Permit(_name) {
        _setMinter(_minter);
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "ZKP: unauthorized");
        _;
    }

    function mint(address _account, uint256 _amount)
        public
        onlyMinter
        returns (bool)
    {
        _mint(_account, _amount);
        return true;
    }

    function setMinter(address _minter) public onlyMinter {
        _setMinter(_minter);
    }

    // batch functions
    function batchTransfer(
        address[] calldata _recipients,
        uint256[] calldata _values
    ) external returns (bool) {
        _throwLengthMismatch(_recipients.length, _values.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(
                transfer(_recipients[i], _values[i]),
                "ZKP: unable to transfer"
            );
        }

        return true;
    }

    function batchTransferFrom(
        address _from,
        address[] calldata _recipients,
        uint256[] calldata _values
    ) external returns (bool) {
        _throwLengthMismatch(_recipients.length, _values.length);

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(
                transferFrom(_from, _recipients[i], _values[i]),
                "$ZKP: unable to transfer"
            );
        }

        return true;
    }

    function batchIncreaseAllowance(
        address[] calldata _spenders,
        uint256[] calldata _addedValues
    ) external returns (bool) {
        _throwLengthMismatch(_spenders.length, _addedValues.length);

        for (uint256 i = 0; i < _addedValues.length; i++) {
            require(
                increaseAllowance(_spenders[i], _addedValues[i]),
                "ZKP: unable to increase"
            );
        }

        return true;
    }

    function batchDecreaseAllowance(
        address[] calldata _spenders,
        uint256[] calldata _subtractedValues
    ) external returns (bool) {
        _throwLengthMismatch(_spenders.length, _subtractedValues.length);

        for (uint256 i = 0; i < _subtractedValues.length; i++) {
            require(
                decreaseAllowance(_spenders[i], _subtractedValues[i]),
                "ZKP: unable to decrease"
            );
        }

        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == address(0)) {
            // On minting
            require(totalSupply() + amount <= MAX_SUPPLY, "ZKP: cap exceeded");
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function _setMinter(address _minter) internal {
        require(_minter != address(0), "ZKP: zero minter address");
        minter = _minter;
    }

    function _throwLengthMismatch(uint256 l1, uint256 l2) private pure {
        require(l1 == l2, "ZKP: invalid input");
    }
}