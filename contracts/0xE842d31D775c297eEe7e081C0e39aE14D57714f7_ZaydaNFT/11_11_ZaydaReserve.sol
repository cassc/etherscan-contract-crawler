// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {Owned} from "./solmate/src/auth/Owned.sol";
import {IERC20, IERC721} from "./Interfaces.sol";

contract ZaydaReserve is Owned {
    /** ****************************************************************
     * EVENTS
     * ****************************************************************/

    event WithdrawnEth(uint256 _timestamp, uint256 _amount);
    event WithdrawnERC20(uint256 _timestamp, uint256 _amount);
    event WithdrawnERC721(uint256 _timestamp, uint256 _id);

    /** ****************************************************************
     * CONSTRUCTOR
     * ****************************************************************/

    /// @notice Initializes the reserve contract.
    /// @param _owner The address of the owner for the contract.
    constructor(address _owner) Owned(_owner) {}

    /// @notice Allows the contract to receive ethers.
    receive() external payable {}

    /** ****************************************************************
     * ZAYDA LOGIC
     * ****************************************************************/

    /// @notice Withdraws ethers in contract to owner.
    function withdrawEth() external onlyOwner {
        uint256 amount = address(this).balance;

        payable(owner).transfer(amount);
        emit WithdrawnEth(block.timestamp, amount);
    }

    /// @notice Withdraws ERC20 token balance in contract to owner.
    /// @param _address The address of the ERC20 token contract.
    function withdrawERC20(IERC20 _address) external onlyOwner {
        uint256 amount = _address.balanceOf(address(this));

        _address.transfer(owner, amount);
        emit WithdrawnERC20(block.timestamp, amount);
    }

    /// @notice Withdraws ERC721 token ids in contract to owner.
    /// @param _address The address of the ERC721 token contract.
    /// @param _ids The token ids owned by contract to send to owner.
    function withdrawERC721(IERC721 _address, uint256[] memory _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];

            _address.transferFrom(address(this), owner, id);
            emit WithdrawnERC721(block.timestamp, id);
        }
    }
}