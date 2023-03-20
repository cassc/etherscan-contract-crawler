// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface WarmInterface {
  function balanceOf(
    address contractAddress,
    address owner
  ) external view returns (uint256);

  function balanceOf(
    address contractAddress,
    address owner,
    uint256 tokenId
  ) external view returns (uint256);

  function ownerOf(
    address contractAddress,
    uint256 tokenId
  ) external view returns (address);
}

contract ForgeNft is ERC721AQueryable, ReentrancyGuard, Ownable, Pausable {
  using SafeERC20 for IERC20;
  event MintWindowUpdate(
    address collectionAddress,
    uint256 maxSupply,
    uint256 fromTimestamp,
    uint256 toTimestamp,
    uint256 feeAmount,
    address inputCurrency
  );

  struct MintWindow {
    uint256 maxSupply; // max supply of NFTs for this window
    uint256 fromTimestamp; // in seconds
    uint256 toTimestamp; // in seconds
    uint256 feeAmount; // in gwei
    address inputCurrency; // currency for mint or 0x0 for ETH
  }

  mapping(uint256 => string) private _tokenCid;
  mapping(address => MintWindow) private mintWindows; // mapping of collection address to mint window
  address messageSigner = 0x5e599CA49A4fDFc0237b7185DF31bDCa9244E6E0;
  address public immutable WARM_CONTRACT_ADDRESS; // mainnet address: 0xC3AA9bc72Bd623168860a1e5c6a4530d3D80456c

  constructor(address _warmAddress) ERC721A("ForgeNft", "FORGE") {
    WARM_CONTRACT_ADDRESS = _warmAddress;
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, IERC721A) returns (bool) {
    // The interface IDs are constants representing the first 4 bytes of the XOR of
    // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
    // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
    return
      interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
      interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
      interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
  }

  /**
   * @dev Sets up a mint window for a specific time period
   * @param collectionAddress Address of the source collection for the NFTs
   * @param maxSupply Max supply of NFTs for this window
   * @param fromTimestamp UTC timestamp in seconds for when mint should open
   * @param toTimestamp  UTC timestamp in seconds for when mint should close
   * @param feeAmount Amount in gwei to charge for minting
   */
  function setMintWindow(
    address collectionAddress,
    uint256 maxSupply,
    uint256 fromTimestamp,
    uint256 toTimestamp,
    uint256 feeAmount,
    address inputCurrency
  ) public onlyOwner {
    // validate inputs
    require(
      fromTimestamp < toTimestamp,
      "From timestamp must be less than to timestamp"
    );
    require(
      toTimestamp > block.timestamp,
      "To timestamp must be in the future"
    );
    require(collectionAddress != address(0), "Invalid address");
    require(feeAmount > 0, "Fee must be greater than 0");

    // define mint window
    mintWindows[collectionAddress] = MintWindow({
      maxSupply: maxSupply,
      fromTimestamp: fromTimestamp,
      toTimestamp: toTimestamp,
      feeAmount: feeAmount,
      inputCurrency: inputCurrency
    });

    emit MintWindowUpdate(
      collectionAddress,
      maxSupply,
      fromTimestamp,
      toTimestamp,
      feeAmount,
      inputCurrency
    );
  }

  /**
   * Read mint window details for a specific collection
   * @param collectionAddress Address of the source collection for the NFTs
   */
  function getMintWindow(
    address collectionAddress
  ) public view returns (MintWindow memory) {
    return mintWindows[collectionAddress];
  }

  /**
   * @dev Pauses all minting
   */
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   * @dev Update the signer address
   * @param newAddress New signer address
   */
  function updateSigner(address newAddress) public onlyOwner {
    require(newAddress != address(0), "Invalid address");
    messageSigner = newAddress;
  }

  /**
   * @dev Mints an NFT
   * @param to Address to mint the NFT to
   * @param contractAddress Contract address for the parent NFT
   * @param tokenId Token ID of the parent NFT
   * @param cid CID of the NFT metadata
   * @param contractType Type of the parent NFT 1 = ERC721, 2 = ERC1155
   * @param signature Signature verifying the CID/CA pair
   */
  function mint(
    address to,
    address contractAddress,
    uint256 tokenId,
    string memory cid,
    uint256 contractType,
    bytes memory signature
  ) public payable whenNotPaused nonReentrant {
    MintWindow memory mintWindow = mintWindows[contractAddress];
    require(
      block.timestamp >= mintWindow.fromTimestamp,
      "Minting not open for this collection"
    );
    require(block.timestamp <= mintWindow.toTimestamp, "Minting has closed");
    require(totalSupply() + 1 <= mintWindow.maxSupply, "Max supply reached");
    // if not owner, require fee
    if (owner() != msg.sender) {
      if (mintWindow.inputCurrency != address(0)) {
        require(
          IERC20(mintWindow.inputCurrency).balanceOf(msg.sender) >=
            mintWindow.feeAmount,
          "Insufficiant funds"
        );
        IERC20(mintWindow.inputCurrency).transferFrom(
          msg.sender,
          address(this),
          mintWindow.feeAmount
        );
      } else {
        require(msg.value >= mintWindow.feeAmount, "Insufficiant funds");
      }
    }
    WarmInterface warmInstance = WarmInterface(WARM_CONTRACT_ADDRESS);
    if (contractType == 1) {
      // verify user owns the base NFT
      try IERC721(contractAddress).ownerOf(tokenId) returns (address owner) {
        require(
          owner == msg.sender ||
            warmInstance.ownerOf(contractAddress, tokenId) == msg.sender,
          "Not owner"
        );
      } catch (bytes memory) {
        revert("Not owner");
      }
    } else if (contractType == 2) {
      require(
        IERC1155(contractAddress).balanceOf(msg.sender, tokenId) >= 1 ||
          warmInstance.balanceOf(contractAddress, msg.sender, tokenId) >= 1,
        "Not owner"
      );
    } else {
      revert("Invalid contract type");
    }

    // validate signature was generated and signed by our backend
    require(
      verifySignature(contractAddress, tokenId, cid, signature),
      "Invalid signature"
    );

    // all requirements met, mint NFT and save the metadata CID
    _safeMint(to, 1);
    _tokenCid[super._nextTokenId() - 1] = cid;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    if (!_exists(tokenId))
      revert("ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = "ipfs://";
    return
      bytes(baseURI).length != 0
        ? string(
          abi.encodePacked(baseURI, _tokenCid[tokenId], "/metadata.json")
        )
        : "";
  }

  /**
   * @dev Withdraw ETH from contract
   */
  function withdrawEth() public payable onlyOwner nonReentrant {
    // withdraw total balance on contract
    (bool success, ) = payable(_msgSender()).call{value: address(this).balance}(
      ""
    );
    require(success, "Transfer failed");
  }

  /**
   * @dev Withdraw USDC from contract
   */
  function withdrawToken(address tokenAddress) public onlyOwner nonReentrant {
    // withdraw total balance on contract
    IERC20 token = IERC20(tokenAddress);
    token.approve(address(this), token.balanceOf(address(this)));
    token.safeTransferFrom(
      address(this),
      msg.sender,
      token.balanceOf(address(this))
    );
  }

  /** INTERNAL FUNCTIONS **/
  function verifySignature(
    address contractAddress,
    uint256 tokenId,
    string memory cid,
    bytes memory signature
  ) internal view returns (bool) {
    require(signature.length == 65, "Invalid signature length");
    uint8 v;
    bytes32 r;
    bytes32 s;

    (v, r, s) = splitSignature(signature);

    if (v < 27) {
      v += 27;
    }
    require(v == 27 || v == 28, "Invalid signature version");

    bytes32 payloadHash = keccak256(abi.encode(contractAddress, tokenId, cid));
    bytes32 messageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash)
    );
    return ecrecover(messageHash, v, r, s) == messageSigner;
  }

  function splitSignature(
    bytes memory _sig
  ) internal pure returns (uint8, bytes32, bytes32) {
    require(_sig.length == 65);

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      // first 32 bytes, after the length prefix
      r := mload(add(_sig, 32))
      // second 32 bytes
      s := mload(add(_sig, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }
}