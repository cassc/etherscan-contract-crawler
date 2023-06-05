// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Votes, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import {ProposedOwnable} from "./vendor/ProposedOwnable.sol";

/**
 * @title ConnextERC20
 * @notice The token used in governance and supporting voting and delegation. Implements the following:
 *          - EIP 2612 allowing signed approvals
 *          - ERC20Votes allowing for delegation and voting
 *          - ERC20Burnable allowing for burning tokens
 *          - ProposedOwnable allowing for a proposed owner to be set after a 1-week delay. Owners are
 *            able to mint tokens.
 * 
 * @dev Source code for the ConnextERC20 contract was taken from:
 * - OP Token: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/contracts/governance/GovernanceToken.sol
 * - ProposedOwnable: https://github.com/connext/monorepo/blob/legacy/packages/contracts/contracts/ProposedOwnable.sol
 * Both of which were independently audited.
 * 
 */
contract ConnextERC20 is ERC20Burnable, ERC20Votes, ProposedOwnable, Initializable {
    constructor() ERC20("Connext", "NEXT") ERC20Permit("Connext") ProposedOwnable() {}

     function initialize(address _owner) initializer public {
        // Set owner
        _setOwner(_owner);
        // Initial supply: 1B NEXT
        _mint(_owner, 1_000_000_000 ether);
    }

    /**
     * @notice Allows the owner to mint tokens.
     *
     * @param _account The account receiving minted tokens.
     * @param _amount  The amount of tokens to mint.
     */
    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);
    }

    /**
     * @notice Callback called after a token transfer.
     *
     * @param from   The account sending tokens.
     * @param to     The account receiving tokens.
     * @param amount The amount of tokens being transfered.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @notice Internal mint function.
     *
     * @param to     The account receiving minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    /**
     * @notice Internal burn function.
     *
     * @param account The account that tokens will be burned from.
     * @param amount  The amount of tokens that will be burned.
     */
    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}