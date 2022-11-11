pragma solidity ^0.8.13;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../registry/IRegistryConsumer.sol";

contract LaunchKey is ERC721Enumerable, AccessControlEnumerable {
    using Strings for uint256;

    bytes32 constant public MASTER_REGISTRY = keccak256("MASTER_REGISTRY");
    bytes32 constant public MINTER_ROLE     = keccak256("MINTER_ROLE");
    bytes32 constant public CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");

    string                      _name;
    string                      _symbol;
    string               public baseURI;
    string               public usedURI;
    bool                 public isInitialised;
    RegistryConsumer            reg = RegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
    uint16                      community_id;

    bool                 public useIndex;

    event IndexChanged(bool _useIndex);
    event NameChanged(string newName);
    event SymbolChanged(string newSymbol);
    event BaseURIChanged(string uri);
    event UsedURIChanged(string uri);


    constructor(string memory name_,string memory symbol_) ERC721(name_,symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN, msg.sender);
    }

    function mint(address owner, uint256 tokenId) external  onlyRole(MINTER_ROLE) {
        _mint(owner,tokenId);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function burn(uint16 tokenID) external onlyRole(MASTER_REGISTRY) {
        _burn(uint256(tokenID));
    }

    function setBaseURI(string calldata _uri) external onlyRole(CONTRACT_ADMIN) {
        baseURI = _uri;
        emit BaseURIChanged(_uri);
    }

    function setUsedURI(string calldata _uri) external onlyRole(CONTRACT_ADMIN) {
        usedURI = _uri;
        emit UsedURIChanged(_uri);
    }

   function setName(string calldata _uri) external onlyRole(CONTRACT_ADMIN) {
        _name = _uri;
        emit NameChanged(_uri);
    }
   function setSymbol(string calldata _uri) external onlyRole(CONTRACT_ADMIN) {
        _symbol = _uri;
        emit SymbolChanged(_uri);
    }

    function setIndexed(bool _useIndex) external onlyRole(CONTRACT_ADMIN) {
       useIndex = _useIndex;
       emit IndexChanged(_useIndex);
    }


   function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI_plain(uint256 _tokenId) internal view  returns (string memory) {
        require(_exists(_tokenId) , 'Token: Token does not exist');
        if (
            ownerOf(_tokenId) == reg.getRegistryAddress("MASTER_REGISTRY") &&
            bytes(usedURI).length > 0
        ) {
            return usedURI;
        }        
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
        if (useIndex) return tokenURI_indexed(_tokenId);
        return tokenURI_plain( _tokenId);

    }

    function tokenURI_indexed(uint256 _tokenId) internal view  returns (string memory) {
        require(_exists(_tokenId) , 'Token: Token does not exist');
    
        string memory folder = (_tokenId % 100).toString(); 
        string memory file = _tokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(baseURI, folder, slash, file));
    }

    function isApprovedForAll(address owner, address operator) public view override( IERC721,ERC721 ) returns(bool) {
        return (super.isApprovedForAll(owner,operator) || (reg.getRegistryAddress("MASTER_REGISTRY") == operator));
    }



}