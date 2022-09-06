// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IHub.sol";

contract MetatopiaSeason1Hub is IHub, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => bool) gameContracts;
    // set of all staked Genesis holders
    EnumerableSet.AddressSet private stakedGenesisHolders;
    // set of all staked Alpha holders
    EnumerableSet.AddressSet private stakedAlphaHolders;
    // set of all staked holders
    EnumerableSet.AddressSet private stakers;
    // array of Owned Genesis token ids
    mapping(address => EnumerableSet.UintSet) genesisOwnedIds;
    // array of Owned Alpha token ids
    mapping(address => EnumerableSet.UintSet) alphaOwnedIds;
    // mapping of tokenIds and what game they are staked in
    mapping(uint16 => uint8) public stakedInGame; // 1 = ForceHQ, 2 = DOGEWorld, 3 = PYEMarket, 4 = BullRun
    // number of Genesis staked
    uint256 public numGenesisStaked;
    // number of Alpha staked
    uint256 public numAlphasStaked;
    // amount of $TOPIA earned so far per holder
    mapping(address => uint256) public totalHolderTOPIA;
    // amount of $TOPIA earned so far
    uint256 public totalTOPIAEarned;

    event TopiaClaimed(address indexed owner, uint256 earned, uint256 blockNum, uint256 timeStamp);

    modifier onlyGames() {
        require(gameContracts[msg.sender], "only game contracts allowed");
        _;
    }

    function emitGenesisStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external override onlyGames {
        if(!stakedGenesisHolders.contains(owner)) {
            stakedGenesisHolders.add(owner);
        }
        if(!stakers.contains(owner)) {
            stakers.add(owner);
        }
        for (uint i = 0; i < tokenIds.length; i++) {
            genesisOwnedIds[owner].add(tokenIds[i]);
            stakedInGame[tokenIds[i]] = gameId;
            numGenesisStaked++;
        }
    }

    function emitAlphaStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external override onlyGames {
        if(!stakedAlphaHolders.contains(owner)) {
            stakedAlphaHolders.add(owner);
        }
        if(!stakers.contains(owner)) {
            stakers.add(owner);
        }
        for (uint i = 0; i < tokenIds.length; i++) {
            alphaOwnedIds[owner].add(tokenIds[i]);
            stakedInGame[tokenIds[i]] = gameId;
            numAlphasStaked++;
        }
    }

    function emitGenesisUnstaked(address owner, uint16[] calldata tokenIds) external override onlyGames {
        for (uint i = 0; i < tokenIds.length; i++) {
            genesisOwnedIds[owner].remove(tokenIds[i]);
            stakedInGame[tokenIds[i]] = 0;
            numGenesisStaked--;
        }
        if(genesisOwnedIds[owner].length() == 0) {
            stakedGenesisHolders.remove(owner);
        }
    }

    function emitAlphaUnstaked(address owner, uint16[] calldata tokenIds) external override onlyGames {
        for (uint i = 0; i < tokenIds.length; i++) {
            alphaOwnedIds[owner].remove(tokenIds[i]);
            stakedInGame[tokenIds[i]] = 0;
            numAlphasStaked--;
        }
        if(alphaOwnedIds[owner].length() == 0) {
            stakedAlphaHolders.remove(owner);
        }
    }

    function emitTopiaClaimed(address owner, uint256 amount) external override onlyGames {
        totalHolderTOPIA[owner] += amount;
        totalTOPIAEarned += amount;
        emit TopiaClaimed(owner, amount, block.number, block.timestamp);
    }

    function balanceOf(address owner) external view override returns (uint256) {
        uint256 stakedBalance = alphaOwnedIds[owner].length() + genesisOwnedIds[owner].length();
        return stakedBalance;
    }

    function getUserGenesisStaked(address owner) external view returns (uint16[] memory stakedGenesis) {
        uint256 length = genesisOwnedIds[owner].length();
        stakedGenesis = new uint16[](length);
        for(uint i = 0; i < length; i++) {
            stakedGenesis[i] = uint16(genesisOwnedIds[owner].at(i));
        }
    }

    function getUserAlphaStaked(address owner) external view returns (uint16[] memory stakedAlphas) {
        uint256 length = alphaOwnedIds[owner].length();
        stakedAlphas = new uint16[](length);
        for(uint i = 0; i < length; i++) {
            stakedAlphas[i] = uint16(alphaOwnedIds[owner].at(i));
        }
    }

    function getStakedGenesisUsers() external view returns (address[] memory stakedGenesisUsers) {
        uint256 length = stakedGenesisHolders.length();
        stakedGenesisUsers = new address[](length);
        for(uint i = 0; i < length; i++) {
            stakedGenesisUsers[i] = stakedGenesisHolders.at(i);
        }
    }

    function getStakedAlphaUsers() external view returns (address[] memory stakedAlphaUsers) {
        uint256 length = stakedAlphaHolders.length();
        stakedAlphaUsers = new address[](length);
        for(uint i = 0; i < length; i++) {
            stakedAlphaUsers[i] = stakedAlphaHolders.at(i);
        }
    }

    function getAllHolderEarnings() external view returns (address[] memory staker, uint256[] memory earnings) {
        uint256 length = stakers.length();
        staker = new address[](length);
        earnings = new uint256[](length);
        for(uint i = 0; i < length; i++) {
            address s = stakers.at(i);
            staker[i] = s;
            earnings[i] = totalHolderTOPIA[s];
        }
    }

    function setGameContract(address _contract, bool flag) external onlyOwner {
        gameContracts[_contract] = flag;
    }
}