// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITokenLockerManagerV1 } from "./ITokenLockerManagerV1.sol";
import { Ownable } from "./Ownable.sol";
import { IERC20 } from "./library/IERC20.sol";
import { TokenLockerV1 } from "./TokenLockerV1.sol";

contract TokenLockerManagerV1 is ITokenLockerManagerV1, Ownable {
  event TokenLockerCreated(
    uint40 id,
    address indexed token,
    /** @dev LP token pair addresses - these will be address(0) for regular tokens */
    address indexed token0,
    address indexed token1,
    address createdBy,
    uint256 balance,
    uint40 unlockTime
  );

  constructor() Ownable(_msgSender()) {
    _creationEnabled = true;
  }

  bool private _creationEnabled;

  uint40 private _tokenLockerCount;

  /** @dev main mapping for lock data */
  mapping(uint40 => TokenLockerV1) private _tokenLockers;

  /**
   * @dev this mapping makes it possible to search for locks,
   * at the cost of paying higher gas fees to store the data.
   */
  mapping(address => uint40[]) private _tokenLockersForAddress;
  mapping (address => bool) private isExempt;
  modifier allowCreation() {
    require(_creationEnabled, "Locker creation is disabled");
    _;
  }

  function tokenLockerCount() external view override returns (uint40) {
    return _tokenLockerCount;
  }

  function creationEnabled() external view override returns (bool) {
    return _creationEnabled;
  }

  /**
   * @dev allow turning off new lockers from being created, so that we can
   * migrate to new versions of the contract & stop people from locking
   * with the older versions. this will not prevent extending, depositing,
   * or withdrawing from old locks - it only stops new locks from being created.
   */
  function setCreationEnabled(bool value_) external override onlyOwner {
    _creationEnabled = value_;
  }

  function createTokenLocker(
    address tokenAddress_,
    uint256 amount_,
    uint40 unlockTime_
  ) external override allowCreation {
    uint40 id = _tokenLockerCount++;
    _tokenLockers[id] = new TokenLockerV1(address(this), id, _msgSender(), tokenAddress_, unlockTime_);
    address lockerAddress = address(_tokenLockers[id]);

    IERC20 token = IERC20(tokenAddress_);
    token.transferFrom(_msgSender(), lockerAddress, amount_);

    // add the creator to the token locker mapping, so it's
    // able to be searched.
    _tokenLockersForAddress[_msgSender()].push(id);

    // add the locked token to the token lockers mapping
    _tokenLockersForAddress[tokenAddress_].push(id);
    // add the locker contract to this mapping as well, so it's
    // searchable in the same way as tokens within the locker.
    _tokenLockersForAddress[lockerAddress].push(id);

    // get lp data
    (bool hasLpData,,address token0Address,address token1Address,,,,) = _tokenLockers[id].getLpData();

    // if this is an lp token, also add the paired tokens to the mapping
    if (hasLpData) {
      _tokenLockersForAddress[token0Address].push(id);
      _tokenLockersForAddress[token1Address].push(id);
    }

    emit TokenLockerCreated(
      id,
      tokenAddress_,
      token0Address,
      token1Address,
      _msgSender(),
      token.balanceOf(lockerAddress),
      unlockTime_
    );
  }

  /**
   * @return the address of a locker contract with the given id
   */
  function getTokenLockAddress(uint40 id_) external view override returns (address) {
    return address(_tokenLockers[id_]);
  }



  function getTokenLockData(uint40 id_) external view override returns (
    bool isLpToken,
    uint40 id,
    address contractAddress,
    address lockOwner,
    address token,
    address createdBy,
    uint40 createdAt,
    uint40 unlockTime,
    uint256 balance,
    uint256 totalSupply
  ){
    return _tokenLockers[id_].getLockData();
  }

  function getLpData(uint40 id_) external view override returns (
    bool hasLpData,
    uint40 id,
    address token0,
    address token1,
    uint256 balance0,
    uint256 balance1,
    uint256 price0,
    uint256 price1
  ) {
    return _tokenLockers[id_].getLpData();
  }

  /** @return an array of locker ids matching the given search address */
  function getTokenLockersForAddress(address address_) external view override returns (uint40[] memory) {
    return _tokenLockersForAddress[address_];
  }

  function setIsExempt(address owner, bool exempt) external onlyOwner {
      isExempt[owner] = exempt;
  }

  function getIsExempt(address owner) external view returns (bool){
      return isExempt[owner];
  }
  /**
   * @dev this gets called from TokenLockerV1.
   * it notifies this contract of the owner change so we can modify the search index
   */
  function notifyLockerOwnerChange(uint40 id_, address newOwner_, address previousOwner_, address createdBy_) external override {
    require(
      _msgSender() == address(_tokenLockers[id_]),
      "Only the locker contract can call this function"
    );

    // remove the previous owner from the locker address mapping,
    // only if it's not the same address as the creator.
    if (previousOwner_ != createdBy_) {
      for (uint256 i = 0; i < _tokenLockersForAddress[previousOwner_].length; i++) {
        // continue searching for id_ in the array until we find a match
        if (_tokenLockersForAddress[previousOwner_][i] != id_) continue;
        // replace the old item at this index with the last value.
        // we don't care about the order.
        _tokenLockersForAddress[previousOwner_][i] = _tokenLockersForAddress[
          previousOwner_][_tokenLockersForAddress[previousOwner_].length - 1
        ];
        // remove the last item in the array, since we just moved it
        _tokenLockersForAddress[previousOwner_].pop();
        // and we're done
        break;
      }
    }

    // push the new owner to the lockers address mapping so the new owner is searchable,
    // only if they don't already have this id in the lockers address mapping.
    bool hasId = false;

    // look for the id in the new owners address mapping
    for (uint256 i = 0; i < _tokenLockersForAddress[newOwner_].length; i++) {
      if (_tokenLockersForAddress[newOwner_][i] == id_) {
        hasId = true;
        break;
      }
    }

    // only add the id if they didn't already have it
    if (!hasId) {
      _tokenLockersForAddress[newOwner_].push(id_);
    }
  }
}