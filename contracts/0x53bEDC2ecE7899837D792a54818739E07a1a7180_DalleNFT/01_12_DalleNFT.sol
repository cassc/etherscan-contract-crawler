//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Dalle2NFT.com
//
/// @title DalleNFT
/// @author FKNG.PRO
/// @notice Mints NFTs from DallE
contract DalleNFT is ERC721, Ownable {
  /// @notice Minting fee as a percentage of gas costs
  uint256 public feePerc;
  /// @notice Estimated mint gas cost
  uint256 public constant mintGas = 150000;
  /// @notice If the Signer signature is required for minting
  bool public requireSigned;
  /// @notice Signer providing minting signatures
  address public signer;

  /// @notice maps keccak256(dalleId) to IPFS CID
  /// @dev wanted bytes32 there, but CIDv1 could be longer than that :(
  mapping(uint256 => string) public nftMetadata;

  // EIP712 niceties
  bytes32 public DOMAIN_SEPARATOR;
  string public constant version = "1";

  event FeeChanged(uint256 oldFee, uint256 newFee);
  event RequireSigned(bool signatureRequired);
  event SignerChanged(address newSigner);
  event Mint(address indexed to, uint256 id, string dalleId, uint256 gasFee);

  constructor(address owner_, address signer_) ERC721("Dalle2NFT", "Dalle2NFT") {
    Ownable.transferOwnership(owner_);
    signer = signer_;
    uint256 chainId = 0;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("Dalle2NFT")),
        keccak256(bytes(version)),
        chainId,
        address(this)
      )
    );
  }

  /////////////////////////
  // Public mint functions

  /// @notice Mint an NFT from DALLE
  /// @notice If feePerc is not zero, the percentage of gas should be paid as a fee
  /// @dev NFT ID will be keccak256() of dalleId
  /// @param metadata The IPFS CID of DALLE metadata
  /// @param dalleId The ID of DALLE generation (as on labs.openai.com share link)
  function mint(string calldata metadata, string calldata dalleId) external payable {
    require(requireSigned == false, "Only Signed mints are allowed");
    mintNFT(metadata, dalleId);
  }

  bytes32 public constant PERMIT_TYPEHASH = keccak256("mintSigned(address msgSender,string metadata,string dalleId)");

  /// @notice Signed Mint an NFT from DALLE
  /// @notice If feePerc is not zero, the percentage of gas should be paid as a fee
  /// @dev NFT ID will be keccak256() of dalleId
  /// @param metadata The IPFS CID of DALLE metadata
  /// @param dalleId The ID of DALLE generation (as on labs.openai.com share link)
  /// @param r_ The first 32 bytes of signature (ECDSA component)
  /// @param s_ The second 32 bytes of signature (ECDSA component)
  /// @param v_ A final byte of signature (ECDSA component)
  function mintSigned(
    string calldata metadata,
    string calldata dalleId,
    bytes32 r_,
    bytes32 s_,
    uint8 v_
  ) external payable {
    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, msg.sender, keccak256(bytes(metadata)), keccak256(bytes(dalleId))))
      )
    );
    require(signer == ecrecover(digest, v_, r_, s_), "invalid signature or parameters");
    mintNFT(metadata, dalleId);
  }

  /////////////////////////
  // Viewers/Getters

  /// @notice NFT Metadata URL
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return string.concat("ipfs://", nftMetadata[tokenId]);
  }

  /// @notice Converts dalleId to NFT id
  function getId(string calldata dalleId) public pure returns (uint256) {
    return uint256(keccak256(bytes(dalleId)));
  }

  /// @notice Estimates the fee based on default mint gas and gasPrice
  /// @param gasPrice desired TX gasPrice
  function estimateFee(uint256 gasPrice) public view returns (uint256) {
    return (feePerc * mintGas * gasPrice) / 1e18;
  }

  /////////////////////////
  // Internal functions

  /// @notice Estimates the fee based on actual gas spent and tx gasPrice
  /// @param actualGas actual TX gas consumed
  function calculateFee(uint256 actualGas) internal view returns (uint256) {
    return (feePerc * actualGas * tx.gasprice) / 1e18;
  }

  /// @dev Internal mint function
  /// @dev It tracks how much gas has been spent on minting and takes feePerc % of that as a fee
  /// @dev In case too much fee was sent - it sends back the rest (and doesn't fail if ETH receiving is disabled)
  /// @dev You can only mint one dalle generation once
  function mintNFT(string calldata metadata, string calldata dalleId) internal {
    uint256 startGas;
    uint256 fee;
    if (feePerc > 0) {
      startGas = gasleft();
      require(msg.value >= estimateFee(tx.gasprice), "Service Fee should be paid");
    }
    uint256 nftId = getId(dalleId);
    require(!_exists(nftId), "NFT Already minted");
    nftMetadata[nftId] = metadata;
    _mint(msg.sender, nftId);
    if (feePerc > 0) {
      uint256 gasConsumed = startGas - gasleft();
      fee = calculateFee(gasConsumed);
      // We just ignore if send fails
      payable(msg.sender).send(msg.value - fee);
    }
    emit Mint(msg.sender, nftId, dalleId, fee);
  }

  /////////////////////////
  // Owner functions

  /// @notice Changes the minting fee
  function changeFee(uint256 newFee) external onlyOwner {
    uint256 oldFee = feePerc;
    feePerc = newFee;
    emit FeeChanged(oldFee, newFee);
  }

  /// @notice Restricts referral creation to be signed by the service
  /// @param requireSigned_ true if signature is required
  function setRequireSigned(bool requireSigned_) external onlyOwner {
    requireSigned = requireSigned_;
    emit RequireSigned(requireSigned_);
  }

  /// @notice Sets a new Signer
  /// @param newSigner new Signer
  function setSigner(address newSigner) external onlyOwner {
    signer = newSigner;
    emit SignerChanged(newSigner);
  }

  /////////////////////////
  // Payout functions

  /// @notice Pays out all Factory ETH balance to owners address
  function payout() external {
    // Ignoring the send failure - doesn't matter
    payable(owner()).send(address(this).balance);
  }

  /// @notice Pays out all Factory ERC20 token balance to owners address
  /// @param _tokenAddress an address of the ERC20 token to payout
  function payoutToken(address _tokenAddress) external {
    IERC20 token = IERC20(_tokenAddress);
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "Nothing to payout");
    token.transfer(owner(), amount);
  }
}