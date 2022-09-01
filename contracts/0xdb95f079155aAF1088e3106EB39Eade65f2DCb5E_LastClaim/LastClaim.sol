/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.7;

interface IMoonBase {
    function mintPaused() external view returns (bool);
    function mintPrice() external view returns (uint256);
    function currentMintId() external view returns (uint256);
    function mint(uint256 amount) external payable;
    function updateMintPaused(bool paused) external;
    function updateCurrentMintId(uint256 mintId) external;
    function updateMintPrice(uint256 price) external;
}

contract LastClaim is Ownable {
    error NotClaimTime();
    error MaxClaimReached();
    error GivenMintOrderVerificationFailed();

    uint256 private constant MAX_FREE_PER_WALLET = 3;
    uint256 private constant MINT_PRICE = 0.01 ether;

    // Security used to prevent from minting directly through MoonBase
    // this will be annoying for me but I doubt this worth its 10 ETH
    uint256 private constant MINT_PRICE_SECURITY = 10 ether;

    // Backend wallet used to sign randomization of mint
    address private constant AUTHORITY = 0x8FDb63D69bCd146D7a52C55196d8ec5692e41369;

    IMoonBase private moonBase;
    IERC721 private mlz;
    uint256 public freeClaimTime;

    mapping(address => uint256) public freeClaims;

    event FreeClaimTimeUpdated(uint256 time);
    event FreeClaimCleared(address addr);

    constructor(address moonBaseAddr, address mlzAddr) {
        moonBase = IMoonBase(moonBaseAddr);
        mlz = IERC721(mlzAddr);
    }

    function setFreeClaimTime(uint256 time) external onlyOwner {
        freeClaimTime = time;

        emit FreeClaimTimeUpdated(time);
    }

    function clearFreeClaim(address addr) external onlyOwner {
        freeClaims[addr] = 0;

        emit FreeClaimCleared(addr);
    }

    function giveBackOwnership() external onlyOwner {
        Ownable(address(moonBase)).transferOwnership(msg.sender);
    }

    function freeClaim(
        uint256[] calldata ids,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        external
    {
        uint256 claimTime = freeClaimTime;

        if (block.timestamp < claimTime || claimTime == 0)
            revert NotClaimTime();

        uint256 len = ids.length;
        uint256 nextClaims;

        unchecked {
            nextClaims = freeClaims[msg.sender] + len;
        }

        if (nextClaims > MAX_FREE_PER_WALLET) {
            revert MaxClaimReached();
        }

        freeClaims[msg.sender] = nextClaims;
        
        moonBase.updateMintPrice(0);

         // Saving gas for successful claims, otherwise considered
        // as exploit attempt, all computations will succeed but
        // the verification will fail at then end of the tx
        uint256 currentId;
        bytes memory encodedMessage = abi.encodePacked(msg.sender);
        address self = address(this);

        for (uint256 i; i < len;) {
            currentId = ids[i];

            encodedMessage = _concat(
                encodedMessage,
                _toBytes(currentId)
            );

            moonBase.updateCurrentMintId(currentId);
            moonBase.mint(1);
            mlz.transferFrom(self, msg.sender, currentId);

            unchecked {
                i++;
            }
        }

        // Reverting here at the end if detecting a fake signature
        // No need to keep any tracks since once sig used,
        // the same sig used again will revert on NFTs transferFrom
        if (
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(encodedMessage)
                    )
                ),
                v,
                r,
                s
            ) != AUTHORITY
        ) revert GivenMintOrderVerificationFailed();

        // Security to prevent anyone from minting directly through MoonBase
        // I could have used mintPaused but we need at some point to update
        // mint price to 0 so this would have required 2 diff write op vs
        // 2 same slot write op => cheaper
        moonBase.updateMintPrice(MINT_PRICE_SECURITY);
    }

    function mint(
        uint256[] calldata ids,
        bytes32 r,
        bytes32 s,
        uint8 v
    )
        external
        payable
    {
        moonBase.updateMintPrice(MINT_PRICE);

        // Saving gas for successful claims, otherwise considered
        // as exploit attempt, all computations will succeed but
        // the verification will fail at then end of the tx
        uint256 len = ids.length;
        uint256 currentId;
        uint256 mintValue;

        unchecked {
            mintValue = msg.value / ids.length;
        }
        
        bytes memory encodedMessage = abi.encodePacked(msg.sender);
        address self = address(this);

        for (uint256 i; i < len;) {
            currentId = ids[i];

            encodedMessage = _concat(
                encodedMessage,
                _toBytes(currentId)
            );

            moonBase.updateCurrentMintId(currentId);
            moonBase.mint{value: mintValue}(1);
            mlz.transferFrom(self, msg.sender, currentId);

            unchecked {
                i++;
            }
        }

        // Reverting here at the end if detecting a fake signature
        // No need to keep any tracks since once sig used,
        // the same sig used again will revert on NFTs transferFrom
        if (
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(encodedMessage))
                ),
                v,
                r,
                s
            ) != AUTHORITY
        ) revert GivenMintOrderVerificationFailed();

        moonBase.updateMintPrice(MINT_PRICE_SECURITY);
    }

    function _toBytes(uint256 nb) private pure returns (bytes memory b) {
        b = new bytes(32);

        assembly { 
            mstore(add(b, 32), nb)
        }
    }

    function _concat(
        bytes memory pre,
        bytes memory post
    )
        private
        pure
        returns (bytes memory result)
    {
        assembly {
            result := mload(0x40)

            let length := mload(pre)

            mstore(result, length)

            let mc := add(result, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(pre, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(post)
            mstore(result, add(length, mload(result)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(post, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(pre)))), 31),
              not(31)
            ))
        }

        return result;
    }
}