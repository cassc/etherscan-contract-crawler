//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ReplicatorPass is ERC721A, Ownable {
  using Strings for uint256;
  using ECDSA for bytes32;

  uint256 public constant MAX_SUPPLY = 3333;
  uint256 public constant WL_SUPPLY = 2000;
  uint256 public mintPrice = 0.03 ether;
  uint256 public MAX_PER_WALLET = 2;
  bool public isPublicSale;
  bool public isSaleActive;
  address private signer;
  address private ogSigner;
  address private receiver;
  string baseURI;
  string public extension = ".json";
  mapping(address => uint256) public mintedPerAddress;

  constructor(
    string memory baseURI_,
    address _receiver,
    address _signer,
    address _ogsigner
  ) ERC721A("Replicator Pass", "RPP") {
    baseURI = baseURI_;
    receiver = _receiver;
    signer = _signer;
    ogSigner = _ogsigner;
    _safeMint(_msgSender(), 1);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    string memory base = _baseURI();
    return string(abi.encodePacked(base, tokenId.toString(), extension));
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  function ogmint(uint256 _amount, bytes calldata proof) external payable {
    require(isSaleActive, "Sale is not started");
    require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
    require(ogSigner == verifySignature(proof), "Invalid Proff");
    require(
      mintedPerAddress[_msgSender()] + _amount <= MAX_PER_WALLET,
      "Max mint per wallet"
    );
    uint256 minted = mintedPerAddress[_msgSender()];
    if (minted > 0) {
      require(msg.value >= _amount * mintPrice, "Insufficient funds");
    } else {
      require(msg.value >= (_amount - 1) * mintPrice, "Insufficient funds");
    }

    mintedPerAddress[_msgSender()] += _amount;
    _safeMint(_msgSender(), _amount);
  }

  function wlmint(uint256 _amount, bytes calldata proof) external payable {
    require(isSaleActive, "Sale is not started");
    require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
    require(signer == verifySignature(proof), "Invalid Proff");
    require(
      mintedPerAddress[_msgSender()] + _amount <= MAX_PER_WALLET,
      "Max mint per wallet"
    );

    require(msg.value >= _amount * mintPrice, "Insufficient funds");

    mintedPerAddress[_msgSender()] += _amount;
    _safeMint(_msgSender(), _amount);
  }

  function mint(uint256 _amount) external payable {
    require(isSaleActive, "Sale is not started");
    
    if (isPublicSale) {
      require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded!");
    } else {
      require(
        totalSupply() + WL_SUPPLY + _amount <= MAX_SUPPLY,
        "Supply exceeded! WL Open"
      );
    }

    require(
      mintedPerAddress[_msgSender()] + _amount <= MAX_PER_WALLET,
      "Max mint per wallet"
    );

    require(msg.value >= _amount * mintPrice, "Insufficient funds");

    mintedPerAddress[_msgSender()] += _amount;
    _safeMint(_msgSender(), _amount);
  }

  function setMintStatus(bool _activeSale, bool _activePublic)
    external
    onlyOwner
  {
    isSaleActive = _activeSale;
    isPublicSale = _activePublic;
  }

  function verifySignature(bytes calldata signature)
    private
    view
    returns (address)
  {
    bytes32 hash = keccak256(bytes(abi.encodePacked(_msgSender())));
    address signermsg = hash.toEthSignedMessageHash().recover(signature);
    return signermsg;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(receiver).transfer(balance);
  }
}