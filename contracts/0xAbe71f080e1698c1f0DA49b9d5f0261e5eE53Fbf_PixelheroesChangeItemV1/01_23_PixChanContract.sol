// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/[email protected]/access/AccessControlUpgradeable.sol";
import "@openzeppelin/[email protected]/security/PausableUpgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/[email protected]/proxy/utils/Initializable.sol";
import "@openzeppelin/[email protected]/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/[email protected]/security/ReentrancyGuardUpgradeable.sol";

/// @custom:security-contact [email protected]
contract PixelheroesChangeItemV1 is Initializable, ERC1155Upgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;

    string public name;
    string public symbol;
    mapping(uint256 => uint256) public mintPrices;

    string private _baseTokenURI;
    address payable private _recipient;
    mapping(uint256 => mapping(address => uint256)) private _mintCountsByAccountByTokenId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) initializer public {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(DEFAULT_ADMIN_ROLE, 0xAa4dD68dC9D319717e6Eb8b3D08EABF6677cAFDb);
        _grantRole(DEFAULT_ADMIN_ROLE, 0x7ec15Ea1b148bBC30184175F05D44D74B2C61ae2);

        name = _name;
        symbol = _symbol;
        setURI(_baseURI);
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = newuri;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function ownerMint(address account, uint256 id, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mint(account, id, amount, "");
    }

    function ownerMintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mintBatch(to, ids, amounts, "");
    }

    function mint(address account, uint256 tokenId, uint256 amount)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 mintCountsOfMsgSender = _mintCountsByAccountByTokenId[tokenId][msg.sender];
        require(mintCountsOfMsgSender > 0, "No eligibility requirements");
        require(mintCountsOfMsgSender >= amount, "Number of purchases has been exceeded");
        require(msg.value == mintPrices[tokenId] * amount, "Value sent is not correct");
        
        _mint(account, tokenId, amount, "");

        _mintCountsByAccountByTokenId[tokenId][msg.sender] = mintCountsOfMsgSender - amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "nonexistent token");
        return string(abi.encodePacked(currentBaseURI(), tokenId.toString(), ".json"));
    }

    function setPrice(uint256 tokenId, uint256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(exists(tokenId), "nonexistent token");
        mintPrices[tokenId] = newPrice;
    }

    function setMintCountsByAccountByTokenId(uint256 tokenId, address account, uint256 mintCount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(exists(tokenId), "nonexistent token");
        _mintCountsByAccountByTokenId[tokenId][account] = mintCount;
    }

    function batchSetMintCountsByAccountByTokenId(uint256 tokenId, address[] memory accounts, uint256[] memory mintCounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(exists(tokenId), "nonexistent token");
        require(accounts.length == mintCounts.length, "invalid array");
        for(uint ix = 0; ix < accounts.length; ix++) {
            _mintCountsByAccountByTokenId[tokenId][accounts[ix]] = mintCounts[ix];
        }
    }

    function getMintCountsByAccountByTokenId(uint256 tokenId, address account) external view returns(uint256) {
        require(exists(tokenId), "nonexistent token");
        return _mintCountsByAccountByTokenId[tokenId][account] == 0 ? 0 : _mintCountsByAccountByTokenId[tokenId][account];
    }

    function setAdminRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_recipient != address(0), "withdraw: Invalid address");
        uint256 sendAmount = address(this).balance;

        bool success;

        (success, ) = payable(_recipient).call{value: sendAmount}("");
        require(success, "Failed to withdraw");
   }

    function setRecipient(address payable account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "setRecipient: Invalid address");
        _recipient = account;
    }

    function currentBaseURI() private view returns (string memory){
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(DEFAULT_ADMIN_ROLE)
        override
    {}
}