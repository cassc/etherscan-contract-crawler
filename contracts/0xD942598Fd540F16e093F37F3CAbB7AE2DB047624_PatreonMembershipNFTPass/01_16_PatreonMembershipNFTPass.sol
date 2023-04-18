// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;


import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract PatreonMembershipNFTPass is ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable {

    string _baseTokenURI;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    address public constant prodOperatorAddress = 0xB62BcD40A24985f560b5a9745d478791d8F1945C;
    address public constant testOperatorAddress = 0x8Eb82154f314EC687957CE1e9c1A5Dc3A3234DF9;

    /* ========== CONSTRUCTOR ========== */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory _name, string memory _symbol, string memory _tokenURI) public initializer {
        __ERC721URIStorage_init();
        __AccessControl_init();
        __ERC721Enumerable_init();
        __ERC721_init(_name, _symbol);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE,ADMIN_ROLE);
        _baseTokenURI = _tokenURI;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "ReddioMintFor: must have admin role"
        );
        _baseTokenURI = baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721Upgradeable,ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyOperator() {
        require((msg.sender == prodOperatorAddress) || (msg.sender == testOperatorAddress), "only the operator contract can call mintFor");
        _;
    }

    function bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for (uint i = 0; i < b.length; i++) {
            number = number + uint(uint8(b[i])) * (2 ** (8 * (b.length - (i + 1))));
        }
        return number;
    }

    // amount for later use
    function mintFor(address player, uint256 amount, bytes calldata mintingBlob)
    public
    onlyOperator
    returns (uint256)
    {
        uint256 tokenId = bytesToUint(mintingBlob);
        _mint(player, tokenId);

        return tokenId;
    }
}