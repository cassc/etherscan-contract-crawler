// SPDX-License-Identifier: None
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";

// DualFaced by LNMH LLC

struct MintConfig {
  uint32 allowlistMintTime;
  uint32 publicMintTime;
  uint32 mintEndTime;
  uint32 supplyLimit;
  uint8 allowlistMintLimit;
  uint8 publicMintLimit;
}

contract DualFaced is Ownable, ERC721A, ERC2981 {
  using SafeCast for uint256;
  using ECDSA for bytes32;

  // EVENTS *****************************************************

  event MintSignerUpdated();
  event RoyaltiesUpdated();
  event BaseUriUpdated();
  event MintConfigUpdated();

  // ERRORS *****************************************************

  error MintNotActive();
  error SignerNotSet();
  error InvalidAddress();
  error InvalidTime();
  error InvalidSignature();
  error MintLimitExceeded();
  error OutOfSupply();
  error ZeroBalance();
  error WithdrawFailed();

  // Storage *****************************************************

  MintConfig public mintConfig;

  string public baseURI = "ipfs://QmXYATp1nxaKbDYhFE9UY8ZeoJP9p4nsaz2K1tyQM7htSD";
  address public mintSigner;

  address payable public withdrawalAddress;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("mint(address buyer)");

  // Constructor *****************************************************

  constructor() ERC721A("DualFaced", "DuFa") {
    mintConfig = MintConfig({
      allowlistMintTime: 1662471000, // Tue Sep 06 2022 13:30:00 GMT+0000
      publicMintTime: 1662557400, // Wed Sep 07 2022 13:30:00 GMT+0000
      mintEndTime: 1663075800, // Tue Sep 13 2022 13:30:00 GMT+0000
      supplyLimit: 8000,
      allowlistMintLimit: 20,
      publicMintLimit: 10
    });

    _setDefaultRoyalty(0xE37EfcE481917fe4545AFE64652BEe1944E4C5bB, 1000); // 10% royalties

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("DualFaced")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  // Public Methods *****************************************************

  function allowlistMint(bytes memory signature, uint64 numberOfTokens) external {
    MintConfig memory _mintConfig = mintConfig;

    if (block.timestamp < _mintConfig.allowlistMintTime || block.timestamp > _mintConfig.publicMintTime) revert MintNotActive();

    if (mintSigner == address(0)) revert SignerNotSet();

    if ((_numberMinted(msg.sender) + numberOfTokens) > _mintConfig.allowlistMintLimit) revert MintLimitExceeded();

    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(TYPEHASH, msg.sender))));

    address signer = digest.recover(signature);

    if (signer == address(0) || signer != mintSigner) revert InvalidSignature();

    mint(msg.sender, numberOfTokens);
  }

  function publicMint(uint64 numberOfTokens) external {
    MintConfig memory _mintConfig = mintConfig;

    if (block.timestamp < _mintConfig.publicMintTime || block.timestamp > _mintConfig.mintEndTime) revert MintNotActive();

    if ((_numberMinted(msg.sender) + numberOfTokens) > _mintConfig.publicMintLimit) revert MintLimitExceeded();

    mint(msg.sender, numberOfTokens);
  }

  // Owner Methods *****************************************************

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    emit BaseUriUpdated();
    baseURI = newBaseUri;
  }

  function setMintSigner(address newSigner) external onlyOwner {
    emit MintSignerUpdated();
    mintSigner = newSigner;
  }

  function setRoyalties(address recipient, uint96 value) external onlyOwner {
    if (recipient == address(0)) revert InvalidAddress();

    emit RoyaltiesUpdated();
    _setDefaultRoyalty(recipient, value);
  }

  function configureMint(
    uint32 allowlistMintTime,
    uint32 publicMintTime,
    uint32 mintEndTime,
    uint32 supplyLimit,
    uint8 allowlistMintLimit,
    uint8 publicMintLimit
  ) external onlyOwner {
    if (0 == allowlistMintTime || allowlistMintTime > publicMintTime || publicMintTime > mintEndTime) revert InvalidTime();

    emit MintConfigUpdated();
    mintConfig = MintConfig({
      allowlistMintTime: allowlistMintTime,
      publicMintTime: publicMintTime,
      mintEndTime: mintEndTime,
      supplyLimit: supplyLimit,
      allowlistMintLimit: allowlistMintLimit,
      publicMintLimit: publicMintLimit
    });
  }

  function ownerMint(address to, uint256 numberOfTokens) external onlyOwner {
    mint(to, numberOfTokens);
  }

  function withdraw() external onlyOwner {
    if (address(this).balance == 0) revert ZeroBalance();

    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    if (!success) revert WithdrawFailed();
  }

  // Private Methods *****************************************************

  function mint(address to, uint256 numberOfTokens) private {
    if ((totalSupply() + numberOfTokens) > mintConfig.supplyLimit) revert OutOfSupply();

    _mint(to, numberOfTokens);
  }

  // Override Methods *****************************************************

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }
}