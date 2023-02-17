// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable no-empty-blocks

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../../interface/core/token/basic/IGameFiTokenERC1155.sol";

/**
 * @author Alex Kaufmann
 * @dev ERC1155 Token contract for GameFiCore.
 * Can be used as a base for expanding functionality.
 * See https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155.
 * Also supports contract-level metadata (https://docs.opensea.io/docs/contract-level-metadata)
 */
contract GameFiTokenERC1155 is
    Initializable,
    OwnableUpgradeable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    IGameFiTokenERC1155
{
    string private _name;
    string private _symbol;
    string private _contractURI;
    uint256 private _totalSupply;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
    * @dev Constructor method (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers).
    * @param name_ name() field (ERC721Metadata analog).
    * @param symbol_ symbol() field (ERC721Metadata analog).
    * @param contractURI_ Contract-level metadata (https://docs.opensea.io/docs/contract-level-metadata).
    * @param tokenURI_  Uniform Resource Identifier (URI) of the token metadata.
    * @param data_ Custom hex-data for additional parameters. Depends on token implementation.
    */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory tokenURI_,
        bytes memory data_
    ) public virtual initializer {
        __ERC1155_init(tokenURI_);
        __Ownable_init();
        __ERC1155Supply_init();
        _name = name_;
        _symbol = symbol_;
        _contractURI = contractURI_;

        _afterInitialize(
            name_,
            symbol_,
            contractURI_,
            tokenURI_,
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

    /**
     * @dev Sets new token metadata URI (see IERC1155MetadataURI).
     * @param newURI Token metadata.
     */
    function setTokenURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _mint(account, id, amount, data);
    }

    /**
     * @dev Creates `amount[]` tokens of token type `id[]`, and assigns them to `to`.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements: see mint(...).
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _burn(from, id, amount);
        data; // for linter
    }

    /**
     * @dev Destroys `amounts[]` tokens of token type `ids[]` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements: see burn(...).
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        _burnBatch(from, ids, amounts);
        data; // for linter
    }

    /**
     * @dev Returns the name of the token.
     * @return Token name.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     * @return Token ticker.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns contract-level metadata URI.
     * @return Contract-level metadata.
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns the amount of tokens in existence.
     * @return Total number of tokens.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return (interfaceId == type(IGameFiTokenERC1155).interfaceId || super.supportsInterface(interfaceId));
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < amounts.length; ++i) {
                _totalSupply += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < amounts.length; ++i) {
                _totalSupply -= amounts[i];
            }
        }
    }

    function _afterInitialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory tokenURI_,
        bytes memory data_
    ) internal virtual {}
}