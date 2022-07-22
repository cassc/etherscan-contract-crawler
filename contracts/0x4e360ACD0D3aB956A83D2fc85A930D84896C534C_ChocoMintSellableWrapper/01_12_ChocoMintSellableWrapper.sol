//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "../../interfaces/IChocoMintERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ChocoMintSellableWrapper is Initializable, PaymentSplitterUpgradeable, OwnableUpgradeable {
  using MerkleProof for bytes32[];

  IChocoMintERC721 public chocomintERC721;
  uint256 public supplied;
  uint256 public preSalePrice;
  uint256 public publicSalePrice;
  uint256 public supplyLimit;
  uint256 public mintLimit;
  uint256 public preSaleStartTimestamp;
  uint256 public publicSaleStartTimestamp;

  bytes32 public saleMerkleRoot;
  mapping(address => uint256) public saleAllowlistClaimed;

  function initialize(
    address _chocomintERC721Address,
    uint256 _preSalePrice,
    uint256 _publicSalePrice,
    uint256 _supplyLimit,
    uint256 _mintLimit,
    uint256 _preSaleStartTimestamp,
    uint256 _publicSaleStartTimestamp,
    address[] memory _payees,
    uint256[] memory _shares
  ) public virtual initializer {
    chocomintERC721 = IChocoMintERC721(_chocomintERC721Address);
    preSalePrice = _preSalePrice;
    publicSalePrice = _publicSalePrice;
    supplyLimit = _supplyLimit;
    mintLimit = _mintLimit;
    preSaleStartTimestamp = _preSaleStartTimestamp;
    publicSaleStartTimestamp = _publicSaleStartTimestamp;
    __PaymentSplitter_init(_payees, _shares);
    __Ownable_init_unchained();
  }

  function setSaleMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    saleMerkleRoot = _merkleRoot;
  }

  function reviewSaleProof(address _sender, bytes32[] calldata _proof) public view returns (bool) {
    return MerkleProof.verify(_proof, saleMerkleRoot, keccak256(abi.encodePacked(_sender)));
  }

  function mintPublic() public payable {
    require(block.timestamp >= publicSaleStartTimestamp, "SellableWrapper: sale has not started");
    require(supplied < supplyLimit, "SellableWrapper: sale has already ended");
    require(msg.value == publicSalePrice, "SellableWrapper: msg value must be same as mint price");
    require(saleAllowlistClaimed[msg.sender] < mintLimit, "SellableWrapper: you have already minted maximum tokens");
    SecurityLib.SecurityData memory validSecurityData = SecurityLib.SecurityData(0, 9999999999, 0);
    MintERC721Lib.MintERC721Data memory mintERC721Data = MintERC721Lib.MintERC721Data(
      validSecurityData,
      address(this),
      msg.sender,
      supplied + 1,
      ""
    );
    bytes32 root = MintERC721Lib.hashStruct(mintERC721Data);
    SignatureLib.SignatureData memory signatureData = SignatureLib.SignatureData(root, new bytes32[](0), "");
    chocomintERC721.mint(mintERC721Data, signatureData);
    supplied++;
    saleAllowlistClaimed[msg.sender]++;
  }

  function mintProof(bytes32[] calldata _proof) public payable {
    require(block.timestamp >= preSaleStartTimestamp, "SellableWrapper: sale has not started");
    require(supplied < supplyLimit, "SellableWrapper: sale has already ended");
    require(msg.value == preSalePrice, "SellableWrapper: msg value must be same as mint price");
    require(saleAllowlistClaimed[msg.sender] < mintLimit, "SellableWrapper: you have already minted maximum tokens");
    require(reviewSaleProof(msg.sender, _proof), "SellableWrapper:Proof does not match data");
    SecurityLib.SecurityData memory validSecurityData = SecurityLib.SecurityData(0, 9999999999, 0);
    MintERC721Lib.MintERC721Data memory mintERC721Data = MintERC721Lib.MintERC721Data(
      validSecurityData,
      address(this),
      msg.sender,
      supplied + 1,
      ""
    );
    bytes32 root = MintERC721Lib.hashStruct(mintERC721Data);
    SignatureLib.SignatureData memory signatureData = SignatureLib.SignatureData(root, new bytes32[](0), "");
    chocomintERC721.mint(mintERC721Data, signatureData);
    supplied++;
    saleAllowlistClaimed[msg.sender]++;
  }
}