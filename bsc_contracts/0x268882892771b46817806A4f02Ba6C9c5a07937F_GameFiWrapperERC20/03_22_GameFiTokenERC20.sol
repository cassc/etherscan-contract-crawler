// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable no-empty-blocks

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "../../../interface/core/token/basic/IGameFiTokenERC20.sol";

/**
 * @author Alex Kaufmann
 * @dev ERC20 Token contract for GameFiCore.
 * Can be used as a base for expanding functionality.
 * See https://docs.openzeppelin.com/contracts/4.x/api/token/erc20.
 * Also supports contract-level metadata (https://docs.opensea.io/docs/contract-level-metadata)
 */
contract GameFiTokenERC20 is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    OwnableUpgradeable,
    ERC165Upgradeable,
    IGameFiTokenERC20
{
    string private _contractURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
    * @dev Constructor method (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers).
    * @param name_ ERC721 name() field (see ERC721Metadata).
    * @param symbol_ ERC721 symbol() field (see ERC721Metadata).
    * @param contractURI_ Contract-level metadata (https://docs.opensea.io/docs/contract-level-metadata).
    * @param data_ Custom hex-data for additional parameters. Depends on token implementation.
    */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        bytes memory data_
    ) public virtual initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        __ERC20Permit_init(name_);
        __ERC165_init();

        _contractURI = contractURI_;

        _afterInitialize(
            name_,
            symbol_,
            contractURI_,
            data_
        );
    }

    /**
     * @dev Sets new contract-level metadata URI (https://docs.opensea.io/docs/contract-level-metadata).
     * @param newURI Contract-level metadata.
     */
    function setContractURI(string memory newURI) external onlyOwner {
        _contractURI = newURI;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - caller must be owner (for GameFiCore only).
     */
    function mint(
        address to,
        uint256 amount,
        bytes memory data
    ) external virtual onlyOwner {
        _mint(to, amount);

        data;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - `caller must be owner (for GameFiCore only).
     */
    function burn(
        address to,
        uint256 amount,
        bytes memory data
    ) external virtual onlyOwner {
        _burn(to, amount);

        data;
    }

    /**
     * @dev Returns contract-level metadata URI.
     * @return Contract-level metadata.
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable) returns (bool) {
        return (interfaceId == type(IGameFiTokenERC20).interfaceId ||
            interfaceId == type(IERC20PermitUpgradeable).interfaceId ||
            interfaceId == type(IERC20MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC20Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    function _afterInitialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        bytes memory data_
    ) internal virtual {}
}