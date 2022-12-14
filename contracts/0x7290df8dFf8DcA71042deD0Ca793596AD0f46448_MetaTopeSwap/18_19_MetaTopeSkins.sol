//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MetaTopeSkins is ERC721, AccessControl, Ownable {
    bytes public uriPrestring;
    bytes public uriPoststring;
    bool public uriEditable = true;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _;
    }

    /**
     * @dev construct
     * @param _name name ot token
     * @param _symbol symbol ot token
     */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function setURI(string memory _pre, string memory _post) external onlyOwner {
        require(uriEditable, "URI no more editable");
        uriPrestring = bytes(_pre);
        uriPoststring = bytes(_post);
    }

    function disableSetURI() external onlyOwner {
        uriEditable = false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(
            "ipfs://",
            uriPrestring,
            Strings.toString(tokenId),
            uriPoststring
        ));
    }

    function mint(address to, uint256 tokenId) public virtual onlyMinter {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual onlyOwner {
        _burn(tokenId);
    }

    function safeMint(address to, uint256 tokenId) public virtual onlyMinter {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual onlyMinter {
        _safeMint(to, tokenId, data);
    }

    function setMinter(address minter) public virtual onlyOwner {
        _setupRole(MINTER_ROLE, minter);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}