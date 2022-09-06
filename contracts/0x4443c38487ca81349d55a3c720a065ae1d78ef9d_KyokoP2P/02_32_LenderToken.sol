// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

/**
 * @dev The lender's certificate
 */
contract LenderToken is
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // this role will only be granted to the KyokoP2P contract 
    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");
    // this role will granted to the default LToken manager
    bytes32 public constant ROLE_LTOKEN_MANAGER = keccak256("ROLE_LTOKEN_MANAGER");

    CountersUpgradeable.Counter private _tokenIds;
    string private _baseURIextended;


    event SetBaseURI(string baseURI_);

    event Mint(address indexed player);


    modifier onlyMinter() {
        require(
            hasRole(ROLE_MINTER, _msgSender()),
            "only the kyokoP2P contract has permission to perform this operation."
        );
        _;
    }

    modifier onlyLTokenManager() {
        require(
            hasRole(ROLE_LTOKEN_MANAGER, _msgSender()),
            "only the LToken manager has permission to perform this operation."
        );
        _;
    }    

    // constructor() ERC721("KyokoLToken", "KL") {}
    function initialize() public initializer {
        __ERC721_init("KyokoLToken", "KL");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __Context_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ROLE_LTOKEN_MANAGER, _msgSender());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function setBaseURI(string memory baseURI_) external onlyLTokenManager {
        _baseURIextended = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function mint(address player) public onlyMinter returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        emit Mint(player);
        return newItemId;
    }

    function burn(uint256 tokenId)
        public
        virtual
        override(ERC721BurnableUpgradeable)
    {
        super._burn(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}