pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFTradeValentines is ERC1155, AccessControl {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _name;
    string private _symbol;

    mapping (uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_) public ERC1155("") {
        _name = name_;
        _symbol = symbol_;
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _setupRole(MINTER_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function addMinter(address minterAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, minterAddress);
    }

    function removeMinter(address minterAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, minterAddress);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /**
     * @notice See definition of `_mint` in ERC1155 contract
     * @dev This implementation only allows admins to mint tokens
     * but can be changed as per requirement
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    /**
     * @notice See definition of `_mintBatch` in ERC1155 contract
     * @dev This implementation only allows admins to mint tokens
     * but can be changed as per requirement
     */
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }
}