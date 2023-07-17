// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EIP2981RoyaltyOverrideCore} from "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {IContractAllowListProxy} from "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";
import {SS2ERC721PsiBurnable, ERC721Psi} from "./SS2ERC721PsiBurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./locker/Lockable.sol";

contract CNPJ is
    SS2ERC721PsiBurnable,
    DefaultOperatorFilterer,
    EIP2981RoyaltyOverrideCore,
    Ownable,
    AccessControl,
    Lockable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using BitMaps for BitMaps.BitMap;
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant BURNER = keccak256("BURNER");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    constructor() SS2ERC721PsiBurnable("CNP Jobs", "CNPJ", 11_111) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    // ==================================================
    // Restrict Approve
    // ==================================================
    IContractAllowListProxy public cal =
        IContractAllowListProxy(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);
    uint256 public calLevel = 1;
    bool public enableRestrict = true;
    EnumerableSet.AddressSet private localAllowedAddresses;

    function setCAL(address value) external onlyOwner {
        cal = IContractAllowListProxy(value);
    }

    function setCALLevel(uint256 value) external onlyOwner {
        calLevel = value;
    }

    function setEnableRestrict(bool value) public onlyRole(ADMIN) {
        enableRestrict = value;
    }

    function addLocalContractAllowList(
        address transferer
    ) external onlyRole(ADMIN) {
        localAllowedAddresses.add(transferer);
    }

    function removeLocalContractAllowList(
        address transferer
    ) external onlyRole(ADMIN) {
        localAllowedAddresses.remove(transferer);
    }

    function getLocalContractAllowList()
        external
        view
        returns (address[] memory)
    {
        return localAllowedAddresses.values();
    }

    function _isAllowed(
        address transferer
    ) internal view virtual returns (bool) {
        if (!enableRestrict) return true;

        return
            localAllowedAddresses.contains(transferer) ||
            cal.isAllowed(transferer, calLevel);
    }

    // ==================================================
    // Lockable
    // ==================================================
    address private _locker;

    function locker() public view override returns (address) {
        return _locker;
    }

    function setLocker(address value) public onlyRole(ADMIN) {
        _locker = value;
    }

    // ==================================================
    // Block
    // ==================================================
    BitMaps.BitMap internal _blockedToken;

    function isBlocked(uint256 tokenId) public view virtual returns (bool) {
        return _blockedToken.get(tokenId);
    }

    modifier whenNotBlocked(uint256 tokenId) {
        require(isBlocked(tokenId) == false, "token is blocked.");
        _;
    }

    function execBlock(uint256[] calldata tokenIds) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < tokenIds.length; ) {
            _blockedToken.set(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function unblock(uint256[] calldata tokenIds) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < tokenIds.length; ) {
            _blockedToken.unset(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    // ======================================================
    // Token Lifecycle
    // ======================================================
    function mint(address to, uint256 amount) external onlyRole(MINTER) {
        _safeMint(to, amount);
    }

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _safeMint(to, amount);
    }

    function burn(
        address from,
        uint256[] calldata tokenIds
    ) external onlyRole(BURNER) {
        require(tx.origin == from, "from is not tx.origin.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(from == ownerOf(tokenId), "address is not owner.");

            _burn(tokenId);
        }
    }

    // ======================================================
    // Aridrop
    // ======================================================
    function setBalance(
        address[] calldata _address,
        uint16[] calldata _balance
    ) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _address.length; ) {
            _setBalance(_address[i], _balance[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setOwnerPointers(
        address[] calldata _pointer,
        uint256 startIndex
    ) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _pointer.length; ) {
            _setOwnerPointer(_pointer[i], startIndex + i);
            unchecked {
                ++i;
            }
        }
    }

    function setAddressPointers(
        address[] calldata _pointer,
        uint256 startIndex
    ) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _pointer.length; ) {
            _setAddressPointer(_pointer[i], startIndex + i);
            unchecked {
                ++i;
            }
        }
    }

    function addOwnerPointer(address pointer) external onlyRole(ADMIN) {
        _pushOwnerPointer(pointer);
    }

    function addAddressPointer(address pointer) external onlyRole(ADMIN) {
        _pushAddressPointer(pointer);
    }

    function setOwnerPointer(
        address pointer,
        uint256 index
    ) external onlyRole(ADMIN) {
        _setOwnerPointer(pointer, index);
    }

    function setAddressPointer(
        address pointer,
        uint256 index
    ) external onlyRole(ADMIN) {
        _setAddressPointer(pointer, index);
    }

    function emitTramsferEvents(
        address[] calldata _address,
        uint256 startIndex
    ) external onlyRole(ADMIN) {
        _transferEvent(_address, startIndex);
    }

    // ==================================================================
    // Royalty
    // ==================================================================
    function setTokenRoyalties(
        TokenRoyaltyConfig[] calldata royaltyConfigs
    ) external override onlyRole(ADMIN) {
        _setTokenRoyalties(royaltyConfigs);
    }

    function setDefaultRoyalty(
        TokenRoyalty calldata royalty
    ) external override onlyRole(ADMIN) {
        _setDefaultRoyalty(royalty);
    }

    // ======================================================
    // ERC721
    // ======================================================
    string public baseExtension = ".json";
    string public baseURI = "https://storage.googleapis.com/cnpj-v2/json/";

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseExtension(string memory value) external onlyRole(ADMIN) {
        baseExtension = value;
    }

    function setBaseURI(string memory value) external onlyRole(ADMIN) {
        baseURI = value;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        string memory queryString = "";
        bool isBlocked_ = isBlocked(tokenId);
        bool isLocked_ = _isLocked(address(this), tokenId);
        if (isBlocked_ || isLocked_) {
            queryString = string(
                abi.encodePacked(
                    "?",
                    isBlocked_ ? "block=true" : "",
                    isBlocked_ && isLocked_ ? "&" : "",
                    isLocked_ ? "lock=true" : ""
                )
            );
        }
        return
            string(
                abi.encodePacked(
                    ERC721Psi.tokenURI(tokenId),
                    baseExtension,
                    queryString
                )
            );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override
        onlyAllowedOperator(from)
        whenNotLocked(tokenId)
        whenNotBlocked(tokenId)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override
        onlyAllowedOperator(from)
        whenNotLocked(tokenId)
        whenNotBlocked(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override
        onlyAllowedOperator(from)
        whenNotLocked(tokenId)
        whenNotBlocked(tokenId)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        require(
            _isAllowed(operator) || !approved,
            "Can not approve locked token"
        );
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        if (!_isAllowed(operator)) return false;
        return super.isApprovedForAll(account, operator);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Psi, AccessControl, EIP2981RoyaltyOverrideCore)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Psi.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
    }
}