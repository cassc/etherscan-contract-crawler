// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BlocVestNft is ERC721Enumerable, Ownable {
  using SafeERC20 for IERC20;
  using Strings for uint256;

  uint256 private totalMinted;
  string private _tokenBaseURI = "";
  string[4] public categoryNames = ["Bronze", "Silver", "Gold", "Platinum"];

  bool public mintAllowed = false;
  uint256 public onetimeMintingLimit = 40;
  address public payingToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
  uint256[4] public prices = [500 ether, 1000 ether, 2500 ether, 5000 ether];
  bool[4] public categoryMintable = [true, true, false, false];

  address public treasury = 0xBd6B80CC1ed8dd3DBB714b2c8AD8b100A7712DA7;
  uint256 public performanceFee = 0.0015 ether;

  mapping(uint256 => string) private _tokenURIs;
  mapping(uint256 => uint256) public rarities;
  mapping(address => bool) private whitelist;
  mapping(address => mapping(uint256 => bool)) private feeExcluded;

  event BaseURIUpdated(string uri);
  event MintEnabled();
  event MintDisabled();
  event SetPayingToken(address token);
  event SetSalePrices(uint256[4] prices);
  event SetOneTimeLimit(uint256 limit);
  event ServiceInfoUpadted(address treasury, uint256 fee);
  event UpdateCategoryMintable(uint256 category, bool status);
  event WhiteListUpdated(address addr, bool enabled);
  event FeeExcluded(address addr, uint256 category);
  event FeeIncluded(address addr, uint256 category);

  constructor() ERC721("BlocVest", "BVST") {}

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    require(
      !checkHoldCategory(to, rarities[tokenId]) || whitelist[to],
      "Non-tranferable more to non whitelisted address"
    );
    super._transfer(from, to, tokenId);
  }

  function mint(uint256 _category) external payable {
    require(mintAllowed, "mint was disabled");
    require(_category < 4, "invalid category");
    require(categoryMintable[_category] == true, "Cannot mint this category");
    require(!checkHoldCategory(msg.sender, _category), "already hold this card");

    _transferPerformanceFee();

    if (!feeExcluded[msg.sender][_category]) {
      uint256 amount = prices[_category];
      IERC20(payingToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    uint256 tokenId = totalMinted + 1;
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, tokenId.toString());

    rarities[tokenId] = _category;
    totalMinted = totalMinted + 1;
  }

  function setWhitelist(address _addr, bool _enabled) external onlyOwner {
    whitelist[_addr] = _enabled;
    emit WhiteListUpdated(_addr, _enabled);
  }

  function excludeFromFee(address[] memory _addrs, uint256 _category) external onlyOwner {
    require(_addrs.length <= 200, "exceed limit");

    for (uint256 i = 0; i < _addrs.length; i++) {
      feeExcluded[_addrs[i]][_category] = true;
      emit FeeExcluded(_addrs[i], _category);
    }
  }

  function includeInFee(address[] memory _addrs, uint256 _category) external onlyOwner {
    require(_addrs.length <= 200, "exceed limit");

    for (uint256 i = 0; i < _addrs.length; i++) {
      feeExcluded[_addrs[i]][_category] = false;
      emit FeeIncluded(_addrs[i], _category);
    }
  }

  function enabledMint() external onlyOwner {
    require(!mintAllowed, "already enabled");
    mintAllowed = true;
    emit MintEnabled();
  }

  function disableMint() external onlyOwner {
    require(mintAllowed, "already disabled");
    mintAllowed = false;
    emit MintDisabled();
  }

  function setCategoryMintable(uint256 _category, bool _status) external onlyOwner {
    require(_category < 4, "invalid category");
    categoryMintable[_category] = _status;
    emit UpdateCategoryMintable(_category, _status);
  }

  function setPayingToken(address _token) external onlyOwner {
    require(!mintAllowed, "mint was enabled");
    require(_token != payingToken, "same token");
    require(_token != address(0x0), "invalid token");

    payingToken = _token;
    emit SetPayingToken(_token);
  }

  function setSalePrices(uint256[4] memory _prices) external onlyOwner {
    require(!mintAllowed, "mint was enabled");
    prices = _prices;
    emit SetSalePrices(_prices);
  }

  function setOneTimeMintingLimit(uint256 _limit) external onlyOwner {
    onetimeMintingLimit = _limit;
    emit SetOneTimeLimit(_limit);
  }

  function setServiceInfo(address _addr, uint256 _fee) external {
    require(msg.sender == treasury, "setServiceInfo: FORBIDDEN");
    require(_addr != address(0x0), "Invalid address");

    treasury = _addr;
    performanceFee = _fee;

    emit ServiceInfoUpadted(_addr, _fee);
  }

  function setTokenBaseURI(string memory _uri) external onlyOwner {
    _tokenBaseURI = _uri;
    emit BaseURIUpdated(_uri);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "BlocVest: URI query for nonexistent token");

    string memory base = _baseURI();

    // If both are set, concatenate the baseURI (via abi.encodePacked).
    string memory metadata = string(
      abi.encodePacked(
        '{"name": "BlocVest NFT Card", "description": "BlocVest NFT Card #',
        tokenId.toString(),
        ': BlocVest NFT Cards are generated as a result of each individual.", "image": "',
        string(abi.encodePacked(base, categoryNames[rarities[tokenId]], ".mp4")),
        '", "attributes":[{"trait_type":"category", "value":"',
        categoryNames[rarities[tokenId]],
        '"}, {"trait_type":"number", "value":"',
        tokenId.toString(),
        '"}]}'
      )
    );

    return string(abi.encodePacked("data:application/json;base64,", _base64(bytes(metadata))));
  }

  function categoryOf(uint256 tokenId) external view returns (string memory) {
    return categoryNames[rarities[tokenId]];
  }

  function checkHoldCategory(address _user, uint256 _category) internal view returns (bool) {
    uint256 balance = balanceOf(_user);
    if (balance == 0) return false;

    for (uint256 i = 0; i < balance; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(_user, i);
      if (rarities[tokenId] == _category) return true;
    }
    return false;
  }

  function _transferPerformanceFee() internal {
    require(msg.value >= performanceFee, "should pay small gas to mint");

    payable(treasury).transfer(performanceFee);
    if (msg.value > performanceFee) {
      payable(msg.sender).transfer(msg.value - performanceFee);
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
    require(_exists(tokenId), "BlocVest: URI set of nonexistent token");
    _tokenURIs[tokenId] = _tokenURI;
  }

  function _base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }

  function rescueTokens(address _token) external onlyOwner {
    if (_token == address(0x0)) {
      uint256 _ethAmount = address(this).balance;
      payable(msg.sender).transfer(_ethAmount);
    } else {
      uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
      IERC20(_token).safeTransfer(msg.sender, _tokenAmount);
    }
  }

  receive() external payable {}
}