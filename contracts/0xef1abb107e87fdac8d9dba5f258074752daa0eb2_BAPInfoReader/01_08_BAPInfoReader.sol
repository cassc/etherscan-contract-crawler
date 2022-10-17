// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "./Interfaces/BAPOrchestratorInterfaceV3.sol";
import "./IERC1155Receiver.sol";
import "./IERC721A.sol";
import "./IERC721Enumerable.sol";
import "./IERC1155.sol";
import "./IERC165.sol";
import "./IERC20.sol";

contract BAPInfoReader {
    uint256 public constant startTime = 1665291600;
    // uint256 public constant timeCounter = 7200;
    uint256 public constant timeCounter = 1 days;

    BAPOrchestratorInterfaceV3 public V3Interface;
    IERC721A public bapGenesis;
    IERC721A public bapTeenBulls;
    IERC1155 public bapUtilities;
    IERC20 public bapMeth;

    mapping(uint256 => bool) public isGod;

    struct BullData {
        uint256 tokenId;
        uint256 claimableMeth;
        uint256 breedings;
        uint256 lastChestOpen;
        bool isGod;
        bool availableForRefund;
    }

    struct TeenData {
        uint256 tokenId;
        uint256 claimableMeth;
        address owner;
        bool isResurrected;
    }

    constructor(
        address _orchestratorV3,
        address _bapGenesis,
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls
    ) {
        V3Interface = BAPOrchestratorInterfaceV3(_orchestratorV3);
        bapGenesis = IERC721A(_bapGenesis);
        bapMeth = IERC20(_bapMethane);
        bapUtilities = IERC1155(_bapUtilities);
        bapTeenBulls = IERC721A(_bapTeenBulls);
        isGod[2016] = true;
        isGod[3622] = true;
        isGod[3714] = true;
        isGod[4473] = true;
        isGod[4741] = true;
        isGod[5843] = true;
        isGod[6109] = true;
        isGod[7977] = true;
        isGod[8190] = true;
        isGod[9690] = true;
    }

    function getBullInfo(uint256 tokenId)
        public
        view
        returns (BullData memory bullInfo)
    {
        bool isGod = godBulls(tokenId);
        uint256 claimableMeth = getClaimableMeth(tokenId, isGod);
        uint256 breedings = V3Interface.breedings(tokenId);
        uint256 lastChestOpen = isGod ? V3Interface.lastChestOpen(tokenId) : 0;
        bool availableForRefund = !isGod
            ? V3Interface.availableForRefund(tokenId)
            : false;

        bullInfo = BullData({
            tokenId: tokenId,
            claimableMeth: claimableMeth,
            breedings: breedings,
            lastChestOpen: lastChestOpen,
            isGod: isGod,
            availableForRefund: availableForRefund
        });
    }

    function getTeenInfo(uint256 tokenId)
        public
        view
        returns (TeenData memory teenInfo)
    {
        uint256 claimed = V3Interface.claimedTeenMeth(tokenId);

        teenInfo = TeenData({
            tokenId: tokenId,
            claimableMeth: getTeenClaimableMeth(tokenId, claimed),
            owner: bapTeenBulls.ownerOf(tokenId),
            isResurrected: claimed > 0
        });
    }

    function getBullsInfoBatch(uint256[] memory tokensIds)
        external
        view
        returns (BullData[] memory data)
    {
        uint256 tokensCount = tokensIds.length;
        data = new BullData[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            data[i] = getBullInfo(tokensIds[i]);
        }
    }

    function getTeensInfoBatch(uint256[] memory tokensIds)
        external
        view
        returns (TeenData[] memory data)
    {
        uint256 tokensCount = tokensIds.length;
        data = new TeenData[](tokensCount);
        for (uint256 i = 0; i < tokensCount; i++) {
            data[i] = getTeenInfo(tokensIds[i]);
        }
    }

    function bullsBatchMeth(uint256[] memory tokensIds)
        external
        view
        returns (uint256[] memory amounts)
    {
        uint256 tokensCount = tokensIds.length;
        amounts = new uint256[](tokensCount);

        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);

        for (uint256 i = 0; i < tokensCount; i++) {
            uint256 tokenId = tokensIds[i];
            bool isGod = godBulls(tokenId);

            uint256 claimed = V3Interface.claimedMeth(tokenId);
            uint256 dailyRewards = isGod ? 20 : 10;
            uint256 claimableMeth = (timeFromCreation * dailyRewards) - claimed;

            if (!isGod && V3Interface.breedings(tokenId) == 0) {
                claimableMeth += claimableMeth / 2;
            }

            bool prevClaimed = V3Interface.prevClaimed(tokenId);

            if (!prevClaimed) {
                claimableMeth += V3Interface.getOldClaimableMeth(
                    tokenId,
                    isGod ? 1 : 0
                );
            }
            amounts[i] = claimableMeth;
        }
    }

    function teensBatchMeth(uint256[] memory tokensIds)
        external
        view
        returns (uint256[] memory amounts)
    {
        uint256 tokensCount = tokensIds.length;
        amounts = new uint256[](tokensCount);

        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);

        uint256 dailyRewards = 5;

        for (uint256 i = 0; i < tokensCount; i++) {
            uint256 tokenId = tokensIds[i];

            uint256 claimed = V3Interface.claimedTeenMeth(tokenId);

            bool isResurrected = V3Interface.isResurrected(tokenId);

            uint256 claimableMeth = isResurrected
                ? (timeFromCreation * dailyRewards) - claimed
                : 0;

            amounts[i] = claimableMeth;
        }
    }

    function walletBalances(address user)
        external
        view
        returns (
            uint256 bulls,
            uint256 teens,
            uint256 meth,
            uint256[] memory utilities
        )
    {
        bulls = bapGenesis.balanceOf(user);
        teens = bapTeenBulls.balanceOf(user);
        meth = bapMeth.balanceOf(user);
        address[] memory addresses = new address[](14);
        addresses[0] = user;
        addresses[1] = user;
        addresses[2] = user;
        addresses[3] = user;
        addresses[4] = user;
        addresses[5] = user;
        addresses[6] = user;
        addresses[7] = user;
        addresses[8] = user;
        addresses[9] = user;
        addresses[10] = user;
        addresses[11] = user;
        addresses[12] = user;
        addresses[13] = user;
        uint256[] memory ids = new uint256[](14);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 20;
        ids[3] = 21;
        ids[4] = 22;
        ids[5] = 23;
        ids[6] = 30;
        ids[7] = 31;
        ids[8] = 32;
        ids[9] = 33;
        ids[10] = 40;
        ids[11] = 41;
        ids[12] = 42;
        ids[13] = 43;
        utilities = bapUtilities.balanceOfBatch(addresses, ids);
    }

    function enumerableUserWallet(address user, address nftContract)
        external
        view
        returns (uint256[] memory ids)
    {
        IERC721Enumerable contractInstace = IERC721Enumerable(nftContract);
        uint256 tokenCount = contractInstace.balanceOf(user);

        ids = new uint256[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            ids[i] = contractInstace.tokenOfOwnerByIndex(user, i);
        }
    }

    function batchOwnerData(uint256[] memory ids, address nftContract)
        external
        view
        returns (address[] memory owners)
    {
        IERC721A contractInstace = IERC721A(nftContract);
        uint256 tokenCount = ids.length;

        owners = new address[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            try contractInstace.ownerOf(ids[i]) returns (address owner) {
                owners[i] = owner;
            } catch {
                owners[i] = address(0);
            }
        }
    }

    function multisender(
        address nftContract,
        uint256[] memory ids,
        address recipient
    ) external {
        IERC721A contractInstace = IERC721A(nftContract);
        for (uint256 i = 0; i < ids.length; i++) {
            contractInstace.safeTransferFrom(msg.sender, recipient, ids[i]);
        }
    }

    function sendTokensToEveryone(
        address[] memory users,
        uint256[] memory amounts
    ) external {
        address sender = msg.sender;
        for (uint256 i = 0; i < users.length; i++) {
            bapMeth.transferFrom(sender, users[i], amounts[i]);
        }
    }

    function godBulls(uint256 tokenId) internal view returns (bool) {
        return tokenId > 10010 || isGod[tokenId];
    }

    function getClaimableMeth(uint256 tokenId, bool isGod)
        internal
        view
        returns (uint256 claimableMeth)
    {
        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);
        uint256 claimed = V3Interface.claimedMeth(tokenId);
        uint256 dailyRewards = isGod ? 20 : 10;
        claimableMeth = (timeFromCreation * dailyRewards) - claimed;

        if (!isGod && V3Interface.breedings(tokenId) == 0) {
            claimableMeth += claimableMeth / 2;
        }

        bool prevClaimed = V3Interface.prevClaimed(tokenId);

        if (!prevClaimed) {
            claimableMeth += V3Interface.getOldClaimableMeth(
                tokenId,
                isGod ? 1 : 0
            );
        }
    }

    function getTeenClaimableMeth(uint256 tokenId, uint256 claimed)
        internal
        view
        returns (uint256 claimableMeth)
    {
        if (claimed == 0) return 0;

        uint256 timeFromCreation = (block.timestamp - startTime) /
            (timeCounter);

        uint256 dailyRewards = 5;

        uint256 rewards = (timeFromCreation * dailyRewards);

        if (claimed > rewards) return 0;

        claimableMeth = rewards - claimed;
    }
}