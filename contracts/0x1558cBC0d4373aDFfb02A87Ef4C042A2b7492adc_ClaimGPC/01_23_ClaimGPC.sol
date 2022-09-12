// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IGPC.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ClaimGPC is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable GPCToken;
    uint256 public totalClaimed;
    mapping(address => uint256) public addressClaimed;
    mapping(uint256 => uint256) public tokensClaimed;

    uint256 public contractStartTime;
    address[] public mps;

    mapping(uint256 => address) public islandContracts;

    uint256[] allIslandOneIds;

    mapping(uint256 => IGPC721) islandSC;

    mapping(uint256 => uint256) goldTokensIds;
    mapping(uint256 => uint256) goldTokensAmount;
    mapping(uint256 => uint256) pandaEarnAmount;

    IGPC islandSC1;

    event Claimed(
        address indexed account,
        uint256 indexed amount,
        uint256 timestamp
    );

    constructor(address _GPCTokenAddress) {
        require(
            _GPCTokenAddress != address(0),
            "The GPC token address can't be 0"
        );
        GPCToken = IERC20(_GPCTokenAddress);

        contractStartTime = block.timestamp;

        islandContracts[1] = address(
            0x495f947276749Ce646f68AC8c248420045cb7b5e
        );
        islandContracts[2] = address(
            0x01FA3813618eE7453904B21678D16a76E8866566
        );
        islandContracts[3] = address(
            0x996820AcfF9177DF1acB9Ed171db49CDC6B1cfe6
        );

        islandSC1 = IGPC(islandContracts[1]);

        islandSC[2] = IGPC721(islandContracts[2]);
        islandSC[3] = IGPC721(islandContracts[3]);

        pandaEarnAmount[1] = 100;
        pandaEarnAmount[2] = 20;
        pandaEarnAmount[3] = 20;

        goldTokensIds[
            1
        ] = 25835164141757543259111126311128023380630954073833337382485104724022554263553;
        goldTokensAmount[1] = 1000;

        goldTokensIds[2] = 700;
        goldTokensAmount[2] = 1000;

        mps.push(address(0x1E0049783F008A0085193E00003D00cd54003c71));
        mps.push(address(0xF849de01B080aDC3A814FaBE1E2087475cF2E354));
    }

    function isListed(address holder, uint256 island)
        public
        view
        returns (bool isApproved)
    {
        bool isApporvedForSale = false;

        if (island == 1) {
            //island 1
            // check if approved for all on different market places
            for (uint256 i = 0; i < mps.length; i++) {
                isApporvedForSale = islandSC1.isApprovedForAll(holder, mps[i]);
                if (isApporvedForSale) {
                    return true;
                }
            }
            return false;
        } else if (island != 0) {
            //all other islands
            for (uint256 i = 0; i < mps.length; i++) {
                isApporvedForSale = islandSC[island].isApprovedForAll(
                    holder,
                    mps[i]
                );
                if (isApporvedForSale) {
                    return isApporvedForSale;
                }
            }
            return isApporvedForSale;
        }

        return isApporvedForSale;
    }

    function getDayDiff() public view returns (uint256) {
        return (block.timestamp - contractStartTime) / 60 / 60 / 24;
    }

    function isIslandOneId(uint256 id) public view returns (bool) {
        bool isIsland1Id = false;
        for (uint256 i = 0; i < allIslandOneIds.length; i++) {
            if (allIslandOneIds[i] == id) {
                isIsland1Id = true;
                break;
            }
        }
        return isIsland1Id;
    }

    function isIslandToken(uint256 id, uint256 island)
        public
        view
        returns (bool)
    {
        if (island == 1) {
            return isIslandOneId(id);
        } else {
            address owner = islandSC[island].ownerOf(id);
            if (owner != address(0)) {
                return true;
            }
            return false;
        }
    }

    function calcCoins(uint256 island, uint256[] memory islandIds)
        public
        view
        returns (uint256[] memory coins)
    {
        uint256 daysDiff = getDayDiff();
        uint256[] memory coinsEarn = new uint256[](islandIds.length);

        for (uint256 i = 0; i < islandIds.length; i++) {
            bool isPanda = isIslandToken(islandIds[i], island);
            if (isPanda) {
                if (island == 3 || island == 4) {
                    //get mint date time from the NFT
                    uint256 nftMintDate = IPandaNFT(islandContracts[island])
                        .getMintTime(islandIds[i]);
                    if (nftMintDate == 0) {
                        coinsEarn[i] = 0;
                        continue;
                    }
                    daysDiff = ((block.timestamp - nftMintDate) / 60 / 60 / 24);
                }

                if (islandIds[i] == goldTokensIds[island]) {
                    //gold panda
                    coinsEarn[i] =
                        (goldTokensAmount[island] * daysDiff) *
                        10**18;
                } else {
                    coinsEarn[i] =
                        (pandaEarnAmount[island] * daysDiff) *
                        10**18;
                }
            } else {
                coinsEarn[i] = 0;
            }
        }
        return coinsEarn;
    }

    function setClaimedTokens(uint256[] memory tokens, uint256[] memory amounts)
        internal
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            tokensClaimed[tokens[i]] += amounts[i] * 10**18;
        }
    }

    function calcTotalToClaim(uint256[] memory amounts)
        internal
        pure
        returns (uint256 total)
    {
        uint256 totalCoins = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalCoins += amounts[i] * 10**18;
        }
        return totalCoins;
    }

    function checkNotExceedBlanace(
        uint256[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory totalCoinsArr
    ) internal view returns (uint256 nftId) {
        uint256 exceedbalanceId = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 token_id = tokens[i];
            if (
                tokensClaimed[token_id] + (amounts[i] * 10**18) >
                totalCoinsArr[i]
            ) {
                exceedbalanceId = token_id;
                break;
            }
        }
        return exceedbalanceId;
    }

    function checkTokensIsOwner(uint256[] memory tokens, uint256 islandType)
        internal
        view
        returns (bool isOwner)
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 token_id = tokens[i];
            if (islandType == 1) {
                if (islandSC1.balanceOf(msg.sender, token_id) == 0) {
                    return false;
                }
            } else {
                if (islandSC[islandType].ownerOf(token_id) != msg.sender) {
                    return false;
                }
            }
        }

        return true;
    }

    function claimTokens(
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory islands
    ) external whenNotPaused {
        uint256 tokensToClaim = calcTotalToClaim(amounts);
        require(
            GPCToken.balanceOf(address(this)) > tokensToClaim + totalClaimed,
            "Max tokens reached"
        );
        uint256 indexTracker = 0;
        for (uint256 i = 0; i < islands.length; i++) {
            uint256 idsCounts = islands[i];
            uint256 islandType = (i + 1);
            if (idsCounts > 0) {
                uint256[] memory localIds = new uint256[](idsCounts);
                uint256[] memory localAmounts = new uint256[](idsCounts);

                for (uint256 j = 0; j < idsCounts; j++) {
                    localIds[j] = ids[indexTracker];
                    localAmounts[j] = amounts[indexTracker];
                    indexTracker++;
                }

                bool checkIsOwner = checkTokensIsOwner(localIds, islandType);
                require(
                    checkIsOwner,
                    "You must be the owner of all island pandas ID sent"
                );

                uint256 exceededBalanceId = 0;
                uint256[] memory totalCoinsArr = calcCoins(
                    islandType,
                    localIds
                );
                bool isApprovedForSale = isListed(msg.sender, islandType);
                if (isApprovedForSale) {
                    for (uint256 j = 0; j < totalCoinsArr.length; j++) {
                        totalCoinsArr[j] = 0;
                    }
                }
                exceededBalanceId = checkNotExceedBlanace(
                    localIds,
                    localAmounts,
                    totalCoinsArr
                );
                require(
                    exceededBalanceId == 0,
                    string(
                        abi.encodePacked(
                            "Exceeded claim balance for panda ",
                            Strings.toString(exceededBalanceId)
                        )
                    )
                );
            }
        }

        GPCToken.safeTransfer(msg.sender, tokensToClaim);
        setClaimedTokens(ids, amounts);

        addressClaimed[msg.sender] += tokensToClaim;
        totalClaimed += tokensToClaim;

        emit Claimed(msg.sender, tokensToClaim, block.timestamp);
    }

    function getCoinsBalance() public view returns (uint256) {
        return GPCToken.balanceOf(address(this));
    }

    function setIslandOneTokens(uint256[] memory Ids) external onlyOwner {
        allIslandOneIds = Ids;
    }

    function setIslandGoldToken(uint256 island, uint256 token)
        external
        onlyOwner
    {
        goldTokensIds[island] = token;
    }

    function setIslandGoldTokenEarningAmount(uint256 island, uint256 amount)
        external
        onlyOwner
    {
        goldTokensAmount[island] = amount;
    }

    function setPandaTokenEarningAmount(uint256 island, uint256 amount)
        external
        onlyOwner
    {
        pandaEarnAmount[island] = amount;
    }

    function addMP(address mp) external onlyOwner {
        mps.push(mp);
    }

    function setMPs(address[] memory _mps) external onlyOwner {
        mps = _mps;
    }

    function setIslandContract1(address _contract) external onlyOwner {
        islandSC1 = IGPC(_contract);
    }

    function setIslandContractMap(uint256 island, address _contract)
        external
        onlyOwner
    {
        islandSC[island] = IGPC721(_contract);
    }

    function setIslandContractAddress(uint256 island, address _contract)
        external
        onlyOwner
    {
        islandContracts[island] = _contract;
    }
}