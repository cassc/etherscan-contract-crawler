//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721PsiBurnableUpgradeable, ERC721PsiUpgradeable} from 'erc721psi/contracts/extension/ERC721PsiBurnableUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {UUPSUpgradeable} from '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {ERC2981Upgradeable} from '@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol';
import {DefaultOperatorFiltererUpgradeable} from 'operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol';
import {IContractAllowListProxy} from 'contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol';
import {EnumerableSetUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

contract CNPNinjaYashiki is
    Initializable,
    UUPSUpgradeable,
    ERC721PsiBurnableUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC2981Upgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');
    bytes32 public constant CONFIGURATOR_ROLE = keccak256('CONFIGURATOR_ROLE');
    string public constant BASE_EXTENSION = '.json';

    string public baseURI;
    IContractAllowListProxy public cal;
    uint256 public calLevel;
    bool public enableRestrict;

    EnumerableSetUpgradeable.AddressSet private localAllowedAddresses;

    mapping(uint256 => bool) internal _blockedToken;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), 'Caller is not a burner');
        _;
    }
    modifier onlyConfigrator() {
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), 'Caller is not a configrator');
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __ERC721Psi_init('CNP Ninja-Yashiki', 'CNPY');
        __Ownable_init();
        __AccessControl_init();
        __DefaultOperatorFilterer_init();
        __ERC2981_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(CONFIGURATOR_ROLE, msg.sender);
        _setDefaultRoyalty(0x0a2C099044c088A431b78a0D6Bb5A137a5663297, 1000);
        baseURI = 'https://data.syou-nft.com/cnpy/json/';
        calLevel = 1;
        enableRestrict = true;
    }

    // internal
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _isAllowed(address transferer) internal view virtual returns (bool) {
        if (!enableRestrict) return true;
        if (address(cal) != address(0)) {
            return localAllowedAddresses.contains(transferer) || cal.isAllowed(transferer, calLevel);
        } else {
            return localAllowedAddresses.contains(transferer);
        }
    }

    function _beforeTokenTransfers(address, address, uint256 startTokenId, uint256) internal virtual override {
        require(!_blockedToken[startTokenId], 'This token ID has been blocked.');
    }

    // external (only minter)
    function minterMint(address _address, uint256 _amount) external onlyMinter {
        _safeMint(_address, _amount);
    }

    // external (only burner)
    function burnerBurn(address _address, uint256[] calldata tokenIds) external onlyBurner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_address == ownerOf(tokenId), 'address is not owner');

            _burn(tokenId);
        }
    }

    // public (only configrator)
    function setBlockedTokens(uint256[] calldata tokenIds) external onlyConfigrator {
        for (uint256 i = 0; i < tokenIds.length; ) {
            _blockedToken[tokenIds[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function unsetBlockedTokens(uint256[] calldata tokenIds) external onlyConfigrator {
        for (uint256 i = 0; i < tokenIds.length; ) {
            _blockedToken[tokenIds[i]] = false;
            unchecked {
                ++i;
            }
        }
    }

    //external
    function getBlockedToken(uint256 tokenId) external view virtual returns (bool) {
        return _blockedToken[tokenId];
    }

    function getLocalContractAllowList() external view returns (address[] memory) {
        return localAllowedAddresses.values();
    }

    // external (only owner)
    function addLocalContractAllowList(address transferer) external onlyOwner {
        localAllowedAddresses.add(transferer);
    }

    function removeLocalContractAllowList(address transferer) external onlyOwner {
        localAllowedAddresses.remove(transferer);
    }

    function setCAL(address value) external onlyOwner {
        cal = IContractAllowListProxy(value);
    }

    function setCALLevel(uint256 value) external onlyOwner {
        calLevel = value;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setEnableRestrict(bool value) external onlyOwner {
        enableRestrict = value;
    }

    // public (only owner)
    function ownerMint(address to, uint256 count) public onlyOwner {
        _safeMint(to, count);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}('');
        require(os, 'withdraw error');
    }

    //public
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721PsiUpgradeable.tokenURI(tokenId), BASE_EXTENSION));
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        require(_isAllowed(operator) || !approved, 'Can not approve locked token');
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if (!_isAllowed(operator)) return false;
        return super.isApprovedForAll(account, operator);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721PsiUpgradeable, AccessControlUpgradeable, ERC2981Upgradeable) returns (bool) {
        return
            ERC721PsiUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }
}