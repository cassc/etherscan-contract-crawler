// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {IContractAllowListProxy} from "ContractAllowList/proxy/interface/IContractAllowListProxy.sol";
import {BitMaps} from "solidity-bits/contracts/BitMaps.sol";
import {SS2ERC721PsiBurnable,ERC721Psi} from './SS2ERC721PsiBurnable.sol';
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {UseLocker} from "./Locker/UseLocker.sol";

contract CryptoNinjaPartners is
    SS2ERC721PsiBurnable,
    DefaultOperatorFilterer,
    Ownable,
    ERC2981,
    AccessControl,
    UseLocker
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using BitMaps for BitMaps.BitMap;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256('CONFIGURATOR_ROLE');
    string public constant BASE_EXTENSION = ".json";

    address public constant WITHDRAW_ADDRESS = 0x0a2C099044c088A431b78a0D6Bb5A137a5663297;
    string public baseURI = "https://data.cryptoninjapartners.com/new/json/";
    IContractAllowListProxy public cal;
    uint256 public calLevel = 1;
    bool public enableRestrict = true;

    BitMaps.BitMap internal _blockedToken;

    EnumerableSet.AddressSet private localAllowedAddresses;
    address[] private pointers;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), "Caller is not a burner");
        _;
    }
    modifier onlyConfigrator() {
        require(hasRole(CONFIGURATOR_ROLE, _msgSender()), "Caller is not a configrator");
        _;
    }

    constructor() SS2ERC721PsiBurnable("CryptoNinjaPartners", "CNP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(CONFIGURATOR_ROLE, msg.sender);
        _setDefaultRoyalty(WITHDRAW_ADDRESS, 1000);
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _isAllowed(address transferer) internal view virtual returns (bool) {
        if (!enableRestrict) return true;

        return localAllowedAddresses.contains(transferer) || cal.isAllowed(transferer, calLevel);
    }

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256
    ) internal virtual override {
        require(!_blockedToken.get(startTokenId),'This token ID has been blocked.');
    }

    //external
    function getBlockedToken(uint256 tokenId) external view virtual returns(bool){
        return _blockedToken.get(tokenId);
    }

    function getLocalContractAllowList() external view returns (address[] memory) {
        return localAllowedAddresses.values();
    }
    
    // external (only minter)
    function minterMint(address _address, uint256 _amount) external onlyMinter {
        _safeMint(_address, _amount);
    }

    // external (only burner)
    function burnerBurn(address _address, uint256[] calldata tokenIds) external onlyBurner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_address == ownerOf(tokenId), "address is not owner");

            _burn(tokenId);
        }
    }

    // public (only configrator)
    function setBlockedTokens(uint256[] calldata tokenIds) external onlyConfigrator{
        for (uint256 i = 0; i < tokenIds.length;) {
            _blockedToken.set(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function unsetBlockedTokens(uint256[] calldata tokenIds) external onlyConfigrator{
        for (uint256 i = 0; i < tokenIds.length;) {
            _blockedToken.unset(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setAddressData(address _address,AddressData calldata _addressData) external onlyConfigrator {
        _setAddressData(_address,_addressData);
    }

    function setAddressDatas(address[] calldata _address,AddressData[] calldata _addressData) external onlyConfigrator {
        for (uint256 i = 0; i < _address.length;) {
            _setAddressData(_address[i],_addressData[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setOwnerPointers(address[] calldata _pointer,uint256 startIndex) external onlyConfigrator {
        for (uint256 i = startIndex; i < _pointer.length;) {
            _pushOwnerPointer(_pointer[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setAddressPointers(address[] calldata _pointer,uint256 startIndex) external onlyConfigrator {
        for (uint256 i = startIndex; i < _pointer.length;) {
            _pushAddressPointer(_pointer[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setOwnerPointer(address pointer,uint256 index) external onlyConfigrator {
        _setOwnerPointer(pointer,index);
    }

    function setAddressPointer(address pointer,uint256 index) external onlyConfigrator {
        _setAddressPointer(pointer,index);
    }

    function emitTramsferEvents(address[] calldata _address,uint256 startIndex) external onlyConfigrator {
        _transferEvent(_address,startIndex);
    }

    function setLocker(address value) external override onlyConfigrator {
        _setLocker(value);
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

    // public (only owner)
    function ownerMint(address to, uint256 count) public onlyOwner {
        _safeMint(to, count);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(WITHDRAW_ADDRESS).call{value: address(this).balance}("");
        require(os, "withdraw error");
    }
    //public
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(ERC721Psi.tokenURI(tokenId), BASE_EXTENSION));
    }

    function approve(address to, uint256 tokenId) public virtual override whenNotLocked(tokenId) {
        super.approve(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Psi) onlyAllowedOperator(from) whenNotLocked(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Psi) onlyAllowedOperator(from) whenNotLocked(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Psi) onlyAllowedOperator(from) whenNotLocked(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Psi, AccessControl, ERC2981)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Psi.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(
            _isAllowed(operator) || !approved,
            "Can not approve locked token"
         );
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if (!_isAllowed(operator)) return false;
        return super.isApprovedForAll(account, operator);
    }
}