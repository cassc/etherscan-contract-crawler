// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

/*

                                            .^!7777777?J?!:.
                          ~~:            ^?5GB######&&#P7:.
                        !YP5J~          ^YB&@@@@@@@@@B5?~.
                      [email protected]@P!.        !5#@@@@@@@@@@#P~
                  .!JG&@@#Y:       ^[email protected]@@@@@@@@@@#Y:
                  :JG&@@@@&5~.    :~Y&@@@@@@@@@@@@#J          ..::..
                  !#@@@@@@&#P7.  :?G&@@@@@@@@@@@@@&GJ~:~?YPGGBBBBBBBBGG5J~:.
                  7&@@@@@@@@&GY?JP#@@@@@@@@@@@@@@@@@&&##&&@@@@@@@@@@@@@@&#P!
                :J#@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P7^.
                :J#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&B?
                  7&@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@&#B5J?77?YYJ7^.
                  !#@@@@@@@@@@@@@@&57^~~~~~~~~~~~~~~^75&@@@@@@@@@@&B57^..    ..::.
      ~77^.       ~P#&@@@@@@@@@@&B5~                  ~5B&@@@@@@@@&P7:
      JB&GY~       ^5#@@@@@@@@@@BJ:                    :[email protected]@@@@@@@@&B57~:
      7P#@&P!^.    ^5#@@@@@@@@&P7:                      :7P&@@@@@@@@@@&B5?~.
      !5B&@@@B5JJJ5G#@@@@@@@@&G!.                        .!G&@@@@@@@@@@@@@#P?~.
      7P#&@@@@@@@@@@@@@@@@@@#Y:.                          .:Y#@@@@@@@@@@@@@@@GJ^
      75B&@@@@@@@@@@@@@@@@&GY~                              ~YG&@@@@@@@@@@@@@@&GJ^
      .!Y&@@@@@@@@@@@@@@@@#?.                                .?#@@@@@@@@@@@@@@@@&Y!:
        ^JG&@@@@@@@@@@@@@@&GY~                              ~JG&@@@@@@@@@@@@@@@@&B57
          ^[email protected]@@@@@@@@@@@@@@#Y.                            .J#@@@@@@@@@@@@@@@@@@&#P7
          .~?P#@@@@@@@@@@@@@#G!.                        .!P#@@@@@@@@&[email protected]@@&B5!
              .~?5B&@@@@@@@@@@&P7:                      :7P&@@@@@@@@&5^    .^!P&@#P7
                :~75B&@@@@@@@@@BJ:                    [email protected]@@@@@@@@@#5^       ~YG&BJ
                    :7P&@@@@@@@@&B5~                  ^YB&@@@@@@@@@@@#G~       .^77^
        .::..    ..:!YB&@@@@@@@@@@&5!^^~~~~~~~~~~~~^^!Y&@@@@@@@@@@@@@@#!
      .^7JYY?77?J5G#&@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@&?.
        . JB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#J:
          .^7P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@#J:
              !P#&@@@@@@@@@@@@@@@&##&&@@@@@@@@@@@@@@@@@#PYJYG&@@@@@@@@&?
              .:~JPGBBBBBBBBBBGP5?!^~JG&@@@@@@@@@@@@@&B?:...!5B&@@@@@@#!
                    .:::::.          [email protected]@@@@@@@@@@@&5!:     ~5&@@@@&BJ^
                                    .Y#@@@@@@@@@@@B5^       :Y#@@&BY!.
                                    ^P#@@@@@@@@@@#5!        .!5&@BJ:
                                .^[email protected]@@@@@@@@&BY~.         ~J5PY!
                              ..!PB&&######BG5?^            :~~.
                              .:~?J?7777777!~.
 */

import {IronPawGang} from "./IronPawGang.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {IERC721Receiver} from "openzeppelin/token/ERC721/IERC721Receiver.sol";

contract IronPawGangDriverRegistry is IERC721Receiver, Ownable, ReentrancyGuard {
    event DriverSwap(uint256 indexed tokenA, uint256 indexed tokenB);

    error PleaseUseRegistryToDepositError();
    error OutOfBoundsError();
    error SenderNotDepositor();
    error SwapDisabledError();
    error TokenNotDepositedError();
    error WithdrawTimeLockError();

    IronPawGang ironPawGang;
    uint256 public constant MAX_SUPPLY = 4000;

    bool public swapEnabled;
    mapping(uint256 => uint256) private _driverIDs;
    mapping(uint256 => address) private _idsToDepositors;
    mapping(address => uint256[]) private _depositorToIds;
    mapping(uint256 => address) private _depositors;

    uint256 public withdrawLockDuration = 0;
    mapping(uint256 => uint256) private _depositTimes;

    constructor(address ironPawAddress) {
        ironPawGang = IronPawGang(ironPawAddress);
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setWithdrawLockDuration(uint256 duration) external onlyOwner {
        withdrawLockDuration = duration;
    }

    function driverId(uint256 tokenId) public view returns (uint256) {
        if (tokenId < 1 || tokenId > MAX_SUPPLY) revert OutOfBoundsError();

        uint256 swappedId = _driverIDs[tokenId];
        if (swappedId != 0) return swappedId;

        return tokenId;
    }

    function depositAndSwap(uint256 a, uint256 b) external nonReentrant {
        if (!swapEnabled) revert SwapDisabledError();

        if (!holds(a)) ironPawGang.safeTransferFrom(_msgSender(), address(this), a);
        if (!holds(b)) ironPawGang.safeTransferFrom(_msgSender(), address(this), b);

        uint256 aDriver = driverId(a);
        uint256 bDriver = driverId(b);

        _driverIDs[a] = bDriver;
        _driverIDs[b] = aDriver;

        emit DriverSwap(a, b);
    }

    function withdraw() external nonReentrant {
        uint256[] memory tokenIds = deposits(_msgSender());

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (tokenId == 0) continue;
            if (timeSinceDeposit(tokenId) < withdrawLockDuration) continue;

            _withdrawToken(tokenId, _msgSender());
        }
    }

    function timeSinceDeposit(uint256 tokenId) public view returns (uint256) {
        return block.timestamp - depositTime(tokenId);
    }

    function depositTime(uint256 tokenId) public view returns (uint256) {
        return _depositTimes[tokenId];
    }

    function holds(uint256 tokenId) public view returns (bool) {
        return ironPawGang.ownerOf(tokenId) == address(this);
    }

    function deposits(address depositor) public view returns (uint256[] memory) {
        return _depositorToIds[depositor];
    }

    function depositorOf(uint256 tokenId) public view returns (address) {
        return _depositors[tokenId];
    }

    function rescueToken(uint256 tokenId, address to) external onlyOwner {
        _withdrawToken(tokenId, to);
    }

    function _withdrawToken(uint256 tokenId, address to) internal {
        _arrayRemove(_depositorToIds[_msgSender()], tokenId);
        _depositors[tokenId] = address(0);
        ironPawGang.safeTransferFrom(address(this), to, tokenId);
    }

    function _arrayRemove(uint256[] storage array, uint256 element) internal {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element) {
                array[i] = array[array.length - 1];
                array.pop();
                return;
            }
        }
    }

    // IERC721Receiver

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata)
        external
        returns (bytes4)
    {
        if (operator != address(this)) revert PleaseUseRegistryToDepositError();

        _depositorToIds[from].push(tokenId);
        _depositTimes[tokenId] = block.timestamp;
        _depositors[tokenId] = from;

        return this.onERC721Received.selector;
    }
}