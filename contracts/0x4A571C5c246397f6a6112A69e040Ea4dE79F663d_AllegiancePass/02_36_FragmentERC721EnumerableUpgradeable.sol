// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

abstract contract FragmentERC721EnumerableUpgradeable is
    ERC721EnumerableUpgradeable,
    ERC2981Upgradeable,
    UUPSUpgradeable,
    AccessControlEnumerableUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    bytes32 public constant OPERATOR_ROLE = keccak256(bytes("OPERATOR"));

    string public baseURI;

    event RoyaltyInfoUpdated(address newReceiver, uint96 newValue);

    function __FragmentERC721_init(string memory name_, string memory symbol_, address owner_)
        public
        onlyInitializing
    {
        __ERC721_init(name_, symbol_);
        __DefaultOperatorFilterer_init();

        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function owner() public view virtual returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function addOperator(address operator) public onlyOperator {
        _grantRole(OPERATOR_ROLE, operator);
    }

    function setRoyaltyInfo(address receiver_, uint96 value_) public onlyOperator {
        _setDefaultRoyalty(receiver_, value_);
        emit RoyaltyInfoUpdated(receiver_, value_);
    }

    function setApprovalForAll(address operator, bool approved) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721Upgradeable, ERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721Upgradeable, ERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return AccessControlEnumerableUpgradeable.supportsInterface(interfaceId)
            || ERC721EnumerableUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId)
            || super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOperator {}

    modifier onlyOperator() {
        _checkRole(OPERATOR_ROLE);
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}