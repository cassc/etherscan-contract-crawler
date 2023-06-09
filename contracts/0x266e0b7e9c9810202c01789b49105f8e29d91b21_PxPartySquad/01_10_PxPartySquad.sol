// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./PsWeekManager.sol";
import "./IPsChainlinkManager.sol";

/// @notice Thrown when all treasures are already claimed
error AlreadyClaimed();
/// @notice Thrown when address is not a winner
error NotAWinner();
/// @notice Thrown when input is not as expected condition
error InvalidInput();
/// @notice Thrown when treasure index doesn't exist
error InvalidTreasureIndex();
/// @notice Thrown when no available treasures to be transferred to the winner
error InsufficientToken();
/// @notice Thrown when the input signature is invalid.
error InvalidSignature();

contract PxPartySquad is PsWeekManager, ReentrancyGuard {
    /// @notice code number for ERC1155 token
    uint8 public constant ERC_1155_TYPE = 1;
    /// @notice code number for ERC721 token
    uint8 public constant ERC_721_TYPE = 2;

    /// @notice Wallet address that keeps all treasures
    address public vaultWalletAddress;

    uint256 public maxSpecialTreasureLimit = 1;

    
    /// @notice Variable to store Special Treasures treasure information such
    ///         as the collection address, token ID, amount, and token type
    Treasure public specialTreasure;
    /// @notice List of addresses who have won Special Treasures 
    /// @custom:key wallet address
    mapping(address => uint256) public specialTreasureWinnersLimit;

    /// @notice Check whether both array input has the same length or not
    /// @param length1 first length of the array input
    /// @param length2 second length of the array input
    modifier validArrayLength(uint256 length1, uint256 length2) {
        if (length1 != length2) {
            revert InvalidLength();
        }
        _;
    }

    /// @notice Check treasure token type and token ID input
    /// @dev Only ERC1155 and ERC721 are supported
    /// @param _treasure Treasure information
    modifier validTreasure(Treasure memory _treasure) {
        if (_treasure.contractType != ERC_1155_TYPE && _treasure.contractType != ERC_721_TYPE) {
            revert InvalidInput();
        }
        if (
            (_treasure.contractType == ERC_1155_TYPE && _treasure.tokenIds.length > 0) ||
            (_treasure.contractType == ERC_721_TYPE && _treasure.tokenIds.length == 0)
        ) {
            revert InvalidInput();
        }
        _;
    }

    /// @notice Emits when a treasure is claimed
    /// @param weekNumber Week number when the treasure is claimed
    /// @param userWallet Wallet address who claims the treasure
    /// @param collectionAddress The contract address of the treasure
    /// @param tokenId The treasure token ID in its contract address
    /// @param tokenType The token type 
    event TreasureTransferred(uint256 weekNumber, address userWallet, address collectionAddress, uint256 tokenId, uint256 tokenType);

    /// @notice The contract constructor
    /// @dev The constructor parameters only used as input
    ///      from PsWeekManager contract
    ///        More https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    /// @param _psChainlinkContractAddress signature contract address
    constructor(address _psChainlinkContractAddress) PsWeekManager() {
        psChainlinkManagerContract = IPsChainlinkManager(_psChainlinkContractAddress);
    }

    /// @notice Sets Chainlink manager contract address
    /// @dev Chainlink manager is used as signer and to interact with Chainlink
    /// @param _psChainlinkContractAddress Chainlink manager contract address
    function setPsChainlinkManagerContractAddress(address _psChainlinkContractAddress) external onlyOwner {
        psChainlinkManagerContract = IPsChainlinkManager(_psChainlinkContractAddress);
    }

    /// @notice Set address to become vault
    /// @param _walletAddress Wallet address that will be the vault
    function setVaultWalletAddress(address _walletAddress) external onlyOwner {
        vaultWalletAddress = _walletAddress;
    }

    /// @notice Adds treasure information
    /// @dev This method is used to add information about the treasure that exists
    ///      in the vault wallet address. Only admin can call this method
    /// @param _treasure Treasure information
    function addTreasures(Treasure memory _treasure) external onlyAdmin(msg.sender) validTreasure(_treasure) {
        totalTreasureCount++;
        _treasure.claimedToken = 0;
        treasures[totalTreasureCount] = _treasure;
    }

    /// @notice Update existing treasure information
    /// @dev Only admin can call this method
    /// @param _index Treasure index
    /// @param _treasure New treasure information
    function updateTreasure(uint256 _index, Treasure memory _treasure) external onlyAdmin(msg.sender) validTreasure(_treasure) {
        _treasure.claimedToken = 0;
        treasures[_index] = _treasure;
    }

    /// @notice Add Special treasure to the smart contract
    /// @dev Can only be called by adminis
    /// @param _treasure Special Treasure information according to Treasure struct
    function addSpecialTreasure(Treasure memory _treasure) external onlyAdmin(msg.sender) validTreasure(_treasure) {
        _treasure.claimedToken = 0;
        specialTreasure = _treasure;
    }

    /// @notice claim function for the winner
    /// @dev Only winner of the week can call this method
    /// @param _weekNumber The week number to claim treasure
    /// @param _signature Signature from signer wallet
    function claimTreasure(uint256 _weekNumber, bytes calldata _signature) external noContracts nonReentrant {
        if (!(block.timestamp >= weekInfos[_weekNumber].claimStartTimeStamp && block.timestamp <= weekInfos[_weekNumber].endTimeStamp)) {
            revert InvalidClaimingPeriod();
        }
        bool isValidSigner = psChainlinkManagerContract.isSignerVerifiedFromSignature(
            _weekNumber,
            weekInfos[_weekNumber].winners[msg.sender].claimed,
            msg.sender,
            _signature
        );

        if (!isValidSigner) {
            revert InvalidSignature();
        }

        if (weekInfos[_weekNumber].winners[msg.sender].claimLimit == 0) {
            revert NotAWinner();
        }
        if (weekInfos[_weekNumber].winners[msg.sender].claimed == weekInfos[_weekNumber].winners[msg.sender].claimLimit) {
            revert AlreadyClaimed();
        }
        if (weekInfos[_weekNumber].winners[msg.sender].claimed == 0) {
            primaryClaim(_weekNumber);
        } else {
            secondaryClaim(_weekNumber);
        }
    }

    /// @notice Method to claim the first treasure
    /// @dev This method is also used to claim Special Treasures if
    ///      the caller is selected as a special treasure winner
    /// @param _weekNumber The week number to claim treasure
    function primaryClaim(uint256 _weekNumber) internal {
        Week storage week = weekInfos[_weekNumber];
        if (week.specialTreasureWinnerMap[msg.sender]) {
            specialTreasureWinnersLimit[msg.sender]++;
            week.specialTreasureWinnerMap[msg.sender] = false;

            unchecked {
                week.winners[msg.sender].claimed++;
                week.availableSpecialTreasureCount--;
                specialTreasure.claimedToken++;
            }
            transferToken(_weekNumber, specialTreasure);
        } else {
            uint256 randomNumber = getRandomNumber();
            uint256 random = randomNumber - ((randomNumber / week.remainingSupply) * week.remainingSupply) + 1;

            uint256 selectedIndex;
            uint16 sumOfTotalSupply;

            for (uint256 index = 1; index <= week.treasureCount; index = _uncheckedInc(index)) {
                if (week.distributions[index].totalSupply == 0) {
                    continue;
                }
                unchecked {
                    sumOfTotalSupply += week.distributions[index].totalSupply;
                }
                if (random <= sumOfTotalSupply) {
                    selectedIndex = index;
                    break;
                }
            }
            uint256 selectedTreasureIndex = week.distributions[selectedIndex].treasureIndex;
            week.winners[msg.sender].treasureTypeClaimed[treasures[selectedTreasureIndex].treasureType] = true;

            unchecked {
                week.distributions[selectedIndex].totalSupply--;
                week.winners[msg.sender].claimed++;
                week.remainingSupply--;
                treasures[selectedTreasureIndex].claimedToken++;
            }

            transferToken(_weekNumber, treasures[selectedTreasureIndex]);
        }
    }

    /// @notice Method to claim the next treasure
    /// @dev This method will give different treasures than the first
    ///      one if there are still other treasure option available
    /// @param _weekNumber The week number to claim treasure
    function secondaryClaim(uint256 _weekNumber) internal {
        Week storage week = weekInfos[_weekNumber];
        uint16 remaining;
        uint16 altRemaining;

        for (uint256 index = 1; index <= week.treasureCount; index = _uncheckedInc(index)) {
            uint256 treasureType = treasures[week.distributions[index].treasureIndex].treasureType;
            if (week.winners[msg.sender].treasureTypeClaimed[treasureType]) {
                unchecked {
                    altRemaining += week.distributions[index].totalSupply;
                }
            } else {
                unchecked {
                    remaining += week.distributions[index].totalSupply;
                }
            }
        }
        uint256 randomNumber = getRandomNumber();

        uint256 selectedIndex;
        uint256 sumOfTotalSupply;
        if (altRemaining == week.remainingSupply) {
            uint256 random = randomNumber - ((randomNumber / altRemaining) * altRemaining) + 1;
            for (uint256 index = 1; index <= week.treasureCount; index = _uncheckedInc(index)) {
                uint256 treasureType = treasures[week.distributions[index].treasureIndex].treasureType;
                if (week.distributions[index].totalSupply == 0 || !week.winners[msg.sender].treasureTypeClaimed[treasureType]) {
                    continue;
                }
                unchecked {
                    sumOfTotalSupply += week.distributions[index].totalSupply;
                }
                if (random <= sumOfTotalSupply) {
                    selectedIndex = index;
                    break;
                }
            }
        } else {
            uint256 random = randomNumber - ((randomNumber / remaining) * remaining) + 1;

            for (uint256 index = 1; index <= week.treasureCount; index = _uncheckedInc(index)) {
                uint256 treasureType = treasures[week.distributions[index].treasureIndex].treasureType;
                if (week.distributions[index].totalSupply == 0 || week.winners[msg.sender].treasureTypeClaimed[treasureType]) {
                    continue;
                }
                unchecked {
                    sumOfTotalSupply += week.distributions[index].totalSupply;
                }
                if (random <= sumOfTotalSupply) {
                    selectedIndex = index;
                    break;
                }
            }
        }

        uint256 selectedTreasureIndex = week.distributions[selectedIndex].treasureIndex;
        week.winners[msg.sender].treasureTypeClaimed[treasures[selectedTreasureIndex].treasureType] = true;
        unchecked {
            week.distributions[selectedIndex].totalSupply--;
            week.winners[msg.sender].claimed++;
            week.remainingSupply--;
            treasures[selectedTreasureIndex].claimedToken++;
        }

        transferToken(_weekNumber, treasures[selectedTreasureIndex]);
    }

    /// @notice Transfers token from vault to the method caller's wallet address
    /// @dev This method will be used in a public method and user who call the
    ///      method will get a token from vault wallet address
    /// @param _treasure Treasure to transfer
    function transferToken(uint256 _weekNumber, Treasure memory _treasure) internal {
        if (_treasure.contractType == ERC_1155_TYPE) {
            IERC1155 erc1155Contract = IERC1155(_treasure.collectionAddress);
            erc1155Contract.safeTransferFrom(vaultWalletAddress, msg.sender, _treasure.tokenId, 1, "");
            emit TreasureTransferred(_weekNumber, msg.sender, _treasure.collectionAddress, _treasure.tokenId, _treasure.contractType);
        }
        if (_treasure.contractType == ERC_721_TYPE) {
            IERC721 erc721Contract = IERC721(_treasure.collectionAddress);
            if (_treasure.tokenIds.length < _treasure.claimedToken) {
                revert InsufficientToken();
            }
            erc721Contract.transferFrom(vaultWalletAddress, msg.sender, _treasure.tokenIds[_treasure.claimedToken - 1]);
            emit TreasureTransferred(_weekNumber, msg.sender, _treasure.collectionAddress,_treasure.tokenIds[_treasure.claimedToken - 1] , _treasure.contractType);
        }
    }

    /// @notice Set treasure distributions for a week
    /// @dev Only admin can call this method
    /// @param _weekNumber The week number
    /// @param _treasureindexes The index of the treasure in 'treasures' mapping variable
    /// @param _treasureCounts Amount of treasure that will be available to claim during the week
    /// @param _specialTreasuresCount Amount of special treasure that will be available to claim during the week
    function setWeeklyTreasureDistribution(
        uint256 _weekNumber,
        uint8[] memory _treasureindexes,
        uint16[] memory _treasureCounts,
        uint8 _specialTreasuresCount
    ) external onlyAdmin(msg.sender) validTreaureDistributionPeriod(_weekNumber) validArrayLength(_treasureindexes.length, _treasureCounts.length) {
        Week storage week = weekInfos[_weekNumber];
        week.specialTreasureCount = _specialTreasuresCount;
        week.availableSpecialTreasureCount = _specialTreasuresCount;
        week.treasureCount = 0;
        for (uint256 index = 0; index < _treasureindexes.length; index = _uncheckedInc(index)) {
            if (_treasureindexes[index] == 0 || _treasureindexes[index] > totalTreasureCount) {
                revert InvalidTreasureIndex();
            }
            week.treasureCount++;
            week.distributions[week.treasureCount].treasureIndex = _treasureindexes[index];
            week.distributions[week.treasureCount].totalSupply = _treasureCounts[index];
            week.remainingSupply += _treasureCounts[index];
        }
    }

    /// @notice Set a list of winners for a particular week
    /// @param _weekNumber The current week number
    /// @param _winners List of wallet addresses that have been selected as winners
    /// @param _treasureCounts Amount of treasure that have been awarded to the corresponding winner
    function updateWeeklyWinners(
        uint256 _weekNumber,
        address[] memory _winners,
        uint8[] memory _treasureCounts
    ) external onlyModerator(msg.sender) validArrayLength(_winners.length, _treasureCounts.length) validWinnerUpdationPeriod(_weekNumber) {
        for (uint256 index = 0; index < weekInfos[_weekNumber].specialTreasureWinners.length; index++) {
            address specialTreasureWinner = weekInfos[_weekNumber].specialTreasureWinners[index];
            weekInfos[_weekNumber].specialTreasureWinnerMap[specialTreasureWinner] = false;
        }
        uint256 randomNumber = getRandomNumber();
        uint256 randomIndex = randomNumber - ((randomNumber / _treasureCounts.length) * _treasureCounts.length);
        uint256 counter = 0;
        uint256 specialTreasureWinnerCount = 0;
        uint256 treasureCount = 0;
        address[] memory tmpSpecialTreasureWinners = new address[](weekInfos[_weekNumber].specialTreasureCount);
        while (counter < _treasureCounts.length) {
            if (randomIndex == _treasureCounts.length) {
                randomIndex = 0;
            }
            if (
                specialTreasureWinnersLimit[_winners[randomIndex]] < maxSpecialTreasureLimit &&
                specialTreasureWinnerCount < weekInfos[_weekNumber].specialTreasureCount &&
                _treasureCounts[randomIndex] > 0
            ) {
                weekInfos[_weekNumber].specialTreasureWinnerMap[_winners[randomIndex]] = true;
                tmpSpecialTreasureWinners[specialTreasureWinnerCount] = _winners[randomIndex];
                specialTreasureWinnerCount++;
            }

            weekInfos[_weekNumber].winners[_winners[randomIndex]].claimLimit = _treasureCounts[randomIndex];
            treasureCount += _treasureCounts[randomIndex];
            unchecked {
                randomIndex++;
                counter++;
            }
        }
        if (treasureCount > weekInfos[_weekNumber].remainingSupply + weekInfos[_weekNumber].specialTreasureCount) {
            revert("Invalid Treasure Amount");
        }

        weekInfos[_weekNumber].specialTreasureWinners = tmpSpecialTreasureWinners;
        emit WeeklyWinnersSet(_weekNumber, tmpSpecialTreasureWinners);
    }

    /// @notice Add a list of wallet addresses that have won Special Treasure
    /// @param _previousWinners List of addresses that have won Special Treasure
    /// @param _counts number of special treasures have already won
    function setSpecialTreasureWinnerLimit(
        address[] memory _previousWinners,
        uint256[] memory _counts
    ) external onlyAdmin(msg.sender) validArrayLength(_previousWinners.length, _counts.length) {
        for (uint256 index = 0; index < _previousWinners.length; index = _uncheckedInc(index)) {
            specialTreasureWinnersLimit[_previousWinners[index]] = _counts[index];
        }
    }

    /// @notice update max limit for special treasure
    /// @param _maxSpecialTreasureLimit List of addresses that have won Special Treasure
    function updateMaxSpecialTreasureLimit(
        uint256 _maxSpecialTreasureLimit
    ) external onlyAdmin(msg.sender) {
        maxSpecialTreasureLimit = _maxSpecialTreasureLimit;
    }
}