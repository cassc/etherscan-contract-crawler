// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//  __  __ _______ __  __
// |  \/  |__   __|  \/  |
// | \  / |  | |  | \  / |
// | |\/| |  | |  | |\/| |
// | |  | |  | |  | |  | |
// |_|  |_|  |_|  |_|  |_|
//
// Mida Token Miner
// t.me/midatoken
// by: @korkey128k
//

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "./MTM/inc/MTMLibrary.sol";
import "./MTM/MShareCalculable.sol";

interface MIDA {
  function totalMidaMined() external view returns (uint128);
  function mineableSupply() external view returns (uint);
}

// Split it up if can (split into more nfts for sending n stuff)

contract MTM is ERC721, ReentrancyGuard, MShareCalculable {
  using { MTMLibrary.decimals, MTMLibrary.isStable, MTMLibrary.name } for address;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  address private immutable OWNER;
  MIDA private immutable _mida;

  address public constant BA_ADDRESS =
    address(0xd2dc058f4068ec0e42655F8a385Eb6333FB67ab6);

  struct _MTMVariables {
    address tokenAddress;
    uint96 requestedMPoints;
  }

  struct MTMVariables {
    uint128 tokenAmount;
    uint96 mPoints;
    address tokenAddress;
  }

  // Key: tokenId
  mapping(uint => MTMVariables) public mtmStorage;
  mapping(uint => address) public burntOwners;

  event MtmMint(uint mtmVariables, address tokenAddress, address minter, uint tokenId);

  error MTMMintIsOver();
  error InvalidTokenAddress(address tokenAddress);
  error NotOwner();

  modifier onlyOwner() {
    if (_msgSender() != OWNER) {
      revert NotOwner();
    }
    _;
  }

  constructor() ERC721("Mida Token Miner", "MTM") {
    OWNER = _msgSender();
    _mida = MIDA(OWNER);
  }

  function owner() external view returns (address) {
    return OWNER;
  }

  // @dev Get the current token amount for mSharesAmount
  // @return the total tokenAmount for this token & requestedMPoints
  function calcTokenAmt(address tokenAddress, uint requestedMPoints) public view returns(uint) {
    uint tokenDecimals = tokenAddress.decimals();
    uint oneHunderedWeiInToken = 100 * (10 ** tokenDecimals);

    uint mPointsPerOneHunderedTokens = calcMTMPoints(tokenAddress, oneHunderedWeiInToken);
    uint totalTokenAmount =
      ((requestedMPoints * oneHunderedWeiInToken) / (mPointsPerOneHunderedTokens));

    return totalTokenAmount;
  }

  // @dev Get the current M-Shares in USD (or converted from ETH) for this token & amount
  // @return the total M-Points for this token & amount
  function calcMTMPoints(address tokenAddress, uint tokenAmount) public view returns(uint) {
    if(!isTokenAvailableForMTM(tokenAddress)) {
      revert InvalidTokenAddress(tokenAddress);
    }

    uint amountUSD = _tokenToUSDPrice(tokenAddress, tokenAmount);
    uint mPoints = amountUSD / MPOINT_RATE_PER_USD;

    return mPoints;
  }

  // @dev Helper function to bulk mint MTMs
  function mint(
    _MTMVariables[] calldata _mtmVariables
  ) external payable nonReentrant {
    for(uint i; i < _mtmVariables.length;) {

      _mintSingle(_mtmVariables[i]);

      unchecked {
        i++;
      }
    }
  }

  // @dev Mint an MTM, sending the required tokens to the BA
  function _mintSingle(
    _MTMVariables calldata _mtmVariable
  ) private {
    // Check if mint is over
    if(_mtmMintIsOver()) {
      revert MTMMintIsOver();
    }

    uint tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();

    uint128 tokenAmount =
      uint128(calcTokenAmt(_mtmVariable.tokenAddress, _mtmVariable.requestedMPoints));

    mtmStorage[tokenId] = MTMVariables({
      tokenAddress: address(_mtmVariable.tokenAddress),
      tokenAmount: tokenAmount,
      mPoints: _mtmVariable.requestedMPoints
    });

    // If this is ether (address(0) for our dapp), just transfer. No erc20 action
    if(_mtmVariable.tokenAddress == address(0)) {

      (bool sent, /* bytes memory data */) = payable(BA_ADDRESS).call{value: tokenAmount}("");
      require(sent, "Failed to send ether for MTM");

    } else {

      IERC20(_mtmVariable.tokenAddress).transferFrom(
        _msgSender(), BA_ADDRESS, tokenAmount
      );

    }

    _safeMint(_msgSender(), tokenId);

    emit MtmMint(
      uint(tokenAmount) | uint(_mtmVariable.requestedMPoints) << 128,
      _mtmVariable.tokenAddress,
      _msgSender(),
      tokenId
    );
  }

  // @dev Helper function to bulk BURN MTMs.
  function bulkBurn(uint[] calldata tokenIds) external {
    for(uint i; i < tokenIds.length;) {

      burn(tokenIds[i]);

      unchecked {
        i++;
      }
    }
  }

  // @notice BURN BABY BURN! 🔥
  function burn(uint tokenId) public {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

    // This token is actually being deleted, remove the storage for gas savings
    delete mtmStorage[tokenId];

    _burn(tokenId);
  }

  // @dev Called by the Mida contract; Remove this MTM from supply
  // @notice fails silently
  function enterMine(uint tokenId) external onlyOwner {
    if(_exists(tokenId)) {
      burntOwners[tokenId] = ownerOf(tokenId);
      _burn(tokenId);
    }
  }

  // @dev Called by the Mida contract; Mint this MTM back to owner
  // @notice fails silently
  function exitMine(uint tokenId) external onlyOwner {
    if(!_exists(tokenId)) {
      _safeMint(burntOwners[tokenId], tokenId);
      delete burntOwners[tokenId];
    }
  }

  // @returns bool Has the mida total supply reached half yet?
  function _mtmMintIsOver() internal view returns(bool) {
    return _mida.totalMidaMined() > (_mida.mineableSupply() / 2);
  }

  function tokenURI(uint tokenId) public view override returns(string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    MTMVariables storage _mtmStorage = mtmStorage[tokenId];

    string memory nftUri;

    if(_mtmStorage.mPoints >= (25_000 * MSHARE_RESOLUTION)) {
      nftUri = 'ipfs://bafybeidfnk5mcpksyxfs4mzawwbnesjwner7m3lzdahfubzwkf2dyw35uy';
    } else if(_mtmStorage.mPoints >= (5_000 * MSHARE_RESOLUTION)) {
      nftUri = 'ipfs://bafybeihpwkikpgi7cqctarsdjxt33x2qvnw6oo6yvdrewua4naczleeqma';
    } else {
      nftUri = 'ipfs://bafybeiegxov7grvrpzqvaxxky2jp5zhv5a7r6xw24c7xtcsy3ihvmix3ju';
    }

    uint tokenDecimals = _mtmStorage.tokenAddress.decimals();

    string memory tokenAmountForDisplay;
    string memory tokenAmountAsString = Strings.toString(_mtmStorage.tokenAmount);
    uint tokenAmountConverted =
      _mtmStorage.tokenAmount / (10 ** tokenDecimals);

    // Is the amount below 1 if converted?
    if(tokenAmountConverted == 0) {
      uint leftJust =
        tokenDecimals - bytes(tokenAmountAsString).length;

      bytes memory zeros = new bytes(leftJust);
      for (uint j = 0; j < leftJust; j++) {
        zeros[j] = '0';
      }

      tokenAmountForDisplay =
        string(abi.encodePacked('0.', zeros, tokenAmountAsString));
    } else {
      uint tokenAmountLength = bytes(tokenAmountAsString).length;
      uint convertedLength = bytes(Strings.toString(tokenAmountConverted)).length;

      tokenAmountForDisplay =
        string(abi.encodePacked(
          Strings.toString(tokenAmountConverted),
          '.',
          _substr(tokenAmountAsString, convertedLength, tokenAmountLength)
        ));
    }

    string memory mPointsForDisplay = Strings.toString(_mtmStorage.mPoints / MSHARE_RESOLUTION);

    string memory mPointsAttribute = string(abi.encodePacked(
      '{',
        '"key": "MPoints", ',
        '"trait_type": "MPoints", ',
        '"value": "', mPointsForDisplay, '"',
      '}, '
    ));

    string memory tokenUsedAttribute = string(abi.encodePacked(
      '{',
        '"key": "Token Used to Mint", ',
        '"trait_type": "Token Used to Mint", ',
        '"value": "', _mtmStorage.tokenAddress.name(), '"',
      '}, '
    ));

    string memory tokensSpentAttribute = string(abi.encodePacked(
      '{',
        '"key": "Tokens Spent", ',
        '"trait_type": "Tokens Spent", ',
        '"value": "', tokenAmountForDisplay, '"',
      '}'
    ));

    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
      '{',
        '"name": "MTM | ', mPointsForDisplay, ' MPoints', '", ',
        '"external_url": "https://midatoken.app/mtm-mint", ',
        '"image": "', nftUri, '", ',
        '"attributes": [',
          mPointsAttribute, tokenUsedAttribute, tokensSpentAttribute,
        ']',
      '}'
    ))));
  }

  function _substr(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }
}