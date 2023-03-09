// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { DefaultOperatorFilterer } from "../royalty/normal/DefaultOperatorFilterer.sol";

// VUCA + Pellar + LightLink 2022

// write upgradable erc1155 contract
contract VucaMascotToken is EIP712, Ownable2Step, ERC1155, DefaultOperatorFilterer {
  using ECDSA for bytes32;

  struct ForwardRequest {
    address from;
  }

  struct Config {
    uint32 start;
    uint32 end;
    uint256 maxSupply;
    uint256 totalClaimed;
  }

  bytes32 private constant _STRUCT_HASH = keccak256("ForwardRequest(address from)");
  mapping(address => bool) public claimed;
  Config public config;

  // disable renounceOwnership
  function renounceOwnership() public pure override {
    revert("renounceOwnership disabled");
  }

  constructor() EIP712("Adot", "1.0.0") ERC1155("") {
    config.maxSupply = 650;
    config.start = 1678719600;
    config.end = 1678813200;
  }

  function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
    address signer = _hashTypedDataV4(keccak256(abi.encode(_STRUCT_HASH, req.from))).recover(signature);
    return signer == req.from;
  }

  // mint function only allow proxy contract
  function mint(ForwardRequest calldata req, bytes calldata signature) public {
    address signer = tx.origin;
    require(config.start <= block.timestamp && block.timestamp <= config.end, "Not active");
    if (signature.length > 0) {
      require(verify(req, signature), "Invalid signature");
      signer = req.from;
    }
    require(!claimed[signer], "Already claimed");
    require(config.maxSupply > config.totalClaimed, "Exceed max");

    claimed[signer] = true;
    config.totalClaimed += 1;

    _mint(signer, 0, 1, "");
  }

  /** Admin */
  function setMaxSupply(uint256 maxSupply) public onlyOwner {
    config.maxSupply = maxSupply;
  }

  function setStart(uint32 start) public onlyOwner {
    config.start = start;
  }

  function setEnd(uint32 end) public onlyOwner {
    config.end = end;
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  /** Royalty */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}