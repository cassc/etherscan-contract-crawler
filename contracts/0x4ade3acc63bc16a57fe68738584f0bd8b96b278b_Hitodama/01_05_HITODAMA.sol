/*                                                                                                       */
/*                                            ..                                                         */
/*                                              ...                                                      */
/*                                               :!!:                                                    */
/*                                      ..      .^!7!.                                                   */
/*                                       .:   :^~77!~.                                                   */
/*                                            ^77!!^.  ..                                                */
/*                                            .~~!~    ::                                                */
/*                                     .:      ^~?~.  :!?!^.  .                                          */
/*                                     .^~!7!^^7555Y???YYJJ7^.^:                                         */
/*                                 ..   :~75PGB###&#BB#G55YJ!^~!~.                                       */
/*                                  .:^:~?PBB&@@@&&&&Y&#GP5Y?!777~.                                      */
/*                               .:^~7J!?#&&#&@@@@@@##@@#GGJ??7777^                                      */
/*                                :^!7JJ5PB#&@@@@@@#@@@@&#B?!JJ?7~:                                      */
/*                                 .^~~7Y5B#&@@@@@&@@@@&&##Y7G5J!^:                                      */
/*                                  :~~??JPB&@@@@@@@@@&&&&BJ#&#5?7^.                                     */
/*                                  .:!J7!7GB&G#@@@@@@&#BPB&&&B5J7^                                      */
/*                                    .~7!!75PPYPB#&&&&#GGGYGPYJ!:                                       */
/*                                      .^!7!77?JYPG##G5J??Y?~:.                                         */
/*                                        .~7?J?J??????????!:                                            */
/*                                           .^^~~~~~~^::..                                              */
/*                                                                                                       */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ERC721A } from "erc721a/ERC721A.sol";

contract Hitodama is Ownable, ERC721A {
    string public baseURI;
    string public uriSuffix;

    uint256 public maxSupply;

    bool public saleStatus;
    uint256 public price;
    uint256 public maxMintPerWallet;

    struct Stats {
        uint8 strength;
        uint8 intelligent;
        uint8 age;
        uint8 luck;
    }
    mapping(uint256 => Stats) public soulStats;

    mapping(uint256 => uint256) public saveSoulAt;
    mapping(uint256 => uint256) public prayCount;
    mapping(uint256 => uint256) public offeringsCount;
    mapping(uint256 => uint256) public lastPray;
    mapping(uint256 => uint256) public lastOfferings;
    mapping(uint256 => uint256) private _lastSize;

    event Pray(uint256 indexed tokenId, address indexed prayer, uint256 changedAt);
    event Offerings(uint256 indexed tokenId, address indexed offerer, uint256 offerAt);

    constructor(
        string memory uri,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _maxMintPerWallet
    ) ERC721A("HITODAMA", "HITO") {
        baseURI = uri;
        maxSupply = _maxSupply;
        price = _price;
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setBaseURI(string memory uri, string memory _uriSuffix) external onlyOwner {
        baseURI = uri;
        uriSuffix = _uriSuffix;
    }

    function setSalesStatus(bool _status) external onlyOwner {
        saleStatus = _status;
    }

    function setMintDetails(uint256 _price, uint256 _maxMintPerWallet) external onlyOwner {
        price = _price;
        maxMintPerWallet = _maxMintPerWallet;
    }

    function mint(uint256 _quantity) external payable {
        require(saleStatus, "Closed!");
        require(msg.sender == tx.origin, "Not Allowed!");
        require(totalSupply() + _quantity <= maxSupply, "Max Supply!");
        require(_numberMinted(msg.sender) + _quantity <= maxMintPerWallet, "Exceed Limit!");
        require(msg.value >= _quantity * price, "Invalid Price!");

        uint256 nextTokenId = _nextTokenId();
        for (uint256 i = nextTokenId; i < nextTokenId + _quantity; ++i) {
            saveSoulAt[i] = block.timestamp;
            soulStats[i] = _computeInitialStats(i);
            lastPray[i] = block.timestamp;
        }
        _mint(msg.sender, _quantity);
    }

    function summon(uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= maxSupply, "Max Supply!");
        uint256 nextTokenId = _nextTokenId();
        for (uint256 i = nextTokenId; i < nextTokenId + _quantity; ++i) {
            saveSoulAt[i] = block.timestamp;
            soulStats[i] = _computeInitialStats(i);
            lastPray[i] = block.timestamp;
        }
        _mint(msg.sender, _quantity);
    }

    function pray(uint256 tokenId) external {
        require(_exists(tokenId), "No Hito!");
        require(block.timestamp - lastPray[tokenId] >= 1 days, "Only Once Per Day!");
        _lastSize[tokenId] = getCurrentSize(tokenId);
        lastPray[tokenId] = block.timestamp;
        prayCount[tokenId]++;

        emit Pray(tokenId, msg.sender, block.timestamp);
    }

    function offerings(uint256 tokenId) external payable {
        require(_exists(tokenId), "No Hito!");
        require(msg.value >= 0.001 ether, "Insufficient Offerings!");
        soulStats[tokenId].strength++; 
        soulStats[tokenId].intelligent++; 
        soulStats[tokenId].luck++; 
        lastOfferings[tokenId] = block.timestamp;
        offeringsCount[tokenId]++;
        
        emit Offerings(tokenId, msg.sender, block.timestamp);
    }

    function withdraw(address payable _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _receiver.call{ value: balance }("");
        require(success, "Withdraw Failed!");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length != 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), uriSuffix))
                : "";
    }

    function getLastSize(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "No Hito!");
        return _lastSize[tokenId] > 0 ? _lastSize[tokenId] : 250;
    }

    function getCurrentSize(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId), "No Hito!");
        uint256 elapsedTime = getElapsedTimeFromLastPray(tokenId);
        uint256 coefficient = 90000 minutes;
        if (elapsedTime <= 20 days) {
            return uint16((100 * elapsedTime) / coefficient + getLastSize(tokenId));
        } else if (elapsedTime <= 50 days) {
            return uint16((95 * elapsedTime + 1440 * 60 * 100) / coefficient + getLastSize(tokenId));
        } else if (elapsedTime <= 80 days) {
            return uint16((50 * elapsedTime + 33840 * 60 * 100) / coefficient + getLastSize(tokenId));
        } else if (elapsedTime <= 100 days) {
            return uint16((10 * elapsedTime + 79920 * 60 * 100) / coefficient + getLastSize(tokenId));
        } else {
            return uint16(getLastSize(tokenId) + ((94320 * 60 * 100) / coefficient));
        }
    }

    function getElapsedTimeFromLastPray(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "No Hito!");
        return block.timestamp - _lastSize[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _computeInitialStats(uint256 tokenId) internal view returns (Stats memory) {
        uint256 pseudorandomness = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId)));

        uint8 strength = (uint8(pseudorandomness) % 10) + 1;
        uint8 intelligent = (uint8(pseudorandomness >> (8 * 1)) % 10) + 1;
        uint8 age = (uint8(pseudorandomness >> (8 * 2)) % 150) + 1;
        uint8 luck = (uint8(pseudorandomness >> (8 * 3)) % 10) + 1;
        return Stats(strength, intelligent, age, luck);
    }
}