// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//                                           ......
//                                 .';codxOO00KKKK00Okxdoc;'.
//                             .,lkKNWMMMMMMMMMMMMMMMMMMMMWNKkl,.
//                           ,o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o'
//                         'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx'
//                       .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.
//                      .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.
//                      cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc
//                     .OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.
//                     :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//                     lWMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXNWMMMNl
//                     'lolc:;,,,:lxKWMMMMMMMMMMMMMMMMMMMW0d:'....',:lol'
//                                  .:xXWMMMMMMMMMMMMMMXx;.
//                                     .oKMMMMMMMMMMMNx'
//                                       'xNMMMMMMMMXl.
//                       :Od:'.        ..;dXMMMMWMMMXd;..        .'cdx,
//                       oWMWNK0kxxxxkOKNWMMMXdccdXMMMWNKOkxxxxk0KNWMX:
//                       oWMMMMMMMMMMMMMMMMWk,    ,kWMMMMMMMMMMMMMMMMX;
//                       ;KMMMMMMMMMMMMMMMNd.      .dNMMMMMMMMMMMMMMMO.
//                        'ok0KXNNNWWMMMMMK,        ,KMMMMMWWNNNNXKOd'
//                           ...''',dNMMMMNd'      'dNMMMMNd,'''...
//                                  :NMMMMMWXkollokXWMMMMMN:
//                                  cNMMMMMMMMMMMMMMMMMMMMNc
//                                  lNMNOkXMMMNXNWMMWKkKWMNl
//                                  oWM0'.dWMNo,;kMMX: :XMWo
//                                  oWMx. lWMX; .oWM0' '0MWo
//                                  'cl,  ;0Xk.  :0Xd.  ,ll,
//                                         ...    ...
//
//   █████╗ ██╗     ██████╗ ██╗  ██╗ █████╗ ███████╗██╗  ██╗██╗   ██╗██╗     ██╗     ███████╗
//  ██╔══██╗██║     ██╔══██╗██║  ██║██╔══██╗██╔════╝██║ ██╔╝██║   ██║██║     ██║     ╚══███╔╝
//  ███████║██║     ██████╔╝███████║███████║███████╗█████╔╝ ██║   ██║██║     ██║       ███╔╝
//  ██╔══██║██║     ██╔═══╝ ██╔══██║██╔══██║╚════██║██╔═██╗ ██║   ██║██║     ██║      ███╔╝
//  ██║  ██║███████╗██║     ██║  ██║██║  ██║███████║██║  ██╗╚██████╔╝███████╗███████╗███████╗
//  ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝
//
//   ██████╗ ███████╗███╗   ██╗███████╗███████╗██╗███████╗
//  ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔════╝██║██╔════╝
//  ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ███████╗██║███████╗
//  ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ╚════██║██║╚════██║
//  ╚██████╔╝███████╗██║ ╚████║███████╗███████║██║███████║
//   ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝╚══════╝
//
//  ███████╗ ██████╗ ██████╗  ██████╗███████╗
//  ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝
//  █████╗  ██║   ██║██████╔╝██║     █████╗
//  ██╔══╝  ██║   ██║██╔══██╗██║     ██╔══╝
//  ██║     ╚██████╔╝██║  ██║╚██████╗███████╗
//  ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝
//

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

error MintSaleNotStarted();
error MintInsufficientPayment();
error MintExceedsMaxSupply();
error MintExceedsMintLimit();
error PresaleNotAlphalist();

contract GenesisForce is Ownable, ERC721A, ReentrancyGuard {
  uint256 public constant price = 0.08 ether;

  uint256 public immutable collectionSize;
  uint256 public immutable maxPerMint;
  uint256 public immutable maxPresaleMints;
  uint256 public immutable amountForDevs;

  bool public presaleActive = false;
  bool public publicSaleActive = false;

  string private baseTokenURI;
  bytes32 private presaleRoot;

  constructor(
    uint256 _collectionSize,
    uint256 _maxPerMint,
    uint256 _maxPresaleMints,
    uint256 _amountForDevs
  ) ERC721A("AlphaSkullz Genesis Force", "GFAS") {
    collectionSize = _collectionSize;
    maxPerMint = _maxPerMint;
    maxPresaleMints = _maxPresaleMints;
    amountForDevs = _amountForDevs;
  }

  function presaleMint(uint64 amount, bytes32[] calldata proof) external payable nonReentrant {
    if (!presaleActive) revert MintSaleNotStarted();

    if (msg.value < price * amount) revert MintInsufficientPayment();
    if (totalSupply() + amount > collectionSize) revert MintExceedsMaxSupply();

    uint64 numWhitelistMinted = _getAux(_msgSender()) + amount;
    if (numWhitelistMinted > maxPresaleMints) revert MintExceedsMintLimit();

    if (MerkleProof.verify(proof, presaleRoot, keccak256(abi.encodePacked(_msgSender()))) == false) {
      revert PresaleNotAlphalist();
    }

    _safeMint(_msgSender(), amount);
    _setAux(_msgSender(), numWhitelistMinted);
  }

  function publicMint(uint256 amount) external payable nonReentrant {
    if (!publicSaleActive) revert MintSaleNotStarted();
    if (msg.value < price * amount) revert MintInsufficientPayment();
    if (amount > maxPerMint) revert MintExceedsMintLimit();
    if (totalSupply() + amount > collectionSize) revert MintExceedsMaxSupply();

    _safeMint(_msgSender(), amount);
  }

  function numberPresaleMinted(address owner) external view returns (uint256) {
    return _getAux(owner);
  }

  function numberMinted(address owner) external view returns (uint256) {
    return _numberMinted(owner);
  }

  function ownershipDataOf(uint256 tokenId) external view returns (TokenOwnership memory) {
    return ownershipOf(tokenId);
  }

  // OWNER ONLY

  function devMint(uint256 amount) external onlyOwner {
    require(totalSupply() + amount <= amountForDevs, "too many already minted before dev mint");
    require(amount % maxPerMint == 0, "can only mint a multiple of the maxPerMint");
    uint256 numChunks = amount / maxPerMint;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(_msgSender(), maxPerMint);
    }
  }

  function setPresaleActive(bool _active) external onlyOwner {
    presaleActive = _active;
  }

  function setPublicSaleActive(bool _active) external onlyOwner {
    publicSaleActive = _active;
  }

  function setPresaleRoot(bytes32 _root) external onlyOwner {
    presaleRoot = _root;
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseTokenURI = _uri;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool ok, ) = payable(_msgSender()).call{value: balance}("");
    require(ok, "Failed to withdraw payment");
  }

  // INTERNAL

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }
}