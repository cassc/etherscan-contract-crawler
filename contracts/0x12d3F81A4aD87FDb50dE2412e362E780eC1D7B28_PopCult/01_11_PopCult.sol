//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PopCult is ERC721AQueryable, Ownable, Pausable {
  using Strings for uint256;

  uint256 public maxSupply = 10000;
  string private baseURI = "";
  string private baseExtension = ".json";

  uint256 public publicEtherCost = 0.2 ether;
  uint256 public publicUSDCCost = 275;

  uint256 public whitelistEtherCost = 0.1 ether;
  uint256 public whitelistUSDCCost = 192;

  bytes32 public whitelistMerkleRoot;
  uint256 public maxWhitelistTokens = 1500;
  uint256 public whitelistTokenCount = 0;

  IERC20 public usdcAddress;
  address public treasuryWallet;

  bool public isWhitelistSaleOpen = false;
  bool public isPublicSaleOpen = false;

  mapping(address => uint256) public whitelistMintCounts;
  mapping(address => uint256) public publicMintCounts;

  uint256 public maxWhitelistPerWallet = 5;
  uint256 public maxPublicPerWallet = 10;

  bool public isRevealed;
  string public unRevealedMetadataURL;

  constructor(address _usdcAddress, address _treasuryWallet)
    ERC721A("PopCult", "POPC")
  {
    usdcAddress = IERC20(_usdcAddress);
    treasuryWallet = _treasuryWallet;
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
      MerkleProof.verify(
        merkleProof,
        root,
        keccak256(abi.encodePacked(msg.sender))
      ),
      "Address does not exist in list"
    );
    _;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded");
    require(tx.origin == msg.sender, "The caller is another contract");

    if (isWhitelistSaleOpen) {
      require(
        whitelistMintCounts[msg.sender] + _mintAmount <= maxWhitelistPerWallet,
        "Invalid mint amount!"
      );
    }

    if (isPublicSaleOpen) {
      require(
        publicMintCounts[msg.sender] + _mintAmount <= maxPublicPerWallet,
        "Invalid mint amount!"
      );
    }
    _;
  }

  function whitelistMint(
    uint256 _mintAmount,
    bool _isUSDC,
    bytes32[] calldata merkleProof
  )
    external
    payable
    whenNotPaused
    mintCompliance(_mintAmount)
    isValidMerkleProof(merkleProof, whitelistMerkleRoot)
  {
    require(isWhitelistSaleOpen, "The whitelist sale is not enabled!");
    require(
      whitelistTokenCount + _mintAmount <= maxWhitelistTokens,
      "Max whitelist tokens exceeded"
    );

    if (_isUSDC == true) {
      usdcAddress.transferFrom(
        msg.sender,
        treasuryWallet,
        (_mintAmount * (whitelistUSDCCost * 10**6))
      );
    } else {
      require(
        msg.value >= (whitelistEtherCost * _mintAmount),
        "Not enough ether!"
      );
      (bool os, ) = payable(treasuryWallet).call{value: address(this).balance}(
        ""
      );
    }

    _mint(msg.sender, _mintAmount);
    whitelistMintCounts[msg.sender] += _mintAmount;
    whitelistTokenCount += _mintAmount;
  }

  function publicMint(uint256 _mintAmount, bool _isUSDC)
    external
    payable
    whenNotPaused
    mintCompliance(_mintAmount)
  {
    require(isPublicSaleOpen, "The public sale is not open!");

    if (_isUSDC == true) {
      usdcAddress.transferFrom(
        msg.sender,
        treasuryWallet,
        (_mintAmount * (publicUSDCCost * 10**6))
      );
    } else {
      require(
        msg.value >= (publicEtherCost * _mintAmount),
        "Not enough ether!"
      );
      (bool os, ) = payable(treasuryWallet).call{value: address(this).balance}(
        ""
      );
    }

    _mint(msg.sender, _mintAmount);
    publicMintCounts[msg.sender] += _mintAmount;
  }

  function mintTo(address to, uint256 _mintAmount) external onlyOwner {
    require(_mintAmount > 0, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded");

    _mint(to, _mintAmount);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setUnRevealedMetadataURL(string memory _unRevealedMetadataURL)
    external
    onlyOwner
  {
    unRevealedMetadataURL = _unRevealedMetadataURL;
  }

  function toggleReveal() external onlyOwner {
    isRevealed = !isRevealed;
  }

  function setTreasuryWallet(address _treasuryWallet) public onlyOwner {
    treasuryWallet = _treasuryWallet;
  }

  function setPublicEtherCost(uint256 _etherCost) public onlyOwner {
    publicEtherCost = _etherCost;
  }

  function setPublicUSDCCost(uint256 _usdcCost) public onlyOwner {
    publicUSDCCost = _usdcCost;
  }

  function setMaxPublicPerWallet(uint256 _max) public onlyOwner {
    maxPublicPerWallet = _max;
  }

  function toggleWhitelistSale() public onlyOwner {
    isWhitelistSaleOpen = !isWhitelistSaleOpen;
  }

  function togglePublicSale() public onlyOwner {
    isPublicSaleOpen = !isPublicSaleOpen;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  // following 6 functions are called to start a new phase in the WL mint.

  function setWhiteListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    whitelistMerkleRoot = merkleRoot;
  }

  function clearWhitelistCounter() public onlyOwner {
    whitelistTokenCount = 0;
  }

  function setMaxWhitelistTokens(uint256 _maxWhitelistTokens) public onlyOwner {
    maxWhitelistTokens = _maxWhitelistTokens;
  }

  function setWhitelistEtherCost(uint256 _etherCost) public onlyOwner {
    whitelistEtherCost = _etherCost;
  }

  function setWhitelistUSDCCost(uint256 _usdcCost) public onlyOwner {
    whitelistUSDCCost = _usdcCost;
  }

  function setMaxWhitelistPerWallet(uint256 _max) public onlyOwner {
    maxWhitelistPerWallet = _max;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721AMetadata: URI query for nonexistent token"
    );

    if (!isRevealed) {
      return unRevealedMetadataURL;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension)
        )
        : "";
  }

  function withdraw() external onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}