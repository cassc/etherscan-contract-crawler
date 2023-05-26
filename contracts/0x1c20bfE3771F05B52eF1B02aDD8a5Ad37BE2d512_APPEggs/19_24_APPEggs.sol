// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./interface/IAPPEggs.sol";
import "./interface/IERC721Pass.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol";
import "default-nft-contract/contracts/libs/TokenSupplier/TokenUriSupplier.sol";
import "contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol";

contract APPEggs is
    IAPPEggs,
    ERC1155,
    AccessControl,
    Ownable,
    TokenUriSupplier,
    EIP2981RoyaltyOverrideCore
{
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ADMIN = keccak256('ADMIN');
    bytes32 public constant MINTER = keccak256('MINTER');
    bytes32 public constant BURNER = keccak256('BURNER');
    string public name = "PANDA NO MOTO";
    string public symbol = "PNM";

    IContractAllowListProxy public cal;
    EnumerableSet.AddressSet localAllowedAddresses;
    uint256 public calLevel = 1;
    bool public enableRestrict = true;

    IERC721Pass public enjoyPassport;

    constructor() ERC1155("") {
        // default royalty set
        _setDefaultRoyalty(
            IEIP2981RoyaltyOverride.TokenRoyalty({bps: 1000, recipient: 0x62314D5A0F7CBed83Df49C53B9f2C687d2c18289})
        );
        _grantRole(ADMIN, msg.sender);
        _grantRole(MINTER, msg.sender);
        _grantRole(BURNER, msg.sender);
        // _mint(msg.sender, 1, 1, "");
    }

    // ==================================================================
    // external contract
    // ==================================================================
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external override onlyRole(MINTER) {
        _mint(to, id, amount, "");
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external override onlyRole(BURNER) {
        _burn(from, id, amount);
    }

    // ==================================================================
    // interface
    // ==================================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl, EIP2981RoyaltyOverrideCore)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId) ||
            EIP2981RoyaltyOverrideCore.supportsInterface(interfaceId);
    }

    // ==================================================================
    // override TokenUriSupplier
    // ==================================================================
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return TokenUriSupplier.tokenURI(tokenId);
    }

    function setBaseURI(string memory _value)
        external
        override
        onlyRole(ADMIN)
    {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value)
        external
        override
        onlyRole(ADMIN)
    {
        baseExtension = _value;
    }

    function setExternalSupplier(address _value)
        external
        override
        onlyRole(ADMIN)
    {
        externalSupplier = ITokenUriSupplier(_value);
    }

    // ==================================================================
    // Royalty
    // ==================================================================
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs)
        external
        override
        onlyRole(ADMIN)
    {
        _setTokenRoyalties(royaltyConfigs);
    }

    function setDefaultRoyalty(TokenRoyalty calldata royalty)
        external
        override
        onlyRole(ADMIN)
    {
        _setDefaultRoyalty(royalty);
    }

    // ==================================================================
    // Ristrict Approve
    // ==================================================================
    function addLocalContractAllowList(address transferer)
        external
        onlyRole(ADMIN)
    {
        localAllowedAddresses.add(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        external
        onlyRole(ADMIN)
    {
        localAllowedAddresses.remove(transferer);
    }

    function getLocalContractAllowList()
        external
        view
        returns (address[] memory)
    {
        return localAllowedAddresses.values();
    }

    function _isLocalAllowed(address transferer)
        internal
        view
        virtual
        returns (bool)
    {
        return localAllowedAddresses.contains(transferer);
    }

    function _isAllowed(address transferer)
        internal
        view
        virtual
        returns (bool)
    {
        if(enableRestrict == false) {
            return true;
        }

        return
            _isLocalAllowed(transferer) || cal.isAllowed(transferer, calLevel);
    }

    function setCAL(address value) external onlyRole(ADMIN) {
        cal = IContractAllowListProxy(value);
    }

    function setCALLevel(uint256 value) external onlyRole(ADMIN) {
        calLevel = value;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _isAllowed(operator) || approved == false,
            "RestrictApprove: Can not approve locked token"
        );
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (_isAllowed(operator) == false) {
            return false;
        }
        return super.isApprovedForAll(account, operator);
    }

    function setEnableRestrict(bool value) external onlyRole(ADMIN) {
        enableRestrict = value;
    }

    // ==================================================================
    // override AccessControl
    // ==================================================================
    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(ADMIN)
    {
        require(role != ADMIN, "not admin only.");
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(ADMIN)
    {
        require(role != ADMIN, "not admin only.");
        _revokeRole(role, account);
    }

    function grantAdmin(address account) external onlyOwner {
        _grantRole(ADMIN, account);
    }

    function revokeAdmin(address account) external onlyOwner {
        _revokeRole(ADMIN, account);
    }

    // ==================================================================
    // override ERC-1155
    // ==================================================================
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override{
        if( from != address(0)){
            if(enjoyPassport.balanceOf(from) > 0){
                enjoyPassport.refreshMetadata(enjoyPassport.tokenOfOwner(from));
            }
        }
        
        if( to != address(0)){
            if(enjoyPassport.balanceOf(to) > 0){
                enjoyPassport.refreshMetadata(enjoyPassport.tokenOfOwner(to));
            }
        }
        
        super._afterTokenTransfer(operator,from,to,ids,amounts,data);
    }

    // ==================================================================
    // onlyAdmin Setting
    // ==================================================================
    function setEnjoyPassport(IERC721Pass _enjoyPassport) external onlyRole(ADMIN) {
        enjoyPassport = _enjoyPassport;
    }
}