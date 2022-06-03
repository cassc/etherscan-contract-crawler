// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/TimeUtil.sol";

/**
    code    |	 meaning
    400	    |    Invalid params
    404	    |    TokenId nonexistent
    101	    |    Contract has been locked and URI can't be changed
    102	    |    Not authorized
    103	    |    Already generate done
    104	    |    Time is illegal
 */

contract EurekaRabbit is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    // tokenId counter
    using Counters for Counters.Counter;
    Counters.Counter    private _tokenIds;
    uint    public  totalSupply;

    uint constant private totalCount = 3261;
    uint private alreadyPopCount;
    bool public contractLocked = false;
    address mintvialAddress; // Approved mintvial contract
    address gotoMoonAddress; // Approved go moon contract
    string public baseUri;
    uint private lastSalt;
    uint private oddSalt;
    uint private evenSalt;

    uint[totalCount] public pool;

    mapping (uint256 => uint256) public realIdMap;
    mapping (uint256 => uint) public luckyCardStatus;
    mapping (uint256 => uint) public holdTime;
    mapping (address => bool) public minter;
    address private LCSigner;

    constructor(string memory _baseUri) ERC721("EurekaRabbit", "Rabbit") {
        baseUri = _baseUri; // Initial base URI
        lastSalt = uint256(keccak256(abi.encodePacked(msg.sender, lastSalt, block.coinbase)));
    }
    // Change the mintvial address contract
    function setMintvialAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "400");
        mintvialAddress = newAddress;
    }
    function setGoMoonAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "400");
        gotoMoonAddress = newAddress;
    }
    function setLCSignerAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "400");
        LCSigner = newAddress;
    }
    function setBaseUri(string memory newUri) external onlyOwner {
        require(!contractLocked, "101");
        baseUri = newUri;
    }
    function setMinter(address _minter, bool yea) external onlyOwner {
        minter[_minter] = yea;
    }
    function lockContract() external onlyOwner {
        contractLocked = true;
    }

    // Only ERC-1155 can do this
    function mintTransfer(address to) external returns(uint256) {
        require(msg.sender == mintvialAddress, "102");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        uint realId = generateRandomId(to);
        realIdMap[tokenId] = realId;
        // The top 78 open lucky card first
        if (realId >= 3184) luckyCardStatus[tokenId] = getDaysFrom1970();
        totalSupply++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    // Only the future contract can do this
    // If executed, the NFT is upgraded to a higher level
    function goMoon(uint tokenId) external {
        require(msg.sender == gotoMoonAddress, "102");
        totalSupply--;
        _burn(tokenId);
    }

    /** OVERRIDES */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "404");
        uint realId = realIdMap[tokenId];
        realId += (luckyCardValue(tokenId) * totalCount);
        return string(abi.encodePacked(baseUri, realId.toString()));
    }

    event UnLock(uint indexed tokenId, uint theDay);
    // It can be triggered by community activities, completing tasks or other activities etc
    function unlock(uint tokenId) external {
        require(minter[msg.sender], "102");
        uint theDay = getDaysFrom1970();
        luckyCardStatus[tokenId] = theDay;
        emit UnLock(tokenId, theDay);
    }

    // You can also choose to unlock yourself if certain missions are completed
    function unlockBySelf(uint tokenId, string calldata salt, bytes memory token, uint validDay) external {
        require(_recover(_hash(salt, msg.sender, tokenId, validDay), token) == LCSigner, "400");
        uint theDay = getDaysFrom1970();
        require(theDay == validDay, "104");
        luckyCardStatus[tokenId] = theDay;
        emit UnLock(tokenId, theDay);
    }

    /*******************************************************the random*********************************************************/
    function generateRandomId(address source) private returns(uint randomId) {
        require(alreadyPopCount < totalCount, "103");
        uint rand = uint256(
            keccak256(abi.encodePacked(source, TimeUtil.currentTime(), block.difficulty, block.number, lastSalt, alreadyPopCount)));
        randomId = getIndex(rand) + 1;
    }

    // Get the index from the pool
    function getIndex(uint rand) private returns (uint) {
        uint lastCount = totalCount - alreadyPopCount;
        uint index = rand % lastCount;
        uint target = pool[index];
        uint pointIndex = target > 0 ? target : index;
        target = pool[--lastCount];
        pool[index] = target > 0 ? target : lastCount;
        alreadyPopCount++;
        return pointIndex;
    }

    /******************************************************* Tarot *********************************************************/
    event ActiveluckyCard(address sender, address from, address to, uint indexed tokenId);
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        uint tempLastSalt = lastSalt;
        if (address(0) != from && address(0) != to) {
            if (luckyCardStatus[tokenId] == 0) {
                uint rand = uint256(keccak256(abi.encodePacked(TimeUtil.currentTime(), block.difficulty, block.number, tempLastSalt)));
                if (rand % 100 >= 90) {
                    // Congratulations! You will soon open luckyCard if the amount is reasonable
                    emit ActiveluckyCard(msg.sender, from, to, tokenId);
                }
            }
            // We will use the last owner to add salt
            tempLastSalt = lastSalt = uint256(keccak256(abi.encodePacked(from, to, tempLastSalt, block.coinbase, block.difficulty, block.number)));
        }

        if (getDaysFrom1970() % 2 == 0) {
            oddSalt = uint256(keccak256(abi.encodePacked(tokenId, oddSalt, tempLastSalt)));
        } else {
            evenSalt = uint256(keccak256(abi.encodePacked(tokenId, evenSalt, tempLastSalt)));
        }
        holdTime[tokenId] = TimeUtil.currentTime();
    }

    // Query if the address has a winning tokens
    function getWinnerIdWithLuckyNum(address addr, uint luckyNum) external view returns (uint[] memory tokenIds, uint winnerCount) {
        if (balanceOf(addr) == 0) return (tokenIds, 0);
        uint[] memory luckyIds = getWinnerTokenIds(luckyNum);
        if (luckyIds.length == 0) return (tokenIds, 0);
        winnerCount = luckyIds.length;
        tokenIds = new uint[](winnerCount);
        uint count = 0;
        for (uint i = 0; i < luckyIds.length; i++) {
            if (ownerOf(luckyIds[i]) == addr) tokenIds[count++] = luckyIds[i];
        }
        if (count == luckyIds.length) return (tokenIds, winnerCount);
        uint[] memory realTokenIds = new uint[](count);
        for (uint j = 0; j < count; j++) {
            realTokenIds[j] = tokenIds[j];
        }
        return (realTokenIds, winnerCount);
    }

    // Query the list of today's winners
    function getWinnerTokenIds(uint luckyNum) public view returns (uint[] memory tokenIds) {
        uint count = 0;
        tokenIds = new uint[](alreadyPopCount);
        for (uint i = 1; i <= alreadyPopCount; i++) {
            if (luckyCardValue(i) == luckyNum) tokenIds[count++] = i;
        }
        if (count == alreadyPopCount) return tokenIds;
        uint[] memory realTokenIds = new uint[](count);
        for (uint j = 0; j < count; j++) {
            realTokenIds[j] = tokenIds[j];
        }
        return realTokenIds;
    }

    // Get lucky value
    // 0:not open      1:totay     >=2:the value
    function luckyCardValue(uint tokenId) public view returns (uint) {
        if (luckyCardStatus[tokenId] == 0) return 0;
        uint theDay = getDaysFrom1970();
        if (theDay == luckyCardStatus[tokenId]) return 1;
        if (theDay % 2 == 0) {
            return uint256(keccak256(abi.encodePacked(theDay, evenSalt, tokenId))) % 78 + 2;
        } else {
            return uint256(keccak256(abi.encodePacked(theDay, oddSalt, tokenId))) % 78 + 2;
        }
    }

    // The days
    function getDaysFrom1970() private view returns (uint _days) {
        _days = TimeUtil.currentTime() / 86400;
    }

    // tools
    function _hash(string calldata salt, address _address, uint tokenId, uint validDay) private view returns (bytes32) {
        return keccak256(abi.encode(salt, address(this), _address, tokenId, validDay));
    }
    function _recover(bytes32 hash, bytes memory token) private pure returns (address) {
        return hash.toEthSignedMessageHash().recover(token);
    }
}