//SPDX-License-Identifier: NONE
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

//import "hardhat/console.sol";

//  ██████╗  ██████╗  ██████╗ ███████╗██████╗  █████╗ ██╗     ██╗          ██████╗  █████╗ ███╗   ██╗ ██████╗
// ██╔════╝ ██╔═══██╗██╔═══██╗██╔════╝██╔══██╗██╔══██╗██║     ██║         ██╔════╝ ██╔══██╗████╗  ██║██╔════╝
// ██║  ███╗██║   ██║██║   ██║█████╗  ██████╔╝███████║██║     ██║         ██║  ███╗███████║██╔██╗ ██║██║  ███╗
// ██║   ██║██║   ██║██║   ██║██╔══╝  ██╔══██╗██╔══██║██║     ██║         ██║   ██║██╔══██║██║╚██╗██║██║   ██║
// ╚██████╔╝╚██████╔╝╚██████╔╝██║     ██████╔╝██║  ██║███████╗███████╗    ╚██████╔╝██║  ██║██║ ╚████║╚██████╔╝
//  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝
// $GOOF token contract
// Utility token for modifying goofball NFTs
//
// https://www.goofballgang.com

contract NFTContract {
    function ownerOf(uint256 tokenId) external view returns (address owner) {}

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {}
}

contract GoofToken is Ownable, ERC20("Goofball Gang Token", "GOOF"), ERC20Burnable {
    uint256 public constant DAILY_RATE = 10 ether;

    uint256 public constant START_TIME = 1634250000; /* ~Oct 15th 2021 */
    uint256 public constant TIME_BLOCKSIZE = 10_000;

    uint256 public constant BONUS_TIME_LIMIT_1 = 1638316800; /* Dec 1st 2021 */
    uint256 public constant BONUS_TIME_LIMIT_2 = 1640995200; /* Jan 1st 2022 */

    uint256 public constant MIN_NAME_LENGTH = 2;
    uint256 public constant MAX_NAME_LENGTH = 30;

    event ChangeCommit(uint256 indexed tokenId, uint256 price, bytes changeData);
    event NameChange(uint256 indexed tokenId, bytes newName);

    NFTContract private delegate;
    uint256 public nameChangePrice = 1000 ether;
    uint256 public distributionEndTime = 1798761600; /* Jan 1st 2027 */
    uint256 public gweiPerGoof = 0;

    /** 
        We stash 16 last update timestamps in every 256 bit word by using only 16
        bits for the last update time.
        Every 16 bit value encodes 10,000 seconds (TIME_BLOCKSIZE) since START_TIME (Nov 1st 2021),
        so we can encode an interval of 20 years.
    */
    mapping(uint256 => uint256) public lastUpdateMap;

    mapping(uint256 => bytes) public goofNameMap;
    mapping(bytes => uint256) public nameOwnerMap;

    mapping(address => uint256) public permittedContracts;

    constructor(address nftContract, uint256 initialSupply) {
        delegate = NFTContract(nftContract);
        _mint(msg.sender, initialSupply);
    }

    function getUpdateTime(uint256 id) public view returns (uint256 updateTime) {
        uint256 value = lastUpdateMap[id >> 4];
        value = (value >> ((id & 0xF) << 4)) & 0xFFFF;
        return value * TIME_BLOCKSIZE + START_TIME;
    }
    function setUpdateTime(uint256 id, uint256 time) internal returns (uint256 roundedTime) {
        require(time > START_TIME, "invalid time");
        uint256 currentValue = lastUpdateMap[id >> 4];
        uint256 shift = ((id & 0xF) << 4);
        uint256 mask = ~(0xFFFF << shift);
        // Round up block time
        uint256 newEncodedValue = (time - START_TIME + TIME_BLOCKSIZE - 1) / TIME_BLOCKSIZE;
        lastUpdateMap[id >> 4] = ((currentValue & mask) | (newEncodedValue << shift));
        return newEncodedValue * TIME_BLOCKSIZE + START_TIME;
    }

    function setPermission(address addr, uint256 permitted) public onlyOwner {
        permittedContracts[addr] = permitted;
    }

    function setGweiPerGoof(uint256 value) public onlyOwner {
        gweiPerGoof = value;
    }

    function getName(uint256 id) public view returns (string memory) {
        return string(abi.encodePacked(goofNameMap[id]));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function setNameChangePrice(uint256 price) public onlyOwner {
        nameChangePrice = price;
    }

    function setDistributionEndTime(uint256 endTime) public onlyOwner {
        distributionEndTime = endTime;
    }

    function getInitialGrant(uint256 t) public pure returns (uint256) {
        if (t < BONUS_TIME_LIMIT_1) {
            return 1000 ether;
        }
        if (t < BONUS_TIME_LIMIT_2) {
            return 500 ether;
        } else {
            return 0;
        }
    }

    function getGrantBetween(uint256 beginTime, uint256 endTime) public pure returns (uint256) {
        if (beginTime > BONUS_TIME_LIMIT_2) {
            return ((endTime - beginTime) * DAILY_RATE) / 86400;
        }
        uint256 weightedTime = 0;
        if (beginTime < BONUS_TIME_LIMIT_1) {
            weightedTime += (min(endTime, BONUS_TIME_LIMIT_1) - beginTime) * 4;
        }
        if (beginTime < BONUS_TIME_LIMIT_2 && endTime > BONUS_TIME_LIMIT_1) {
            weightedTime += (min(endTime, BONUS_TIME_LIMIT_2) - max(beginTime, BONUS_TIME_LIMIT_1)) * 2;
        }
        if (endTime > BONUS_TIME_LIMIT_2) {
            weightedTime += endTime - max(beginTime, BONUS_TIME_LIMIT_2);
        }
        return (weightedTime * DAILY_RATE) / 86400;
    }

    function claim(uint256 tokenId) internal returns (uint256) {
        uint256 lastUpdate = getUpdateTime(tokenId);
        // Round up by block
        uint256 timeUpdate = min(block.timestamp, distributionEndTime);
        timeUpdate = setUpdateTime(tokenId, timeUpdate);
        if (lastUpdate == START_TIME) {
            return getInitialGrant(timeUpdate);
        } else {
            return getGrantBetween(lastUpdate, timeUpdate);
        }
    }

    function claimReward(uint256[] memory id) public {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < id.length; i++) {
            require(delegate.ownerOf(id[i]) == msg.sender, "id not owned");
            totalReward += claim(id[i]);
        }
        if (totalReward > 0) {
            _mint(msg.sender, totalReward);
        }
    }

    function claimFull() public {
        claimFullFor(msg.sender);
    }

    function claimFullFor(address addr) public {
        uint256[] memory id = delegate.walletOfOwner(addr);
        uint256 totalReward = 0;
        for (uint256 i = 0; i < id.length; i++) {
            totalReward += claim(id[i]);
        }
        if (totalReward > 0) {
            _mint(addr, totalReward);
        }
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    // burn tokens, allowing sent ETH to be converted according to gweiPerGoof
    function burnTokens(uint256 amount) private {
        if (msg.value > 0 && gweiPerGoof > 0) {
            uint256 converted = (msg.value * 1 gwei) / gweiPerGoof;
            if (converted >= amount) {
                amount = 0;
            } else {
                amount -= converted;
            }
        }
        if (amount > 0) {
            _burn(msg.sender, amount);
        }
    }

    // Buy items
    function commitChange(
        uint256 tokenId,
        uint256 pricePaid,
        bytes memory changeData
    ) public payable {
        require(delegate.ownerOf(tokenId) == msg.sender, "not owner");
        burnTokens(pricePaid);
        emit ChangeCommit(tokenId, pricePaid, changeData);
    }

    function isValidName(bytes memory nameBytes) public pure returns (bool) {
        if (nameBytes.length < MIN_NAME_LENGTH || nameBytes.length > MAX_NAME_LENGTH) {
            return false;
        }
        uint8 prevChar = 32;
        for (uint256 i = 0; i < nameBytes.length; i++) {
            uint8 ch = uint8(nameBytes[i]);
            if (ch == 32 && prevChar == 32) {
                return false; // no repeated spaces (and also checks first character)
            }
            // allow letter, numbers, punctuation, but no risk of HTML tags (<>) or
            // impersonating another goofball (# sign)
            if (!(ch >= 32 && ch <= 126) || ch == 60 || ch == 62 || ch == 35) {
                return false;
            }
            prevChar = ch;
        }
        if (prevChar == 32) {
            // No trailing space
            return false;
        }
        return true;
    }

    function toLower(bytes memory name) private pure returns (bytes memory) {
        bytes memory lowerCased = new bytes(name.length);
        for (uint256 i = 0; i < name.length; i++) {
            uint8 ch = uint8(name[i]);
            if (ch >= 65 && ch <= 90) {
                lowerCased[i] = bytes1(
                    ch +
                        97 - /* 'a' */
                        65 /* 'A' */
                );
            } else {
                lowerCased[i] = bytes1(ch);
            }
        }
        return lowerCased;
    }

    function changeName(uint256 tokenId, bytes memory newName) public payable {
        require(newName.length == 0 || isValidName(newName), "not valid name");
        require(delegate.ownerOf(tokenId) == msg.sender, "not owner");

        bytes memory lowerCased = toLower(newName);
        if (newName.length > 0) {
            uint256 nameOwner = nameOwnerMap[lowerCased];
            // 0 = nobody, other number is id + 1
            require(nameOwner == 0 || nameOwner == tokenId + 1, "name duplicate");
        }
        burnTokens(nameChangePrice);

        bytes memory currentName = goofNameMap[tokenId];
        if (currentName.length > 0) {
            delete nameOwnerMap[toLower(currentName)];
        }
        goofNameMap[tokenId] = newName;
        if (newName.length > 0) {
            nameOwnerMap[lowerCased] = tokenId + 1;
        }
        emit NameChange(tokenId, newName);
    }

    function permittedMint(address destination, uint256 amount) public {
        require(permittedContracts[msg.sender] == 1);
        _mint(destination, amount);
    }

    function permittedBurn(address src, uint256 amount) public {
        require(permittedContracts[msg.sender] == 1);
        _burn(src, amount);
    }

    function permittedTransfer(
        address src,
        address dest,
        uint256 amount
    ) public {
        require(permittedContracts[msg.sender] == 1);
        _transfer(src, dest, amount);
    }

    function withdrawBalance(address to, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }
        // https://consensys.github.io/smart-contract-best-practices/recommendations/#dont-use-transfer-or-send
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}