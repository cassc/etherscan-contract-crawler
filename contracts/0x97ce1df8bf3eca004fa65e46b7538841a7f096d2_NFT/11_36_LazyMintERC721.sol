// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { TokenOwner } from "../../DataTypes.sol";

import "@limitbreak/creator-token-contracts/contracts/access/OwnablePermissions.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract LazyMintERC721Base is OwnablePermissions, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    error LazyMintERC721Base__AddressZeroIsNotAValidOwner();
    error LazyMintERC721Base__AmountExceedsMaxRemainingSupply();
    error LazyMintERC721Base__AmountMustBeGreaterThanZero();
    error LazyMintERC721Base__ApprovalToCurrentOwner();
    error LazyMintERC721Base__ApproveCallerIsNotTokenOwnerOrApprovedForAll();
    error LazyMintERC721Base__ApproveToCaller();
    error LazyMintERC721Base__MaxSupplyMustBeGreaterThanZero();
    error LazyMintERC721Base__MaxTokensPerConsecutiveTransferMustBeGreaterThanZero();
    error LazyMintERC721Base__MaxTokensPerConsecutiveTransferUpperLimitExceeded();
    error LazyMintERC721Base__TokenDoesNotExist();
    error LazyMintERC721Base__TransferCallerIsNotOwnerNorApproved();
    error LazyMintERC721Base__TransferFromIncorrectOwner();
    error LazyMintERC721Base__TransferToNonERC721Receiver();
    error LazyMintERC721Base__TransferToTheZeroAddress();
    error LazyMintERC721Base__TransferToNonERC721ReceiverImplementer();

    address public constant DEFAULT_TOKEN_OWNER = address(0x00000089E8825c9A59B4503398fAACF2e9A9CDb0);

    // Never allow more than 1 million tokens per consecutive transfer event
    uint256 public constant MAX_TOKENS_PER_CONSECUTIVE_TRANSFER_UPPER_LIMIT = 1_000_000;

    uint256 private _amountCreated;

    uint256 private _remainingMintableSupply;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address and a flag on whether it has left original default owner wallet   
    mapping(uint256 => TokenOwner) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId, 
        uint256 toTokenId, 
        address indexed fromAddress, 
        address indexed toAddress);

    // The recommended value for `maxTokensPerConsecutiveTransfer` is 5000, as this limit is imposed by OpenSea.
    // This value could go up or down in the future, so it is capped only by 
    // `MAX_TOKENS_PER_CONSECUTIVE_TRANSFER_UPPER_LIMIT` (1 million).
    function mint(uint256 amount, uint256 maxTokensPerConsecutiveTransfer) external {
        _requireCallerIsMinterOrContractOwner();

        if (amount == 0) {
            revert LazyMintERC721Base__AmountMustBeGreaterThanZero();
        }

        if (amount > _remainingMintableSupply) {
            revert LazyMintERC721Base__AmountExceedsMaxRemainingSupply();
        }

        if (maxTokensPerConsecutiveTransfer == 0) {
            revert LazyMintERC721Base__MaxTokensPerConsecutiveTransferMustBeGreaterThanZero();
        }

        if (maxTokensPerConsecutiveTransfer > MAX_TOKENS_PER_CONSECUTIVE_TRANSFER_UPPER_LIMIT) {
            revert LazyMintERC721Base__MaxTokensPerConsecutiveTransferUpperLimitExceeded();
        }
        
        _balances[DEFAULT_TOKEN_OWNER] += amount;

        unchecked {
            uint256 tokenStartId = _amountCreated + 1;
            uint256 tokenStopId = tokenStartId + amount - 1;
            for (tokenStartId; tokenStartId <= tokenStopId; tokenStartId += maxTokensPerConsecutiveTransfer) {
                uint256 tokenEndId = tokenStartId + maxTokensPerConsecutiveTransfer - 1;
                if (tokenEndId > tokenStopId) {
                    tokenEndId = tokenStopId;
                }

                emit ConsecutiveTransfer(tokenStartId, tokenEndId, address(0), DEFAULT_TOKEN_OWNER);
            }

            _amountCreated += amount;
            _remainingMintableSupply -= amount;
        }
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner_ = ownerOf(tokenId);
        if (to == owner_) {
            revert LazyMintERC721Base__ApprovalToCurrentOwner();
        }

        if (!(_msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()))) {
            revert LazyMintERC721Base__ApproveCallerIsNotTokenOwnerOrApprovedForAll();
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (_msgSender() == operator) {
            revert LazyMintERC721Base__ApproveToCaller();
        }

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        (address owner_, TokenOwner storage tokenOwner_) = _ownerOf(tokenId);

        bool isApprovedOrOwner_ = 
        (
            _msgSender() == owner_ || 
            _operatorApprovals[owner_][_msgSender()] || 
            _tokenApprovals[tokenId] == _msgSender()
        );
       
        if (!isApprovedOrOwner_) {
            revert LazyMintERC721Base__TransferCallerIsNotOwnerNorApproved();
        }

        _transfer(owner_, tokenOwner_, from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        transferFrom(from, to, tokenId);

        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert LazyMintERC721Base__TransferToNonERC721Receiver();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function amountCreated() public view returns (uint256) {
        return _amountCreated;
    }

    function remainingMintableSupply() public view returns (uint256) {
        return _remainingMintableSupply;
    }

    function balanceOf(address owner_) public view virtual override returns (uint256) {
        if (owner_ == address(0)) {
            revert LazyMintERC721Base__AddressZeroIsNotAValidOwner();
        }

        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address owner_) {
        (owner_, ) = _ownerOf(tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
            revert LazyMintERC721Base__TokenDoesNotExist();
        }

        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory);

    function _transfer(
        address owner_,
        TokenOwner storage tokenOwner_,
        address from,
        address to,
        uint256 tokenId) internal virtual {

        if (owner_ != from) {
            revert LazyMintERC721Base__TransferFromIncorrectOwner();
        }
        
        if (to == address(0)) {
            revert LazyMintERC721Base__TransferToTheZeroAddress();
        }

        _beforeTokenTransfer(from, to, tokenId, 1);

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;

            if (tokenOwner_.transferCount < type(uint88).max) {
                ++tokenOwner_.transferCount;
            }
        }

        tokenOwner_.transferred = true;
        tokenOwner_.ownerAddress = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    function _safeTransfer(
        address owner_,
        TokenOwner storage tokenOwner_,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data) internal virtual {

        _transfer(owner_, tokenOwner_, from, to, tokenId);

        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert LazyMintERC721Base__TransferToNonERC721Receiver();
        }
    }

    function _burn(address owner_, uint256 tokenId) internal virtual {
        _beforeTokenTransfer(owner_, address(0), tokenId, 1);

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[owner_] -= 1;
        }

        _owners[tokenId].transferred = true;
        _owners[tokenId].ownerAddress = address(0);

        emit Transfer(owner_, address(0), tokenId);

        _afterTokenTransfer(owner_, address(0), tokenId, 1);
    }

    function _setMaxSupplyNameAndSymbol(uint256 maxSupply_, string memory name_, string memory symbol_) internal virtual {
        if (maxSupply_ == 0) {
            revert LazyMintERC721Base__MaxSupplyMustBeGreaterThanZero();
        }

        _remainingMintableSupply = maxSupply_;
        _name = name_;
        _symbol = symbol_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        if(_isValidTokenId(tokenId)) {
            TokenOwner memory tokenOwner = _owners[tokenId];
            return tokenOwner.ownerAddress != address(0) || !tokenOwner.transferred;
        } else {
            return false;   
        }
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address owner_, TokenOwner storage tokenOwner_) {
        tokenOwner_ = _owners[tokenId];
        if (tokenOwner_.transferred) {
            if (tokenOwner_.ownerAddress == address(0)) {
                revert LazyMintERC721Base__TokenDoesNotExist();
            }

            owner_ = tokenOwner_.ownerAddress;
        } else {
            if (!_isValidTokenId(tokenId)) {
                revert LazyMintERC721Base__TokenDoesNotExist();
            }

            owner_ = DEFAULT_TOKEN_OWNER;
        }
    }

    function _isValidTokenId(uint256 tokenId) internal view returns (bool) {
        return tokenId <= _amountCreated && tokenId > 0;
    }

    /** 
     * @dev Validates that the caller is a minter
     * @dev Throws when the caller is not a minter
     */
    function _requireCallerIsMinterOrContractOwner() internal view virtual {
        _requireCallerIsContractOwner();
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert LazyMintERC721Base__TransferToNonERC721ReceiverImplementer();
                } else {
                    /// @solidity memory-safe-assembly
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

abstract contract LazyMintERC721 is LazyMintERC721Base {
    constructor(uint256 maxSupply_, string memory name_, string memory symbol_) {
        _setMaxSupplyNameAndSymbol(maxSupply_, name_, symbol_);
    }
}

abstract contract LazyMintERC721Initializable is LazyMintERC721Base {

    error LazyMintERC721Initializable__AlreadyInitializedERC721();

    /// @notice Specifies whether or not the contract is initialized
    bool private _erc721Initialized;

    /// @dev Initializes parameters of ERC721 tokens.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeERC721(uint256 maxSupply_, string memory name_, string memory symbol_) public {
        _requireCallerIsContractOwner();

        if(_erc721Initialized) {
            revert LazyMintERC721Initializable__AlreadyInitializedERC721();
        }

        _erc721Initialized = true;

        _setMaxSupplyNameAndSymbol(maxSupply_, name_, symbol_);
    }
}