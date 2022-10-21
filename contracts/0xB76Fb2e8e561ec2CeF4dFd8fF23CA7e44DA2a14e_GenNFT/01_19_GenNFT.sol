// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

contract GenNFT is
    ERC1155SupplyUpgradeable,
    ERC1155URIStorageUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC2981Upgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a

    string public name;
    string public contractURI;

    address private _owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner_,
        address royaltyAccount,
        uint96 royaltyValue, // in basis points: 10000 -> 100%
        string calldata contractUri
    ) public initializer {
        __ERC1155_init("");
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC2981_init();

        require(owner_ != address(0), "Null owner account address");
        require(royaltyAccount != address(0), "Null royalty account address");
        require(royaltyValue <= 10000, "Royalty value too high");

        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _grantRole(MINTER_ROLE, owner_);
        _grantRole(PAUSER_ROLE, owner_);

        _setDefaultRoyalty(royaltyAccount, royaltyValue);

        name = "Genesis NFT";
        contractURI = contractUri;
    }

    function setTokenURI(uint256 id, string calldata tokenUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(id, tokenUri);
    }

    function setContractURI(string calldata contractUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = contractUri;
    }

    function setOwner(address owner_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _owner = owner_;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string memory tokenURI
    ) external onlyRole(MINTER_ROLE) {
        require(amount > 0, "Invalid minting token amount");

        if (totalSupply(id) == 0) {
            _setURI(id, tokenURI);
        }
        _mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] memory tokenURIs
    ) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i] > 0, "Invalid token amount to mint");
            uint256 id = ids[i];
            if (totalSupply(id) == 0) {
                _setURI(id, tokenURIs[i]);
            }
        }
        _mintBatch(to, ids, amounts, "");
    }

    function owner() public view returns(address) {
        return _owner;
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC1155URIStorageUpgradeable.uri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    uint256[47] private __gap;
}