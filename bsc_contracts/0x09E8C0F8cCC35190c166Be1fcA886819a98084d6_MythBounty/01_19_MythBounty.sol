// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "ERC20.sol";
import "Degen.sol";

contract MythralTest is ERC20 {
    constructor() ERC20("Mythral Test", "MTEST") {}

    function mint(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }
}

contract MythBounty {
    //bountys will have an available Pool of MYTHRAL which pays out to address owners
    //Each address will have a total claimed rewards and unclaimed rewards
    //Total claimed rewards and unclaimed rewards and reward pool
    uint256 public bountyCooldownBlocks;
    address public owner;
    address public degenAddress;
    address public rewardsAddress;
    mapping(uint256 => BountyStats) public bountyIds;
    mapping(address => bool) public resolverAddress;
    mapping(uint256 => bool) public bountyExists;
    mapping(uint256 => uint256) public lastBlockOfDegenId;
    mapping(uint256 => uint256) public lastBlockOfWeaponId;
    mapping(uint256 => uint256) public lastBlockOfModId;
    mapping(uint256 => uint256) public lastBlockOfEquipmentId;
    mapping(uint256 => uint256) public blockNumberCount;
    mapping(uint256 => BattleStats) public bountyBattleIds;
    mapping(uint256 => mapping(uint256 => uint256)) public blockToCountToId;
    mapping(uint256 => bool) public resolvedBlock;
    event bountyAdded(
        uint256 bountyId,
        uint256 bountyCore,
        uint256 bountyRewardPercent
    );
    event bountyRemoved(
        uint256 bountyId,
        uint256 bountyCore,
        uint256 bountyRewardPercent
    );

    event bountyStarted(
        uint256 degenId,
        uint256 weaponId,
        uint256 modId,
        uint256 equipmentId,
        uint256 idOfBountyStats,
        address bountyHunterAddress,
        uint256 initializationBlock
    );
    event bountyResolved(
        uint256 bountyId,
        uint256 winnings,
        uint256 numberRolled,
        uint256 degenCore,
        uint256 bountyCore,
        uint256 bountyStatsId,
        address bountyHunter,
        bytes32 resolutionSeed
    );
    struct BountyStats {
        uint256 core;
        uint256 rewardPercent;
    }
    struct BattleStats {
        uint256 bountyId;
        uint256 coreOfDegen;
        uint256 initializationBlock;
        uint256 degenId;
        uint256 weaponId;
        uint256 modId;
        uint256 equipmentId;
        address degenOwner;
        bool degenWinner;
        bytes32 resolutionSeed;
    }

    constructor(address _degenAddress, address _rewardsAddress) {
        owner = msg.sender;
        resolverAddress[msg.sender] = true;
        bountyCooldownBlocks = 28500;
        degenAddress = _degenAddress;
        rewardsAddress = _rewardsAddress;
    }

    function getBattleResults(
        uint256 _battleId,
        uint256 _degenCore,
        uint256 _bountyId,
        bytes32 _resolutionSeed
    ) public view returns (bool) {
        BountyStats memory currentBounty = bountyIds[_bountyId];
        uint256 numberRolled = uint256(
            keccak256(abi.encodePacked(_resolutionSeed, _battleId))
        ) % (_degenCore + currentBounty.core);
        if (numberRolled <= _degenCore) {
            return true;
        } else {
            return false;
        }
    }

    function getNumberRolled(
        uint256 _battleId,
        uint256 _degenCore,
        uint256 _bountyId,
        bytes32 _resolutionSeed
    ) public view returns (uint256) {
        BountyStats memory currentBounty = bountyIds[_bountyId];
        uint256 numberRolled = uint256(
            keccak256(abi.encodePacked(_resolutionSeed, _battleId))
        ) % (_degenCore + currentBounty.core);
        return numberRolled;
    }

    function resolveBlock(uint256 _blockNumber, bytes32 _resolutionSeed)
        external
    {
        require(
            resolverAddress[msg.sender],
            "Only approved addresses can resolve Blocks"
        );
        require(!resolvedBlock[_blockNumber], "Block already resolved");
        require(
            _blockNumber < block.number,
            "Block Number too low compared to current block number"
        );
        resolvedBlock[_blockNumber] = true;
        uint256 resolveCountOfBlock = blockNumberCount[_blockNumber];
        require(resolveCountOfBlock > 0, "Nothing to resolve");
        uint256 counter = 0;
        bytes32 tempBytes;
        while (counter < resolveCountOfBlock) {
            uint256 tempId = blockToCountToId[_blockNumber][counter];
            BattleStats memory currentBattle = bountyBattleIds[tempId];
            if (currentBattle.resolutionSeed != tempBytes) {
                continue;
            }
            currentBattle.resolutionSeed = _resolutionSeed;
            currentBattle.degenWinner = getBattleResults(
                tempId,
                currentBattle.coreOfDegen,
                currentBattle.bountyId,
                _resolutionSeed
            );
            uint256 winnings;
            BountyStats memory currentBounty = bountyIds[
                currentBattle.bountyId
            ];
            if (currentBattle.degenWinner) {
                BountyRewards rewardContract = BountyRewards(rewardsAddress);

                (bool paid, uint256 tempWinnings) = rewardContract.payoutBounty(
                    currentBattle.bountyId,
                    currentBattle.degenOwner,
                    currentBounty.rewardPercent
                );
                winnings = tempWinnings;
                require(paid, "Bounty not paid out.");
            }
            bountyBattleIds[tempId] = currentBattle;

            emit bountyResolved(
                tempId,
                winnings,
                getNumberRolled(
                    tempId,
                    currentBattle.coreOfDegen,
                    currentBattle.bountyId,
                    _resolutionSeed
                ),
                currentBattle.coreOfDegen,
                currentBounty.core,
                currentBattle.bountyId,
                currentBattle.degenOwner,
                _resolutionSeed
            );
            counter++;
        }
    }

    function startBountys(
        uint256[] calldata _bountyIds,
        uint256[] calldata _degenIds
    ) external {
        require(
            _bountyIds.length == _degenIds.length,
            "lists need to be same length"
        );
        for (uint256 i = 0; i < _bountyIds.length; i++) {
            startBounty(_bountyIds[i], _degenIds[i]);
        }
    }

    function startBounty(uint256 _bountyId, uint256 _degenId) public {
        uint256 currentBlockNumber = block.number;
        require(bountyExists[_bountyId], "This bounty does not exist");
        require(
            currentBlockNumber - lastBlockOfDegenId[_degenId] >=
                bountyCooldownBlocks,
            "This Degen is still on cooldown"
        );
        MythDegen degenContract = MythDegen(degenAddress);
        uint256[3] memory tempIds;
        MythDegen.equippedItems memory equippedItems = degenContract
            .getDegenEquips(_degenId);
        MythDegen.stats memory degenStats = degenContract.getStats(_degenId);
        require(
            degenStats.owner == msg.sender,
            "Only the owner of the degen can use it"
        );
        if (equippedItems.weaponData > 0) {
            require(
                currentBlockNumber -
                    lastBlockOfWeaponId[equippedItems.weaponData] >=
                    bountyCooldownBlocks,
                "This Weapon is still on cooldown"
            );
            tempIds[0] = equippedItems.weaponData;
            lastBlockOfWeaponId[equippedItems.weaponData] = currentBlockNumber;
        }
        if (equippedItems.faceModData > 0) {
            require(
                currentBlockNumber -
                    lastBlockOfModId[equippedItems.faceModData] >=
                    bountyCooldownBlocks,
                "This Mod is still on cooldown"
            );
            tempIds[1] = equippedItems.faceModData;
            lastBlockOfModId[equippedItems.faceModData] = currentBlockNumber;
        }
        if (equippedItems.equipmentData > 0) {
            require(
                currentBlockNumber -
                    lastBlockOfEquipmentId[equippedItems.equipmentData] >=
                    bountyCooldownBlocks,
                "This Equipment is still on cooldown"
            );
            tempIds[2] = equippedItems.equipmentData;
            lastBlockOfEquipmentId[
                equippedItems.equipmentData
            ] = currentBlockNumber;
        }
        BountyStats memory currentBounty = bountyIds[_bountyId];
        lastBlockOfDegenId[_degenId] = currentBlockNumber;
        blockToCountToId[currentBlockNumber][
            blockNumberCount[currentBlockNumber]
        ] = _degenId;
        blockNumberCount[currentBlockNumber] += 1;
        bytes32 tempBytes;
        uint256 tempCore = degenContract.getDegenTotalCore(_degenId);
        bountyBattleIds[_degenId] = BattleStats(
            _bountyId,
            tempCore,
            currentBlockNumber,
            _degenId,
            tempIds[0],
            tempIds[1],
            tempIds[2],
            msg.sender,
            false,
            tempBytes
        );
        emit bountyStarted(
            _degenId,
            tempIds[0],
            tempIds[1],
            tempIds[2],
            _bountyId,
            msg.sender,
            currentBlockNumber
        );
    }

    function isDegenReady(uint256 _degenId)
        public
        view
        returns (uint256[5] memory)
    {
        uint256[5] memory tempData;
        uint256 currentCooldown = bountyCooldownBlocks;
        uint256 currentBlockNumber = block.number;
        tempData[0] = currentCooldown;
        tempData[1] = currentBlockNumber - lastBlockOfDegenId[_degenId];
        MythDegen degenContract = MythDegen(degenAddress);
        MythDegen.equippedItems memory equippedItems = degenContract
            .getDegenEquips(_degenId);
        tempData[2] =
            currentBlockNumber -
            lastBlockOfWeaponId[equippedItems.weaponData];
        tempData[3] =
            currentBlockNumber -
            lastBlockOfModId[equippedItems.faceModData];
        tempData[4] =
            currentBlockNumber -
            lastBlockOfEquipmentId[equippedItems.equipmentData];
        return tempData;
    }

    function changeDegenAddress(address _degenAddress) external {
        require(msg.sender == owner, "Only the owner can change degen address");
        degenAddress = _degenAddress;
    }

    function changeRewardAddress(address _rewardAddress) external {
        require(
            msg.sender == owner,
            "Only the owner can change reward address"
        );
        rewardsAddress = _rewardAddress;
    }

    function alterResolver(address _address) external {
        require(
            msg.sender == owner,
            "Only the owner can change resolver addresses"
        );
        resolverAddress[_address] = !resolverAddress[_address];
    }

    function changeCoolDown(uint256 _amount) external {
        require(
            msg.sender == owner,
            "Only the owner can change bounty cooldown"
        );
        bountyCooldownBlocks = _amount;
    }

    function addBounty(
        uint256 _bountyId,
        uint256 _bountyCore,
        uint256 _bountyRewardPercent
    ) external {
        require(msg.sender == owner, "Only the owner can add a bounty");
        bountyIds[_bountyId] = BountyStats(_bountyCore, _bountyRewardPercent);
        bountyExists[_bountyId] = true;
        emit bountyAdded(_bountyId, _bountyCore, _bountyRewardPercent);
    }

    function removeBounty(
        uint256 _bountyId,
        uint256 _bountyCore,
        uint256 _bountyRewardPercent
    ) external {
        require(msg.sender == owner, "Only the owner can remove a bounty");
        bountyIds[_bountyId] = BountyStats(_bountyCore, _bountyRewardPercent);
        bountyExists[_bountyId] = false;
        emit bountyRemoved(_bountyId, _bountyCore, _bountyRewardPercent);
    }
}

