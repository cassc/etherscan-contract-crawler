// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../Signable.sol";
import "../royalties/ContractRoyalties.sol";

// Version: ReservedToken-1.0
// Investigate gas savings in ERC721Enumerable
contract QuantumMemoriesNoise is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    ContractRoyalties,
    AccessControlEnumerable
{
    // OpenSea metadata freeze
    event PermanentURI(string _value, uint256 indexed _id);

    address payable private immutable royaltyReceiver;
    uint256 private immutable royaltyBPS;

    string private _baseURIextended;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINTER_ROLE_ADMIN = keccak256("MINTER_ROLE_ADMIN");

    constructor(
        string memory baseURI,
        string memory contractName,
        string memory tokenSymbol,
        address artist,
        address payable royaltyReceiver_,
        uint256 royaltyBPS_
    ) ERC721(contractName, tokenSymbol) {
        require(royaltyBPS_ >= 0, "Royalties cannot be lower than 0");
        _baseURIextended = baseURI;

        /**
         * @dev Minter admin is set as the artist meaning they have rights over the minter role
         * The minter admin role can be updated by the default admin only
         */
        _setupRole(DEFAULT_ADMIN_ROLE, artist);
        _setupRole(MINTER_ROLE, artist);
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE_ADMIN);
        _setupRole(MINTER_ROLE_ADMIN, artist);

        royaltyReceiver = royaltyReceiver_;
        royaltyBPS = royaltyBPS_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * Required to allow the artist to administrate the contract on OpenSea.
     * Note if there are many addresses with the DEFAULT_ADMIN_ROLE, the one which is returned may be arbitrary.
     */
    function owner() public view virtual returns (address) {
        return _getPrimaryAdmin();
    }

    function _getPrimaryAdmin() internal view virtual returns (address) {
        if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0) {
            return address(0);
        }
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
     * @dev Throws if called by any account other than an approved minter.
     */
    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Restricted to approved minters"
        );
        _;
    }

    function mint(address to, uint256 tokenId) public onlyMinter {
        _mintSingle(to, tokenId);
    }

    function mintBatch(address to, uint256[] memory tokenIds)
        public
        onlyMinter
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mintSingle(to, tokenIds[i]);
        }
    }

    function _mintSingle(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function _getBps()
        internal
        view
        virtual
        override(ContractRoyalties)
        returns (uint256)
    {
        return royaltyBPS;
    }

    function _getReceiver()
        internal
        view
        virtual
        override(ContractRoyalties)
        returns (address payable)
    {
        return royaltyReceiver;
    }

    function _existsRoyalties(uint256 tokenId)
        internal
        view
        virtual
        override(ContractRoyalties)
        returns (bool)
    {
        return super._exists(tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            _supportsRoyaltyInterfaces(interfaceId);
    }
}