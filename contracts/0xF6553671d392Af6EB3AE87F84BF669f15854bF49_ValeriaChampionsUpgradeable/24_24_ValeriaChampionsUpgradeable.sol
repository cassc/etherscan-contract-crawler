// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import {ERC721BUpgradeable} from "./abstract/ERC721BUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./abstract/LockRegistry.sol";
import "./interfaces/IDelegationRegistry.sol";
import "./interfaces/IValeria.sol";

/**
 * @title ValeriaChampionsUpgradeable
 * @custom:website https://valeriagames.com
 * @author @ValeriaStudios
 */
contract ValeriaChampionsUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    ERC2981Upgradeable,
    ERC721BUpgradeable,
    OperatorFilterer,
    LockRegistry,
    IValeria
{
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    // Roles
    bytes32 constant EXTERNAL_STAKE_ROLE = keccak256("EXTERNAL_STAKE_ROLE");
    bytes32 constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @notice Base uri
    string public baseURI;

    /// @notice Maximum supply for the collection
    uint256 public constant MAX_SUPPLY = 1201;

    /// @notice Total supply
    uint256 private _totalMinted;

    /// @notice Operator filter toggle switch
    bool private operatorFilteringEnabled;

    /// @notice Delegation registry
    address public delegationRegistryAddress;

    modifier isDelegate(address vault) {
        bool isDelegateValid = IDelegationRegistry(delegationRegistryAddress)
            .checkDelegateForContract(_msgSender(), vault, address(this));
        require(isDelegateValid, "Invalid delegate-vault pairing");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _delegationRegistryAddress
    ) public virtual initializer {
        __ERC721B_init("Valeria Champions", "VC");
        LockRegistry.__LockRegistry_init();
        __AccessControl_init();
        __ERC2981_init();
        // Setup access control
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(EXTERNAL_STAKE_ROLE, _msgSender());
        // Setup filter registry
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Setup royalties to 6.5% (default denominator is 10000)
        _setDefaultRoyalty(_msgSender(), 650);
        // Setup contracts
        delegationRegistryAddress = _delegationRegistryAddress;
        // Set metadata
        baseURI = "ipfs://QmW8rvstfAN6JaG2cBsV1jLr3LziEe3265x3PgpYo63oiz/";
    }

    /**
     * @notice Migrate NFTs from a snapshot
     * @param tokenIds - The token ids
     * @param owners - The token owners
     */
    function migrateTokens(
        uint256[] calldata tokenIds,
        address[] calldata owners
    ) external onlyOwner {
        uint256 inputSize = tokenIds.length;
        uint256 newTotalMinted = _totalMinted + inputSize;
        require(owners.length == inputSize);
        require(newTotalMinted <= MAX_SUPPLY);
        uint256 tokenId;
        address owner;
        for (uint256 i; i < inputSize; ) {
            tokenId = tokenIds[i];
            owner = owners[i];
            // Mint new token token id to previous owner
            _mint(owner, tokenId);
            unchecked {
                i++;
            }
        }
        _totalMinted = newTotalMinted;
    }

    /**
     * @notice Total supply of the collection
     * @return uint256 The total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalMinted;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            ERC721BUpgradeable,
            ERC2981Upgradeable,
            AccessControlUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            ERC721BUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721BUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "!unlocked");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function lockId(uint256 _id) external onlyRole(EXTERNAL_STAKE_ROLE) {
        require(_exists(_id), "Token !exist");
        _lockId(_id);
    }

    function unlockId(uint256 _id) external onlyRole(EXTERNAL_STAKE_ROLE) {
        require(_exists(_id), "Token !exist");
        _unlockId(_id);
    }

    function freeId(
        uint256 _id,
        address _contract
    ) external onlyRole(EXTERNAL_STAKE_ROLE) {
        require(_exists(_id), "Token !exist");
        _freeId(_id, _contract);
    }

    /**
     * @notice Sets the delegation registry address
     * @param _delegationRegistryAddress The delegation registry address
     */
    function setDelegationRegistry(
        address _delegationRegistryAddress
    ) external onlyOwner {
        delegationRegistryAddress = _delegationRegistryAddress;
    }

    /**
     * @notice Token uri
     * @param tokenId The token id
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_exists(tokenId), "!exists");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @notice Sets the base uri for the token metadata
     * @param _baseURI The base uri
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Set default royalty
     * @param receiver The royalty receiver address
     * @param feeNumerator A number for 10k basis
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Sets whether the operator filter is enabled or disabled
     * @param operatorFilteringEnabled_ A boolean value for the operator filter
     */
    function setOperatorFilteringEnabled(
        bool operatorFilteringEnabled_
    ) public onlyOwner {
        operatorFilteringEnabled = operatorFilteringEnabled_;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    /**
     * @notice Return token ids owned by user
     * @param account Account to query
     * @return tokenIds
     */
    function tokensOfOwner(
        address account
    ) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(account);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                if (!_exists(i)) {
                    continue;
                }
                if (ownerOf(i) == account) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}