// contract MythBounty {
//     //bountys will have an available Pool of MYTHRAL which pays out to address owners
//     //Each address will have a total claimed rewards and unclaimed rewards
//     //Total claimed rewards and unclaimed rewards and reward pool

//     uint256 public bountyCooldownBlocks;
//     uint256 public bountyCount;

//     mapping(uint256 => BountyStats) public bountyIds;
//     mapping(uint256 => bool) public bountyExists;
//     mapping(uint256 => bool) public resolvedBlock;
//     mapping(uint256 => BattleStats) public bountyBattleIds;

//     mapping(uint256 => uint256) public lastBlockOfDegenId;
//     mapping(uint256 => uint256) public lastBlockOfWeaponId;
//     mapping(uint256 => uint256) public lastBlockOfModId;
//     mapping(uint256 => uint256) public lastBlockOfEquipmentId;
//     mapping(uint256 => uint256) public blockNumberCount;
//     mapping(uint256 => mapping(uint256 => uint256)) public blockToCountToId;

//     mapping(address => bool) public resolverAddress;
//     address public owner;
//     address public degenAddress;
//     address public rewardsAddress;
//     struct BountyStats {
//         uint256 core;
//         uint256 rewardPercent;
//     }
//     struct BattleStats {
//         uint256 bountyId;
//         uint256 coreOfDegen;
//         uint256 initializationBlock;
//         uint256 degenId;
//         uint256 weaponId;
//         uint256 modId;
//         uint256 equipmentId;
//         address degenOwner;
//         bool degenWinner;
//         bytes32 resolutionSeed;
//     }

