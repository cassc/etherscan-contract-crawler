//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import 'hardhat/console.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

//                                                             ..
//                                                           -#@@%+.
//                                                        -*@@+**[email protected]@#-
//                                                     [email protected]@@[email protected]@@@:@@##@#-
//                                                   =#@@@@@[email protected]@-#@*%##@@@@+.
//                                                -#@@#.-%@@%@#@@@:-*%%****@%=.
//                                             :*@@@@@%@@@[email protected]@+#@:%+%@@@@@@@*@%=
//                                           -%@@*+++%#@%[email protected]#%*@=*@@@@@@@#[email protected]@[email protected]%%@+
//                                           *@####@@@**%%@@@#**@@:%@*@@[email protected]*#@*@@*@@
//                                           *@##[email protected]@#=*@@@#[email protected][email protected]#@*#@@%@@##+*@@@@
//                                           *@@@@@@@@[email protected]*+#@@*++-%@[email protected]@@%@@%%%#@@@@
//                                           *@@*@%[email protected]+*#[email protected]#[email protected]@%@@:#@#***%@@@@@=*[email protected]
//                                           *@@@@@#@#%%%@+--%+#@@*%*@%++#[email protected]@@@@#[email protected]
//                                           *%:%@@@%***%@[email protected][email protected]@@%+%@*++=%[email protected]@#[email protected]@@@
//                                           *%-***@%*%*@%#@@@@%-:++#@@@=%@#--++#@@
//                                           [email protected]@@@@@@#[email protected]@#[email protected]@@[email protected]#%@@+*@@@@@@%@@@@@*
//                                             -*@@#[email protected]#::++#@[email protected]@[email protected]+*-%@*#*%%@@%=
//                                                =#@@@*@@@@@***[email protected]@#@@*@@+*@%+:
//                                                  .=%@%+++%@@@-#@@=:*@@@*:
//                                                     :*@@@+%@%#@@@##@#=
//                                                        -*@#@#[email protected]%@%=.
//                                                           -#@%@+:
//                                                             .:
//
//
//
//
//  +++-       :++=    :++=       :++=    :++=          =++-    -+++++++++++++    =++++++++++++-        -++++++       .+++
//  @@@@=      [email protected]@%    [email protected]@#       [email protected]@%    [email protected]@@#.       *@@@#    *@@@@@@@@@@@@@    %@@@@@@@@@@@@@*       %@@@@@@-      [email protected]@@
//  @@@@@*     [email protected]@%    [email protected]@#       [email protected]@%    [email protected]@@@@-    :%@@@@#    *@@#              %@@+       *@@*      [email protected]@= [email protected]@@      [email protected]@@
//  @@@#@@%:   [email protected]@%    [email protected]@#       [email protected]@%    [email protected]@#%@@*  [email protected]@@#@@#    *@@#              %@@+       *@@*     [email protected]@%   [email protected]@*     [email protected]@@
//  @@@[email protected]@@-  [email protected]@%    [email protected]@#       [email protected]@%    [email protected]@* *@@#*@@%[email protected]@#    *@@%++++++++      %@@*-------#@@*     *@@-    %@@.    [email protected]@@
//  @@@- :%@@* [email protected]@%    [email protected]@#       [email protected]@%    [email protected]@*  [email protected]@@@+  [email protected]@#    *@@@@@@@@@@@.     %@@@@@@@@@@@@@-    [email protected]@%:::::*@@#    [email protected]@@
//  @@@-   *@@#[email protected]@%    [email protected]@#       [email protected]@%    [email protected]@*   .%@:   [email protected]@#    *@@#              %@@*...:#@@%:      %@@@@@@@@@@@@-   [email protected]@@
//  @@@-    [email protected]@@@@%    [email protected]@#       [email protected]@%    [email protected]@*     .    [email protected]@#    *@@#              %@@+     *@@%     [email protected]@%[email protected]@@   [email protected]@@
//  @@@-     :%@@@%    [email protected]@%+++++++#@@%    [email protected]@*          [email protected]@#    *@@%++++++++++    %@@+      [email protected]@%:  [email protected]@@:        #@@+  [email protected]@@
//  @@@-      .%@@%    .*@@@@@@@@@@@%-    [email protected]@*          [email protected]@*    *@@@@@@@@@@@@@    #@@+       [email protected]@@: *@@*         [email protected]@@. [email protected]@@
//

