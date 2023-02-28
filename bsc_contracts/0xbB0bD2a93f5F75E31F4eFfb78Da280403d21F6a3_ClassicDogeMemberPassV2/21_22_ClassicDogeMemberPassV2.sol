// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./oracle/interfaces/IPriceOracle.sol";

contract ClassicDogeMemberPassV2 is
  Ownable,
  Pausable,
  ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  ERC721Burnable
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

  mapping(uint256 => uint256) public memberPassLevel; // tokenID -> member level
  mapping(uint256 => uint256) public mintedTimestamp; // tokenID -> minted timestamp

  mapping(address => mapping(uint256 => uint256)) public memberPassBalanceOf; // address -> member level -> balance

  string[] public uriPool;
  uint256[] public mintPrice;
  uint256[] public whitelistMintPrice;

  uint256 public totalSupplyLimit = 1000;
  uint256 public maxAmountPerAddress = 5;

  string private _name;
  string private _symbol;
  bool public mintStarted = false;
  bool public preventTransferMaxLimit = false;

  address public buyTokenAddress;
  address public priceOracle;

  constructor(
    string memory name_,
    string memory symbol_
  ) public ERC721(name_, symbol_) {}

  receive() external payable {}

  modifier mintStartedOnly() {
    require(mintStarted == true, "Mint not started yet!");
    _;
  }

  modifier validMemberLevel(uint256 _level) {
    require(_level > 0, "Invalid member level 0");
    require(_level <= uriPool.length, "Invalid member level uri");
    _;
  }

  modifier validMintAmountWithLevel(uint256 _amount, uint256 _memberLevel) {
    require(_amount > 0, "Invalid mint amount 0");
    require(
      totalSupply() + _amount <= totalSupplyLimit,
      "Maximum mint limit reached"
    );
    require(
      memberPassBalanceOf[msg.sender][_memberLevel] + _amount <=
        maxAmountPerAddress,
      "NFT: Max mint amount per user exceeded"
    );
    _;
  }

  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string(abi.encodePacked("", uriPool[memberPassLevel[tokenId]]));
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    memberPassLevel[tokenId] = 0;
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchAmount
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    uint256 _memberPassLevelOfToken = memberPassLevel[tokenId];
    if (from == address(0)) {
      memberPassBalanceOf[to][_memberPassLevelOfToken] += batchAmount;
    } else if (to == address(0)) {
      memberPassBalanceOf[from][_memberPassLevelOfToken] -= batchAmount;
    } else {
      memberPassBalanceOf[from][_memberPassLevelOfToken] -= batchAmount;
      memberPassBalanceOf[to][_memberPassLevelOfToken] += batchAmount;
    }
    if (preventTransferMaxLimit == true) {
      require(
        memberPassBalanceOf[to][_memberPassLevelOfToken] <= maxAmountPerAddress,
        "NFT: Max holdable amount per user exceeded"
      );
    }

    super._beforeTokenTransfer(from, to, tokenId, batchAmount);
  }

  function internalMint(address to, uint256 memberLevel) internal {
    _tokenIdCounter.increment();
    uint256 mintTokenId = _tokenIdCounter.current();
    memberPassLevel[mintTokenId] = memberLevel;
    mintedTimestamp[mintTokenId] = block.timestamp;
    _safeMint(to, mintTokenId);
  }

  function isNativeToken(address _address) public pure returns (bool) {
    return _address == WETH;
  }

  function getMintPrice(
    address _buyToken,
    uint256 _costUSD
  ) public view returns (uint256) {
    return ((_costUSD * 1e8) /
      IPriceOracle(priceOracle).getUnderlyingPrice(_buyToken));
  }

  function processCost(
    address _user,
    uint256 _txValue,
    uint256 _mintCostUSD
  ) internal {
    uint256 _mintCost = getMintPrice(buyTokenAddress, _mintCostUSD);
    if (isNativeToken(buyTokenAddress)) {
      if (_txValue < _mintCost) {
        revert("NFT: Insufficient mint fees!");
      } else if (_txValue > _mintCost) {
        payable(_user).transfer(_txValue - _mintCost);
      }
    } else {
      if (_txValue > 0) {
        payable(_user).transfer(_txValue);
      }
      SafeERC20.safeTransferFrom(
        IERC20(buyTokenAddress),
        _user,
        address(this),
        _mintCost
      );
    }
  }

  function mintNFT(
    uint256 amount,
    uint256 memberLevel
  )
    public
    payable
    mintStartedOnly
    validMemberLevel(memberLevel)
    validMintAmountWithLevel(amount, memberLevel)
  {
    require(mintPrice.length > 0, "NFT: Mint price not set yet!");
    uint256 _mintCost = mintPrice[memberLevel] * amount;
    address _user = msg.sender;
    uint256 _txValue = msg.value;
    processCost(_user, _txValue, _mintCost);
    for (uint256 i = 0; i < amount; i++) {
      internalMint(_user, memberLevel);
    }
  }

  function whitelistMintNFT(
    uint256 amount,
    uint256 memberLevel
  )
    public
    payable
    mintStartedOnly
    validMemberLevel(memberLevel)
    validMintAmountWithLevel(amount, memberLevel)
  {
    require(balanceOf(msg.sender) > 0, "NFT: Account is not whitelisted!");
    require(
      whitelistMintPrice.length > 0,
      "NFT: Whitelist mint price not set yet!"
    );
    uint256 _mintCost = whitelistMintPrice[memberLevel] * amount;
    address _user = msg.sender;
    uint256 _txValue = msg.value;
    processCost(_user, _txValue, _mintCost);
    for (uint256 i = 0; i < amount; i++) {
      internalMint(_user, memberLevel);
    }
  }

  function ownerMintNFT(
    uint256 amount,
    uint256 memberLevel
  ) public onlyOwner mintStartedOnly validMemberLevel(memberLevel) {
    for (uint256 i = 0; i < amount; i++) {
      internalMint(msg.sender, memberLevel);
    }
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function toggleMint() public onlyOwner {
    mintStarted = !mintStarted;
  }

  function togglePreventTransferMaxLimit() public onlyOwner {
    preventTransferMaxLimit = !preventTransferMaxLimit;
  }

  function setUriPool(string[] memory _uriPoolData) public onlyOwner {
    delete uriPool;
    uint256 length = _uriPoolData.length;
    for (uint256 i = 0; i < length; i++) {
      uriPool.push(_uriPoolData[i]);
    }
  }

  function setMintPrice(uint256[] memory _mintPrice) public onlyOwner {
    delete mintPrice;
    uint256 length = _mintPrice.length;
    for (uint256 i = 0; i < length; i++) {
      mintPrice.push(_mintPrice[i]);
    }
  }

  function setPriceOracle(address _priceOracle) external onlyOwner {
    priceOracle = _priceOracle;
  }

  function setWhitelistMintPrice(
    uint256[] memory _whitelistMintPrice
  ) external onlyOwner {
    delete whitelistMintPrice;
    uint256 length = _whitelistMintPrice.length;
    for (uint256 i = 0; i < length; i++) {
      whitelistMintPrice.push(_whitelistMintPrice[i]);
    }
  }

  function setBuyTokenAddress(address _buyTokenAddress) public onlyOwner {
    buyTokenAddress = _buyTokenAddress;
  }

  function setMaxAmountPerAddress(
    uint256 _maxAmountPerAddress
  ) public onlyOwner {
    maxAmountPerAddress = _maxAmountPerAddress;
  }

  function setTotalSupplyLimit(uint256 _totalSupplyLimit) public onlyOwner {
    totalSupplyLimit = _totalSupplyLimit;
  }

  // ------------------------------------------------------------------------
  // Function to Withdraw Coins sent by mistake to the Token Contract Address.
  // Only the Contract owner can withdraw the Coins.
  // ------------------------------------------------------------------------
  function withdrawCoins() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  // ------------------------------------------------------------------------
  // Function to Withdraw Tokens sent by mistake to the Token Contract Address.
  // Only the Contract owner can withdraw the Tokens.
  // ------------------------------------------------------------------------
  function withdrawTokens(
    address tokenAddress,
    uint256 tokenAmount
  ) public virtual onlyOwner {
    SafeERC20.safeTransfer(IERC20(tokenAddress), msg.sender, tokenAmount);
  }
}