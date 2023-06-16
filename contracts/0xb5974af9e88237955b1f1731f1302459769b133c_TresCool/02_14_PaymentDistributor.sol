// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.2;

/// @dev Implementation of the zero-out balance distribution. Distribution will see the requested balance zeroed out.
contract PaymentDistributor {

    uint16 private _shareDenominator = 10000;
    uint16[] private _shares;
    address[] private _payees;

    /// @notice Adds a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function _addPayee(address payee, uint16 share) internal {
        require(_payees.length == _shares.length, "Payee and shares must be the same length.");
        require(totalShares() + share <= _shareDenominator, "Cannot overassign share distribution.");
        require(_indexOfPayee(payee) == _payees.length, "Payee has already been added.");
        _payees.push(payee);
        _shares.push(share);
    }

    /// @notice Updates a payee to the distribution list
    /// @dev Ensures that both payee and share length match and also that there is no over assignment of shares.
    function _updatePayee(address payee, uint16 share) internal {
        uint payeeIndex = _indexOfPayee(payee);
        require(payeeIndex < _payees.length, "Payee has not been added yet.");
        _shares[payeeIndex] = share;
        require(totalShares() <= _shareDenominator, "Cannot overassign share distribution.");
    }

    /// @notice Removes a payee from the distribution list
    /// @dev Sets a payees shares to zero, but does not remove them from the array. Payee will be ignored in the distributeFunds function
    function _removePayee(address payee) internal {
        uint payeeIndex = _indexOfPayee(payee);
        require(payeeIndex < _payees.length, "Payee has not been added yet.");
        _shares[payeeIndex] = 0;
    }

    /// @notice Gets the index of a payee
    /// @dev Returns the index of the payee from _payees or returns _payees.length if no payee was found
    function _indexOfPayee(address payee) internal view returns (uint) {
        for (uint i=0; i < _payees.length; i++) {
            if(_payees[i] == payee) return i;
        }
        return _payees.length;
    }

    /// @notice Gets the total number of shares assigned to payees
    /// @dev Calculates total shares from shares[] array.
    function totalShares() private view returns(uint16) {
        uint16 sharesTotal = 0;
        for (uint i=0; i < _shares.length; i++) {
            sharesTotal += _shares[i];
        }
        return sharesTotal;
    }

    /// @notice Fund distribution function.
    /// @dev Uses the payees and shares array to calculate. Will send all remaining funds to the msg.sender.
    function _distributeShares() internal {

        uint currentBalance = address(this).balance;

        for (uint i=0; i < _payees.length; i++) {
            if(_shares[i] == 0) continue;
            uint share = (_shares[i] * currentBalance) / _shareDenominator;
            (bool sent,) = payable(_payees[i]).call{value : share}("");
            require(sent, "Failed to distribute to payee.");
        }

        if(address(this).balance > 0) {
            (bool sent,) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to distribute remaining funds.");
        }
    }

    /// @notice ERC20 fund distribution function.
    /// @dev Uses the payees and shares array to calculate. Will send all remaining funds to the msg.sender.
    function _distributeERC20Shares(address tokenAddress) internal {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint currentBalance = tokenContract.balanceOf(address(this));

        for (uint i=0; i < _payees.length; i++) {
            if(_shares[i] == 0) continue;
            uint share = (_shares[i] * currentBalance) / _shareDenominator;
            tokenContract.transfer(_payees[i], share);
        }

        if(tokenContract.balanceOf(address(this)) > 0) {
            tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
        }
    }
}