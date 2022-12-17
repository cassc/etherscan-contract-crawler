/*
     _____________________________________________________________________________________
    (__   ___________________________________________________________________________   __)
       | |                                                                           | |
       | |                         ███████╗███╗   ██╗██████╗                         | |
       | |                         ██╔════╝████╗  ██║██╔══██╗                        | |
       | |                         █████╗  ██╔██╗ ██║██║  ██║                        | |
       | |                         ██╔══╝  ██║╚██╗██║██║  ██║                        | |
       | |                         ███████╗██║ ╚████║██████╔╝                        | |
       | |                         ╚══════╝╚═╝  ╚═══╝╚═════╝                         | |
       | |                                                                           | |
       | |                         █████╗ ███████╗██╗ ██████╗                        | |
       | |                        ██╔══██╗██╔════╝██║██╔════╝                        | |
       | |                        ███████║███████╗██║██║                             | |
       | |                        ██╔══██║╚════██║██║██║                             | |
       | |                        ██║  ██║███████║██║╚██████╗                        | |
       | |                        ╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝                        | |
       | |                                                                           | |
       | |             ███╗   ███╗██╗███╗   ██╗███████╗██████╗ ███████╗              | |
       | |             ████╗ ████║██║████╗  ██║██╔════╝██╔══██╗██╔════╝              | |
       | |             ██╔████╔██║██║██╔██╗ ██║█████╗  ██████╔╝███████╗              | |
       | |             ██║╚██╔╝██║██║██║╚██╗██║██╔══╝  ██╔══██╗╚════██║              | |
       | |             ██║ ╚═╝ ██║██║██║ ╚████║███████╗██║  ██║███████║              | |
       | |             ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝              | |
 ______| |___________________________________________________________________________| |_______
(_   ______________________________________________________________________________________   _)
  | |                                                                                      | |
  | |  _                           _     _     _                              _            | |
  | | | |__  _ __ ___  _   _  __ _| |__ | |_  | |_ ___    _   _  ___  _   _  | |__  _   _  | |
  | | | '_ \| '__/ _ \| | | |/ _` | '_ \| __| | __/ _ \  | | | |/ _ \| | | | | '_ \| | | | | |
  | | | |_) | | | (_) | |_| | (_| | | | | |_  | || (_) | | |_| | (_) | |_| | | |_) | |_| | | |
  | | |_.__/|_|  \___/ \__,_|\__, |_| |_|\__|  \__\___/   \__, |\___/ \__,_| |_.__/ \__, | | |
  | |                        |___/                        |___/                     |___/  | |
  | |        _  __          _                _______ _            _____                    | |
  | |       | |/ /         | |              |__   __| |          |  __ \                   | |
  | |       | ' / ___  _ __| | _____ _   _     | |  | |__   ___  | |  | | _____   __       | |
  | |       |  < / _ \| '__| |/ / _ \ | | |    | |  | '_ \ / _ \ | |  | |/ _ \ \ / /       | |
  | |       | . \ (_) | |  |   <  __/ |_| |    | |  | | | |  __/ | |__| |  __/\ V /        | |
  | |       |_|\_\___/|_|  |_|\_\___|\__, |    |_|  |_| |_|\___| |_____/ \___| \_/         | |
  | |                                 __/ |                                                | |
  | |                                |___/                                                 | |
 _| |______________________________________________________________________________________| |_
(______________________________________________________________________________________________)

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PulseBitcoin.sol";
import "./Asic.sol";

contract EndASICMiners is Ownable {

  PulseBitcoin public immutable PLSB;
  Asic public immutable ASIC;

  // Our own custom event. Potentially useful for future iterations of the dapp
  event EndMinerError(uint256 minerId, string reason);

  // PLSB Event for successfull minerEnd
  event MinerEnd(
    uint256 data0,
    uint256 data1,
    address indexed accountant,
    uint40 indexed minerId
  );

  // Generic Event
  event Transfer(address indexed from, address indexed to, uint256 value);

  // Storage for all the claims mapped by PLSB.currentDay => claimer => claims
  mapping(uint256 => mapping(address => uint256)) public senderSums;

  // Fee the receiver takes from the asicReturn (owner modifiable)
  uint96 public asicFee;

  // The max amount of ASIC that can be claimed per day by one wallet (including fee)
  uint256 private _maxAsicPerDay;

  // The address of the reciever
  address public receiverAddress;

  // Should the ASIC fee be sent to the reciever or to the caller?
  bool public sendFundsToReceiver;

  // PLSB error selectors
  bytes4 private minerListEmptyError = PulseBitcoin.MinerListEmpty.selector;
  bytes4 private invalidMinerIndexError = PulseBitcoin.InvalidMinerIndex.selector;
  bytes4 private invalidMinerIdError = PulseBitcoin.InvalidMinerId.selector;
  bytes4 private cannotEndMinerEarlyError = PulseBitcoin.CannotEndMinerEarly.selector;

  constructor() {
    PLSB = PulseBitcoin(address(0x5EE84583f67D5EcEa5420dBb42b462896E7f8D06));
    ASIC = Asic(address(0x347a96a5BD06D2E15199b032F46fB724d6c73047));

    asicFee = 5000; // Initalize fee @ 50%
    _maxAsicPerDay = 10; // Initalize _maxAsicPerDay @ 10 ASIC
    sendFundsToReceiver = true;
    receiverAddress = 0x2CDB9AC4B2591Dcc85aad39Ec389137f8728E5d7;
  }

  function setAsicFee(uint96 _asicFee) public onlyOwner {
    asicFee = _asicFee;
  }

  function setMaxAsicPerDay(uint256 __maxAsicPerDay) public onlyOwner {
    _maxAsicPerDay = __maxAsicPerDay;
  }

  function setReceiverAddress(address _receiverAddress) public onlyOwner {
    receiverAddress = _receiverAddress;
  }

  function setSendFundsToReceiver(bool _sendFunds) public onlyOwner {
    sendFundsToReceiver = _sendFunds;
  }

  function maxAsicPerDay() public view returns(uint256) {
    return _maxAsicPerDay * 1e12; // Convert to 12 decimal places per ASIC contract
  }

  function _asicChecks(uint256[] calldata asicReturns) internal {
    uint asicReturnsSum;
    for( uint i; i < asicReturns.length; i++) {
      asicReturnsSum = asicReturnsSum + (asicReturns[i] * asicFee / 10000);
    }

    uint initalSenderSum = senderSums[PLSB.currentDay()][msg.sender];

    senderSums[PLSB.currentDay()][msg.sender] =
      senderSums[PLSB.currentDay()][msg.sender] + asicReturnsSum;

    // Don't check the max per day if this is the first claim for this wallet today
    if(initalSenderSum != 0) {
      require(
        senderSums[PLSB.currentDay()][msg.sender] < (maxAsicPerDay() + 1),
        "Account has reached max asic claim for currentDay"
      );
    }

    // Is this the first claim for this wallet today? &&
    // Is it over the daily limit?
    if(
      initalSenderSum == 0 &&
      senderSums[PLSB.currentDay()][msg.sender] > (maxAsicPerDay() + 1)
    ) {
      // require that only 1 miner is being claimed
      if(asicReturns.length != 1) {
        senderSums[PLSB.currentDay()][msg.sender] = 0;
        revert("When claiming miners over the limit, you may only claim one per day");
      }
    }
  }

  // @dev verifies the caller can end these miners on this day
  modifier _canEndExpiredMiners(uint256[] calldata asicReturns) {

    // Exclude these checks for the owner && receiver
    if(msg.sender != owner() && msg.sender != receiverAddress) {

      _asicChecks(asicReturns);

    }

    _;
  }

  // @dev End a single miner, emitting an event on failure (for internal use only)
  // @return hasEnded did this miner end successfully?
  function _endMiner(
    uint256 minerIndex,
    uint256 minerId,
    address minerOwner
  ) internal returns(bool hasEnded) {

    try PLSB.minerEnd(minerIndex, minerId, minerOwner) {

      return true;

    } catch (bytes memory error_bytes) {

      string memory reason;

      if(bytes4(error_bytes) == minerListEmptyError) {
        reason = "Owner Miner List Empty";
      }
      if(bytes4(error_bytes) == invalidMinerIndexError) {
        reason = "Invalid Miner Index";
      }
      if(bytes4(error_bytes) == invalidMinerIdError) {
        reason = "Invalid Miner Id";
      }
      if(bytes4(error_bytes) == cannotEndMinerEarlyError) {
        reason = "Cannot End Miner Early";
      }

      emit EndMinerError(minerId, reason);

      return false;

    }
  }

  // @dev End miners in bulk (DOES NOT SEND ANY ASIC TO THE CALLER)
  // Intended for use with miners not yet expired
  function endMiners(
    address[] calldata miners,
    uint256[] calldata minerIds,
    uint256[] calldata minerIndexes
  ) external {
    uint minersCount = miners.length;

    require(minersCount == minerIds.length, "Miners input != minerIds input");
    require(minersCount == minerIndexes.length, "Miners input != minerIndexes input");

    for( uint i; i < minersCount; ) {
      _endMiner(minerIndexes[i], minerIds[i], miners[i]);

      unchecked {
        ++i;
      }
    }
  }

  // @dev End Expired Miners in bulk (DOES SEND ASIC TO THE CALLER & RECEIVER)
  function endExpiredMiners(
    address[] calldata miners,
    uint256[] calldata minerIds,
    uint256[] calldata minerIndexes,
    uint256[] calldata asicReturns
  ) external _canEndExpiredMiners(asicReturns) {
    uint minersCount = miners.length;

    require(minersCount == minerIds.length, "Miners input != minerIds input");
    require(minersCount == minerIndexes.length, "Miners input != minerIndexes input");
    require(minersCount == asicReturns.length, "Miners input != asicReturns input");

    uint senderBalance;
    for( uint i; i < minersCount;) {
      if(_endMiner(minerIndexes[i], minerIds[i], miners[i])) {
        uint asicReturn = asicReturns[i];
        uint receiverFee = asicReturn * asicFee / 10000;

        senderBalance += asicReturn - receiverFee;
      }

      unchecked {
        ++i;
      }
    }

    require(senderBalance != 0, "No valid miners were claimed");

    if(sendFundsToReceiver) {
      ASIC.transfer(msg.sender, senderBalance);
      ASIC.transfer(receiverAddress, ASIC.balanceOf(address(this)));
    } else {
      ASIC.transfer(msg.sender, ASIC.balanceOf(address(this)));
    }
  }

  // @dev base function to accept tokens
  receive() external payable {}

  // @dev Send all ETH, ASIC & PLSB held by the contract to the receiver
  function flush() public onlyOwner {
    PLSB.transfer(receiverAddress, PLSB.balanceOf(address(this)));
    require(PLSB.balanceOf(address(this)) == 0, "Flush failed");

    ASIC.transfer(receiverAddress, ASIC.balanceOf(address(this)));
    require(ASIC.balanceOf(address(this)) == 0, "Flush failed");

    payable(receiverAddress).transfer(address(this).balance);
    require(address(this).balance == 0, "Flush failed");
  }
}