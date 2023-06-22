// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract TheArmors is ERC1155, ERC2981, PaymentSplitter, Pausable, AccessControl, ERC1155Burnable, EIP712, ReentrancyGuard {
    using SafeMath for uint256;
    string private constant SIGNING_DOMAIN = "TheArmorsSign";
    string private constant SIGNATURE_VERSION = "1";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    mapping(uint256 => uint256) private _control;
    
    event Mint(address indexed to, uint256 indexed id, uint256 _value);
    
    bool private metaREVEAL = false;
    string private armorGenericMetaURI;
    string private armorIPFSMetaURI;

    struct ArmorVoucher {
        uint256 tokenId;
        uint256 minPrice;
        address to;
        bytes signature;
    }
    struct ArmorFuse {
        uint256 tokenId;
        uint256[] armorsIds;
        uint256[] amounts;
        bytes signature;
    }


    constructor(address[] memory _address, uint256[] memory _shares, string memory _ipfs) ERC1155("") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) PaymentSplitter(_address,_shares) payable {

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _setDefaultRoyalty(msg.sender, 500);
   
        armorGenericMetaURI = "ipfs://QmW61jF4MDwMRVUqLTbQk5V3tdVUXSxPkVtx11bfiS2F6z";
        armorIPFSMetaURI = _ipfs;
    }

    function contractURI() public pure returns (string memory) {
        return "https://thearmors.io/assets/contract.json";
    }

    function uri(uint256 tokenId) override public view returns (string memory) {

        if (!metaREVEAL)
            return armorGenericMetaURI;

        return(string(abi.encodePacked(armorIPFSMetaURI, Strings.toString(tokenId),".json")));
    }

    function setGenericMeta(string memory sampleURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        armorGenericMetaURI = sampleURI;
    }

    function setMetaReveal(bool _reveal) public onlyRole(DEFAULT_ADMIN_ROLE) {
        metaREVEAL = _reveal;
    }

    function getArmor(ArmorVoucher calldata voucher) public whenNotPaused nonReentrant payable
    {
        address signer = _verify(voucher);
        require(hasRole(MINTER_ROLE, signer), "Not authorized to mint");
        require(msg.value >= voucher.minPrice, "Value below price");
        require(_control[voucher.tokenId] == 0, "already minted");
        _mint(voucher.to, voucher.tokenId, 1, "");
        _control[voucher.tokenId] = voucher.tokenId;
        emit Mint(voucher.to, voucher.tokenId, msg.value);
    }

    function fuseArmors(ArmorFuse calldata toFuse) public whenNotPaused nonReentrant
    {
        address signer = _verify(toFuse);
        require(toFuse.armorsIds.length == 2, "require 2 armors");
        require(hasRole(MINTER_ROLE, signer), "Not authorized to fuse");
        require(_control[toFuse.tokenId] == 0, "already minted");
        address wallet = _msgSender();
        _burnBatch(wallet, toFuse.armorsIds, toFuse.amounts);
        _mint(wallet, toFuse.tokenId, 1, "");
        _control[toFuse.tokenId] = toFuse.tokenId;
    }

    function _verify(ArmorFuse calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _hash(ArmorFuse calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("ArmorToFuse(uint256 tokenId,uint256[] armorsIds,uint256[] amounts)"),
            voucher.tokenId,
            keccak256(abi.encodePacked(voucher.armorsIds)),
            keccak256(abi.encodePacked(voucher.amounts))
        )));
    }
    
    function _verify(ArmorVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _hash(ArmorVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("ArmorVoucher(uint256 tokenId,uint256 minPrice,address to)"),
            voucher.tokenId,
            voucher.minPrice,
            voucher.to
        )));
    }

    function deleteDefaultRoyalty() public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _deleteDefaultRoyalty();
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _resetTokenRoyalty(tokenId);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}