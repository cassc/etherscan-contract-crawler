// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/draft-ERC721VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AMBToken is Initializable,AccessControlUpgradeable,ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINTER_ADMIN = keccak256("MINTER_ADMIN");


    using StringsUpgradeable for uint256;

    error TokenIsSoulbound();

    string public baseURI;
    
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("AMBToken", "AMB");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _setupRole(MINTER_ROLE,msg.sender);
        _setupRole(MINTER_ADMIN,msg.sender);
        _setRoleAdmin(MINTER_ROLE,MINTER_ADMIN);
        baseURI = "https://raw.githubusercontent.com/NutiDAODEV1/NutsDAO_AMB/main/AMB_";
    }


    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    
    // 1 to 1 bound
    function safeMint() public {
      require(hasRole(MINTER_ROLE, msg.sender), "Unauthorized to mint");

        uint256 tokenId = _tokenIdCounter.current();

        require(balanceOf(msg.sender) == 0, "Not reclaimable");
    
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }


    function onlySoulbound(address from, address to) internal pure {
        // Revert if transfers are not from the 0 address and not to the 0 address
        if (from != address(0) && to != address(0)) {
            revert TokenIsSoulbound();
        }
    }



    function transferFrom(address from, address to, uint256 id) public override {
        onlySoulbound(from, to);
        super.transferFrom(from, to, id);
    }


    // The following two functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }


    // function tokenURI(uint256 tokenId)
    //     public
    //     view
    //     override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    //     returns (string memory)
    // {
    //     return super.tokenURI(tokenId);
    // }


    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }


    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner{

        _setTokenURI(tokenId, _tokenURI);
    }

    
    function burn(uint256 tokenId)
        public onlyOwner{
        _burn(tokenId);
        }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
  

        function tokenURI(uint256 tokenId)
        public view virtual 
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        _requireMinted(tokenId);
        string memory tokenBaseURI = _baseURI();
        string memory tokenJon = string(abi.encodePacked(tokenId.toString(),".json"));
        return bytes(tokenBaseURI).length > 0 ? string(abi.encodePacked(tokenBaseURI, tokenJon)) : "";
    }


    function grantMinterRole(address account) public virtual onlyRole(getRoleAdmin(MINTER_ROLE)){
        
    _grantRole(MINTER_ROLE, account);
    }


    function revokeMinterRole(address account) public virtual onlyRole(getRoleAdmin(MINTER_ROLE)){
        
    _revokeRole(MINTER_ROLE, account);
    }


    // function grantSSR(address account) public virtual onlyOwner{

    // _grantRole(MINTER_ADMIN, account);
    // }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControlUpgradeable, ERC721Upgradeable) returns (bool) {
    return ERC721Upgradeable.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
  }

}