//     event bountyAdded(
//         uint256 bountyId,
//         uint256 bountyCore,
//         uint256 bountyRewardPercent
//     );
//     event bountyRemoved(
//         uint256 bountyId,
//         uint256 bountyCore,
//         uint256 bountyRewardPercent
//     );

//     event bountyStarted(
//         uint256 bountyId,
//         uint256 idOfBountyStats,
//         address bountyHunterAddress,
//         uint256 initializationBlock
//     );
//     event bountyResolved(
//         uint256 bountyId,
//         uint256 winnings,
//         uint256 numberRolled,
//         uint256 degenCore,
//         uint256 bountyCore,
//         uint256 bountyStatsId,
//         address bountyHunter,
//         bytes32 resolutionSeed
//     );

//     constructor(address _degenAddress, address _rewardsAddress) {
//         owner = msg.sender;
//         resolverAddress[msg.sender] = true;
//         bountyCooldownBlocks = 30000;
//         degenAddress = _degenAddress;
//         rewardsAddress = _rewardsAddress;
//         bountyCount = 0;
//     }

//     function changeDegenAddress(address _degenAddress) external {
//         require(msg.sender == owner, "Only the owner can change degen address");
//         degenAddress = _degenAddress;
//     }

//     function changeCoolDown(uint256 _amount) external {
//         require(
//             msg.sender == owner,
//             "Only the owner can change bounty cooldown"
//         );
//         bountyCooldownBlocks = _amount;
//     }

