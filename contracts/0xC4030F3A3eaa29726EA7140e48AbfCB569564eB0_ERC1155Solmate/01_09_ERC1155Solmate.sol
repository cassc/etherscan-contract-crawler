// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)

pragma solidity 0.8.17;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Context} from "openzeppelin-contracts/contracts/utils/Context.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability to check the total supply for a token id
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC1155Solmate is AccessControl, ERC1155 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event GrantMinterRole(address minter);
    event RevokeMinterRole(address minter);

    error ZeroAddress();
    error NotMinter();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        @notice Grant the minter role to an address
        @param  minter  address  Address to grant the minter role
     */
    function grantMinterRole(address minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (minter == address(0)) revert ZeroAddress();

        _grantRole(MINTER_ROLE, minter);

        emit GrantMinterRole(minter);
    }

    /**
     @notice Revoke the minter role from an address
     @param  minter  address  Address to revoke the minter role
  */
    function revokeMinterRole(address minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (hasRole(MINTER_ROLE, minter) == false) revert NotMinter();

        _revokeRole(MINTER_ROLE, minter);

        emit RevokeMinterRole(minter);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        _batchMint(to, ids, amounts, data);
    }

    function burnBatch(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) {
        _batchBurn(from, ids, amounts);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) {
        _burn(from, id, amount);
    }

    function uri(uint256 id) public view override returns (string memory) {}

    // Necessary override due to AccessControl having the same method
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }
}