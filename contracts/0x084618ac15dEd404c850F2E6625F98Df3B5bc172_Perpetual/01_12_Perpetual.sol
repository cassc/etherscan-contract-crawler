// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Admin.sol";

// ♺

// Perpetual
// 0xG

contract Perpetual is ERC721, IERC721Receiver, Admin {
  uint tokenId;

  address public editionFrom;
  uint    public editionFromNo;
  uint    public editionNo;
  mapping(address => uint)  public editionSupply;
  mapping(uint => string[]) public editionUri;

  mapping(uint => string) _tokenUri;

  mapping(uint => uint) public tokenIdToEditionNo;
  mapping(uint => bool) public unlockedToken;

  uint    public pValue;
  address public pToken;
  address pRecipient;
  address auth;

  mapping(uint => uint) public royalties;

  constructor() ERC721("Perpetual", "PTVL") {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return (
      interfaceId == type(IERC721Receiver).interfaceId ||
      interfaceId == /* EIP2981 */ 0x2a55205a ||
      super.supportsInterface(interfaceId)
    );
  }

  function mint(address to, uint editionNo) external adminOnly {
    _mintToken(to, editionNo);
  }

  function mint(bytes calldata data) external payable {
    require(address(0) == editionFrom, "Cannot mint this edition");
    require(editionSupply[editionFrom] > 0, "No tokens left");
    if (auth != address(0)) {
      _auth(data, msg.sender);
    }
    if (pValue > 0) {
      require(pRecipient != address(0), "Invalid pRecipient");
      if (pToken == address(0)) {
        require(msg.value == pValue, "Invalid ETH amount");
        _fwd();
      } else {
        require(
          IERC20(pToken).transferFrom(msg.sender, pRecipient, pValue),
          "Payment failed"
        );
      }
    }
    editionSupply[editionFrom] -= 1;
    _mintToken(msg.sender, editionNo);
  }

  function mint(uint fromTokenId, bytes calldata data) external payable {
    require(msg.sender == ERC721.ownerOf(fromTokenId), "Unauthorized");
    if (auth != address(0)) {
      _auth(data, msg.sender);
    }
    _mintTokenFrom(address(this), fromTokenId, msg.sender);
  }

  function onERC721Received(
    address,
    address to,
    uint256 fromTokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    require(msg.sender != address(this), "Invalid edition source");
    if (auth != address(0)) {
      _auth(data, to);
    }
    _mintTokenFrom(msg.sender, fromTokenId, to);
    return this.onERC721Received.selector;
  }

  function _mintToken(address to, uint editionNo) internal virtual {
    tokenId += 1;
    _mint(to, tokenId);
    tokenIdToEditionNo[tokenId] = editionNo;
    _tokenUri[tokenId] = editionUri[editionNo][0];
  }

  function _mintTokenFrom(address fromContract, uint fromTokenId, address to) internal virtual {
    require(editionFrom == fromContract, "Invalid edition source");
    require(
      editionFromNo == 0 ||
      tokenIdToEditionNo[fromTokenId] == editionFromNo,
      "Cannot burn this token"
    );
    require(editionSupply[fromContract] > 0, "No tokens left");
    editionSupply[fromContract] -= 1;

    if (pValue > 0) {
      require(pRecipient != address(0), "Invalid pRecipient");
      if (pToken == address(0)) {
        require(msg.value == pValue, "Invalid ETH amount");
        _fwd();
      } else {
        require(
          IERC20(pToken).transferFrom(to, pRecipient, pValue),
          "Payment failed"
        );
      }
    }

    bool isExternal = fromContract != address(this);

    if (isExternal) {
      try IBurnable(fromContract).burn(fromTokenId) {}
      catch {
        IBurnable(fromContract).transferFrom(address(this), address(0xdEaD), fromTokenId);
      }
    } else {
      require(unlockedToken[fromTokenId], "Token locked");
      unlockedToken[fromTokenId] = false;
      tokenIdToEditionNo[fromTokenId] = 0;
      _tokenUri[fromTokenId] = "";
      _burn(fromTokenId);
    }

    _mintToken(to, editionNo);
  }

  function burn(uint tokenId) external {
    require(msg.sender == ERC721.ownerOf(tokenId), "Unauthorized");
    unlockedToken[tokenId] = false;
    tokenIdToEditionNo[tokenId] = 0;
    _tokenUri[tokenId] = "";
    _burn(tokenId);
  }

  function unlock(uint tokenId) external {
    require(msg.sender == ERC721.ownerOf(tokenId), "Unauthorized");
    unlockedToken[tokenId] = true;
    _tokenUri[tokenId] = editionUri[tokenIdToEditionNo[tokenId]][1];
  }

  function configureEdition(
    address editionFrom_,
    uint editionFromNo_,
    uint editionNo_,
    uint supply,
    string[] memory uris
  ) external adminOnly {
    if (pValue > 0 && editionFrom_ != address(0) && editionFrom_ != address(this)) {
      require(
        pToken != address(0),
        "pToken for burn to mint tokens must be an ERC20 address"
      );
    }

    if (editionSupply[editionFrom] > 0) {
      editionSupply[editionFrom] = 0;
    }

    editionFrom = editionFrom_;
    require(editionFromNo_ == 0 || editionFrom_ == address(this), "External tokens cannot define an editionFromNo");
    editionFromNo = editionFromNo_;
    editionNo = editionNo_;
    editionSupply[editionFrom_] = supply;

    if (uris.length == 2) {
      editionUri[editionNo] = uris;
    }
  }

  function setUris(uint editionNo, string[] memory uris) external adminOnly {
    require(uris.length == 2, "Invalid uris");
    editionUri[editionNo] = uris;
  }

  function updateUri(uint tokenId) external {
    require(msg.sender == ERC721.ownerOf(tokenId), "Unauthorized");
    _tokenUri[tokenId] = editionUri[tokenIdToEditionNo[tokenId]][unlockedToken[tokenId] ? 1 : 0];
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    return _tokenUri[tokenId];
  }

  function setRoyalties(uint[] calldata tokenIds, uint value) external adminOnly {
    if (tokenIds.length == 1) {
      royalties[tokenIds[0]] = value;
    } else {
      for (uint i; i < tokenIds.length; i++) {
        royalties[tokenIds[i]] = value;
      }
    }
  }

  function royaltyInfo(uint tokenId, uint value) external view returns (address receiver, uint royaltyAmount) {
    uint tokenRoyalties = royalties[tokenId];
    if (tokenRoyalties == 1 || royalties[0] == 0 || pRecipient == address(0)) {
      return (address(0), 0);
    }
    if (tokenRoyalties == 0) {
      tokenRoyalties = royalties[0];
    }
    return (pRecipient, value * tokenRoyalties / 10000);
  }

  function setP(uint pValue_, address pToken_, address pRecipient_) external adminOnly {
    pValue = pValue_;
    pToken = pToken_;
    pRecipient = pRecipient_;
  }

  function setP(uint pValue_, address pToken_) external adminOnly {
    pValue = pValue_;
    pToken = pToken_;
  }

  function setP(address pRecipient_) external adminOnly {
    pRecipient = pRecipient_;
  }

  function _fwd() internal {
    (bool sent,) = pRecipient.call{value: msg.value}("");
    require(sent, "Failed to send ETH");
  }

  function setAuth(address auth_) external adminOnly {
    auth = auth_;
  }

  mapping(bytes32 => bool) _a;
  function _auth(bytes calldata data, address sender) internal {
    bytes32 hash = keccak256(data);
    require(_a[hash] == false, "Unauthorized");
    require(data.length > 1, "Invalid data");
    (bytes32 claims, bytes memory signature) = abi.decode(data, (bytes32, bytes));
    require(
      ECDSA.recover(
        keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(address(this), sender, claims))
          )
        ),
        signature
      ) == auth,
      "Unauthorized"
    );
    _a[hash] = true;
  }
}

interface IBurnable {
  function burn(uint tokenId) external;
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}