//     function resolveBlock(uint256 _blockNumber, bytes32 _resolutionSeed)
//         external
//     {
//         require(
//             resolverAddress[msg.sender],
//             "Only approved addresses can resolve Blocks"
//         );
//         require(!resolvedBlock[_blockNumber], "Block already resolved");
//         require(
//             _blockNumber < block.number,
//             "Block Number too low compared to current block number"
//         );
//         resolvedBlock[_blockNumber] = true;
//         uint256 resolveCountOfBlock = blockNumberCount[_blockNumber];
//         require(resolveCountOfBlock > 0, "Nothing to resolve");
//         uint256 counter = 0;
//         bytes32 tempBytes;
//         while (counter < resolveCountOfBlock) {
//             uint256 tempId = blockToCountToId[_blockNumber][counter];
//             BattleStats memory currentBattle = bountyBattleIds[tempId];
//             if (currentBattle.resolutionSeed != tempBytes) {
//                 continue;
//             }
//             currentBattle.resolutionSeed = _resolutionSeed;
//             currentBattle.degenWinner = getBattleResults(
//                 tempId,
//                 currentBattle.coreOfDegen,
//                 currentBattle.bountyId,
//                 _resolutionSeed
//             );
//             uint256 winnings;
//             BountyStats memory currentBounty = bountyIds[
//                 currentBattle.bountyId
//             ];
//             if (currentBattle.degenWinner) {
//                 BountyRewards rewardContract = BountyRewards(rewardsAddress);

