// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import { ERC20 } from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import { Base64 } from '@openzeppelin/contracts/utils/Base64.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { BokkyPooBahsDateTimeLibrary as DateTime } from '@BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol';
import { Exit10 } from '../Exit10.sol';

contract Artwork {
  using Strings for uint256;

  Exit10 public exit10;

  struct NFTData {
    uint256 tokenID;
    uint256 bondAmount;
    uint256 claimedBLP;
    uint256 amount0;
    uint256 amount1;
    uint256 exitClaimed;
    uint64 startTime; // 8 bytes
    uint64 endTime; // 8 bytes
    uint8 status; // 1 byte
  }

  NFTData public data;

  constructor(address payable exit10_) {
    exit10 = Exit10(exit10_);
  }

  function tokenURI(uint256 _tokenID) external view returns (string memory) {
    NFTData memory nftData;
    (nftData.bondAmount, nftData.claimedBLP, nftData.startTime, nftData.endTime, nftData.status) = exit10.getBondData(
      _tokenID
    );
    nftData.tokenID = _tokenID;
    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(_getMetadataJSON(nftData)))));
  }

  function _getMetadataJSON(NFTData memory _nftData) internal view returns (bytes memory) {
    return
      abi.encodePacked(
        '{',
        '"name":"EXIT10 Bond #',
        _nftData.tokenID.toString(),
        '",',
        '"description":"EXIT10 - Automatically convert your Uniswap v3 fees into staked ETH. There is no place for weak hands on our inevitable journey to 10K.",',
        '"image":"data:image/svg+xml;base64,',
        Base64.encode(_getSVG(_nftData)),
        '}'
      );
  }

  function _getSVG(NFTData memory _nftData) internal view returns (bytes memory) {
    return
      abi.encodePacked(
        '<svg viewBox="0 0 800 1200" xmlns="http://www.w3.org/2000/svg">',
        _getSVGCard(_nftData),
        _getSVGExit10Logo(),
        _getSVGEthereumLogo(),
        _getSVGBondData(_nftData),
        '</svg>'
      );
  }

  function _getSVGCard(NFTData memory _nftData) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '<rect width="800" height="1200" rx="15" fill="#1D0D39"/>',
        '<text fill="#fff" font-family="Arial Black, Arial" font-size="60px" font-weight="800" text-anchor="middle" x="50%" y="400">ID: ',
        _nftData.tokenID.toString(),
        '</text>'
      );
  }

  function _getSVGExit10Logo() internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '<g id="Exit10-logo" transform="translate(150,150)">',
        '<path opacity="0.5" fill-rule="evenodd" clip-rule="evenodd" d="M371.585 14.572H255.009V131.148H371.585V14.572ZM265.027 86.5209L284.153 105.647L322.404 67.3953L341.53 86.5209V29.1439H284.153L303.279 48.2696L265.027 86.5209Z" fill="#5500FF"/>',
        '<path opacity="0.5" fill-rule="evenodd" clip-rule="evenodd" d="M357.013 0H240.437V116.576H357.013V0ZM265.027 86.521L284.153 105.647L322.404 67.3953L341.53 86.521V29.1439H284.153L303.279 48.2696L265.027 86.521Z" fill="#FF00AA"/>',
        '<path fill-rule="evenodd" clip-rule="evenodd" d="M460.838 103.825C482.467 103.825 500 86.6994 500 65.5738C500 44.4481 482.467 27.3224 460.838 27.3224C439.209 27.3224 421.676 44.4481 421.676 65.5738C421.676 86.6994 439.209 103.825 460.838 103.825ZM460.838 91.0747C473.413 91.0747 483.607 80.0653 483.607 66.4845C483.607 52.9037 473.413 41.8944 460.838 41.8944C448.263 41.8944 438.069 52.9037 438.069 66.4845C438.069 80.0653 448.263 91.0747 460.838 91.0747Z" fill="white"/>',
        '<path d="M394.354 102.004V43.7159H380.692V29.1439H412.569V102.004H394.354Z" fill="white"/>',
        '<path d="M190.346 102.004V43.7159H167.578V29.1439H231.33V43.7159H208.561V102.004H190.346Z" fill="white"/>',
        '<path d="M140.255 102.004V29.1439H158.47V102.004H140.255Z" fill="white"/>',
        '<path d="M79.8136 29.1439L132.969 102.004H113.265L60.1094 29.1439H79.8136Z" fill="white"/>',
        '<path d="M113.265 29.1439L60.1095 102.004H79.8137L132.969 29.1439H113.265Z" fill="white"/>',
        '<path d="M0 102.004V87.4316H52.8233V102.004H0Z" fill="white"/>',
        '<path d="M1.82129 29.1439V43.5944L51.0016 43.7159V29.1439H1.82129Z" fill="white"/>',
        '<path d="M6.375 57.3771V71.949H46.4479V57.3771H6.375Z" fill="white"/>',
        '</g>'
      );
  }

  function _getSVGEthereumLogo() internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '<g id="ethereum-logo" opacity="0.5" transform="translate(310,800)">',
        '<path d="M90.1962 0.195068L88.2295 6.86573V200.416L90.1962 202.375L180.167 149.269L90.1962 0.195068Z" fill="#343434"/>',
        '<path d="M90.1958 0.195068L0.222168 149.269L90.1958 202.375V108.431V0.195068Z" fill="#8C8C8C"/>',
        '<path d="M90.1958 219.385L89.0874 220.735V289.68L90.1958 292.911L180.222 166.306L90.1958 219.385Z" fill="#3C3C3B"/>',
        '<path d="M90.1958 292.911V219.385L0.222168 166.306L90.1958 292.911Z" fill="#8C8C8C"/>',
        '<path d="M90.1953 202.375L180.167 149.269L90.1953 108.431V202.375Z" fill="#141414"/>',
        '<path d="M0.222168 149.269L90.1958 202.375V108.431L0.222168 149.269Z" fill="#393939"/>',
        '</g>'
      );
  }

  function _getSVGBondData(NFTData memory _nftData) internal view returns (bytes memory) {
    return
      abi.encodePacked(
        '<text fill="#fff" font-family="'
        'Arial Black'
        ', Arial" font-size="40px" font-weight="800" text-anchor="middle" x="50%" y="500">BOND AMOUNT</text>',
        '<text fill="#fff" font-family="'
        'Arial Black'
        ', Arial" font-size="64px" font-weight="800" text-anchor="middle" x="50%" y="590">',
        _displayInDecimals(address(exit10.BLP()), _nftData.bondAmount * exit10.TOKEN_MULTIPLIER()),
        '</text>',
        '<text fill="#fff" font-family="'
        'Arial Black'
        ', Arial" font-size="30px" font-weight="800" text-anchor="middle" x="50%" y="700" opacity="0.6">',
        _getDate(_nftData.startTime),
        '</text>'
      );
  }

  function _getDate(uint256 _timestamp) internal pure returns (string memory) {
    (uint year, uint month, uint day, uint hour, uint minute, uint second) = DateTime.timestampToDateTime(_timestamp);
    return
      string.concat(
        _getMonthString(month),
        ' ',
        day.toString(),
        ' ',
        year.toString(),
        ' ',
        hour.toString(),
        ':',
        minute.toString(),
        ':',
        second.toString()
      );
  }

  function _getMonthString(uint256 _month) internal pure returns (string memory) {
    if (_month == 1) return 'JANUARY';
    if (_month == 2) return 'FEBRUARY';
    if (_month == 3) return 'MARCH';
    if (_month == 4) return 'APRIL';
    if (_month == 5) return 'MAY';
    if (_month == 6) return 'JUNE';
    if (_month == 7) return 'JULY';
    if (_month == 8) return 'AUGUST';
    if (_month == 9) return 'SEPTEMBER';
    if (_month == 10) return 'OCTOBER';
    if (_month == 11) return 'NOVEMBER';
    if (_month == 12) return 'DECEMBER';

    revert('SimpleArtwork: _month must be within [1, 12]');
  }

  function _displayInDecimals(address _token, uint256 _amount) internal view returns (string memory) {
    uint256 integer;
    uint256 decimal;
    uint256 decimals = 3;
    decimals = 10 ** decimals;

    integer = _amount / 10 ** ERC20(_token).decimals();
    decimal = ((_amount * decimals) / 10 ** ERC20(_token).decimals()) - (integer * decimals);
    return string.concat(Strings.toString(integer), '.', Strings.toString(decimal));
  }
}