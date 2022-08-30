//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IRandom.sol";

contract Raffle is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    IERC721Receiver
{
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721 public nft;
    IRandom internal randomizer;

    EnumerableSet.UintSet internal _tokens;
    mapping(uint256 => address) internal _tokenToOwner;

    uint256 public currentPrizeNumber;

    mapping(uint256 => uint256) internal _shares;
    mapping(uint256 => uint256) internal _released;
    uint256 internal _totalReleased;
    uint256 public totalSupply;

    //function initialize() public initializer {
    //    __Ownable_init();
    //    __Pausable_init();
    //    currentPrizeNumber = 1;
    //}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}