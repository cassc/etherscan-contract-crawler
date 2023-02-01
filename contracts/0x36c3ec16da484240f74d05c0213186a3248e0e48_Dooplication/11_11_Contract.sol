// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./external/delegate-cash/IDelegationRegistry.sol";

contract Dooplication is Ownable, AccessControl {
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    uint256 private constant _DOOPLICATOR_WORDS = 37; // doop bitmap length

    // Map (tokenContract => approved). Approved contracts for dooplication
    mapping(address => bool) private _approvedContracts;

    // Map (tokenContract => bitmap). Track dooplicated tokens in each contract
    mapping(address => uint256[]) private _bitmaps;

    // Map (tokenContract => bitmap). Track dooplicator usage per contract.
    mapping(address => uint256[_DOOPLICATOR_WORDS]) private _bitmapDooplicators; // 9_375 doops

    // Map (tokenContract => active). Track dooplicationActive per contract
    mapping(address => bool) public dooplicationActive;

    address public immutable dooplicatorContract;
    address public constant DELEGATION_REGISTRY =
        0x00000000000076A84feF008CDAbe6409d2FE638B;

    /**************************************************************************
     * Events
     */

    event Dooplicate(
        uint256 indexed dooplicatorId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address dooplicatorOwner,
        bytes8 addressOnTheOtherSide,
        bytes data
    );

    /**************************************************************************
     * Errors
     */

    error ContractAlreadyApproved();
    error ContractNotApprovedForDooplication();
    error InvalidInputAddress();
    error InvalidInputNotERC721Address();
    error DooplicationNotActive();
    error DooplicatorHasBeenUsed();
    error TokenHasBeenDooplicated();
    error TokenOutOfRange();
    error NotOwnerOrDelegateOfDooplicator();
    error NotOwnerOrDelegateOfToken();
    error NoTokenRecordsForThisContract();

    /**************************************************************************
     * Modifiers
     */

    modifier contractIsApproved(address tokenContract) {
        if (!_approvedContracts[tokenContract]) {
            revert ContractNotApprovedForDooplication();
        }
        _;
    }

    /**************************************************************************
     * Constructor
     */

    /**
     * @param dooplicatorContract_ address for the dooplicator token contract
     */
    constructor(address dooplicatorContract_) {
        bytes4 erc721InterfaceId = type(IERC721).interfaceId;

        try
            IERC721(dooplicatorContract_).supportsInterface(erc721InterfaceId)
        returns (bool result) {
            if (!result) revert InvalidInputNotERC721Address();
        } catch {
            revert InvalidInputAddress();
        }

        dooplicatorContract = dooplicatorContract_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);
    }

    /**************************************************************************
     * Functions - external
     */

    /**
     * @notice We doo a little dooplication
     *  Use a dooplicator to dooplicate a token you own or are approved on.
     *  If your token or dooplicator is in a vault, you can delegate another
     *  address to act on its behalf using delegate.cash.
     *
     *  Please be aware delegate.cash is an external service - you can read
     *  about it and delegate your tokens at https://delegate.cash
     *  Their smart contract is readable at:
     *  0x00000000000076A84feF008CDAbe6409d2FE638B
     *
     * @param dooplicatorId a dooplicator you own or are delegated for
     * @param dooplicatorVault the address that holds the dooplicator if using
     *  delegation, or the zero address otherwise (0x00..00)
     * @param tokenId a token you own, or are delegated for
     * @param tokenContract the contract address of the token to dooplicate
     * @param tokenVault the address that holds the token if using delegation,
     *  or the zero address otherwise (0x00..00)
     * @param addressOnTheOtherSide an address you control, on the other side...
     * @param data optional data to add to the log. Use '0x' or [] for empty data
     */
    function dooplicate(
        uint256 dooplicatorId,
        address dooplicatorVault,
        uint256 tokenId,
        address tokenContract,
        address tokenVault,
        bytes8 addressOnTheOtherSide,
        bytes calldata data
    )
        external
        contractIsApproved(tokenContract)
    {
        if (!dooplicationActive[tokenContract]) revert DooplicationNotActive();

        // check dooplicator ownership
        if (
            !_ownerOrDelegate(
                msg.sender,
                dooplicatorVault,
                dooplicatorContract,
                dooplicatorId
            )
        ) {
            revert NotOwnerOrDelegateOfDooplicator();
        }

        // check token ownership
        if (
            !_ownerOrDelegate(
                msg.sender,
                tokenVault,
                tokenContract,
                tokenId
            )
        ) {
            revert NotOwnerOrDelegateOfToken();
        }

        // check dooplicator & token usage
        if (dooplicatorUsed(dooplicatorId, tokenContract)) {
            revert DooplicatorHasBeenUsed();
        }

        if (tokenDooplicated(tokenId, tokenContract)) {
            revert TokenHasBeenDooplicated();
        }

        // effects
        _setDooplicatorUsed(dooplicatorId, tokenContract);
        _setTokenDooplicated(tokenId, tokenContract);

        emit Dooplicate(
            dooplicatorId,
            tokenId,
            tokenContract,
            dooplicatorVault == address(0) ? msg.sender : dooplicatorVault,
            addressOnTheOtherSide,
            data
        );
    }

    /**************************************************************************
     * Functions - external - access & info
     */

    /**
     * @notice check if a specific user can dooplicate a specific token using a
     *  specific dooplicator. Set vault addresses to the zero address if unused.
     * @param operator the user address to check
     * @param dooplicatorId the dooplicator token ID to check
     * @param dooplicatorVault address that holds the dooplicator if using
     *  delegation, or the zero address otherwise (0x00..00)
     * @param tokenId the token ID to check
     * @param tokenContract the contract address for the token
     * @param tokenVault address that holds the token if using delegation, or
     *  the zero address otherwise (0x00..00)
     * @return boolean true if the operator can dooplicate these tokens, false
     *  otherwise
     */
    function canDooplicate(
        address operator,
        uint256 dooplicatorId,
        address dooplicatorVault,
        uint256 tokenId,
        address tokenContract,
        address tokenVault
    )
        external
        view
        returns (bool)
    {
        if (
            !_approvedContracts[tokenContract] ||
            !dooplicationActive[tokenContract] ||
            dooplicatorUsed(dooplicatorId, tokenContract) ||
            tokenDooplicated(tokenId, tokenContract) ||
            !_ownerOrDelegate(
                operator,
                dooplicatorVault,
                dooplicatorContract,
                dooplicatorId
            ) ||
            !_ownerOrDelegate(operator, tokenVault, tokenContract, tokenId)
        ) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice check if a contract address has been approved for its tokens
     *  to be dooplicated
     * @param tokenContract the contract address to check
     * @return approved true if approved, false otherwise
     */
    function contractApproved(address tokenContract)
        external
        view
        returns (bool)
    {
        return _approvedContracts[tokenContract];
    }

    /**
     * @notice check if a dooplicator has been used to dooplicate tokens from a
     *  specific token contract
     * @param dooplicatorId the dooplicator to check
     * @param tokenContract the contract to check against
     * @return used true if used, false otherwise
     */
    function dooplicatorUsed(uint256 dooplicatorId, address tokenContract)
        public
        view
        returns (bool)
    {
        uint256[_DOOPLICATOR_WORDS] storage bitmap = _bitmapDooplicators[
            tokenContract
        ];

        (uint256 wordIndex, uint256 bitIndex) = _wordAndBit(dooplicatorId);
        if (wordIndex >= _DOOPLICATOR_WORDS) revert TokenOutOfRange();

        uint256 word = bitmap[wordIndex];
        uint256 mask = 1 << bitIndex;

        return (word & mask) == mask;
    }

    /**
     * @notice check if a token has been dooplicated
     * @param tokenId the token to check
     * @param tokenContract the contract address of the token to check
     * @return dooplicated true if dooplicated, false otherwise
     */
    function tokenDooplicated(uint256 tokenId, address tokenContract)
        public
        view
        returns (bool)
    {
        uint256[] storage bitmap = _bitmaps[tokenContract];
        uint256 bitmapLength = bitmap.length;
        if (bitmapLength == 0) revert NoTokenRecordsForThisContract();

        (uint256 wordIndex, uint256 bitIndex) = _wordAndBit(tokenId);
        if (wordIndex >= bitmapLength) revert TokenOutOfRange();

        uint256 word = bitmap[wordIndex];
        uint256 mask = 1 << bitIndex;

        return (word & mask) == mask;
    }

    /**************************************************************************
     * Functions - owner/dev
     */

    /**
     * @dev start and stop dooplication
     * @param active true to start dooplication, false to stop
     * @param tokenContract the contract to modify
     */
    function setDooplicationActive(bool active, address tokenContract)
        external
        onlyRole(SUPPORT_ROLE)
    {
        dooplicationActive[tokenContract] = active;
    }

    /**
     * @dev approve a new contract of ERC721 tokens that can be dooplicated.
     * @param approvedContract the ERC721 contract to approve
     * @param highestTokenId the highest tokenId in the approvedContract
     */
    function addApprovedContract(
        address approvedContract,
        uint256 highestTokenId
    )
        external
        onlyRole(SUPPORT_ROLE)
    {
        if (_approvedContracts[approvedContract]) {
            revert ContractAlreadyApproved();
        }

        bytes4 erc721InterfaceId = type(IERC721).interfaceId;

        try
            IERC721(approvedContract).supportsInterface(erc721InterfaceId)
        returns (bool result) {
            if (!result) revert InvalidInputNotERC721Address();
        } catch {
            revert InvalidInputAddress();
        }

        // compute required bitmap length (tokenIds start at 0)
        uint256 requiredBits = highestTokenId + 1;
        uint256 size = Math.ceilDiv(requiredBits, 256);
        uint256[] memory newBitmap = new uint256[](size);

        // add bitmap and approve address
        _bitmaps[approvedContract] = newBitmap;
        _approvedContracts[approvedContract] = true;

        // ensure dooplicationActive is reset
        delete dooplicationActive[approvedContract];
    }

    /**
     * @dev revoke approval for a contract's tokens to be dooplicated.
     *  The record of dooplicated items in the contract will also be reset.
     * @param contractToRevoke revoke approval for this contract address
     */
    function revokeContractApproval(address contractToRevoke)
        external
        contractIsApproved(contractToRevoke)
        onlyRole(SUPPORT_ROLE)
    {
        delete _approvedContracts[contractToRevoke];
        delete _bitmaps[contractToRevoke];
        delete _bitmapDooplicators[contractToRevoke];
        delete dooplicationActive[contractToRevoke];
    }

    /**************************************************************************
     * Functions - internal
     */

    /**
     * @dev check if an operator is the owner or delegate of a token. If the
     *  operator has been delegated, the delegating address must own the token.
     *  The external call to tokenContract should be to a trusted contract.
     * @param operator the potential owner or delegate address
     * @param vault the vault address to check, zero address if not used
     * @param tokenContract contract address of the token to check
     * @param tokenId the tokenId to check
     * @return true if the operator is owner or delegate, false otherwise
     */
    function _ownerOrDelegate(
        address operator,
        address vault,
        address tokenContract,
        uint256 tokenId
    )
        internal
        view
        returns (bool)
    {
        address requester = operator;

        if (vault != address(0)) {
            if (
                IDelegationRegistry(DELEGATION_REGISTRY).checkDelegateForToken(
                    operator,
                    vault,
                    tokenContract,
                    tokenId
                )
            ) {
                requester = vault;
            }
        }

        return IERC721(tokenContract).ownerOf(tokenId) == requester;
    }

    /**
     * @dev mark a dooplicator as used on a specific contract
     * @param dooplicatorId the dooplicator to mark
     * @param tokenContract the contract whose token has been dooplicated
     */
    function _setDooplicatorUsed(uint256 dooplicatorId, address tokenContract)
        internal
    {
        uint256[_DOOPLICATOR_WORDS] storage bitmap = _bitmapDooplicators[
            tokenContract
        ];

        (uint256 wordIndex, uint256 bitIndex) = _wordAndBit(dooplicatorId);
        uint256 word = bitmap[wordIndex];
        uint256 mask = 1 << bitIndex;

        bitmap[wordIndex] = word | mask;
    }

    /**
     * @dev mark a token as dooplicated
     * @param tokenId the token to mark
     * @param tokenContract the contract whose token has been dooplicated
     */
    function _setTokenDooplicated(uint256 tokenId, address tokenContract)
        internal
    {
        uint256[] storage bitmap = _bitmaps[tokenContract];

        (uint256 wordIndex, uint256 bitIndex) = _wordAndBit(tokenId);
        uint256 word = bitmap[wordIndex];
        uint256 mask = 1 << bitIndex;

        bitmap[wordIndex] = word | mask;
    }

    /**
     * @dev helper for indexing into bitmaps
     */
    function _wordAndBit(uint256 index)
        private
        pure
        returns (uint256, uint256)
    {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;

        return (wordIndex, bitIndex);
    }
}