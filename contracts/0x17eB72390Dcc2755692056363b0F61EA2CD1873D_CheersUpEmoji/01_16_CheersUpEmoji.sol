// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

/**
 * @title IExtendableERC1155
 * @author BaseLabs
 */
abstract contract IExtendableERC1155 is IERC1155 {
    /**
     * @dev Transfers `amount_` tokens of token type `id_` from `from_` to `to`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - `from_` must have a balance of tokens of type `id_` of at least `amount`.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawSafeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     * Emits a {TransferBatch} event.
     * Requirements:
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawSafeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external virtual;

    /**
     * @dev Creates `amount_` tokens of token type `id_`, and assigns them to `to_`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawMint(address to_, uint256 id_, uint256 amount_, bytes memory data_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawMintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external virtual;

    /**
     * @dev Destroys `amount_` tokens of token type `id_` from `from_`
     * Requirements:
     * - `from_` cannot be the zero address.
     * - `from_` must have at least `amount` tokens of token type `id`.
     */
    function rawBurn(address from_, uint256 id_, uint256 amount_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     */
    function rawBurnBatch(address from_, uint256[] memory ids_, uint256[] memory amounts_) external virtual;

    /**
     * @dev Approve `operator_` to operate on all of `owner_` tokens
     * Emits a {ApprovalForAll} event.
     */
    function rawSetApprovalForAll(address owner_, address operator_, bool approved_) external virtual;
}

/**
 * @title ExtendableERC1155
 * @author BaseLabs
 */
contract ExtendableERC1155 is ERC1155Burnable, ERC1155Pausable, Ownable {
    event ChildAdded(address indexed address_);
    event ChildRemoved(address indexed address_);
    event ContractSealed();

    string public name;
    string public symbol;
    bool public contractSealed = false;
    mapping(address => bool) public children;
    mapping(uint256 => string) private _uris;

    constructor(string memory name_, string memory symbol_) ERC1155("") {
        name = name_;
        symbol = symbol_;
    }

    /**
     * @dev Transfers `amount_` tokens of token type `id_` from `from_` to `to`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - `from_` must have a balance of tokens of type `id_` of at least `amount`.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawSafeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) external onlyChild {
        super._safeTransferFrom(from_, to_, id_, amount_, data_);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     * Emits a {TransferBatch} event.
     * Requirements:
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawSafeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external onlyChild {
        super._safeBatchTransferFrom(from_, to_, ids_, amounts_, data_);
    }

    /**
     * @dev Creates `amount_` tokens of token type `id_`, and assigns them to `to_`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawMint(address to_, uint256 id_, uint256 amount_, bytes memory data_) external onlyChild {
        super._mint(to_, id_, amount_, data_);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawMintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external onlyChild {
        super._mintBatch(to_, ids_, amounts_, data_);
    }

    /**
     * @dev Destroys `amount_` tokens of token type `id_` from `from_`
     * Requirements:
     * - `from_` cannot be the zero address.
     * - `from_` must have at least `amount` tokens of token type `id`.
     */
    function rawBurn(address from_, uint256 id_, uint256 amount_) external onlyChild {
        super._burn(from_, id_, amount_);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     */
    function rawBurnBatch(address from_, uint256[] memory ids_, uint256[] memory amounts_) external onlyChild {
        super._burnBatch(from_, ids_, amounts_);
    }

    /**
     * @dev Approve `operator_` to operate on all of `owner_` tokens
     * Emits a {ApprovalForAll} event.
     */
    function rawSetApprovalForAll(address owner_, address operator_, bool approved_) external onlyChild {
        super._setApprovalForAll(owner_, operator_, approved_);
    }

    /**
     * @notice Adds a child contract to the list of children.
     * @param address_ The address of the child contract.
     */
    function addChild(address address_) external onlyOwner notSealed {
        children[address_] = true;
        emit ChildAdded(address_);
    }

    /**
     * @notice Removes a child contract from the list of children.
     * @param address_ The address of the child contract.
     */
    function removeChild(address address_) external onlyOwner notSealed {
        children[address_] = false;
        emit ChildRemoved(address_);
    }

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions,
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external onlyOwner notSealed {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner notSealed {
        _unpause();
    }

    /**
     * @notice When the project is stable enough, the issuer will call sealContract to
     * give up some excessive permissions to make the project more decentralized.
     */
    function sealContract() external onlyOwner notSealed {
        contractSealed = true;
        emit ContractSealed();
    }

    /**
     * @notice setURI is used to set the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @param uri_ metadata uri corresponding to the token
     */
    function setURI(uint256 tokenId_, string calldata uri_) external onlyOwner {
        _uris[tokenId_] = uri_;
        emit URI(uri_, tokenId_);
    }

    /**
     * @notice uri is used to get the URI corresponding to the tokenId
     * @param tokenId_ token id
     * @return metadata uri corresponding to the token
     */
    function uri(uint256 tokenId_) public view virtual override returns (string memory) {
        return _uris[tokenId_];
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @notice function call is only allowed when the caller is child contract.
     */
    modifier onlyChild() {
        require(children[msg.sender], "address is not permitted");
        _;
    }

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }
}

/**
 * @title CheersUpEmoji
 * @author BaseLabs
 */
contract CheersUpEmoji is ExtendableERC1155, ERC2981 {
    constructor(address royaltyRecipient_) ExtendableERC1155("Cheers UP Emoji", "CUPEMOJI") {
        // 5% royalties
        _setDefaultRoyalty(royaltyRecipient_, 500);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, ERC2981)
    returns (bool)
    {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}