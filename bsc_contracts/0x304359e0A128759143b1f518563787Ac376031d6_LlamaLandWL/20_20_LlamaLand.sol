// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "./URIStorage.sol";

contract LlamaLand is Context, ERC721Enumerable, URIStorage, AccessControl {
    using Strings for uint256;

    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");

    address public owner;
    address public admin;
    uint public serialNo;

    string _baseUri = "ipfs://";

    constructor(address _owner, address _admin) ERC721("Llama Land", "LL") {
        owner = _owner;
        admin = _admin;

        _grantRole(OWNER_ROLE, owner);
        _grantRole(ADMIN_ROLE, admin);

        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        _setRoleAdmin(MINT_ROLE, ADMIN_ROLE);
        _setRoleAdmin(UPGRADE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURN_ROLE, ADMIN_ROLE);
    }

    function mint(address to, string memory cid) onlyRole(MINT_ROLE) external {
        addUri(serialNo, cid);
        _safeMint(to, serialNo);
        serialNo++;
    }

    function upgrade(uint tokenId, string memory cid) onlyRole(UPGRADE_ROLE) external {
        updateUri(tokenId, cid);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return (
        string(abi.encodePacked(
                _baseURI(),
                getUri(tokenId)
            ))
        );
    }

    function setBaseUri(string memory uri) onlyRole(ADMIN_ROLE) external {
        _baseUri = uri;
    }

    function burn(uint tokenId) onlyRole(BURN_ROLE) external {
        _burn(tokenId);
    }

    function transferAdmin(address to) onlyRole(OWNER_ROLE) external {
        revokeRole(ADMIN_ROLE, admin);
        grantRole(ADMIN_ROLE, to);
        admin = to;
    }

    function destroy() external {
        require(_msgSender() == owner, "Caller is not the owner");
        selfdestruct(payable(owner));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}