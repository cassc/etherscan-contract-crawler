pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract LazyComics is ERC1155Burnable, ERC1155Supply, Ownable, AccessControl {
    using Strings for uint256;
    bytes32 public constant drop_manager = keccak256("drop_manager");

    constructor() ERC1155('ipfs://QmaBK7t9zvoN6cx8jkckbSHEz5RK42dQVz5VCc6vZrVukz/') {
        _setupRole(0x00, msg.sender);
        _setRoleAdmin(drop_manager, DEFAULT_ADMIN_ROLE);
        // _setupRole(drop_manager, )
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply){
        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function set_drop_manager(address _manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(drop_manager, _manager);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl)
        returns (bool) 
    {
        return 
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId || 
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public onlyRole(drop_manager) returns (bool) {
        _mint(_to, _id, _amount, _data);
        return true;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri(
        uint256 _id
    ) public view virtual override(ERC1155) returns (string memory) {
        require(exists(_id), "Nonexistent Token");
        return string(abi.encodePacked(super.uri(0), _id.toString()));
    }

}