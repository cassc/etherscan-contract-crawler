// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IInscription.sol";
import "./interfaces/IInscriptionMetadata.sol";
import "./interfaces/IInscriptionReceiver.sol";

contract Inscription is Context, ERC165, IInscription, IInscriptionMetadata {
    using Address for address;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from inscription ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IInscription).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IInscription-ownerOf}.
     */
    function ownerOf(uint256 inscriptionId) public view virtual override returns (address) {
        address owner = _owners[inscriptionId];
        require(owner != address(0), "Inscription: owner query for nonexistent inscription");
        return owner;
    }

    /**
     * @dev Returns the name of the inscription.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the inscription.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI of the inscription.
     */
    function tokenURI(uint256 inscriptionId) public view virtual override returns (string memory) {
        return "";
    }

    /**
     * @dev Returns the URL of the inscription.
     */
    function inscriptionURL(uint256 inscriptionId) public view virtual override returns (string memory) {
        return "";
    }

    /**
     * @dev See {IInscription-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IInscription-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IInscription-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 inscriptionId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), inscriptionId), "Inscription: transfer caller is not owner nor approved");
        _safeTransfer(from, to, inscriptionId, _data);
    }

    /**
     * @dev Safely transfers `inscriptionId` inscription from `from` to `to`, checking first that contract recipients
     * are aware of the Inscription protocol to prevent inscriptions from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform inscription transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `inscriptionId` inscription must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IInscriptionReceiver-onInscriptionReceived}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 inscriptionId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, inscriptionId);
        require(_checkOnInscriptionReceived(from, to, inscriptionId, _data), "Inscription: transfer to non InscriptionReceiver implementer");
    }

    /**
     * @dev Mints `inscriptionId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `inscriptionId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IInscriptionReceiver-onInscriptionReceived}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _inscribe(
        address to,
        uint256 inscriptionId,
        bytes memory _data
    ) internal virtual {
        require(to != address(0), "Inscription: inscribe to the zero address");
        require(!_exists(inscriptionId), "Inscription: inscription already inscribed");

        _owners[inscriptionId] = to;
        emit Transfer(address(0), to, inscriptionId);

        require(
            _checkOnInscriptionReceived(address(0), to, inscriptionId, _data),
            "Inscription: transfer to non InscriptionReceiver implementer"
        );
    }

    /**
     * @dev Returns whether `inscriptionId` exists.
     *
     * Inscriptions can be managed by their owner or approved accounts via {setApprovalForAll}.
     *
     * Inscriptions start existing when they are inscribed (`_inscribe`).
     */
    function _exists(uint256 inscriptionId) internal view virtual returns (bool) {
        return _owners[inscriptionId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `inscriptionId`.
     *
     * Requirements:
     *
     * - `inscriptionId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 inscriptionId) internal view virtual returns (bool) {
        require(_exists(inscriptionId), "Inscription: operator query for nonexistent inscription");
        address owner = Inscription.ownerOf(inscriptionId);
        return (spender == owner || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Transfers `inscriptionId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `inscriptionId` inscription must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 inscriptionId
    ) internal virtual {
        require(Inscription.ownerOf(inscriptionId) == from, "Inscription: transfer from incorrect owner");
        require(to != address(0), "Inscription: transfer to the zero address");

        _owners[inscriptionId] = to;
        emit Transfer(from, to, inscriptionId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` inscriptions
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "Inscription: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IInscriptionReceiver-onInscriptionReceived} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given inscription ID
     * @param to target address that will receive the inscriptions
     * @param inscriptionId uint256 ID of the inscription to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnInscriptionReceived(
        address from,
        address to,
        uint256 inscriptionId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IInscriptionReceiver(to).onInscriptionReceived(_msgSender(), from, inscriptionId, _data) returns (bytes4 retval) {
                return retval == IInscriptionReceiver.onInscriptionReceived.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Inscription: transfer to non InscriptionReceiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

}