contract NumeraiTshirts is ERC721, EIP712, Ownable {
  string public constant DOMAIN_NAME = 'NumeraiNFTee-Voucher';
  string public constant DOMAIN_VERSION = '1';
  uint256 public constant maxTokens = 6000;

  // Base URI and contract URI
  string private _myBaseURI;
  string private _myContractURI;

  constructor()
    ERC721('Numerai NFTees', 'NFTEE')
    EIP712(DOMAIN_NAME, DOMAIN_VERSION)
  {}

  /// @notice This function is used by OpenSea to retrieve storefront-level metadata
  /// see: https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return _myContractURI;
  }

  /// @notice This contract uses the lazy and permissioned minting pattern enabled
  /// by draft-EIP712. The minter signs and distributes vouchers to users off-chain, and
  /// the user uses the signed voucher to redeem the NFT
  struct Voucher {
    uint256[] tokenIds;
    address minter;
    bytes signature;
  }

  /// @notice Check if the token exists
  function tokenExists(uint256 tokenId) public view returns (bool) {
    return _exists(tokenId);
  }

  /// @notice Redeems a voucher for a NFT and returns the tokenIds
  function redeem(Voucher calldata voucher)
    external
    returns (uint256[] memory)
  {
    // Make sure voucher is valid
    _verify(voucher);

    // Mint the NFTs to msg.sender. Will revert if tokenId is already owned!
    for (uint256 i = 0; i < voucher.tokenIds.length; i++) {
      _mint(msg.sender, voucher.tokenIds[i]);
    }

    return voucher.tokenIds;
  }

  /// @notice Verifies the signature of the voucher
  /// @dev Will revert if msg.sender does not match voucher.minter address
  /// @dev Will revert if the signature does not match the tokenIds
  /// @dev Will revert if the signature does not match the domain name and version
  /// @dev Will revert if the signature does not match the contract address and chain id
  /// @dev Will revert if not signed by owner
  function _verify(Voucher calldata voucher) internal view {
    require(
      voucher.minter == msg.sender,
      'Voucher can only be redeemed by assigned wallet'
    );
    bytes32 digest = _hash(voucher);
    address signer = ECDSA.recover(digest, voucher.signature);
    require(signer == owner(), 'Signature invalid or unauthorized');
  }

  /// @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
  /// @dev see https://docs.openzeppelin.com/contracts/3.x/api/drafts#EIP712-_hashTypedDataV4-bytes32-
  function _hash(Voucher calldata voucher) internal view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              abi.encodePacked('Voucher(uint256[] tokenIds,address minter)')
            ),
            keccak256(abi.encodePacked(voucher.tokenIds)),
            voucher.minter
          )
        )
      );
  }

  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * Returns the base URI set via {_setBaseURI}. This will be
   * automatically added as a prefix in {tokenURI} to each token's URI, or
   * to the token ID if no specific URI is set for that token ID.
   */
  function _baseURI() internal view override returns (string memory) {
    return _myBaseURI;
  }

  /// @notice Mints tokenId to wallet address. External function can only be called
  /// outside of the contract but uses less gas than a public function
  function mintToAddress(uint256 tokenId, address recipient)
    external
    onlyOwner
    returns (uint256)
  {
    require(tokenId < maxTokens);

    // Mint the NFT to recipient. Will revert if tokenId is already owned!
    _mint(recipient, tokenId);

    return tokenId;
  }

  /// @notice Mints tokenIds to wallet addresses
  function batchMintToAddress(
    uint256[] calldata tokenIds,
    address[] calldata recipients
  ) external onlyOwner returns (uint256[] memory) {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(tokenIds[i] < maxTokens);
      // Mint the NFT to recipient. Will revert if tokenId is already owned!
      _mint(recipients[i], tokenIds[i]);
    }

    return tokenIds;
  }

  /// @notice Sets myBaseURI
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _myBaseURI = baseURI;
  }

  /// @notice Sets _myContractURI
  function setContractURI(string calldata _contractURI) external onlyOwner {
    _myContractURI = _contractURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json")) : "";
  }
}