pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Xy3Nft is ERC721, AccessControl {
    using Strings for uint256;

    
    struct Ticket {
        uint256 loanId;
        address minter;
    }

    
    string public baseURI;

    
    mapping(uint256 => Ticket) public tickets;

    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    
    constructor(
        address _admin,
        string memory _name,
        string memory _symbol,
        string memory _customBaseURI
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setBaseURI(_customBaseURI);
    }

    
    function burn(uint256 _tokenId) external onlyRole(MINTER_ROLE) {
        delete tickets[_tokenId];
        _burn(_tokenId);
    }

    
    function mint(
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external onlyRole(MINTER_ROLE) {
        require(_data.length > 0, "no data");

        uint256 loanId = abi.decode(_data, (uint256));
        tickets[_tokenId] = Ticket({loanId: loanId, minter: msg.sender});
        _safeMint(_to, _tokenId, _data);
    }

    
    function setBaseURI(string memory _customBaseURI)
        external
        onlyRole(MANAGER_ROLE)
    {
        _setBaseURI(_customBaseURI);
    }

    
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool) 
    {
        return super.supportsInterface(_interfaceId);
    }

    
    function exists(uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _exists(_tokenId);
    }

    
    function _getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseURI;
    }

    
    function _setBaseURI(string memory _customBaseURI) internal virtual {
        baseURI = bytes(_customBaseURI).length > 0
            ? string(abi.encodePacked(_customBaseURI, _getChainID().toString(), "/"))
            : "";
    }
}