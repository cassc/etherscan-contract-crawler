// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ERC998TopDown.sol";
import "./IItem.sol";

/// @title Hero
/// @notice Hero is a composable NFT designed to equip other ERC1155 tokens
contract Hero is ERC721Enumerable, ERC998TopDown, Ownable, EIP712, IERC2981 {
  using ERC165Checker for address;

  struct MintVoucher {
    uint256 price;
    address wallet;
    bytes signature;
  }

  struct BulkChangeVoucher {
    uint256 tokenId;
    address itemContractAddress;
    uint256[] itemsToEquip;
    uint256[] amountsToEquip;
    uint256[] slotsToEquip;
    uint256[] itemsToUnequip;
    uint256[] amountsToUnequip;
    bytes signature;
  }

  struct Item {
    address itemAddress;
    uint256 id;
  }

  event BulkChanges(
    uint256 tokenId,
    uint256[] itemsToEquip,
    uint256[] amountsToEquip,
    uint256[] slotsToEquip,
    uint256[] itemsToUnequip,
    uint256[] amountsToUnequip,
    address heroOwner
  );

  event ItemsClaimed(uint256 tokenId);

  bytes4 internal constant ERC_1155_INTERFACE = 0xd9b67a26;

  mapping(address => bool) private _allowedMinters;

  string private constant SIGNING_DOMAIN = "Hero";
  string private constant SIGNATURE_VERSION = "1";

  address public primarySalesReceiver;
  address public royaltyReceiver;
  uint8 public royaltyPercentage;
  string private baseUri;
  uint256 public maxSupply;

  string private _contractURI;
  using Counters for Counters.Counter;
  Counters.Counter private _heroCounter;
  mapping(address => uint256) private mintNonce;
  mapping(uint256 => uint256) private claimNonce;
  string public provenanceHash;

  constructor(
    uint256 maxSupply_,
    string memory uri_,
    address payable signer_,
    address payable primarySalesReceiver_,
    address payable royaltyReceiver_,
    uint8 royaltyPercentage_,
    string memory contractURI_,
    string memory provenanceHash_
  ) ERC998TopDown("Hero", "HERO") EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
    _allowedMinters[signer_] = true;
    maxSupply = maxSupply_;
    _heroCounter.increment();
    baseUri = uri_;
    primarySalesReceiver = primarySalesReceiver_;
    royaltyReceiver = royaltyReceiver_;
    royaltyPercentage = royaltyPercentage_;
    _contractURI = contractURI_;
    provenanceHash = provenanceHash_;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory contractURI_) external {
    _contractURI = contractURI_;
  }

  function addSigner(address signer_) public onlyOwner {
    _allowedMinters[signer_] = true;
  }

  function disableSigner(address signer_) public onlyOwner {
    _allowedMinters[signer_] = false;
  }

  function getMintNonce(address msgSigner) external view returns (uint256) {
    return mintNonce[msgSigner];
  }

  function getClaimNonce(uint256 tokenId) external view returns (uint256) {
    return claimNonce[tokenId];
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable, ERC721, IERC165)
    returns (bool)
  {
    return
      type(IERC2981).interfaceId == interfaceId ||
      super.supportsInterface(interfaceId);
  }

  modifier onlyAuthorized(uint256 _tokenId) {
    require(
      _isApprovedOrOwner(msg.sender, _tokenId),
      "Hero: Caller is not owner nor approved"
    );
    _;
  }

  function bulkChanges(BulkChangeVoucher calldata bulkChangeVoucher)
    external
    onlyAuthorized(bulkChangeVoucher.tokenId)
  {
    address signer = _verifyBulkChangeData(bulkChangeVoucher, false);
    require(
      _allowedMinters[signer] == true,
      "Signature invalid or unauthorized"
    );

    _transferItemOut(
      bulkChangeVoucher.tokenId,
      ownerOf(bulkChangeVoucher.tokenId),
      bulkChangeVoucher.itemContractAddress,
      bulkChangeVoucher.itemsToUnequip,
      bulkChangeVoucher.amountsToUnequip
    );

    _transferItemIn(
      bulkChangeVoucher.tokenId,
      _msgSender(),
      bulkChangeVoucher.itemContractAddress,
      bulkChangeVoucher.itemsToEquip,
      bulkChangeVoucher.amountsToEquip
    );

    emit BulkChanges(
      bulkChangeVoucher.tokenId,
      bulkChangeVoucher.itemsToEquip,
      bulkChangeVoucher.amountsToEquip,
      bulkChangeVoucher.slotsToEquip,
      bulkChangeVoucher.itemsToUnequip,
      bulkChangeVoucher.amountsToUnequip,
      ownerOf(bulkChangeVoucher.tokenId)
    );
  }

  function mint(MintVoucher calldata voucher) external payable {
    require(msg.value == voucher.price, "Voucher: Invalid price amount");

    uint256 currentHeroCounter = _heroCounter.current();
    require(currentHeroCounter <= maxSupply, "Hero: No more heroes available");
    address signer = _verifyMintData(voucher);

    require(
      _allowedMinters[signer] == true,
      "Signature invalid or unauthorized"
    );

    require(_msgSender() == voucher.wallet, "Hero: Invalid wallet");
    mintNonce[_msgSender()]++;

    _safeMint(_msgSender(), currentHeroCounter);
    (bool paymentSucess, ) = payable(primarySalesReceiver).call{
      value: msg.value
    }("");
    require(paymentSucess, "Hero: Payment failed");
    _heroCounter.increment();
  }

  function claimItems(BulkChangeVoucher calldata voucher)
    external
    onlyAuthorized(voucher.tokenId)
  {
    address signer = _verifyBulkChangeData(voucher, true);

    require(
      _allowedMinters[signer] == true,
      "Signature invalid or unauthorized"
    );

    claimNonce[voucher.tokenId]++;

    IItem(voucher.itemContractAddress).claimFromHero(
      owner(),
      address(this),
      voucher.itemsToEquip,
      voucher.amountsToEquip,
      toBytes(voucher.tokenId)
    );
    emit ItemsClaimed(voucher.tokenId);
  }

  function setUri(string memory uri_) public onlyOwner {
    baseUri = uri_;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Hero: URI query for nonexistent token");

    return string(abi.encodePacked(baseUri, Strings.toString(tokenId)));
  }

  function _transferItemIn(
    uint256 _tokenId,
    address _operator,
    address _itemAddress,
    uint256[] memory _itemIds,
    uint256[] memory _amounts
  ) internal {
    if (_itemAddress.supportsInterface(ERC_1155_INTERFACE)) {
      IERC1155(_itemAddress).safeBatchTransferFrom(
        _operator,
        address(this),
        _itemIds,
        _amounts,
        toBytes(_tokenId)
      );
    } else {
      require(false, "Hero: Item does not support ERC-1155 standards");
    }
  }

  function _transferItemOut(
    uint256 _tokenId,
    address _owner,
    address _itemAddress,
    uint256[] memory _unequipItemIds,
    uint256[] memory _amountsToUnequip
  ) internal {
    _safeBatchTransferChild1155From(
      _tokenId,
      _owner,
      _itemAddress,
      _unequipItemIds,
      _amountsToUnequip,
      toBytes(_tokenId)
    );
  }

  function _hashMintData(MintVoucher calldata voucher)
    internal
    view
    returns (bytes32)
  {
    bytes memory changeInfo = abi.encodePacked(voucher.price, voucher.wallet);

    bytes memory domainInfo = abi.encodePacked(
      this.getChainID(),
      SIGNING_DOMAIN,
      SIGNATURE_VERSION,
      address(this),
      mintNonce[_msgSender()]
    );

    return
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked(changeInfo, domainInfo))
      );
  }

  function _hashBulkChangeData(
    BulkChangeVoucher calldata voucher,
    bool includeNonce
  ) internal view returns (bytes32) {
    bytes memory firstPart = abi.encodePacked(
      voucher.tokenId,
      voucher.itemContractAddress,
      voucher.itemsToEquip,
      voucher.amountsToEquip,
      voucher.slotsToEquip,
      voucher.itemsToUnequip
    );

    bytes memory secondPart = abi.encodePacked(
      voucher.amountsToUnequip,
      this.getChainID(),
      SIGNING_DOMAIN,
      SIGNATURE_VERSION,
      address(this)
    );

    if (includeNonce) {
      bytes memory nonce = abi.encodePacked(claimNonce[voucher.tokenId]);
      return
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked(firstPart, secondPart, nonce))
        );
    } else {
      return
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked(firstPart, secondPart))
        );
    }
  }

  function _verifyMintData(MintVoucher calldata voucher)
    internal
    view
    returns (address)
  {
    bytes32 digest = _hashMintData(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  function _verifyBulkChangeData(
    BulkChangeVoucher calldata voucher,
    bool includeNonce
  ) internal view returns (address) {
    bytes32 digest = _hashBulkChangeData(voucher, includeNonce);
    return ECDSA.recover(digest, voucher.signature);
  }

  function setRoyalty(address creator, uint8 _royaltyPercentage)
    public
    onlyOwner
  {
    royaltyReceiver = creator;
    royaltyPercentage = _royaltyPercentage;
  }

  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param tokenId - the NFT asset queried for royalty information (not used)
  /// @param _salePrice - sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _value sale price
  function royaltyInfo(uint256 tokenId, uint256 _salePrice)
    external
    view
    override(IERC2981)
    returns (address receiver, uint256 royaltyAmount)
  {
    uint256 _royalties = (_salePrice * royaltyPercentage) / 100;
    return (royaltyReceiver, _royalties);
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public override returns (bytes4) {
    require(
      operator == address(this),
      "Only the Hero contract can pull items in"
    );
    return super.onERC1155Received(operator, from, id, amount, data);
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory ids,
    uint256[] memory values,
    bytes memory data
  ) public override returns (bytes4) {
    require(
      operator == address(this),
      "Only the Hero contract can pull items in"
    );
    return super.onERC1155BatchReceived(operator, from, ids, values, data);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  function toBytes(uint256 x) internal pure returns (bytes memory b) {
    b = new bytes(32);
    assembly {
      mstore(add(b, 32), x)
    }
  }
}