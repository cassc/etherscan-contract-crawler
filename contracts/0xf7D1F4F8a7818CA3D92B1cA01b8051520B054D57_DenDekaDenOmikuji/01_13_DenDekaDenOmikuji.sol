// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;
/* 
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@............[email protected]@
* @@@............[email protected]@
* @@@@........................................................................*@@@
* @@@@@.......[email protected]@@@@
* @@@@@@#....[email protected]@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@*[email protected]@@@@@@@[email protected]@@@@@@@%[email protected]@@@@@@@@@@@
* @@@@@@@@@@@@@..............%@@@@@@@[email protected]@@@@@@,[email protected]@@@@@@@@@@@
* @@@@@@@@@@@@@@[email protected]@@@@@@&............/@@@@@@@............/@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@[email protected]@@@@@@*[email protected]@@@@@@@............*@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@.......,@@@@@@@[email protected]@@@@@@%............(@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@............/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@%...............................,@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,............/@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(............%@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@............,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(............%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@([email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.... @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 電殿神伝 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ DenDekaDen @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Do you believe? @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ JD & BH @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract DenDekaDenOmikuji is Ownable, ERC721 { 
  // Libraries
  using Strings for uint256;

  // For random attribute, use:
  // tokenId, timestamp, and donation amount
  struct TraitSeeds {
    uint256 timestamp;
    // how much was donated during mint -- used for better probabilities
    uint256 donationAmount;
  }

  // CONSTANTS
  uint8 constant NUM_CHARACTERS = 7;
  uint16 constant OMIKUJI_PER_CHARACTER = 108;

  // 0.07ETH is donation boost!
  // If you donate 0.07ETH or greater, your luck probabilities are boosted!
  uint256 constant DONATION_BOOST_THRESHOLD = 70000000000000000;

  /******* MINTING DATA *******/

  // track omikuji minter per character
  uint8[NUM_CHARACTERS] ascendingCharacterMints;
  // need to track team mints too
  uint8[NUM_CHARACTERS] descendingCharacterMints;


  // track GODLY tokenId for each character
  // IMPORTANT: defaults to 0 so NO TOKEN should have id of 0
  uint256[NUM_CHARACTERS] public godlyTokens;

  // storage of seeds for calculating traits
  mapping(uint256 /* tokenId */ => TraitSeeds) tokenTraitSeeds;

  // record ifa wallet has already minted a character
  mapping(address => mapping(uint8 /* characterId */ => uint256)) addressCharacterMints;

  // WHITELIST props
  bytes32 whitelistMerkleRoot;
  // JAPAN 2023-01-01 00:00:00 TIMESTAMP
  uint256 whitelistMintStartTime = 1672498800;
  // JAPAN 2023-01-01 07:30:00 TIMESTAMP
  uint256 mainMintStartTime = 1672525800;
  // whitelist mint records
  mapping(address /* user */ => bool) whitelistAddressMints;
  // team mint merkle root
  bytes32 teamMerkleRoot;
  // Team mints capped at 35
  uint256 teamMintsRemaining = 35;

  /******* ATTRIBUTE PROBABILITIES *********/

  // base attributes do not include "very good"
  uint8[] baseAttributeProbabilities = [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3];

  // special attribute probabilities includes "very good"
  uint8[] specialAttributeProbabilities = [0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4];

  // Very good most likely, then great, then good -- godly boosted on mint
  uint8[] boostAttributeProbabilities = [2, 3, 3, 3, 3, 4, 4, 4];

  // METADATA PROPS
  string _baseImgUri = "https://dendekaden.s3.ap-northeast-1.amazonaws.com/";
  bool _imgUriLocked = false;
  string constant DESCRIPTION = 'Sacred lots drawn by the First Believers, and held by the most ardent Devotees of ';
  string constant EXTERNAL_URL = 'https://www.dendekaden.com/';
  string[] fortuneCategories = [
    '2. LOVE',
    '3. BENEFACTOR',
    '4. BUSINESS',
    '5. ACADEMICS',
    '6. DISPUTES',
    '7. TRAVEL',
    '8. HEALTH',
    '9. WISH'
  ];
 
  string[] characterNames = [
    // 吉祥天
    'Megna',
    // 弁財天
    'Bene',
    // 大黒天
    'Yoa',
    // 恵比寿こひる
    'Kohiru',
    // 毘沙門天
    'Hisato',
    // 布袋
    'Taylor',
    // 寿老人
    'Momo'
  ];

  string[][] fortuneValues = [
    // LOVE
    [
      // 告白しらく待て
      '\xe5\x91\x8a\xe7\x99\xbd\xe3\x81\x97\xe3\x81\xb0\xe3\x82\x89\xe3\x81\x8f\xe5\xbe\x85\xe3\x81\xa6',
      // 今叶わずとも縁あり
      '\xe4\xbb\x8a\xe5\x8f\xb6\xe3\x82\x8f\xe3\x81\x9a\xe3\x81\xa8\xe3\x82\x82\xe7\xb8\x81\xe3\x81\x82\xe3\x82\x8a',
      // 歳に囚われる必要なし
      '\xe6\xad\xb3\xe3\x81\xab\xe5\x9b\x9a\xe3\x82\x8f\xe3\x82\x8c\xe3\x82\x8b\xe5\xbf\x85\xe8\xa6\x81\xe3\x81\xaa\xe3\x81\x97',
      // 良い人既に近くに
      '\xe8\x89\xaf\xe3\x81\x84\xe4\xba\xba\xe6\x97\xa2\xe3\x81\xab\xe8\xbf\x91\xe3\x81\x8f\xe3\x81\xab'
    ],
    // BENEFACTOR
    [
      // たよりなし
      '\xe3\x81\x9f\xe3\x82\x88\xe3\x82\x8a\xe3\x81\xaa\xe3\x81\x97',
      // 来るとも遅し 往きて利あり
      '\xe6\x9d\xa5\xe3\x82\x8b\xe3\x81\xa8\xe3\x82\x82\xe9\x81\x85\xe3\x81\x97\x20\xe5\xbe\x80\xe3\x81\x8d\xe3\x81\xa6\xe5\x88\xa9\xe3\x81\x82\xe3\x82\x8a',
      // 来る
      '\xe6\x9d\xa5\xe3\x82\x8b',
      // 来たる つれあり
      '\xe6\x9d\xa5\xe3\x81\x9f\xe3\x82\x8b\x20\xe3\x81\xa4\xe3\x82\x8c\xe3\x81\x82\xe3\x82\x8a'
    ],
    // BUSINESS
    [
      // 堅実さを取り戻せ
      '\xe5\xa0\x85\xe5\xae\x9f\xe3\x81\x95\xe3\x82\x92\xe5\x8f\x96\xe3\x82\x8a\xe6\x88\xbb\xe3\x81\x9b',
      // 利益少し焦るな　後になれば益あり
      '\xe5\x88\xa9\xe7\x9b\x8a\xe5\xb0\x91\xe3\x81\x97\xe7\x84\xa6\xe3\x82\x8b\xe3\x81\xaa\xe3\x80\x80\xe5\xbe\x8c\xe3\x81\xab\xe3\x81\xaa\xe3\x82\x8c\xe3\x81\xb0\xe7\x9b\x8a\xe3\x81\x82\xe3\x82\x8a',
      // 利益たしかなり
      '\xe5\x88\xa9\xe7\x9b\x8a\xe3\x81\x9f\xe3\x81\x97\xe3\x81\x8b\xe3\x81\xaa\xe3\x82\x8a',
      // 十分幸福
      '\xe5\x8d\x81\xe5\x88\x86\xe5\xb9\xb8\xe7\xa6\x8f'
    ],
    // ACADEMICS
    [
      // 今回は諦め切り替えるべし
      '\xe4\xbb\x8a\xe5\x9b\x9e\xe3\x81\xaf\xe8\xab\xa6\xe3\x82\x81\xe5\x88\x87\xe3\x82\x8a\xe6\x9b\xbf\xe3\x81\x88\xe3\x82\x8b\xe3\x81\xb9\xe3\x81\x97',
      // 伸びる時努力せよ
      '\xe4\xbc\xb8\xe3\x81\xb3\xe3\x82\x8b\xe6\x99\x82\xe5\x8a\xaa\xe5\x8a\x9b\xe3\x81\x9b\xe3\x82\x88',
      // 努力しただけ力になる
      '\xe5\x8a\xaa\xe5\x8a\x9b\xe3\x81\x97\xe3\x81\x9f\xe3\x81\xa0\xe3\x81\x91\xe5\x8a\x9b\xe3\x81\xab\xe3\x81\xaa\xe3\x82\x8b',
      // 歩み遅くとも着実に実る
      '\xe6\xad\xa9\xe3\x81\xbf\xe9\x81\x85\xe3\x81\x8f\xe3\x81\xa8\xe3\x82\x82\xe7\x9d\x80\xe5\xae\x9f\xe3\x81\xab\xe5\xae\x9f\xe3\x82\x8b'
    ],
    // DISPUTES
    [
      // 争いごと負けなり
      '\xe4\xba\x89\xe3\x81\x84\xe3\x81\x94\xe3\x81\xa8\xe8\xb2\xa0\xe3\x81\x91\xe3\x81\xaa\xe3\x82\x8a',
      // 勝ち退くが利
      '\xe5\x8b\x9d\xe3\x81\xa1\xe9\x80\x80\xe3\x81\x8f\xe3\x81\x8c\xe5\x88\xa9',
      // よろしさわぐな
      '\xe3\x82\x88\xe3\x82\x8d\xe3\x81\x97\xe3\x81\x95\xe3\x82\x8f\xe3\x81\x90\xe3\x81\xaa',
      // 心和やかにして吉
      '\xe5\xbf\x83\xe5\x92\x8c\xe3\x82\x84\xe3\x81\x8b\xe3\x81\xab\xe3\x81\x97\xe3\x81\xa6\xe5\x90\x89'
    ],
    // TRAVEL
    [
      // かえりはほど知れず
      '\xe3\x81\x8b\xe3\x81\x88\xe3\x82\x8a\xe3\x81\xaf\xe3\x81\xbb\xe3\x81\xa9\xe7\x9f\xa5\xe3\x82\x8c\xe3\x81\x9a',
      // して良いが無理避けよ
      '\xe3\x81\x97\xe3\x81\xa6\xe8\x89\xaf\xe3\x81\x84\xe3\x81\x8c\xe7\x84\xa1\xe7\x90\x86\xe9\x81\xbf\xe3\x81\x91\xe3\x82\x88',
      // 遠くはいかぬが利
      '\xe9\x81\xa0\xe3\x81\x8f\xe3\x81\xaf\xe3\x81\x84\xe3\x81\x8b\xe3\x81\xac\xe3\x81\x8c\xe5\x88\xa9',
      // 快調に進む
      '\xe5\xbf\xab\xe8\xaa\xbf\xe3\x81\xab\xe9\x80\xb2\xe3\x82\x80'
    ],
    // HEALTH
    [
      // 医師はしっかり選べ
      '\xe5\x8c\xbb\xe5\xb8\xab\xe3\x81\xaf\xe3\x81\x97\xe3\x81\xa3\xe3\x81\x8b\xe3\x82\x8a\xe9\x81\xb8\xe3\x81\xb9',
      // 早く医師に診せろ
      '\xe6\x97\xa9\xe3\x81\x8f\xe5\x8c\xbb\xe5\xb8\xab\xe3\x81\xab\xe8\xa8\xba\xe3\x81\x9b\xe3\x82\x8d',
      // 異変感じたら休め
      '\xe7\x95\xb0\xe5\xa4\x89\xe6\x84\x9f\xe3\x81\x98\xe3\x81\x9f\xe3\x82\x89\xe4\xbc\x91\xe3\x82\x81',
      // 心穏やかに過ごせ 快方に向かう
      '\xe5\xbf\x83\xe7\xa9\x8f\xe3\x82\x84\xe3\x81\x8b\xe3\x81\xab\xe9\x81\x8e\xe3\x81\x94\xe3\x81\x9b\x20\xe5\xbf\xab\xe6\x96\xb9\xe3\x81\xab\xe5\x90\x91\xe3\x81\x8b\xe3\x81\x86'
    ],
    // WISH
    [
      // 障りあり
      '\xe9\x9a\x9c\xe3\x82\x8a\xe3\x81\x82\xe3\x82\x8a',
      // 焦るな機は来る
      '\xe7\x84\xa6\xe3\x82\x8b\xe3\x81\xaa\xe6\xa9\x9f\xe3\x81\xaf\xe6\x9d\xa5\xe3\x82\x8b',
      // 多く望まなければ叶う
      '\xe5\xa4\x9a\xe3\x81\x8f\xe6\x9c\x9b\xe3\x81\xbe\xe3\x81\xaa\xe3\x81\x91\xe3\x82\x8c\xe3\x81\xb0\xe5\x8f\xb6\xe3\x81\x86',
      // 力合わせればきっと叶う
      '\xe5\x8a\x9b\xe5\x90\x88\xe3\x82\x8f\xe3\x81\x9b\xe3\x82\x8c\xe3\x81\xb0\xe3\x81\x8d\xe3\x81\xa3\xe3\x81\xa8\xe5\x8f\xb6\xe3\x81\x86'
    ]
  ];

  string[][] specialFortuneValues = [
    // LOVE
    [
      // 告白しばらく待て
      '\xe5\x91\x8a\xe7\x99\xbd\xe3\x81\x97\xe3\x81\xb0\xe3\x82\x89\xe3\x81\x8f\xe5\xbe\x85\xe3\x81\xa6',
      // 今叶わずとも縁あり
      '\xe4\xbb\x8a\xe5\x8f\xb6\xe3\x82\x8f\xe3\x81\x9a\xe3\x81\xa8\xe3\x82\x82\xe7\xb8\x81\xe3\x81\x82\xe3\x82\x8a',
      // 歳に囚われる必要なし
      '\xe6\xad\xb3\xe3\x81\xab\xe5\x9b\x9a\xe3\x82\x8f\xe3\x82\x8c\xe3\x82\x8b\xe5\xbf\x85\xe8\xa6\x81\xe3\x81\xaa\xe3\x81\x97',
      // 良い人既に近くに
      '\xe8\x89\xaf\xe3\x81\x84\xe4\xba\xba\xe6\x97\xa2\xe3\x81\xab\xe8\xbf\x91\xe3\x81\x8f\xe3\x81\xab',
      // 迷うことなかれ 心に決めた人が最上
      '\xe8\xbf\xb7\xe3\x81\x86\xe3\x81\x93\xe3\x81\xa8\xe3\x81\xaa\xe3\x81\x8b\xe3\x82\x8c\x20\xe5\xbf\x83\xe3\x81\xab\xe6\xb1\xba\xe3\x82\x81\xe3\x81\x9f\xe4\xba\xba\xe3\x81\x8c\xe6\x9c\x80\xe4\xb8\x8a',
      // 愛せよ 全て叶う
      '\xe6\x84\x9b\xe3\x81\x9b\xe3\x82\x88\x20\xe5\x85\xa8\xe3\x81\xa6\xe5\x8f\xb6\xe3\x81\x86'
    ],
    // BENEFACTOR
    [
      // たよりなし
      '\xe3\x81\x9f\xe3\x82\x88\xe3\x82\x8a\xe3\x81\xaa\xe3\x81\x97',
      // 来るとも遅し 往きて利あり
      '\xe6\x9d\xa5\xe3\x82\x8b\xe3\x81\xa8\xe3\x82\x82\xe9\x81\x85\xe3\x81\x97\x20\xe5\xbe\x80\xe3\x81\x8d\xe3\x81\xa6\xe5\x88\xa9\xe3\x81\x82\xe3\x82\x8a',
      // 来る
      '\xe6\x9d\xa5\xe3\x82\x8b',
      // 来たる つれあり
      '\xe6\x9d\xa5\xe3\x81\x9f\xe3\x82\x8b\x20\xe3\x81\xa4\xe3\x82\x8c\xe3\x81\x82\xe3\x82\x8a',
      // 来る 驚くことあり
      '\xe6\x9d\xa5\xe3\x82\x8b\x20\xe9\xa9\x9a\xe3\x81\x8f\xe3\x81\x93\xe3\x81\xa8\xe3\x81\x82\xe3\x82\x8a',
      // 来て喜びの奏こだまする
      '\xe6\x9d\xa5\xe3\x81\xa6\xe5\x96\x9c\xe3\x81\xb3\xe3\x81\xae\xe5\xa5\x8f\xe3\x81\x93\xe3\x81\xa0\xe3\x81\xbe\xe3\x81\x99\xe3\x82\x8b'
    ],
    // BUSINESS
    [
      // 堅実さを取り戻せ
      '\xe5\xa0\x85\xe5\xae\x9f\xe3\x81\x95\xe3\x82\x92\xe5\x8f\x96\xe3\x82\x8a\xe6\x88\xbb\xe3\x81\x9b',
      // 利益少し焦るな　後になれば益あり
      '\xe5\x88\xa9\xe7\x9b\x8a\xe5\xb0\x91\xe3\x81\x97\xe7\x84\xa6\xe3\x82\x8b\xe3\x81\xaa\xe3\x80\x80\xe5\xbe\x8c\xe3\x81\xab\xe3\x81\xaa\xe3\x82\x8c\xe3\x81\xb0\xe7\x9b\x8a\xe3\x81\x82\xe3\x82\x8a',
      // 利益たしかなり
      '\xe5\x88\xa9\xe7\x9b\x8a\xe3\x81\x9f\xe3\x81\x97\xe3\x81\x8b\xe3\x81\xaa\xe3\x82\x8a',
      // 十分幸福
      '\xe5\x8d\x81\xe5\x88\x86\xe5\xb9\xb8\xe7\xa6\x8f',
      // 御神徳により隆昌する
      '\xe5\xbe\xa1\xe7\xa5\x9e\xe5\xbe\xb3\xe3\x81\xab\xe3\x82\x88\xe3\x82\x8a\xe9\x9a\x86\xe6\x98\x8c\xe3\x81\x99\xe3\x82\x8b',
      // 夜動かばおおいに利あり
      '\xe5\xa4\x9c\xe5\x8b\x95\xe3\x81\x8b\xe3\x81\xb0\xe3\x81\x8a\xe3\x81\x8a\xe3\x81\x84\xe3\x81\xab\xe5\x88\xa9\xe3\x81\x82\xe3\x82\x8a'
    ],
    // ACADEMICS
    [
      // 今回は諦め切り替えるべし
      '\xe4\xbb\x8a\xe5\x9b\x9e\xe3\x81\xaf\xe8\xab\xa6\xe3\x82\x81\xe5\x88\x87\xe3\x82\x8a\xe6\x9b\xbf\xe3\x81\x88\xe3\x82\x8b\xe3\x81\xb9\xe3\x81\x97',
      // 伸びる時努力せよ
      '\xe4\xbc\xb8\xe3\x81\xb3\xe3\x82\x8b\xe6\x99\x82\xe5\x8a\xaa\xe5\x8a\x9b\xe3\x81\x9b\xe3\x82\x88',
      // 努力しただけ力になる
      '\xe5\x8a\xaa\xe5\x8a\x9b\xe3\x81\x97\xe3\x81\x9f\xe3\x81\xa0\xe3\x81\x91\xe5\x8a\x9b\xe3\x81\xab\xe3\x81\xaa\xe3\x82\x8b',
      // 歩み遅くとも着実に実る
      '\xe6\xad\xa9\xe3\x81\xbf\xe9\x81\x85\xe3\x81\x8f\xe3\x81\xa8\xe3\x82\x82\xe7\x9d\x80\xe5\xae\x9f\xe3\x81\xab\xe5\xae\x9f\xe3\x82\x8b',
      // 自信持てよろししかない
      '\xe8\x87\xaa\xe4\xbf\xa1\xe6\x8c\x81\xe3\x81\xa6\xe3\x82\x88\xe3\x82\x8d\xe3\x81\x97\xe3\x81\x97\xe3\x81\x8b\xe3\x81\xaa\xe3\x81\x84',
      // 信心すればどこまでも伸びる
      '\xe4\xbf\xa1\xe5\xbf\x83\xe3\x81\x99\xe3\x82\x8c\xe3\x81\xb0\xe3\x81\xa9\xe3\x81\x93\xe3\x81\xbe\xe3\x81\xa7\xe3\x82\x82\xe4\xbc\xb8\xe3\x81\xb3\xe3\x82\x8b'
    ],
    // DISPUTES
    [
      // 争いごと負けなり
      '\xe4\xba\x89\xe3\x81\x84\xe3\x81\x94\xe3\x81\xa8\xe8\xb2\xa0\xe3\x81\x91\xe3\x81\xaa\xe3\x82\x8a',
      // 勝ち退くが利
      '\xe5\x8b\x9d\xe3\x81\xa1\xe9\x80\x80\xe3\x81\x8f\xe3\x81\x8c\xe5\x88\xa9',
      // よろしさわぐな
      '\xe3\x82\x88\xe3\x82\x8d\xe3\x81\x97\xe3\x81\x95\xe3\x82\x8f\xe3\x81\x90\xe3\x81\xaa',
      // 心和やかにして吉
      '\xe5\xbf\x83\xe5\x92\x8c\xe3\x82\x84\xe3\x81\x8b\xe3\x81\xab\xe3\x81\x97\xe3\x81\xa6\xe5\x90\x89',
      // 勝負に利あり
      '\xe5\x8b\x9d\xe8\xb2\xa0\xe3\x81\xab\xe5\x88\xa9\xe3\x81\x82\xe3\x82\x8a',
      // 不言実行にて勝つことやすし
      '\xe4\xb8\x8d\xe8\xa8\x80\xe5\xae\x9f\xe8\xa1\x8c\xe3\x81\xab\xe3\x81\xa6\xe5\x8b\x9d\xe3\x81\xa4\xe3\x81\x93\xe3\x81\xa8\xe3\x82\x84\xe3\x81\x99\xe3\x81\x97'
    ],
    // TRAVEL
    [
      // かえりはほど知れず
      '\xe3\x81\x8b\xe3\x81\x88\xe3\x82\x8a\xe3\x81\xaf\xe3\x81\xbb\xe3\x81\xa9\xe7\x9f\xa5\xe3\x82\x8c\xe3\x81\x9a',
      // して良いが無理避けよ
      '\xe3\x81\x97\xe3\x81\xa6\xe8\x89\xaf\xe3\x81\x84\xe3\x81\x8c\xe7\x84\xa1\xe7\x90\x86\xe9\x81\xbf\xe3\x81\x91\xe3\x82\x88',
      // 遠くはいかぬが利
      '\xe9\x81\xa0\xe3\x81\x8f\xe3\x81\xaf\xe3\x81\x84\xe3\x81\x8b\xe3\x81\xac\xe3\x81\x8c\xe5\x88\xa9',
      // 快調に進む
      '\xe5\xbf\xab\xe8\xaa\xbf\xe3\x81\xab\xe9\x80\xb2\xe3\x82\x80',
      // 場所に執着するな いけうまくいく
      '\xe5\xa0\xb4\xe6\x89\x80\xe3\x81\xab\xe5\x9f\xb7\xe7\x9d\x80\xe3\x81\x99\xe3\x82\x8b\xe3\x81\xaa\x20\xe3\x81\x84\xe3\x81\x91\xe3\x81\x86\xe3\x81\xbe\xe3\x81\x8f\xe3\x81\x84\xe3\x81\x8f',
      // 御神徳により成功しかない
      '\xe5\xbe\xa1\xe7\xa5\x9e\xe5\xbe\xb3\xe3\x81\xab\xe3\x82\x88\xe3\x82\x8a\xe6\x88\x90\xe5\x8a\x9f\xe3\x81\x97\xe3\x81\x8b\xe3\x81\xaa\xe3\x81\x84'
    ],
    // HEALTH
    [
      // 医師はしっかり選べ
      '\xe5\x8c\xbb\xe5\xb8\xab\xe3\x81\xaf\xe3\x81\x97\xe3\x81\xa3\xe3\x81\x8b\xe3\x82\x8a\xe9\x81\xb8\xe3\x81\xb9',
      // 早く医師に診せろ
      '\xe6\x97\xa9\xe3\x81\x8f\xe5\x8c\xbb\xe5\xb8\xab\xe3\x81\xab\xe8\xa8\xba\xe3\x81\x9b\xe3\x82\x8d',
      // 異変感じたら休め
      '\xe7\x95\xb0\xe5\xa4\x89\xe6\x84\x9f\xe3\x81\x98\xe3\x81\x9f\xe3\x82\x89\xe4\xbc\x91\xe3\x82\x81',
      // 心穏やかに過ごせ 快方に向かう
      '\xe5\xbf\x83\xe7\xa9\x8f\xe3\x82\x84\xe3\x81\x8b\xe3\x81\xab\xe9\x81\x8e\xe3\x81\x94\xe3\x81\x9b\x20\xe5\xbf\xab\xe6\x96\xb9\xe3\x81\xab\xe5\x90\x91\xe3\x81\x8b\xe3\x81\x86',
      // 技術信ぜよ必ず治る
      '\xe6\x8a\x80\xe8\xa1\x93\xe4\xbf\xa1\xe3\x81\x9c\xe3\x82\x88\xe5\xbf\x85\xe3\x81\x9a\xe6\xb2\xbb\xe3\x82\x8b',
      // 御神徳により全て治る
      '\xe5\xbe\xa1\xe7\xa5\x9e\xe5\xbe\xb3\xe3\x81\xab\xe3\x82\x88\xe3\x82\x8a\xe5\x85\xa8\xe3\x81\xa6\xe6\xb2\xbb\xe3\x82\x8b'
    ]
  ];

  string[] overallFortune = [
    // 凶
    '\xe5\x87\xb6',
    // 末吉
    '\xe6\x9c\xab\xe5\x90\x89',
    // 吉
    '\xe5\x90\x89',
    // 中吉
    '\xe4\xb8\xad\xe5\x90\x89',
    // 大吉
    '\xe5\xa4\xa7\xe5\x90\x89',
    // 大大吉
    '\xe5\xa4\xa7\xe5\xa4\xa7\xe5\x90\x89'
  ];

  // Beneficiary address
  address beneficiary;

  constructor() ERC721('DenDekaDen Genesis Omikuji', '$DDD') {
    beneficiary = owner();
  }

  /**
   * @dev Check mints remaining per character
   *
   * Returns entire array for less rpc calls on frontend. Can't just return
   * mintsPerCharacter because it is a storage pointer.
   */
  function characterMintsRemaining() public view returns (uint256[] memory) {
    uint256[] memory mintsRemaining = new uint256[](NUM_CHARACTERS);
    for (uint8 i = 0; i < NUM_CHARACTERS; i++) {
      mintsRemaining[i] = characterMintsRemaining(i);
    }
    return mintsRemaining;
  }

   /**
   * @dev Check mints remaining per character
   *
   * Returns entire array for less rpc calls on frontend. Can't just return
   * mintsPerCharacter because it is a storage pointer.
   */
  function characterMintsRemaining(uint8 characterId) private view returns (uint256) {
    return OMIKUJI_PER_CHARACTER - ascendingCharacterMints[characterId] - descendingCharacterMints[characterId];
  }

  /**
   * @dev Check mint eligability for address
   * 
   * Returns:
   *  - 0 if not eligable
   *  - 1 if main mint
   *  - 2 if whitelist
   *  - 3 if teammint
   */
  function mintEligability(address user, bytes32[] calldata proof) public view returns (uint8) {
    // first check if main mint is open
    if(mainMintStartTime <= block.timestamp) {
      return 1;
    }

    bytes32 leaf = keccak256(abi.encodePacked(user));
    
    if(whitelistMintStartTime <= block.timestamp) {
      // check whitelist
      if (MerkleProof.verify(proof, whitelistMerkleRoot, leaf)) {
        return 2;
      }
    }
    // now check team whitelist
    if (MerkleProof.verify(proof, teamMerkleRoot, leaf)) {
      return 3;
    }

    return 0;
  }
 
  /**
   * @dev Set the whitelist root
   */
  function setWhitelistRoot(bytes32 root) public onlyOwner {
    whitelistMerkleRoot = root;
  }

  /**
   * @dev Set the team whitelist root
   */
  function setTeamMerkleRoot(bytes32 root) public onlyOwner {
    teamMerkleRoot = root;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  /**
   * @dev Set the whitelist and mint start times
   *
   * NOTE: can be used to close mint if need be
   */
  function setMintTimes(uint256 whitelistStart, uint256 mintStart) public onlyOwner {
    whitelistMintStartTime = whitelistStart;
    mainMintStartTime = mintStart;
  }

  /**
   * @dev Public mint function
   *
   * If time is before open mint, will call whitelist mint, otherwise will call
   * normal mint.
   *
   * Cannot mint if not before start time.
   *
   * Requirements:
   *  - cannot
   */
  function mint(uint8 characterId, bytes32[] memory proof) public payable returns (uint256 tokenId) {
    // Check if should be whitelist or normal mint

    // if past normal mint time, do normal mint
    if (mainMintStartTime <= block.timestamp) {
      return _mint(characterId, true);
    } else if (whitelistMintStartTime <= block.timestamp) {
      // if during normal whitelist period, no need to decrement team mints
      if(_validateWhitelist(proof, whitelistMerkleRoot, true) || _validateWhitelist(proof, teamMerkleRoot, false)) {
        return _mint(characterId, true);
      }
    } else {
      if(_validateWhitelist(proof, teamMerkleRoot, false)) {
        return _teamMint(characterId);
      }
    }
    revert("DDDO: Not eligable or already whitelist minted");
  }

  /**
   * @dev Whitelist mint
   *
   * Requirements:
   *  - only allow ONE mint per whitelist address
   */
  function _validateWhitelist(bytes32[] memory proof, bytes32 root, bool oneLimit) private returns (bool) {
    // ensure wallet owns no tokens
    if(whitelistAddressMints[msg.sender]) {
      return false;
    }

    // Check if address exists in merkle tree
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if(!MerkleProof.verify(proof, root, leaf)){
      return false;
    }

    // mark account as having minted
    if(oneLimit) {
      whitelistAddressMints[msg.sender] = true;
    }
    
    // mint if qualifies
    return true;

  }

   /**
   * @dev Team Mint function
   *
   * Team can mint a limited number of tokens.
   * Team tokens CANNOT be godly tokens.
   */
  function _teamMint(uint8 characterId) private returns (uint256) {
    // check we still have mints remaining
    require(teamMintsRemaining > 0, 'DDDO: No more team mints');
    
    teamMintsRemaining -= 1;

    return _mint(characterId, false);
  }

  function ownerCharacters(address owner) public view returns (uint256[] memory) {
    uint256[] memory characters = new uint256[](NUM_CHARACTERS);

    for (uint8 i = 0; i < NUM_CHARACTERS; i++) {
      characters[i] = addressCharacterMints[owner][i];
    }

    return characters;
  }

  /**
   * @dev Mints a new omikuji based on character provided
   *
   * Requirements:
   *  - must not be called from contract
   *  - must be valid character
   *  - character must have available omikuji
   *  - must not already own omikuji from this character
   */
  function _mint(uint8 characterId, bool ascending) private returns (uint256) {
    // only allow mint from user address, not bot
    require(tx.origin == msg.sender, 'DDDO: must be wallet');

    // ensure does not already own this character omikuji
    require(addressCharacterMints[msg.sender][characterId] == 0, "DDDO: Only 1 omikuji per chara");

    // get next token id -- will revert if too many tokens minted for character
    uint256 tokenId = nextTokenIdForCharacter(characterId, ascending);

    // store seed variables used to calculate attributes
    // on mint, jsut store blockNum + blockHash (?) with tokenId & donation?
    uint256 timestamp = block.timestamp;
    TraitSeeds storage seeds = tokenTraitSeeds[tokenId];
    seeds.timestamp = timestamp;
    seeds.donationAmount = msg.value;

    // if we do not have a godly token for this character, ~randomly see if godly token
    // NOTE: team mints CANNOT be godly tokens because they progress in descending order
    if (ascending && godlyTokens[characterId] == 0) {
      // if we do not have a godly token within first 107 mints, force 108 mint to be godly
      uint256 mintsRemaining = characterMintsRemaining(characterId);
      if (mintsRemaining == 0) {
        godlyTokens[characterId] = tokenId;
      } else {
        uint256 godlyModulo = mintsRemaining;

        // if donation is above threshold, boost probability to 20% or better
        if (msg.value >= DONATION_BOOST_THRESHOLD) {
          godlyModulo = godlyModulo > 5 ? 5 : godlyModulo;
        }

        // Roll for godly trait calculation here to test
        uint256 randRoll = uint256(keccak256(abi.encodePacked(tokenId, msg.sender, timestamp))) % godlyModulo;

        // If matches godlyModulo, we have found godly token!
        if (randRoll == 0) {
          godlyTokens[characterId] = tokenId;
        }
      }
    }

    // mint token
    super._mint(msg.sender, tokenId);


    // record this address has minted this character
    addressCharacterMints[msg.sender][characterId] = tokenId;

    return tokenId;
  }


  /**
   * @dev Generate the random attributes of a given token
   * 
   * Depends on when and how minted, so pseudo random.
   * 
   * NOTE: this is public because likely will use these values in the future.
   * 
   * Traits are:
   * 
   * LOVE
   * BENEFACTOR
   * BUSINESS
   * ACADEMICS
   * DISPUTES
   * TRAVEL
   * HEALTH
   * WISH -- no special -- last idx in arr
   */
  function _generatePseudoRandomAttributes(uint256 tokenId) public view returns (uint8[] memory) {

    uint256 characterId = characterIdFromToken(tokenId);

    // in total 8 traits to derive from tokenId, timestamp, blockhash
    uint8[] memory attributes = new uint8[](8);
    TraitSeeds memory seeds = tokenTraitSeeds[tokenId];
    bytes memory baseSeed = abi.encodePacked(seeds.timestamp, seeds.donationAmount, tokenId);

    for (uint256 i = 0; i < 8; i++) {
      uint8[] memory traitProbabilities;

      // check if should use special traits
      if (i == characterId) {
        // check if godly token
        if (godlyTokens[i] == tokenId) {
          traitProbabilities = new uint8[](1);
          traitProbabilities[0] = 5;
        } else {
          // check if should use boost or special probabilities
          if (seeds.donationAmount >= DONATION_BOOST_THRESHOLD) {
            traitProbabilities = boostAttributeProbabilities;
          } else {
            traitProbabilities = specialAttributeProbabilities;
          }
        }
      } else {
        // use base attribute probabilities
        traitProbabilities = baseAttributeProbabilities;
      }

      // generate random seed
      uint256 randSeed = uint256(keccak256(abi.encodePacked(baseSeed, i)));
      uint8 traitBucket = traitProbabilities[randSeed % traitProbabilities.length];
      attributes[i] = traitBucket;
    }

    return attributes;
  }

  function attributesJson(uint256 tokenId, uint8[] memory wishAttrs) public view returns (bytes memory) {
    // check if has soul fragment
    // subtract one because tokens are 1 indexed
    uint256 characterId = characterIdFromToken(tokenId);

    // put together metadata
    bytes memory attributes = '[';

    // add in character name
    attributes = abi.encodePacked(attributes, attributeJson('0. SOUL', characterNames[characterId]));

    // loop through all fortune categories
    for (uint8 i = 0; i < wishAttrs.length; i++) {
      bytes memory attr;
      // check if special attribute for character
      if (i == characterId) {
        attr = attributeJson(fortuneCategories[i], specialFortuneValues[i][wishAttrs[i]]);
        attr = abi.encodePacked(attr, ',', attributeJson('1. FORTUNE', overallFortune[wishAttrs[i]]));
      } else {
        // not special category, so use normal odds
        attr = attributeJson(fortuneCategories[i], fortuneValues[i][wishAttrs[i]]);
      }

      attributes = abi.encodePacked(
        // add comma if not the first entry for json correct formatting
        attributes,
        ',',
        attr
      );
    }

    // add in soul fragment
    attributes = abi.encodePacked(attributes, ',', attributeJson('Epoch', 'First Believers'));

    // close attributes
    attributes = abi.encodePacked(attributes, ']');

    return attributes;
  }

  function attributeJson(string memory traitType, string memory traitValue) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '{',
        abi.encodePacked('"trait_type": "', traitType, '",'),
        abi.encodePacked('"value": "', traitValue, '"'),
        '}'
      );
  }

  /**
   * @dev create the image uri for resources
   *
   * Image is based on the luck level of the special attribute of the character.
   *
   */
  function _generateImgUri(uint256 characterId, uint8 luckLevel) internal view returns (string memory) {
    return
      string(
        abi.encodePacked(_baseImgUri, uint256(characterId).toString(), '_', uint256(luckLevel).toString(), '.png')
      );
  }

  /**
   * @dev Set a new uri for images so we can transition to IPFS
   *
   * If URI is locked, can never be changed.
   */
  function setImgUri(string calldata _uri) external onlyOwner {
    require(!_imgUriLocked, 'DDDO: Img Uri is locked!');
    _baseImgUri = _uri;
  }

  /**
   * @dev Lock the image URI so forever immutable
   *
   * NOTE: Can ONLY be called once, be sure images are correct
   */
  function lockImgUri() public onlyOwner {
    _imgUriLocked = true;
  }

  /////////////// TOKEN ID UTILITY FUNCTIONS //////////////////

  /**
   * @dev Calculates the next Id
   */
  function nextTokenIdForCharacter(uint8 characterId, bool ascending) internal returns (uint256) {
    // ensure valid character
    require(characterId < NUM_CHARACTERS, 'DDDO: Invalid character id!');

    // check can still mint for this character
    require(characterMintsRemaining(characterId) > 0, 'DDDO: No more omikuji available');

    uint16 tokenOffset;
    if(ascending) {
      // mint from bottom up -- increment first so 1 indexed
      ascendingCharacterMints[characterId] += 1;
      tokenOffset = ascendingCharacterMints[characterId];
    } else {
      // mint from top down -- increment after so ids are 1 indexed
      tokenOffset = OMIKUJI_PER_CHARACTER - descendingCharacterMints[characterId];
      descendingCharacterMints[characterId] += 1;
    }

    // derive tokenId
    // NOTE: we add 1 here because NO TOKEN should have ID of 0 (for godly attribute check), so 1 indexed
    return characterId * OMIKUJI_PER_CHARACTER + tokenOffset;
  }

  function characterIdFromToken(uint256 tokenId) internal pure returns (uint256) {
    // subtract 1 because ids start at 1
    return ((tokenId - 1) / OMIKUJI_PER_CHARACTER);
  }

  function tokenNumberForCharacter(uint256 tokenId) internal pure returns (uint256) {
    // subtract 1 because ids start at 1
    return (tokenId - 1) % OMIKUJI_PER_CHARACTER;
  }

  function withdraw() public {
    beneficiary.call{ value: address(this).balance }('');
  }

  /**
   * @dev Get OnChainMetadata for token
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    return getTokenURI(tokenId);
  }

  /**
   * @dev Generate metadata for each token.
   * 
   * All attributes are onchain, images can be moved to ipfs when ready.
   */
  function getTokenURI(uint256 tokenId) public view returns (string memory) {
    // 1 index characterID and character token
    uint256 characterId = characterIdFromToken(tokenId);
    uint256 characterToken = tokenNumberForCharacter(tokenId) + 1;
    uint8[] memory attributes = _generatePseudoRandomAttributes(tokenId);
    bytes memory tokenNameFormat = abi.encodePacked((characterToken < 10 ? '00' : (characterToken < 100 ? '0' : '')), characterToken.toString());

    bytes memory dataURI = abi.encodePacked(
      '{',
      '"name": "',
      characterNames[characterId],
      "'s Fortune #", tokenNameFormat,     
      '",',
      '"description": "',
      DESCRIPTION, characterNames[characterId], '.',
      '",',
      '"external_url": "',
      EXTERNAL_URL,
      '",',
      '"image": "',
      _generateImgUri(characterId, attributes[characterId]),
      '",',
      '"attributes": ',
      attributesJson(tokenId, attributes),
      '}'
    );
    return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
  }
}