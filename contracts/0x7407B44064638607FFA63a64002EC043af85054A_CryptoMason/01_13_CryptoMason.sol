//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract CryptoMason is ERC721A, Ownable {
    string private baseTokenURI;

    uint256 public publicSalePrice;

    uint256 private totalNFTs;

    mapping(address => uint256) mintedNFTs;

    mapping(address => uint256) public NFTtracker;

    bool public isMintActive;
    bool public isStakeActive;

    mapping(address => address[]) public adrToAllRefs;
    mapping(address => address) public adrToParentRef;

    mapping(address => uint256) adrToCycle;

    uint256 internal refLevel1Percent;

    uint256 public NFTLimitPublic;

    uint256 public maxNFTs;

    event BaseURIChanged(string baseURI);

    event PublicSaleMint(address mintTo, uint256 tokensCount);

    event Received();

    address founderAddress;

    mapping(address => bool) registeredUsers;

    mapping(address => claim[]) claimInfo;
    mapping(address => uint256) public adrToClaimAmount;
    mapping(address => uint256) public adrToUsedClaimAmount;
    mapping(address => uint256[]) adrToIdsArray;
    mapping(address => uint256[]) adrToStakes;

    mapping(address => uint256) moneyFromAllRefs;
    mapping(address => refs[]) adrToRefsInfo;

    uint256 allMoneyForUsers;

    struct refs {
        address ref;
        uint256 money;
        uint256 date;
    }

    bool rewardAvailable;

    struct claim {
        address user;
        uint256 nftAmount;
        uint256 nftStartAmount;
        uint256[] nftIds;
        uint256 startTime;
        uint256 lockTime;
        uint256 percent;
        uint256 floor;
        uint256 rewardAmount;
        uint256 alreadyGiven;
        uint256 allowTime;
    }

    mapping(address => bool) isAdmin;
    address[] admins;

    constructor(
        string memory baseURI,
        address _founderAddress,
        uint256 maxNFT
    ) ERC721A("CryptoMason", "MASON", 100, 9999) {
        baseTokenURI = baseURI;

        founderAddress = _founderAddress;

        NFTLimitPublic = 4;

        maxNFTs = maxNFT;
        publicSalePrice = 74000000000000000;

        refLevel1Percent = 20;

        registeredUsers[founderAddress] = true;
        adrToParentRef[founderAddress] = _founderAddress;
    }

    function setPrices(uint256 _newPublicSalePrice) public onlyOwner {
        publicSalePrice = _newPublicSalePrice;
    }

    function setNFTLimits(uint256 _newLimitPublic) public onlyOwner {
        NFTLimitPublic = _newLimitPublic;
    }

    function setNFTHardcap(uint256 _newMax) public onlyOwner {
        maxNFTs = _newMax;
    }

    function registerInSystem(address referal) external {
        require(
            registeredUsers[referal] == true,
            "referal address is not registered"
        );
        require(referal != msg.sender, "You cannot be referal of yourself");
        registeredUsers[msg.sender] = true;
        adrToParentRef[msg.sender] = referal;
        adrToAllRefs[referal].push(msg.sender);
        adrToRefsInfo[adrToParentRef[msg.sender]].push(refs(msg.sender, 0, 0));
    }

    function freeMint() external {
        require(registeredUsers[msg.sender], "Not registered in system");
        require(totalNFTs + 1 <= maxNFTs, "Exceeded max NFTs amount");

        require(isMintActive, "mint is paused");

        require(
            adrToCycle[msg.sender] > 9,
            "Not enough nfts minted with your referal"
        );

        totalNFTs += 1;

        mintedNFTs[msg.sender] += 1;

        NFTtracker[msg.sender] += 1;

        adrToCycle[msg.sender] -= 10;

        _safeMint(msg.sender, 1, true, "");
    }

    function PublicMint(uint256 quantity) external payable {
        require(registeredUsers[msg.sender], "Not registered in system");
        require(totalNFTs + quantity <= maxNFTs, "Exceeded max NFTs amount");
        require(isMintActive, "mint is paused");

        require(
            NFTtracker[msg.sender] + quantity <= NFTLimitPublic,
            "Minting would exceed wallet limit"
        );
        require(quantity > 0, "Quantity has to be more than 0");

        require(
            msg.value >= publicSalePrice * quantity,
            "Fund amount is incorrect"
        );

        _safeMint(msg.sender, quantity, true, "");

        totalNFTs += quantity;

        NFTtracker[msg.sender] += quantity;
        mintedNFTs[msg.sender] += quantity;

        uint256 money = msg.value;

        address par = adrToParentRef[msg.sender];

        uint256 mon = (refLevel1Percent * money) / 100;

        _widthdraw(par, mon);
        moneyFromAllRefs[par] += mon;

        bool found;
        uint256 place;
        for (uint256 i; i < adrToRefsInfo[par].length; i++) {
            if (adrToRefsInfo[par][i].ref == msg.sender) {
                found = true;
                place = i;
                break;
            }
        }
        if (found) {
            adrToRefsInfo[par][place].money += mon;
            adrToRefsInfo[par][place].date = block.timestamp;
        } else {
            adrToRefsInfo[par].push(refs(msg.sender, mon, block.timestamp));
        }

        money -= mon;

        _widthdraw(founderAddress, money);
        adrToCycle[par] += quantity;
    }

    function Airdrop(uint256 quantity, address wallet)
        external
        payable
        onlyOwner
    {
        require(totalNFTs + quantity <= maxNFTs, "Exceeded max NFTs amount");

        require(quantity <= 150, "Exceeded max transaction amount");

        _safeMint(wallet, quantity, true, "");

        totalNFTs += quantity;

        NFTtracker[wallet] += quantity;
    }

    function allowUser(
        uint256[] memory tokenIds,
        uint256 floor,
        uint256 time,
        uint256 perc,
        address user1
    ) external {
        require(
            msg.sender == owner() || isAdmin[msg.sender],
            "Not enough rights"
        );
        require(registeredUsers[user1], "Not registered in system");

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                this.ownerOf(tokenIds[i]) == user1,
                "This user is not owner of the nft"
            );
        }

        uint256 divide = 1 days * 100;

        uint256 myReward = (floor * tokenIds.length * perc * time * 60) /
            divide;

        if (adrToClaimAmount[user1] == adrToUsedClaimAmount[user1]) {
            adrToClaimAmount[user1]++;

            claimInfo[user1].push(
                claim(
                    user1,
                    tokenIds.length,
                    tokenIds.length,
                    tokenIds,
                    0,
                    time * 60,
                    perc,
                    floor,
                    myReward,
                    0,
                    block.timestamp
                )
            );
            allMoneyForUsers += myReward;
        } else {
            claimInfo[user1][claimInfo[user1].length - 1] = claim(
                user1,
                tokenIds.length,
                tokenIds.length,
                tokenIds,
                0,
                time * 60,
                perc,
                floor,
                myReward,
                0,
                block.timestamp
            );
        }
    }

    function stake() external {
        require(registeredUsers[msg.sender], "Not registered in system");
        require(isStakeActive, "Stake is paused");

        require(
            adrToUsedClaimAmount[msg.sender] < adrToClaimAmount[msg.sender],
            "Don't have stakes"
        );
        require(
            claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]].nftAmount >
                0,
            "Do not have stakes at all"
        );
        require(
            block.timestamp <=
                claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]]
                    .allowTime +
                    1 hours,
            "Stake deadline is over"
        );

        adrToStakes[msg.sender].push(adrToClaimAmount[msg.sender]);

        for (
            uint256 i;
            i <
            claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]]
                .nftIds
                .length;
            i++
        ) {
            require(
                ownerOf(
                    claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]]
                        .nftIds[i]
                ) == msg.sender,
                "This user is not owner of the nft"
            );

            safeTransferFrom(
                msg.sender,
                address(this),
                claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]].nftIds[
                    i
                ]
            );
            adrToIdsArray[msg.sender].push(
                claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]].nftIds[
                    i
                ]
            );
        }
        claimInfo[msg.sender][adrToUsedClaimAmount[msg.sender]]
            .startTime = block.timestamp;
        adrToUsedClaimAmount[msg.sender]++;
    }

    function checkReferals(address user, uint256 startPoint)
        external
        view
        returns (refs[] memory referalInfo)
    {
        uint256 amount = 8;

        require(startPoint % 8 == 0, "startPoint must be 0, 8, 16 ... etc.");
        require(startPoint < adrToRefsInfo[user].length, "startPoint too big");

        uint256 count;
        bool a;

        if (adrToRefsInfo[user].length < startPoint + amount) {
            uint256 newStartPoint = startPoint - (startPoint % 8);
            refs[] memory adrArray = new refs[](
                adrToRefsInfo[user].length - newStartPoint
            );
            for (
                uint256 i = newStartPoint;
                i < adrToRefsInfo[user].length;
                i++
            ) {
                if (adrToRefsInfo[user][i].ref != address(0)) {
                    adrArray[count] = adrToRefsInfo[user][i];
                    count++;
                }
            }
            return adrArray;
        } else {
            refs[] memory adrArray = new refs[](amount);
            for (uint256 i = startPoint; i < startPoint + amount; i++) {
                if (adrToRefsInfo[user][i].ref != address(0)) {
                    adrArray[count] = adrToRefsInfo[user][i];
                    count++;
                    a = true;
                }
            }

            return adrArray;
        }
    }

    function checkUserStakings(address user)
        external
        view
        returns (
            uint256 totalRewards,
            uint256 _totalNFTs,
            uint256[] memory stakeNumbers,
            uint256[] memory stakeNotZero
        )
    {
        uint256 len = adrToStakes[user].length;
        uint256[] memory array = new uint256[](len);

        for (uint256 i; i < adrToStakes[user].length; i++) {
            if (checkMyRewards(user, adrToStakes[user][i]) != 0) {
                array[i] = adrToStakes[user][i];
            }
        }

        return (
            checkMyAllRewards(user),
            adrToIdsArray[user].length,
            adrToStakes[user],
            array
        );
    }

    function checkGeneralRefInfo(address user)
        external
        view
        returns (uint256 totalMoney, uint256 refAmount)
    {
        return (moneyFromAllRefs[user], adrToRefsInfo[user].length);
    }

    function checkClaimInfo(address user, uint256 claimNumber)
        external
        view
        returns (
            uint256[] memory tokenIds,
            uint256 floor,
            uint256 percent,
            uint256 startTime,
            uint256 timeAvailable
        )
    {
        return (
            claimInfo[user][claimNumber - 1].nftIds,
            claimInfo[user][claimNumber - 1].floor,
            claimInfo[user][claimNumber - 1].percent,
            claimInfo[user][claimNumber - 1].startTime,
            claimInfo[user][claimNumber - 1].startTime +
                claimInfo[user][claimNumber - 1].lockTime
        );
    }

    function batchUnstakeNFTs(uint256[] memory nfts) external {
        for (uint256 i; i < nfts.length; i++) {
            unStakeNFTs(nfts[i]);
            uint256 index = 0;
            for (
                uint256 l;
                l < claimInfo[msg.sender][nfts[i] - 1].nftIds.length;
                l++
            ) {
                for (uint256 j; j < adrToIdsArray[msg.sender].length; j++) {
                    if (
                        adrToIdsArray[msg.sender][j] ==
                        claimInfo[msg.sender][nfts[i] - 1].nftIds[l]
                    ) {
                        index = j;
                    }
                }
                removeNFTs(msg.sender, index);
            }
        }
    }

    function unStakeNFTs(uint256 numberClaim) internal {
        require(numberClaim != 0, "Not correct number");
        numberClaim -= 1;
        require(registeredUsers[msg.sender], "Not registered in system");
        require(
            claimInfo[msg.sender][numberClaim].startTime +
                claimInfo[msg.sender][numberClaim].lockTime <
                block.timestamp,
            "Wait for ending of your deadline"
        );

        for (
            uint256 i;
            i < claimInfo[msg.sender][numberClaim].nftIds.length;
            i++
        ) {
            this.safeTransferFrom(
                address(this),
                msg.sender,
                claimInfo[msg.sender][numberClaim].nftIds[i]
            );
        }

        claimInfo[msg.sender][numberClaim].nftAmount == 0;
        if (claimInfo[msg.sender][numberClaim].rewardAmount == 0) {
            uint256 index = 0;
            for (uint256 j; j < adrToStakes[msg.sender].length; j++) {
                if (adrToStakes[msg.sender][j] == numberClaim) {
                    index = j;
                }
            }
            removeStakes(msg.sender, index);
        }
    }

    function addAdmin(address user) external onlyOwner {
        require(!isAdmin[user], "Already admin");
        isAdmin[user] = true;
        admins.push(user);
    }

    function deleteAdmin(address user) external onlyOwner {
        require(isAdmin[user], "Not admin");
        for (uint256 i; i < admins.length; i++) {
            if (admins[i] == user) {
                removeAdmin(i);
            }
        }
    }

    function removeAdmin(uint256 index) internal returns (address[] memory) {
        for (uint256 i = index; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }
        delete admins[admins.length - 1];
        admins.pop();
        return admins;
    }

    function removeNFTs(address user, uint256 index)
        internal
        returns (uint256[] memory)
    {
        for (uint256 i = index; i < adrToIdsArray[user].length - 1; i++) {
            adrToIdsArray[user][i] = adrToIdsArray[user][i + 1];
        }
        delete adrToIdsArray[user][adrToIdsArray[user].length - 1];
        adrToIdsArray[user].pop();
        return adrToIdsArray[user];
    }

    function removeStakes(address user, uint256 index)
        internal
        returns (uint256[] memory)
    {
        for (uint256 i = index; i < adrToStakes[user].length - 1; i++) {
            adrToStakes[user][i] = adrToStakes[user][i + 1];
        }
        delete adrToStakes[user][adrToStakes[user].length - 1];
        adrToStakes[user].pop();
        return adrToStakes[user];
    }

    function checkAllAdmins()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return admins;
    }

    function setRewardAmount() external payable onlyOwner {
        rewardAvailable = true;
    }

    function getRewardsAndNFTs(uint256[] memory numberClaim) external {
        for (uint256 i; i < numberClaim.length; i++) {
            getRewards(numberClaim[i]);
            unStakeNFTs(numberClaim[i]);
        }
    }

    function batchRewards(uint256[] memory stakeNumbers) external {
        for (uint256 i; i < stakeNumbers.length; i++) {
            getRewards(stakeNumbers[i]);
        }
    }

    function getRewards(uint256 numberClaim) internal {
        require(numberClaim != 0, "Not correct number");
        numberClaim -= 1;
        require(registeredUsers[msg.sender], "Not registered in system");

        require(rewardAvailable, "Admin didn't set rewardSumm yet");

        require(
            adrToUsedClaimAmount[msg.sender] <= adrToClaimAmount[msg.sender],
            "Don't have stakes"
        );
        require(
            claimInfo[msg.sender][numberClaim].startTime > 0,
            "Stake at first"
        );
        require(
            claimInfo[msg.sender][numberClaim].rewardAmount > 0,
            "Dont have rewards"
        );

        uint256 nows = block.timestamp;
        uint256 myReward;
        bool a;

        if (
            claimInfo[msg.sender][numberClaim].startTime +
                claimInfo[msg.sender][numberClaim].lockTime <
            nows
        ) {
            myReward = claimInfo[msg.sender][numberClaim].rewardAmount;
            claimInfo[msg.sender][numberClaim].rewardAmount -= myReward;
            a = true;
        } else {
            uint256 divide = 1 days * 100;

            myReward =
                (claimInfo[msg.sender][numberClaim].floor *
                    claimInfo[msg.sender][numberClaim].nftStartAmount *
                    claimInfo[msg.sender][numberClaim].percent *
                    (block.timestamp -
                        claimInfo[msg.sender][numberClaim].startTime)) /
                divide -
                claimInfo[msg.sender][numberClaim].alreadyGiven;

            claimInfo[msg.sender][numberClaim].rewardAmount -= myReward;
        }
        claimInfo[msg.sender][numberClaim].alreadyGiven += myReward;

        allMoneyForUsers -= myReward;

        (bool success, ) = payable(msg.sender).call{value: myReward}("");

        require(success, "Transfer failed");
        if (a) {
            claimInfo[msg.sender][numberClaim].rewardAmount = 0;
        }
    }

    function changeStakePauseStatus() external onlyOwner {
        isStakeActive = !isStakeActive;
    }

    function changeMintPauseStatus() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function checkMyRewards(address user, uint256 numberClaim)
        public
        view
        returns (uint256)
    {
        require(numberClaim != 0, "Not correct number");
        numberClaim -= 1;
        require(registeredUsers[user], "Not registered in system");
        uint256 nows = block.timestamp;
        uint256 myReward;
        if (numberClaim + 1 <= adrToUsedClaimAmount[user]) {
            if (
                claimInfo[user][numberClaim].startTime +
                    claimInfo[user][numberClaim].lockTime <
                nows
            ) {
                myReward = claimInfo[user][numberClaim].rewardAmount;
            } else {
                uint256 divide = 1 days * 100;

                myReward =
                    (claimInfo[user][numberClaim].floor *
                        claimInfo[user][numberClaim].nftStartAmount *
                        claimInfo[user][numberClaim].percent *
                        (block.timestamp -
                            claimInfo[user][numberClaim].startTime)) /
                    divide -
                    claimInfo[user][numberClaim].alreadyGiven;
            }
            return myReward;
        } else {
            return 0;
        }
    }

    function checkMyAllRewards(address user) public view returns (uint256) {
        uint256 sum;
        for (uint256 i; i < adrToStakes[user].length; i++) {
            sum += checkMyRewards(user, adrToStakes[user][i]);
        }
        return sum;
    }

    function userNFTIds(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function checkReferalPercents() external view returns (uint256 level1) {
        return (refLevel1Percent);
    }

    function checkAllMoneyForAllUsers() external view returns (uint256) {
        return allMoneyForUsers;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        string memory _tokenURI = super.tokenURI(tokenId);

        return string(abi.encodePacked(_tokenURI, ".json"));
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;

        emit BaseURIChanged(baseURI);
    }

    function isRegistered(address user) external view returns (bool) {
        return registeredUsers[user];
    }

    function isMinted(address user) external view returns (bool) {
        if (mintedNFTs[user] > 0) {
            return true;
        }
        return false;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;

        require(balance > 0, "Insufficent balance");

        _widthdraw(founderAddress, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");

        require(success, "Failed to widthdraw Ether");
    }

    function changeFounderAddress(address adr) external onlyOwner {
        founderAddress = adr;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;
        emit Received();
        return 0x150b7a02;
    }
}