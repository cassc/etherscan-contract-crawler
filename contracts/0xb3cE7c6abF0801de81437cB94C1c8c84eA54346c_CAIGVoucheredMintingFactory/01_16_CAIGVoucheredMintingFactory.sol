// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./ChampionsAscensionImperialGallery.sol";

/**
 * @title The minting factory for ChampionsAscensionImperialGallery NFTs
 * @notice This contract manages the minting of NFTs in the Imperial Gallery.
 * The players use this contract to redeem the voucher for an NFT.
 * @dev This contract should be in the MINTER_ROLE in the ChampoinsAscensionImperialGallery contract.
 */
contract CAIGVoucheredMintingFactory is EIP712, Pausable, AccessControl {
  event CAIGVoucheredMinted(
    address indexed to,
    uint256 indexed tokenId
  );

  // The ChampionsAscensionImperialGallery contract address
  address public immutable nftAddress;

  // Roles
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  bytes32 public constant MINT_ADMIN_ROLE = keccak256("MINT_ADMIN_ROLE");
  bytes32 public constant VOUCHER_SIGNER_ROLE = keccak256("VOUCHER_SIGNER_ROLE");

  // Signing verification
  string private constant SIGNING_DOMAIN_NAME = "CAIG_Voucher";
  string private constant SIGNING_DOMAIN_VERSION = "1";

  struct Voucher {
    // @notice The id of the token to be minted. 
    uint256 tokenId;
    
    // @notice The EIP-712 signature of this struct
    bytes signature;
  }
  
  /**
   * @param _nftAddress address of the ERC721 contract
   */
  constructor(address _nftAddress) 
    EIP712(SIGNING_DOMAIN_NAME, SIGNING_DOMAIN_VERSION)
  {
    require(_nftAddress != address(0), "_nftAddress is zero address");
    nftAddress = _nftAddress;
    _setupRole(DEPLOYER_ROLE, msg.sender);
    _setupRole(MINT_ADMIN_ROLE, msg.sender);

    /**
     * @dev set deployer role as administrator of the mint admin and voucher signer roles.
     * i.e. a member of DEPLOYER_ROLE can grant/revoke the MINT_ADMIN_ROLE or VOUCHER_SIGNER_ROLE to addresses
     */
    _setRoleAdmin(MINT_ADMIN_ROLE, DEPLOYER_ROLE);
    _setRoleAdmin(VOUCHER_SIGNER_ROLE, DEPLOYER_ROLE);
  }

  /**
   * @notice Disables minting
   */
  function pause() external onlyRole(MINT_ADMIN_ROLE) {
      _pause();
  }

  /**
   * @notice Re-enables paused minting 
   */
  function unpause() external onlyRole(MINT_ADMIN_ROLE) {
      _unpause();
  }

  /**
   * @notice Returns the digest of the Voucher with EIP712 extras
   * @dev combines the EIP712 extras with the digest of the Voucher fields
   */
  function digestVoucher(Voucher calldata voucher) public view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("Voucher(uint256 tokenId)"),
      voucher.tokenId
    )));
  }

  /**
   * @notice Returns the address of the verified signer or reverts if invalid.
   */
  function verify(Voucher calldata voucher) public view returns (address) {
    bytes32 digest = digestVoucher(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  /**
   * @notice Redeems a voucher for a minted NFT
   * @param _to The address to which the NFT will be minted
   * @param _voucher The signed Voucher for the NFT
   */
  function redeem(address _to, Voucher calldata _voucher) public {
    
    // check the signature on the voucher and get the signer's address
    address signer = verify(_voucher);

    // make sure the signer is authorized to sign our vouchers
    require(hasRole(VOUCHER_SIGNER_ROLE, signer), "Voucher invalid or not authorized");

    ChampionsAscensionImperialGallery caig = ChampionsAscensionImperialGallery(nftAddress);

    uint128 tokenType;
    uint128 tokenIndex;
    (tokenType, tokenIndex) = caig.decomposeTokenId(_voucher.tokenId);
    caig.mint(_to, tokenType, tokenIndex);

    emit CAIGVoucheredMinted(_to, _voucher.tokenId);
  }

  function selfDestruct() external onlyRole(DEPLOYER_ROLE) {
    selfdestruct(payable(msg.sender));
  }
}