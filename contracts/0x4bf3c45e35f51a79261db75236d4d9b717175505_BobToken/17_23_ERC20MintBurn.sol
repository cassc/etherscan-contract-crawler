// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.15;

import "../utils/Ownable.sol";
import "../interfaces/IMintableERC20.sol";
import "./BaseERC20.sol";
import "../interfaces/IMintableERC20.sol";
import "../interfaces/IBurnableERC20.sol";

/**
 * @title ERC20MintBurn
 */
abstract contract ERC20MintBurn is IMintableERC20, IBurnableERC20, Ownable, BaseERC20 {
    mapping(address => uint256) internal permissions;

    event UpdateMinter(address indexed minter, bool canMint, bool canBurn);

    function isMinter(address _account) public view returns (bool) {
        return permissions[_account] & 2 > 0;
    }

    function isBurner(address _account) public view returns (bool) {
        return permissions[_account] & 1 > 0;
    }

    /**
     * @dev Updates mint/burn permissions of the specific account.
     * Callable only by the contract owner.
     * @param _account address of the new minter EOA or contract.
     * @param _canMint true if minting is allowed.
     * @param _canBurn true if burning is allowed.
     */
    function updateMinter(address _account, bool _canMint, bool _canBurn) external onlyOwner {
        permissions[_account] = (_canMint ? 2 : 0) + (_canBurn ? 1 : 0);
        emit UpdateMinter(_account, _canMint, _canBurn);
    }

    /**
     * @dev Mints the specified amount of tokens.
     * Callable only by one of the minter addresses.
     * @param _to address of the tokens receiver.
     * @param _amount amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external {
        require(isMinter(msg.sender), "ERC20MintBurn: not a minter");

        _mint(_to, _amount);
    }

    /**
     * @dev Burns tokens from the caller.
     * Callable only by one of the burner addresses.
     * @param _value amount of tokens to burn. Should be less than or equal to caller balance.
     */
    function burn(uint256 _value) external virtual {
        require(isBurner(msg.sender), "ERC20MintBurn: not a burner");

        _burn(msg.sender, _value);
    }
}