//                 (bool paid, uint256 tempWinnings) = rewardContract.payoutBounty(
//                     currentBattle.bountyId,
//                     currentBattle.degenOwner,
//                     currentBounty.rewardPercent
//                 );
//                 winnings = tempWinnings;
//                 require(paid, "Bounty not paid out.");
//             }
//             bountyBattleIds[tempId] = currentBattle;

//             emit bountyResolved(
//                 tempId,
//                 winnings,
//                 getNumberRolled(
//                     tempId,
//                     currentBattle.coreOfDegen,
//                     currentBattle.bountyId,
//                     _resolutionSeed
//                 ),
//                 currentBattle.coreOfDegen,
//                 currentBounty.core,
//                 currentBattle.bountyId,
//                 currentBattle.degenOwner,
//                 _resolutionSeed
//             );
//             counter++;
//         }
//     }

//     function getBattleResults(
//         uint256 _battleId,
//         uint256 _degenCore,
//         uint256 _bountyId,
//         bytes32 _resolutionSeed
//     ) public view returns (bool) {
//         BountyStats memory currentBounty = bountyIds[_bountyId];
//         uint256 numberRolled = uint256(
//             keccak256(abi.encodePacked(_resolutionSeed, _battleId))
//         ) % (_degenCore + currentBounty.core);
//         if (numberRolled <= _degenCore) {
//             return true;
//         } else {
//             return false;
//         }
//     }

//     function getNumberRolled(
//         uint256 _battleId,
//         uint256 _degenCore,
//         uint256 _bountyId,
//         bytes32 _resolutionSeed
//     ) public view returns (uint256) {
//         BountyStats memory currentBounty = bountyIds[_bountyId];
//         uint256 numberRolled = uint256(
//             keccak256(abi.encodePacked(_resolutionSeed, _battleId))
//         ) % (_degenCore + currentBounty.core);
//         return numberRolled;
//     }

//     function addBounty(
//         uint256 _bountyId,
//         uint256 _bountyCore,
//         uint256 _bountyRewardPercent
//     ) external {
//         require(msg.sender == owner, "Only the owner can add a bounty");
//         bountyIds[_bountyId] = BountyStats(_bountyCore, _bountyRewardPercent);
//         bountyExists[_bountyId] = true;
//         emit bountyAdded(_bountyId, _bountyCore, _bountyRewardPercent);
//     }

//     function removeBounty(
//         uint256 _bountyId,
//         uint256 _bountyCore,
//         uint256 _bountyRewardPercent
//     ) external {
//         require(msg.sender == owner, "Only the owner can remove a bounty");
//         bountyIds[_bountyId] = BountyStats(_bountyCore, _bountyRewardPercent);
//         bountyExists[_bountyId] = false;
//         emit bountyRemoved(_bountyId, _bountyCore, _bountyRewardPercent);
//     }

//     function isDegenReady(uint256 _degenId)
//         public
//         view
//         returns (uint256[5] memory)
//     {
//         uint256[5] memory tempData;
//         uint256 currentCooldown = bountyCooldownBlocks;
//         uint256 currentBlockNumber = block.number;
//         tempData[0] = currentCooldown;
//         tempData[1] = currentBlockNumber - lastBlockOfDegenId[_degenId];
//         MythDegen degenContract = MythDegen(degenAddress);
//         MythDegen.equippedItems memory equippedItems = degenContract
//             .getDegenEquips(_degenId);
//         tempData[2] =
//             currentBlockNumber -
//             lastBlockOfWeaponId[equippedItems.weaponData];
//         tempData[3] =
//             currentBlockNumber -
//             lastBlockOfModId[equippedItems.faceModData];
//         tempData[4] =
//             currentBlockNumber -
//             lastBlockOfEquipmentId[equippedItems.equipmentData];
//         return tempData;
//     }

