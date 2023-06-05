// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./../helpers/ERC20Decimals.sol";
import "./../helpers/ERC20Mintable.sol";
import "./../helpers/ERC20Ownable.sol";

import "./../service/Helper.sol";
import "./../helpers/TokenGeneratorMetadata.sol";

/**
 * @title CMTProfessional
 * @author Create My Token (https://www.createmytoken.com/)
 * @dev Implementation of the CMTProfessional
 */
contract CMTProfessional is
    ERC20Decimals,
    ERC20Capped,
    ERC20Mintable,
    ERC20Burnable,
    ERC20Ownable,
    Helper,
    TokenGeneratorMetadata
{
    constructor(
        string memory __cmt_name,
        string memory __cmt_symbol,
        uint8 __cmt_decimals,
        uint256 __cmt_cap,
        uint256 __cmt_initial
    ) payable ERC20(__cmt_name, __cmt_symbol) ERC20Decimals(__cmt_decimals) ERC20Capped(__cmt_cap) {
        // Immutable variables cannot be read during contract creation time
        // https://github.com/ethereum/solidity/issues/10463
        require(__cmt_initial <= __cmt_cap, "ERC20Capped: cap exceeded");
        ERC20._mint(_msgSender(), __cmt_initial);
    }

    function decimals() public view virtual override(ERC20, ERC20Decimals) returns (uint8) {
        return super.decimals();
    }

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) onlyOwner {
        super._mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-finishMinting}.
     */
    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }
}