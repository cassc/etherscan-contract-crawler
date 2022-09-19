/*
 _______ .___________. __    __   _______ .______       __        ______   .___________.___________.  ______
|   ____||           ||  |  |  | |   ____||   _  \     |  |      /  __  \  |           |           | /  __  \
|  |__   `---|  |----`|  |__|  | |  |__   |  |_)  |    |  |     |  |  |  | `---|  |----`---|  |----`|  |  |  |
|   __|      |  |     |   __   | |   __|  |      /     |  |     |  |  |  |     |  |        |  |     |  |  |  |
|  |____     |  |     |  |  |  | |  |____ |  |\  \----.|  `----.|  `--'  |     |  |        |  |     |  `--'  |
|_______|    |__|     |__|  |__| |_______|| _| `._____||_______| \______/      |__|        |__|      \______/

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import './Lottery.sol';
import './Period.sol';
import './Base64.sol';

contract EtherLotto is ERC721, Ownable, PullPayment {
  uint256 public constant totalSupply = type(uint256).max;

  uint256 private tokenId = 0;
  
  /// @notice Token列表 [TokenId => 彩票信息]
  mapping(uint256 => Lottery) private tokens;
  
  /// @notice 彩票列表 [玩法金额 => Token列表]
  mapping(uint256 => uint256 [100]) private lotteries;

  /// @notice 类型列表 [玩法金额 => 是否有效]
  mapping(uint256 => uint256) private types;

  /// @notice 期数列表 [玩法金额 => 期数编号]
  mapping(uint256 => Period) public periods;

  /// @notice 奖励列表 [奖励账号 => 奖励金额]
  mapping(address => uint256) public awards;

  constructor() ERC721("Ether Lotto", "LOT") {
    /// @notice 初始化玩法类型
    for(uint256 i = 0.001 ether; i <= 1000 ether; i *= 10) {
      types[i] = 1;
    }
  }

  /// @notice 开奖事件
  event Open(uint256, uint256, uint256);

  /// @notice 购买彩票
  /// @param number 彩票号码
  function buyLottery(uint256 number) public payable {
    require(types[msg.value] == 1, "play type error");
    require(number >= 1 && number <= 100, "number error");

    // 获取当前期数
    Period memory period = periods[msg.value];

    if (period.code == 100) {
      // 获取中奖彩票
      uint256 winNumber = tokens[lotteries[msg.value][calcIndex()]].number;

      uint256 count = 0;

      for (uint256 i = 0; i < 100; i++) {
        tokens[lotteries[msg.value][i]].isOpen = 1;
        tokens[lotteries[msg.value][i]].winNumber = winNumber;

        if (tokens[lotteries[msg.value][i]].number == winNumber) {
          tokens[lotteries[msg.value][i]].isWin = 1;
          count++;
        }
      }

      // 所有中奖人平分奖励
      uint256 winAmount = (msg.value * 80) / count;

      for (uint256 i = 0; i < 100; i++) {
        if (tokens[lotteries[msg.value][i]].isWin == 1) {
          tokens[lotteries[msg.value][i]].winAmount = winAmount;
        }
      }

      // 重置当前玩法的编号
      periods[msg.value].id += 1;
      periods[msg.value].code = 1;

      unchecked {
        // 编号为1的彩票创建者负责开奖 奖励上期10%的销售额
        awards[msg.sender] += msg.value * 10;
      }

      // 触发开奖事件
      emit Open(msg.value, winNumber, count);

      period.id += 1;
      period.code = 0;
    } else {
      periods[msg.value].code = period.code + 1;
    }

    // 当前TokenId
    uint256 id = ++tokenId;

    // 创建彩票
    Lottery memory lottery = Lottery(msg.value, period.id + 1, period.code + 1, number, msg.sender, 0, 0, 0, 0, 0);

    tokens[id] = lottery;

    // 彩票记录
    lotteries[msg.value][period.code] = id;

    // 手续费 
    unchecked {
      awards[owner()] += msg.value / 10;
    }

    _safeMint(msg.sender, id);
  }

  /// @notice 计算出一个中奖人
  function calcIndex() private view returns (uint256 index) {
    bytes memory temp;
    for (uint256 i = 0; i < lotteries[msg.value].length; i++) {
      temp = abi.encodePacked(temp, tokens[lotteries[msg.value][i]].creator.balance);
    }
    uint256 tempIndex = uint256(keccak256(temp)) % 100;
    return tempIndex > 99 ? 99 : tempIndex;
  }

  /// @notice 兑奖
  /// @param id 彩票TokenId
  /// @param payee 兑奖提款账号
  function redeem(uint256 id, address payable payee) public {
    require(ownerOf(id) == msg.sender, 'not lottery owner');
    require(tokens[id].isWin == 1, 'lottery did not win');
    require(tokens[id].isRedeem == 0, 'rewards cannot be repeated');

    _asyncTransfer(payee, tokens[id].winAmount);

    tokens[id].isRedeem = 1;

    withdrawPayments(payee);
  }

  /// @notice 领取自己的奖励
  /// @param payee 奖励提款账号
  function receiveAward(address payable payee) public {
    require(awards[msg.sender] > 0, 'no rewards currently');

    _asyncTransfer(payee, awards[msg.sender]);

    awards[msg.sender] = 0;

    withdrawPayments(payee);
  }

  /// @notice 获取彩票TokenURL
  /// @param id 彩票TokenId
  function tokenURI(uint256 id) override public view returns (string memory) {
    string[20] memory parts;
    parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 141.73 170.08"><text transform="translate(14.17 31.57)" font-size="4.8">Period: ';
    parts[1] = toString(tokens[id].period);
    parts[2] = '</text><text transform="translate(14.17 40.07)" font-size="4.8">Code: ';
    parts[3] = toString(tokens[id].code);
    parts[4] = '</text><text transform="translate(14.17 48.57)" font-size="4.8">Open: ';
    parts[5] = tokens[id].isOpen == 1 ? 'YES' : 'NO';
    parts[6] = '</text><text transform="translate(14.17 57.07)" font-size="4.8">Amount: ';
    parts[7] = toString(tokens[id].amount);
    parts[8] = ' Wei</text>';

    // 中奖号码
    if (tokens[id].winNumber != 0) {
      parts[9] = '<text transform="translate(14.17 65.57)" fill="#ff0000" font-size="4.8">Win Number: ';
      parts[10] = toString(tokens[id].winNumber);
      parts[11] = '</text>';
    } else {
      parts[9] = '';
      parts[10] = '';
      parts[11] = '';
    }

    // 是否中奖
    if (tokens[id].isWin == 1) {
      parts[12] = '<text transform="translate(14.17 74.07)" fill="#ff0000" font-size="4.8">Win Amount: ';
      parts[13] = toString(tokens[id].winAmount);
      parts[14] = ' Wei</text><text transform="translate(14.17 82.57)" fill="#ff0000" font-size="4.8">Redeem: ';
      parts[15] = tokens[id].isRedeem == 1 ? 'YES' : 'NO';
      parts[16] = '</text>';
    } else {
      parts[12] = '';
      parts[13] = '';
      parts[14] = '';
      parts[15] = '';
      parts[16] = '';
    }

    if (tokens[id].number == 100) {
      parts[17] = '<text transform="translate(8.65 140.25)" font-size="72">';
    } else if (tokens[id].number > 9) {
      parts[17] = '<text transform="translate(31.05 140.25)" font-size="72">';
    } else {
      parts[17] = '<text transform="translate(51.07 140.25)" font-size="72">';
    }

    parts[18] = toString(tokens[id].number);
    parts[19] = '</text></svg>';

    string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9]));
    output = string(abi.encodePacked(output, parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16], parts[17], parts[18], parts[19]));
    
    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Ether Lotto #', toString(id), '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
  }

  /// @notice Uint256转String
  /// @param value Uint256
  function toString(uint256 value) private pure returns (string memory) {
    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}