//     function initializeBounty(uint256 _bountyId, uint256 _degenId) external {
//         uint256 currentBlockNumber = block.number;
//         require(bountyExists[_bountyId], "This bounty does not exist");
//         require(
//             currentBlockNumber - lastBlockOfDegenId[_degenId] >=
//                 bountyCooldownBlocks,
//             "This Degen is still on cooldown"
//         );
//         MythDegen degenContract = MythDegen(degenAddress);
//         uint256[3] memory tempIds;
//         MythDegen.equippedItems memory equippedItems = degenContract
//             .getDegenEquips(_degenId);
//         MythDegen.stats memory degenStats = degenContract.getStats(_degenId);
//         require(
//             degenStats.owner == msg.sender,
//             "Only the owner of the degen can use it"
//         );
//         if (equippedItems.weaponData > 0) {
//             require(
//                 currentBlockNumber -
//                     lastBlockOfWeaponId[equippedItems.weaponData] >=
//                     bountyCooldownBlocks,
//                 "This Weapon is still on cooldown"
//             );
//             tempIds[0] = equippedItems.weaponData;
//             lastBlockOfWeaponId[equippedItems.weaponData] = currentBlockNumber;
//         }
//         if (equippedItems.faceModData > 0) {
//             require(
//                 currentBlockNumber -
//                     lastBlockOfModId[equippedItems.faceModData] >=
//                     bountyCooldownBlocks,
//                 "This Mod is still on cooldown"
//             );
//             tempIds[1] = equippedItems.faceModData;
//             lastBlockOfModId[equippedItems.faceModData] = currentBlockNumber;
//         }
//         if (equippedItems.equipmentData > 0) {
//             require(
//                 currentBlockNumber -
//                     lastBlockOfEquipmentId[equippedItems.equipmentData] >=
//                     bountyCooldownBlocks,
//                 "This Equipment is still on cooldown"
//             );
//             tempIds[2] = equippedItems.equipmentData;
//             lastBlockOfEquipmentId[
//                 equippedItems.equipmentData
//             ] = currentBlockNumber;
//         }
//         BountyStats memory currentBounty = bountyIds[_bountyId];
//         lastBlockOfDegenId[_degenId] = currentBlockNumber;
//         uint256 tempCount = bountyCount;
//         blockToCountToId[currentBlockNumber][
//             blockNumberCount[tempCount]
//         ] = tempCount;
//         blockNumberCount[currentBlockNumber] += 1;
//         bytes32 tempBytes = bytes32(0);
//         uint256 tempCore = 0;
//         tempCore = degenContract.getDegenTotalCore(_degenId);
//         bountyBattleIds[tempCount] = BattleStats(
//             _bountyId,
//             tempCore,
//             currentBlockNumber,
//             _degenId,
//             tempIds[0],
//             tempIds[1],
//             tempIds[2],
//             msg.sender,
//             false,
//             tempBytes
//         );
//         emit bountyStarted(
//             tempCount,
//             _bountyId,
//             msg.sender,
//             currentBlockNumber
//         );
//         bountyCount++;
//     }
// }

