// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract GangWars is ERC1155, Ownable {

    struct SaleRound {
        uint price; // wei
        uint32 quantity;
        uint32 timestamp;
        bool whitelist;
        string uri;
    }

    uint32 idCounter = 0;

    SaleRound[] public saleRounds;
    bool isMintStarted = true;
    bool isFrozen = false;
    uint32 userMintLimitPerRound = 5;

    mapping(uint32 => uint32) public cardRound; // card id => round id
    mapping(uint32 => uint32) public cardsSold; // round id => quantity
    mapping(address => mapping(uint32 => uint32)) userMintedPerRound; // user => round id => sales
    mapping(address => uint32[]) collection; // user > card ids

    string private placeholderURI;

    constructor(string memory _uri, SaleRound[] memory rounds) ERC1155(_uri) {
        placeholderURI = _uri;
        setRounds(rounds);
    }

    function setRounds(SaleRound[] memory rounds) public onlyOwner {
        require(isFrozen == false);
        if (saleRounds.length > 0) {
            delete saleRounds;
        }
        for (uint32 i = 0; i < rounds.length; i++) {
            saleRounds.push(rounds[i]);
        }
    }

    function froze() external onlyOwner {
        isFrozen = true;
    }

    function setConfigs(bool _isMintStarted, uint32 _userMintLimitPerRound) external onlyOwner {
        isMintStarted = _isMintStarted;
        userMintLimitPerRound = _userMintLimitPerRound;
    }

    function withdrawEther(uint amount, address payable to) external onlyOwner {
        to.transfer(amount);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        if (block.timestamp >= saleRounds[saleRounds.length - 1].timestamp) {
            return saleRounds[saleRounds.length - 1].uri;
        }
        if (cardRound[uint32(id)] + 1 == saleRounds.length ||
            block.timestamp >= saleRounds[cardRound[uint32(id)] + 1].timestamp
        ) {
            return saleRounds[cardRound[uint32(id)]].uri;
        }
        return placeholderURI;
    }

    function mint(uint32 quantity, bytes32 hash, uint8 _v, bytes32 _r, bytes32 _s) payable external {

        require(isMintStarted, "stopped");
        require(block.timestamp >= saleRounds[0].timestamp, "time");

        uint32 currentRound;
        uint32 cardsNumber;
        for (uint32 i = 0; i < saleRounds.length; i++) {
            cardsNumber += saleRounds[i].quantity - cardsSold[i];
            if (saleRounds[i].timestamp <= block.timestamp) {
                if (i + 1 == saleRounds.length || saleRounds[i + 1].timestamp > block.timestamp) {
                    currentRound = i;
                    break;
                }
            }
            if (i + 1 == saleRounds.length - 1 && cardsNumber > 0) {
                currentRound = i;
                break;
            }
        }

        if (saleRounds[currentRound].whitelist) {
            require(
                owner() == ecrecover(
                    keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s
                ) && keccak256(abi.encodePacked(msg.sender, currentRound)) == hash
            , "whitelist");
        }

        require(userMintedPerRound[msg.sender][currentRound] < userMintLimitPerRound, "limit");
        require(msg.value >= saleRounds[currentRound].price, "value");
        require(cardsNumber > 0, "sold out");

        uint32 times = msg.value == 0 ? quantity : uint32(msg.value / saleRounds[currentRound].price);
        uint32 limit = userMintLimitPerRound - userMintedPerRound[msg.sender][currentRound];
        if (limit < times) {
            times = limit;
        }
        if (cardsNumber < times) {
            times = cardsNumber;
        }
        if (msg.value > times * saleRounds[currentRound].price) {
            payable(msg.sender).transfer(msg.value - times * saleRounds[currentRound].price);
        }

        uint32 j = 0;
        while (times > 0) {
            idCounter++;
            j++;
            userMintedPerRound[msg.sender][currentRound]++;
            times--;

            uint32 totalQuantity;
            for (uint32 i = 0; i < saleRounds.length; i++) {
                totalQuantity += saleRounds[i].quantity;
                if (idCounter <= totalQuantity) {
                    cardRound[idCounter] = i;
                    cardsSold[i]++;
                    break;
                }
            }

            _mint(msg.sender, idCounter, 1, "");
        }
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override(ERC1155) {
        if (to != address(0)) {// mint || transfer
            for (uint32 i = 0; i < ids.length; i++) {
                collection[to].push(uint32(ids[i]));
            }
        }
        if (from != address(0)) {// transfer
            for (uint32 i = 0; i < ids.length; i++) {
                for (uint32 j = 0; j < collection[from].length; j++) {
                    if (collection[from][j] == ids[i]) {
                        delete collection[from][j];
                    }
                }
            }
        }
    }

    function getCollection(address user) external view returns (uint32[] memory, string[] memory) {
        uint32[] memory ids = new uint32[](collection[user].length);
        string[] memory _uris = new string[](collection[user].length);
        for (uint32 i = 0; i < collection[user].length; i++) {
            ids[i] = collection[user][i];
            _uris[i] = uri(ids[i]);
        }
        return (ids, _uris);
    }

    receive() payable external {
        revert();
    }
}