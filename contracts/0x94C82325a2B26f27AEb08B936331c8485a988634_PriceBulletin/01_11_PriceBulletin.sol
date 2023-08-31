// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IPriceBulletin} from "./interfaces/IPriceBulletin.sol";
import {BulletinSigning} from "./BulletinSigning.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {RoundData} from "./libraries/AppStorage.sol";

contract PriceBulletin is IPriceBulletin, BulletinSigning, Ownable {
  /// Events
  event BulletinUpdated(int256 answer);
  event FailedBulletingUpdate(address presumedSigner);
  event SetAuthorizedPublisher(address publisher, bool status);

  /// Errors
  error PriceBulletin__setter_invalidInput();
  error PriceBulletin__setter_noChange();

  RoundData private _recordedRoundInfo;

  mapping(address => bool) public authorizedPublishers;

  function decimals() external pure returns (uint8) {
    return 8;
  }

  function description() external pure returns (string memory) {
    return "priceBulletin MXN / USD";
  }

  function version() external pure returns (string memory) {
    return VERSION;
  }

  function latestAnswer() external view returns (int256) {
    (, int256 answer,,,) = latestRoundData();
    return answer;
  }

  function latestRound() public view returns (uint80) {
    return _recordedRoundInfo.roundId;
  }

  function latestRoundData()
    public
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint80 lastRound = latestRound();

    if (lastRound == 0) {
      return (0, 0, 0, 0, 0);
    } else {
      return (
        lastRound,
        _recordedRoundInfo.answer,
        _recordedRoundInfo.startedAt,
        _recordedRoundInfo.updatedAt,
        lastRound
      );
    }
  }

  function xReceive(
    bytes32 transferId,
    uint256,
    address,
    address,
    uint32,
    bytes memory callData
  )
    external
    returns (bytes memory)
  {
    (RoundData memory round, uint8 v, bytes32 r, bytes32 s) =
      abi.decode(callData, (RoundData, uint8, bytes32, bytes32));

    bytes32 structHash = getStructHashRoundData(round);
    address presumedSigner = _getSigner(structHash, v, r, s);

    if (authorizedPublishers[presumedSigner]) {
      _recordedRoundInfo = round;
      emit BulletinUpdated(round.answer);
    } else {
      emit FailedBulletingUpdate(presumedSigner);
    }

    return abi.encode(transferId);
  }

  function setAuthorizedPublisher(address publisher, bool set) external onlyOwner {
    if (publisher == address(0)) {
      revert PriceBulletin__setter_invalidInput();
    }
    if (authorizedPublishers[publisher] == set) {
      revert PriceBulletin__setter_noChange();
    }

    authorizedPublishers[publisher] = set;

    emit SetAuthorizedPublisher(publisher, set);
  }

  /**
   * @dev Returns the signer of the`structHash`.
   *
   * @param structHash of data
   * @param v signature value
   * @param r signautre value
   * @param s signature value
   */
  function _getSigner(
    bytes32 structHash,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    internal
    view
    returns (address presumedSigner)
  {
    bytes32 digest = getHashTypedDataV4Digest(structHash);
    presumedSigner = ECDSA.recover(digest, v, r, s);
  }

  function _getDomainSeparator() internal view override returns (bytes32) {
    return keccak256(
      abi.encode(TYPEHASH, NAMEHASH, VERSIONHASH, address(this), keccak256(abi.encode(0x64)))
    );
  }
}