contract BountyRewards {
    uint256 public totalClaimedMythral; //tracker for claimed Mythral
    uint256 public totalUnClaimedMythral; //tracker for unclaimed mythral
    uint256 public totalAvailableMythral; // total supply of reward pool
    mapping(address => uint256) public unclaimedRewardsByAddress; //available rewards for an address
    mapping(address => uint256) public claimedRewardsByAddress; //tracker of claimed rewards for an address
    address payable public owner;
    address public mythralAddress;
    mapping(address => bool) public gameAddresses;

    constructor(address _mythral) {
        owner = payable(msg.sender);
        mythralAddress = _mythral;
    }

    function increaseRewardPool(uint256 _amount) external {
        ERC20 mythralContract = ERC20(mythralAddress);
        require(
            mythralContract.transferFrom(msg.sender, address(this), _amount),
            "Failed to transfer Mythral"
        );
        totalAvailableMythral += _amount;
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
    }

    function addGameAddress(address _gameAddress) external {
        require(msg.sender == owner, "only the owner can add games");
        gameAddresses[_gameAddress] = true;
    }

    function removeGameAddress(address _gameAddress) external {
        require(msg.sender == owner, "only the owner can remove games");
        gameAddresses[_gameAddress] = false;
    }

    function withdrawRewards() external {
        uint256 claimableRewards = unclaimedRewardsByAddress[msg.sender];
        require(claimableRewards > 0, "You have no rewards to claim");
        unclaimedRewardsByAddress[msg.sender] = 0;
        totalUnClaimedMythral -= claimableRewards;
        claimedRewardsByAddress[msg.sender] += claimableRewards;
        totalClaimedMythral += claimableRewards;
        ERC20 mythralContract = ERC20(mythralAddress);
        mythralContract.transfer(msg.sender, claimableRewards);
    }

    function withdrawRewardsAmount(uint256 _amount) external {
        uint256 claimableRewards = unclaimedRewardsByAddress[msg.sender];
        require(
            claimableRewards > 0 && claimableRewards >= _amount,
            "You have no rewards to claim"
        );
        unclaimedRewardsByAddress[msg.sender] = claimableRewards - _amount;
        totalUnClaimedMythral -= claimableRewards - _amount;
        claimedRewardsByAddress[msg.sender] += _amount;
        totalClaimedMythral += _amount;
        ERC20 mythralContract = ERC20(mythralAddress);
        mythralContract.transfer(msg.sender, _amount);
    }

    function withdrawAmount(uint256 _amount) external {
        require(msg.sender == owner, "only owner");
        ERC20 mythralContract = ERC20(mythralAddress);
        mythralContract.transfer(owner, _amount);
    }

    function changeAvailableMythral(uint256 _amount) external {
        require(msg.sender == owner, "only owner");
        totalAvailableMythral = _amount;
    }

    function payoutBounty(
        uint256 _bountyId,
        address _degenOwnerAddress,
        uint256 _amountReward
    ) external returns (bool, uint256) {
        require(
            gameAddresses[msg.sender],
            "Only approved addresses can pay out rewards"
        );
        uint256 currentRewardPool = totalAvailableMythral;
        require(
            currentRewardPool > _amountReward,
            "Reward Pool not big enough"
        );
        totalAvailableMythral -= _amountReward;
        unclaimedRewardsByAddress[_degenOwnerAddress] += _amountReward;
        totalUnClaimedMythral += _amountReward;
        return (true, _amountReward);
    }
    // function payoutBounty(
    //     uint256 _bountyId,
    //     address _degenOwnerAddress,
    //     uint256 _amountReward
    // ) external returns (bool, uint256) {
    //     require(
    //         gameAddresses[msg.sender],
    //         "Only approved addresses can pay out rewards"
    //     );
    //     uint256 currentRewardPool = totalAvailableMythral;
    //     require(currentRewardPool > 1 * 10**9, "Reward Pool not big enough");
    //     uint256 rewardOfBounty = (((currentRewardPool * 10**18) / 100000) *
    //         _amountReward) / 10**18;
    //     totalAvailableMythral -= rewardOfBounty;
    //     unclaimedRewardsByAddress[_degenOwnerAddress] += rewardOfBounty;
    //     totalUnClaimedMythral += rewardOfBounty;
    //     return (true, rewardOfBounty);
    // }
}