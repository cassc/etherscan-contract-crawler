// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IDroidInvaders {
  function ownerOf(uint256 tokenId) external returns (address);

  function batchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds
  ) external;
}

interface INanoTechChips {
  function burn(address _from, uint256 _amount) external;
}

contract Exovaders is ERC721A, ERC721AQueryable, Ownable {
  uint256 public constant PRICE = 0.055 ether;
  uint256 public constant MAX_SUPPLY = 5500;
  uint256 public constant MAX_PUBLIC_SUPPLY = 3000;
  uint256 public constant MAX_MINT_PER_WALLET = 2;

  uint256 public fusionSupply = 0;
  uint256 public publicSupply = 0;

  string public tokenBaseUri = "ipfs://QmSWVgwjoHH9uTJdDLhKJh82WX3pJGetfur3PQufeTiWTn/?";

  bool public paused = true;
  bool public publicSale = false;
  bool public finalSale = false;

  address private verifier;

  mapping(uint256 => bool) public usedApe;
  mapping(address => uint256) public walletCount;

  IDroidInvaders private immutable droidInvaders;
  INanoTechChips private immutable nanoTechChips;

  constructor(address _droidInvadersContract, address _nanoTechChipsContract)
    ERC721A("Exovaders", "EXO")
  {
    droidInvaders = IDroidInvaders(_droidInvadersContract);
    nanoTechChips = INanoTechChips(_nanoTechChipsContract);
  }

  function mint(uint256 _quantity, bytes memory _signature) external payable {
    require(!paused, "Minting paused");

    address signer = _validateMint(msg.sender, _signature);

    require(signer == verifier, "Invalid signature");

    if (!finalSale) {
      require(
        publicSupply + _quantity <= MAX_PUBLIC_SUPPLY,
        "Excedes max supply"
      );

      publicSupply += _quantity;
    } else {
      require(totalSupply() + _quantity <= MAX_SUPPLY, "Excedes max supply");
    }

    if (!publicSale) {
      require(
        walletCount[msg.sender] + _quantity <= MAX_MINT_PER_WALLET,
        "Max mint per wallet reached"
      );

      walletCount[msg.sender] += _quantity;
    }

    require(_quantity * PRICE == msg.value, "Ether sent is not correct");

    _mint(msg.sender, _quantity);
  }

  function fusion(
    uint256 _apeId,
    uint256[] calldata _droidIds,
    bytes memory _signature
  ) external payable {
    require(!paused, "Fusion paused");
    require(totalSupply() < MAX_SUPPLY, "Excedes max supply");
    require(!usedApe[_apeId], "Ape already used");

    address signer = _validateFusion(msg.sender, _apeId, _droidIds, _signature);

    require(signer == verifier, "Invalid signature");

    for (uint256 i; i < _droidIds.length; ++i) {
      require(
        droidInvaders.ownerOf(_droidIds[i]) == msg.sender,
        "Not Droid owner"
      );
    }

    usedApe[_apeId] = true;

    nanoTechChips.burn(msg.sender, 1);

    droidInvaders.batchTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, _droidIds);

    _mint(msg.sender, 1);
  }

  function _validateMint(address _wallet, bytes memory _signature)
    internal
    pure
    returns (address)
  {
    return
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_wallet))),
        _signature
      );
  }

  function _validateFusion(
    address _wallet,
    uint256 _apeId,
    uint256[] calldata _droidIds,
    bytes memory _signature
  ) internal pure returns (address) {
    return
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(abi.encodePacked(_wallet, _apeId, _droidIds))
        ),
        _signature
      );
  }

  function _baseURI() internal view override returns (string memory) {
    return tokenBaseUri;
  }

  function usedApes(uint256[] calldata _apeIds)
    external
    view
    returns (bool[] memory)
  {
    bool[] memory areUsed = new bool[](_apeIds.length);

    for (uint256 i = 0; i < _apeIds.length; ++i) {
      areUsed[i] = usedApe[_apeIds[i]];
    }

    return areUsed;
  }

  function setBaseURI(string calldata _newBaseUri) external onlyOwner {
    tokenBaseUri = _newBaseUri;
  }

  function setVerifier(address _newVerifier) public onlyOwner {
    verifier = _newVerifier;
  }

  function flipSale() external onlyOwner {
    paused = !paused;
  }

  function flipPublicSale() external onlyOwner {
    publicSale = !publicSale;
  }

  function flipFinalSale() external onlyOwner {
    finalSale = !finalSale;
  }

  function collectInitial() external onlyOwner {
    require(totalSupply() == 0, "Already collected");

    _mint(msg.sender, 15);
  }

  function collectRemaining() external onlyOwner {
    require(totalSupply() < MAX_SUPPLY, "Excedes max supply");

    _mint(msg.sender, MAX_SUPPLY - totalSupply());
  }

  function withdraw() public onlyOwner {
    require(
      payable(owner()).send(address(this).balance),
      "Withdraw unsuccessful"
    );
  }
}