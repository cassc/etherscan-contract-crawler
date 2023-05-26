// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
* @author Karl
*/
contract DCCShopItem is ERC1155, AccessControlEnumerable, Ownable2Step {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private baseURI = "";

    /* ====== EVENTS ======= */

    event Burn(address indexed sender, bytes32 indexed to, uint256 id, uint256 amount);

    /* ====== CONSTRUCTOR ====== */

    constructor() ERC1155(baseURI) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /* ====== PUBLIC FUNCTIONS (onlyRole) ====== */

    function mintBatch(address _user, uint256[] memory _tokenIds, uint256[] memory _quantities) external onlyRole(MINTER_ROLE) {
        _mintBatch(_user, _tokenIds, _quantities, "");
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    function burnBatch(uint256[] memory _tokenIds, uint256[] memory _quantities, bytes32 _to) external {
        _burnBatch(_msgSender(), _tokenIds, _quantities);

        for (uint i = 0; i < _tokenIds.length; i++) {
            if (_quantities[i] > 0) {
                emit Burn(_msgSender(), _to, _tokenIds[i], _quantities[i]);
            }
        }
    }

    /* ====== VIEW FUNCTIONS ====== */

    function uri(uint256 _id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_id)));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC1155) returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId ||
        interfaceId == type(IERC1155).interfaceId ||
        interfaceId == type(IERC1155MetadataURI).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /* ====== ADMIN FUNCTIONS ====== */

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
}