pragma solidity ^0.8.0;

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ERC1155CollectionBase.sol";

contract Parts is ERC1155, ERC1155CollectionBase {
    
    uint TOKEN_ID_TO_ASSIGN = 0;
    bytes32 immutable public merkleRoot;
    bool IS_PUBLIC_SALE_ACTIVE = false;
    address[] private whitelist;
    
    constructor(address signingAddress_, bytes32 _merkleRoot) ERC1155('') {
        merkleRoot = _merkleRoot;
        _initialize(
            // total supply
            14000,
            // total supply available to purchase
            14000,
            // 0.01 eth public sale price
            0,
            // purchase limit (0 for no limit)
            0,
            // transaction limit (0 for no limit)
            0,
            // 0.01 eth presale price
            0,
            // presale limit (unused but 0 for no limit)
            0,
            signingAddress_,
            // use dynamic presale purchase limit
            true
        );
    }

    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155CollectionBase) returns (bool) {
      return ERC1155CollectionBase.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155Collection-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return ERC1155.balanceOf(owner, TOKEN_ID);
    }

    /**
     * @dev See {IERC1155Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function purchase(bytes32[] calldata merkleProof) public {
        _purchase();
    }

    /**
     * @dev See {IERC1155Collection-activate}.
     */
    function activate() override external adminRequired {
        _activate();
    }

    function setPublicSale(bool isActive) external adminRequired {
        IS_PUBLIC_SALE_ACTIVE = isActive;
    }
    function deActivate() external adminRequired {
        _deActivate();
        IS_PUBLIC_SALE_ACTIVE = false;
    }
    /**
     * @dev See {IERC1155Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC1155Collection-setCollectionURI}.
     */
    function setCollectionURI(string calldata uri) external override adminRequired {
        _setURI(uri);
    }

    /**
     * @dev See {ERC1155CollectionBase-_mint}.
     */
    function _mintERC1155(address to, uint16 amount) internal virtual override {
        ERC1155._mint(to, TOKEN_ID, amount, "");
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address, address , address, uint256[] memory, uint256[] memory, bytes memory) internal virtual override {
        _validateTokenTransferability();
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
      _updateRoyalties(recipient, bps);
    }
}