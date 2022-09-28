// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Ownable.sol";

/**
 * @title Claimable
 */
contract Claimable is Ownable {
    address claimingAdmin;

    /**
     * @dev Throws if called by any account other than the contract owner or claiming admin.
     */
    modifier onlyClaimingAdmin() {
        require(_msgSender() == claimingAdmin || _isOwner(), "Claimable: not authorized for claiming");
        _;
    }

    /**
     * @dev Updates the address of the claiming admin account.
     * Callable only by the contract owner.
     * Claiming admin is only authorized to claim ERC20 tokens or native tokens mistakenly sent to the token contract address.
     * @param _claimingAdmin address of the new claiming admin account.
     */
    function setClaimingAdmin(address _claimingAdmin) external onlyOwner {
        claimingAdmin = _claimingAdmin;
    }

    /**
     * @dev Allows to transfer any locked token from this contract.
     * Callable only by the contract owner or claiming admin.
     * @param _token address of the token contract, or 0x00..00 for transferring native coins.
     * @param _to locked tokens receiver address.
     */
    function claimTokens(address _token, address _to) external virtual onlyClaimingAdmin {
        if (_token == address(0)) {
            payable(_to).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(_to, balance);
        }
    }
}