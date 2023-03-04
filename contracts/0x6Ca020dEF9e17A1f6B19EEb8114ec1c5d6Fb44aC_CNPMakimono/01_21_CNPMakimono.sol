// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@manifoldxyz/royalty-registry-solidity/contracts/overrides/RoyaltyOverrideCore.sol';
import 'contract-allow-list/contracts/proxy/interface/IContractAllowListProxy.sol';
import './interface/ICNPMakimono.sol';

contract CNPMakimono is ICNPMakimono, ERC1155Supply, Ownable, AccessControl, EIP2981RoyaltyOverrideCore {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;
    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

    string public constant baseExtension = '.json';
    string public constant name = 'CNP Makimono';
    string public constant symbol = 'CNPM';

    string public baseURI = 'https://data.syou-nft.com/cnpm/json/';

    IContractAllowListProxy public cal;
    EnumerableSet.AddressSet localAllowedAddresses;
    uint256 public calLevel = 1;
    bool public enableRestrict = true;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), 'Caller is not a minter');
        _;
    }
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), 'Caller is not a burner');
        _;
    }

    constructor() ERC1155('') {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        cal = IContractAllowListProxy(0xdbaa28cBe70aF04EbFB166b1A3E8F8034e5B9FC7);
        _setDefaultRoyalty(TokenRoyalty({recipient: 0x0a2C099044c088A431b78a0D6Bb5A137a5663297, bps: 1000}));
        _mint(0x0a2C099044c088A431b78a0D6Bb5A137a5663297, 1, 500, '');
    }

    // public
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

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

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_isAllowed(operator) || !approved, 'RestrictApprove: Can not approve locked token');
        super.setApprovalForAll(operator, approved);
    }

    function getLocalContractAllowList() external view returns (address[] memory) {
        return localAllowedAddresses.values();
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if (!_isAllowed(operator)) return false;
        return super.isApprovedForAll(account, operator);
    }

    function _isAllowed(address transferer) internal view virtual returns (bool) {
        if (!enableRestrict) return true;

        return localAllowedAddresses.contains(transferer) || cal.isAllowed(transferer, calLevel);
    }

    // external (only minter)
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    // external (only burner)
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override onlyRole(BURNER_ROLE) {
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override onlyRole(BURNER_ROLE) {
        _burnBatch(account, ids, values);
    }

    // public (only owner)
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw(address withdrawAddress) external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royaltyConfigs) external override onlyOwner {
        _setTokenRoyalties(royaltyConfigs);
    }

    function setDefaultRoyalty(TokenRoyalty calldata royalty) external override onlyOwner {
        _setDefaultRoyalty(royalty);
    }

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

    function setEnableRestrict(bool value) external onlyOwner {
        enableRestrict = value;
    }
}