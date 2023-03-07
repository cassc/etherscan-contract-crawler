// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */

contract DecentNFT is
    OwnableUpgradeable,
    ERC165,
    IERC1155Upgradeable,
    IERC1155MetadataURIUpgradeable
{
    using AddressUpgradeable for address;

    address private _collateral;

    // Mapping from token ID to holder account
    mapping(uint256 => address) private _holders;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    address public hotWalletAddress;
    mapping(uint256 => mapping(address => uint256)) public hotWalletNFTs;

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event SetURI(string _uri);
    event SetCollateralAddress(address indexed _address);
    event SetHotWalletAddress(address indexed _address);
    event TransferCollateral(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount,
        bytes data
    );

    function initialize(string memory initial_uri) external initializer {
        _collateral = msg.sender;
        _setURI(initial_uri);

        __Ownable_init();
        emit Initialized(msg.sender, block.number);
    }

    modifier onlyCollateral() {
        require(msg.sender == _collateral, "DecentNFT: only collateral");
        _;
    }

    function updateCollateral(address _newCollateral) external onlyCollateral {
        _collateral = _newCollateral;

        emit SetCollateralAddress(_newCollateral);
    }

    function setURI(string memory newUri) external onlyCollateral {
        _setURI(newUri);

        emit SetURI(_uri);
    }

    function setHotWalletAddress(address _address) external onlyCollateral {
        hotWalletAddress = _address;

        emit SetHotWalletAddress(_address);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external payable onlyCollateral {
        address holder = _holders[id];
        if (amount != 1) {
            revert("DecentNFT: Amount not 1");
        } else if (holder == address(0)) {
            require(to != address(0), "ERC1155: mint to the zero address");
            require(amount == 1, "ERC1155: amount can be 1 only");
            hotWalletNFTs[id][to] = amount;
            _mint(to, id, amount, data);
        } else if (holder != _collateral) {
            revert("DecentNFT: Permission denied");
        } else if (to == _collateral) {
            revert("DecentNFT: Mint to collateral addr forbidden");
        } else {
            hotWalletNFTs[id][to] = amount;
            _safeTransferFrom(_collateral, hotWalletAddress, id, amount, data);
        }
    }

    function getHolder(uint256 id) external view returns (address) {
        return _holders[id];
    }

    function getCollateral() external view returns (address) {
        return _collateral;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * The function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 nfttokenid) external view virtual override returns (string memory) {
        return string(abi.encodePacked(_uri, StringsUpgradeable.toString(nfttokenid), ".json"));
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        if (from != msg.sender) {
            require(
                isApprovedForAll(from, _msgSender()),
                "ERC1155: caller is not token owner or approved"
            );
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(to != from, "ERC1155: transfer to the same address");
        require(to != _collateral, "DWERC1155: batch transfer to collateral restricted");

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return (_holders[id] == account) ? 1 : 0;
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     * Emits a {TransferSingleWithData} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(to != from, "ERC1155: transfer to the same address");
        if (to == _collateral) {
            require(data.length > 0, "DWERC1155: transfer needs not empty data");
            for (uint i = 0; i < data.length; ++i) {
                uint8 ch = uint8(data[i]);
                require(
                    (ch >= 48 && ch <= 57) || // 0-9
                        (ch >= 97 && ch <= 122) || // a-z
                        (ch >= 65 && ch <= 90) || // A-Z
                        ch == 58, // :
                    "DWERC1155: invalid data value"
                );
            }
        }

        require(_holders[id] == from, "ERC1155: insufficient balance for transfer");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, id, amount, data);
        _holders[id] = to;

        emit TransferSingle(operator, from, to, id, amount);
        if (to == _collateral) {
            // || from == _collateral
            emit TransferCollateral(operator, from, to, id, amount, data);
        }

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            require(_holders[id] == from, "ERC1155: insufficient balance for transfer");
            _holders[id] = to;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) private {
        _uri = newuri;
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
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) private {
        address operator = _msgSender();

        _holders[id] = to;

        emit TransferSingle(operator, address(0), to, id, amount);
        // emit TransferCollateral(operator, address(0), to, id, amount, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            require(amounts[i] == 1, "ERC1155: amount can be 1 only");
            require(_holders[id] == address(0), "ERC1155: nft minted already");
            _holders[id] = to;
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
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
    function _burn(address from, uint256 id, uint256 amount) private {
        address operator = _msgSender();

        require(_holders[id] == from, "ERC1155: burn amount exceeds balance");
        _holders[id] = address(0);

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) private {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            require(amount == 1, "ERC1155: burn amount can be 1 only");
            require(_holders[id] == from, "ERC1155: burn amount exceeds balance");
            _holders[id] = address(0);
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) private {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @notice Function to perform the logic before transfer
     * @param operator: operator address
     * @param from: address from
     * @param to: address to
     * @param id: token id
     * @param amount: token amount
     * @param data: token data
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (operator == hotWalletAddress) {
            uint256 _amount = hotWalletNFTs[id][from];
            require(_amount >= amount, "ERC1155: Invalid balance for transfer");
            delete hotWalletNFTs[id][from];
        }
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        int256 id,
        uint256 amount,
        bytes memory data
    ) private {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data)
            returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
}