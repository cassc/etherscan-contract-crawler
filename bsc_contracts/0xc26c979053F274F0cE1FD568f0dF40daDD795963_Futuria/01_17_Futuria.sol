// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

contract Futuria is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter _tokenIdCounter;

    bool isTestnet = block.chainid == 97;
    bool isRefundGasEnabled = false;

    address busdAddress =
        isTestnet
            ? 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee
            : 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address admin = 0x0D0095Ac3d4E5F01c6B625A971bA893b42E5AEf6;
    address defaultReferralAccount = 0x2198354afa0bCb24ddd0344d69D89a88B8876674;

    uint256 public subscriptionPercentage = 97;
    uint256 matchingBonus = 10;
    uint256 championBonus = 3;
    uint256 public txFee = 1000000000000000; // 0.001 BNB
    // uint256 public createNftFee = 4000000000000000; // 0.004 BNB
    uint256 public minWeeklyTurnoverPerLeg = isTestnet ? 1 ether : 200 ether;
    uint256 weekTurnover = 0;
    uint256 globalCap = 53;
    uint256 championBonusMinAmount = 2000 ether;

    uint256[] directSalesPercentage = [20, 22, 25, 27, 30];
    uint256[] binaryPercentage = [10, 12, 15, 17, 20];

    // User addresses
    address[] addresses;
    mapping(address => bool) public hasAddress;

    // Volume
    mapping(address => uint256) public addressToDirectCustomersVolume;
    mapping(address => uint256) public addressToWeeklyDirectCustomersVolume;
    mapping(address => uint256) public addressToPurchases;
    mapping(address => uint256) public addressToWeeklyPurchases;
    mapping(address => uint256) public addressToEarnings;
    // mapping(address => uint256) public addressToClaimed;
    // mapping(address => uint256) public addressToLastClaimedTimestamp;
    mapping(address => uint256) public addressToMinRank;
    uint256[] minParity = [1500 ether, 5000 ether, 25000 ether, 100000 ether];
    uint256[] salesToAchieveRank = [
        1500 ether,
        5000 ether,
        25000 ether,
        50000 ether
    ];

    // Extra bonus
    uint256[] extraBonusMinAmount = [150 ether, 300 ether, 1500 ether];
    uint256[] extraBonusPerc = [3, 5, 10];

    // Legs
    mapping(address => address) public addressToSponsor;
    mapping(address => address) public addressToLeg1Address;
    mapping(address => address) public addressToLeg2Address;
    mapping(address => bool) public addressToIsRightLegSelected;
    mapping(address => uint256) addressToLeftTurnover;
    mapping(address => uint256) addressToRightTurnover;
    mapping(address => uint256) public addressToLegPosition; // 1 for left, 2 for right

    // Price
    mapping(uint256 => uint256) public tokenIdToPrice;

    // Subscriptions
    mapping(address => uint256) public subscriberToTimestamp;
    mapping(address => uint256) public addressToPenalty;
    mapping(uint256 => uint256) public tokenIdToSubsLength;

    mapping(address => bool) public isFounder;
    uint256 remainingFounders = 250;
    uint256 founderBonusPercentage = 1;

    constructor() ERC721("Futuria", "FUTURIA") {
        saveAddressIfNeeded(defaultReferralAccount);
        saveAddressIfNeeded(admin);

        subscriberToTimestamp[defaultReferralAccount] =
            block.timestamp +
            9000 days;
        addFounderIfPossible(defaultReferralAccount);

        if (isTestnet) {
            safeMint(1, msg.sender, "", 1 ether, 30 days);
        } else {
            safeMint(1, admin, "", 400 ether, 365 days);
            safeMint(1, admin, "", 250 ether, 182 days);
            safeMint(1, admin, "", 60 ether, 30 days);
            safeMint(1, admin, "", 150 ether, 91 days);
        }

        address NHTPGOA6 = 0xab41875E5C9Ec3d72c3EFf6d6e37BAc32a06e816;
        address SXZEWWRV = 0x33c3511f05f72624aa9c0cfC817966e3535A597A;
        address Twolions = 0x7d096F8E9C1ff08b7AE0EF7b0FA22CB0270763Cf;
        address Micetta = 0x9089dde89113552031b635939B65e36FA9C3b0a7;
        address SISIYQEN = 0xc0C3CE0C4791e573fFb978e951F55463aD0d4A30;
        address Eagle = 0x88c6c349458466b9b2e87A56e64FD59604B7f7C1;

        address[18] memory addressList = [
            Eagle,
            address(0),
            SISIYQEN,
            0x30E46028A50853e215973ca368B1d9B0109310f6, //9Q2VH7AX
            0xdC446dcc8E9A35ee7Ac01ea35Dbd056b1d5ce978, // S6PS3DS1
            NHTPGOA6,
            0xC45Ca52f499117EFd9AfDa391f9ea800CD56A5cb, // Ricdelco
            0xEc9228Cabaf4A35dD223629A0Ca18a6C8B20eD81, // SCK1AYMO
            0x4693c8dddb03fAFda20D24b468CAd74c56816A33, // BXA5AXBN
            SXZEWWRV,
            address(0),
            Twolions,
            0x7aBCBc97408daa9B7A698b4866d3027E0488c150, // 1FNSU0ML
            0x166e3BfbFEeF8Ae0daC3897bC789652A768019bF, // Z5OOXUS0
            0x26867b4b58005b8E9c62535f29a3B5fDaD1F7e0C, // SOR6ULJA
            0x4703C8aB372A9a795b02BC6a159ae63134B998c5, // APFFRFII
            0x166a6E5aB19b36E75915C5b8Df5BA65a34Cc4c48, // N06RKQUV
            0x3569dB61A67E8F766BA72b8e1C53AC7EA225ada3 // D90RLGDQ
        ];

        for (uint256 i; i < addressList.length; i++) {
            if (addressList[i] == address(0)) {
                addressToIsRightLegSelected[
                    defaultReferralAccount
                ] = !addressToIsRightLegSelected[defaultReferralAccount];
            } else if (addressList[i] == SXZEWWRV) {
                addressToIsRightLegSelected[NHTPGOA6] = true;
                addToTreeOnlyAdmin(NHTPGOA6, addressList[i]);
            } else {
                addToTreeOnlyAdmin(defaultReferralAccount, addressList[i]);
            }
        }

        subscribeOnlyAdmin(0, Eagle);
        subscribeOnlyAdmin(0, NHTPGOA6);
        subscribeOnlyAdmin(0, SISIYQEN);
        addressToIsRightLegSelected[Twolions] = true;
        addToTreeOnlyAdmin(Twolions, Micetta);
        addToTreeOnlyAdmin(Micetta, 0x9d4Dc2a438040336Be41f94E2FC9002D3B1b6703);
        addToTreeOnlyAdmin(
            defaultReferralAccount,
            0x9f4A6E4c48ed9e409195718A7B8cF09BaAb3e05c
        );
        addressToIsRightLegSelected[Micetta] = true;
        addToTreeOnlyAdmin(Micetta, 0xeB6116008F28517aC27F17E3F8BD72416565D165);
        addToTreeOnlyAdmin(
            Twolions,
            0xa84618B3DD8D6EbC98Eb18B50e78f1bd6B786F96
        );
    }

    modifier onlyAdmin() {
        require(isAdmin());
        _;
    }

    modifier refundGas() {
        if (msg.sender == owner() && !isTestnet && isRefundGasEnabled) {
            uint256 gasAtStart = gasleft();
            _;
            uint256 gasSpent = gasAtStart - gasleft() + 30000;

            (bool success, ) = payable(msg.sender).call{
                value: gasSpent * tx.gasprice
            }("");
            require(success);
        } else {
            _;
        }
    }

    modifier onlyNftOwnerOrAdmin(uint256 tokenId) {
        address nftOwner = ownerOf(tokenId);

        require(msg.sender == nftOwner || isAdmin(), "unauth");
        _;
    }

    // View functions
    function checkIfActiveSubscription(address addr)
        public
        view
        returns (bool)
    {
        return subscriberToTimestamp[addr] >= block.timestamp;
    }

    // function totalSupply() public view virtual returns (uint256) {
    //     return _tokenIdCounter.current();
    // }

    function allowanceBUSD(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return ERC20(busdAddress).allowance(owner, spender);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getTreeSum(address rootAddress, uint256 count)
        public
        view
        virtual
        returns (uint256)
    {
        address leg1Address = addressToLeg1Address[rootAddress];
        address leg2Address = addressToLeg2Address[rootAddress];
        uint256 sum = addressToWeeklyPurchases[rootAddress];

        if (count > 800) {
            return sum;
        }

        if (leg1Address != address(0)) {
            sum += getTreeSum(leg1Address, count + 1);
        }

        if (leg2Address != address(0)) {
            sum += getTreeSum(leg2Address, count + 1);
        }

        return sum;
    }

    /**
     * Override isApprovedForAll to auto-approve MLM's proxy contract
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721)
        returns (bool isOperator)
    {
        // if MLM's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(this)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function hasMatchingBonus(address addr) public view returns (bool) {
        bool hasActiveSubs = checkIfActiveSubscription(addr);

        if (!hasActiveSubs || rankOf(addr) < 2) {
            return false;
        }

        return true;
    }

    function hasChampionBonus(address addr) public view returns (bool) {
        bool hasActiveSubs = checkIfActiveSubscription(addr);
        uint256 profits = addressToEarnings[addr];
        uint256 rank = rankOf(addr);

        if (!hasActiveSubs || profits < championBonusMinAmount || rank < 3) {
            return false;
        }

        return true;
    }

    function getChampionBonusAmount() public view returns (uint256) {
        return (weekTurnover * championBonus) / 100;
    }

    function getFoundersBonusAmount() public view returns (uint256) {
        return (weekTurnover * founderBonusPercentage) / 100;
    }

    function getDirectSalesPercentage(address addr)
        public
        view
        returns (uint256)
    {
        return directSalesPercentage[rankOf(addr) - 1];
    }

    function getDirectCommissions(address addr) public view returns (uint256) {
        uint256 weeklyDirectCustomersVolume = addressToWeeklyDirectCustomersVolume[
                addr
            ];
        return
            (weeklyDirectCustomersVolume * getDirectSalesPercentage(addr)) /
            100;
    }

    function getIndirectCommissions(address addr)
        public
        view
        returns (uint256)
    {
        bool hasActiveSubs = checkIfActiveSubscription(addr);
        uint256 parity = getParity(addr);

        if (!hasActiveSubs || parity < minWeeklyTurnoverPerLeg) {
            return 0;
        }

        uint256 rank = rankOf(addr);
        uint256 binaryPerc = binaryPercentage[rank - 1];
        uint256 binaryExtraBonus = getBinaryExtraBonus(addr);
        uint256 percentage = binaryExtraBonus + binaryPerc;

        return (parity * percentage) / 100;
    }

    function getWeeklyLegsTurnover(address rootAddress)
        public
        view
        returns (uint256[] memory)
    {
        address leg1Address = addressToLeg1Address[rootAddress];
        address leg2Address = addressToLeg2Address[rootAddress];
        uint256[] memory weeklyLegsTurnover = new uint256[](2);

        weeklyLegsTurnover[0] =
            getTreeSum(leg1Address, 0) +
            addressToLeftTurnover[rootAddress];
        weeklyLegsTurnover[1] =
            getTreeSum(leg2Address, 0) +
            addressToRightTurnover[rootAddress];

        return weeklyLegsTurnover;
    }

    // function getCapAmount() public view returns (uint256) {
    //     return (globalCap * weekTurnover) / 100;
    // }

    function getBinaryExtraBonus(address addr) public view returns (uint256) {
        uint256 weeklyVolume = addressToWeeklyDirectCustomersVolume[addr];

        if (weeklyVolume >= extraBonusMinAmount[2]) {
            return extraBonusPerc[2];
        } else if (weeklyVolume >= extraBonusMinAmount[1]) {
            return extraBonusPerc[1];
        } else if (weeklyVolume >= extraBonusMinAmount[0]) {
            return extraBonusPerc[0];
        }

        return 0;
    }

    function getParity(address addr) public view returns (uint256) {
        uint256[] memory weeklyLegsTurnover = getWeeklyLegsTurnover(addr);
        uint256 leftTurnover = weeklyLegsTurnover[0];
        uint256 rightTurnover = weeklyLegsTurnover[1];

        return leftTurnover >= rightTurnover ? rightTurnover : leftTurnover;
    }

    function rankOf(address addr) public view returns (uint256) {
        uint256 sales = addressToDirectCustomersVolume[addr];
        uint256 salesToAchieveRank2 = salesToAchieveRank[0];
        uint256 salesToAchieveRank3 = salesToAchieveRank[1];
        uint256 salesToAchieveRank4 = salesToAchieveRank[2];
        uint256 salesToAchieveRank5 = salesToAchieveRank[3];
        uint256 rankPenalty = addressToPenalty[addr];
        uint256 rank = 1;
        uint256 minRank = addressToMinRank[addr];
        uint256 parity = getParity(addr);

        if (sales >= salesToAchieveRank5 || parity >= minParity[3]) {
            rank = 5;
        } else if (sales >= salesToAchieveRank4 || parity >= minParity[2]) {
            rank = 4;
        } else if (sales >= salesToAchieveRank3 || parity >= minParity[1]) {
            rank = 3;
        } else if (
            sales >= salesToAchieveRank2 ||
            isFounder[addr] ||
            parity >= minParity[0]
        ) {
            rank = 2;
        }

        if (minRank > rank) {
            rank = minRank;
        }

        rank = rank - rankPenalty;

        if (rank < 1) {
            return 1;
        }

        return rank;
    }

    function claim() public payable nonReentrant {
        uint256 busdAmountInWei = addressToEarnings[msg.sender];
        uint256 busdBalance = ERC20(busdAddress).balanceOf(address(this));

        require(busdAmountInWei > 0, "0 amount");
        require(busdBalance > 0, "No tokens");

        addressToEarnings[msg.sender] = 0;
        saveAddressIfNeeded(msg.sender);
        // addressToLastClaimedTimestamp[msg.sender] = block.timestamp;
        // addressToClaimed[msg.sender] += busdAmountInWei;
        transferBUSD(busdAmountInWei);
    }

    function setTokenIdSubs(uint256 tokenId, uint256 subsLength)
        public
        onlyNftOwnerOrAdmin(tokenId)
    {
        tokenIdToSubsLength[tokenId] = subsLength;
    }

    function setTokenIdPrice(uint256 tokenId, uint256 price)
        public
        onlyNftOwnerOrAdmin(tokenId)
    {
        tokenIdToPrice[tokenId] = price;
    }

    function updateSubscription(
        uint256 tokenId,
        uint256 price,
        uint256 subsLength
    ) external onlyNftOwnerOrAdmin(tokenId) refundGas {
        setTokenIdSubs(tokenId, subsLength);
        setTokenIdPrice(tokenId, price);
    }

    // function buyNFT(uint256 tokenId, address referralAddress)
    //     external
    //     refundGas
    // {
    //     uint256 amount = tokenIdToPrice[tokenId];
    //     address owner = ownerOf(tokenId);
    //     address sponsor = addressToSponsor[msg.sender];

    //     addToTreeIfNeeded(referralAddress);
    //     saveAddressIfNeeded(msg.sender);
    //     updateDirectCustomersVolume(owner, amount);
    //     updatePurchases(msg.sender, amount);
    //     transferFromBUSD(msg.sender, address(this), amount);
    //     _transfer(owner, msg.sender, tokenId);
    // }

    function subscribe(uint256 tokenId, address referralAddress)
        external
        payable
        refundGas
    {
        uint256 subsPrice = tokenIdToPrice[tokenId];
        uint256 volume = (subsPrice * subscriptionPercentage) / 100;
        address sponsor = addToTreeIfNeeded(referralAddress);

        if (sponsor != address(0)) {
            updateDirectCustomersVolume(sponsor, volume);
        }

        subscriberToTimestamp[msg.sender] =
            block.timestamp +
            tokenIdToSubsLength[tokenId];
        updatePurchases(msg.sender, volume);
        addFounderIfPossible(msg.sender);
        transferFromBUSD(msg.sender, address(this), subsPrice);
    }

    function subscribeOnlyAdmin(uint256 tokenId, address subscriber)
        public
        refundGas
        onlyAdmin
    {
        uint256 subsPrice = tokenIdToPrice[tokenId];
        uint256 volume = (subsPrice * subscriptionPercentage) / 100;
        address sponsor = addressToSponsor[subscriber];

        if (sponsor != address(0)) {
            updateDirectCustomersVolume(sponsor, volume);
        }

        subscriberToTimestamp[subscriber] =
            block.timestamp +
            tokenIdToSubsLength[tokenId];
        updatePurchases(subscriber, volume);
        addFounderIfPossible(subscriber);
    }

    function setSelectedLeg(bool isRightLegSelected, address referralAddress)
        external
        payable
        refundGas
    {
        addressToIsRightLegSelected[msg.sender] = isRightLegSelected;
        saveAddressIfNeeded(msg.sender);
        addToTreeIfNeeded(referralAddress);
    }

    // Admin functions
    function setPercentages(
        uint256[] calldata _directSalesPercentage,
        uint256[] calldata _binaryPercentage,
        uint256[] calldata _salesToAchieveRank,
        // uint256 _createNftFee,
        uint256 _minWeeklyTurnoverPerLeg,
        uint256 _globalCap,
        uint256 _subscriptionPercentage,
        uint256 _matchingBonus,
        uint256 _championBonus,
        uint256 _txFee
    ) external onlyAdmin refundGas {
        directSalesPercentage = _directSalesPercentage;
        binaryPercentage = _binaryPercentage;
        salesToAchieveRank = _salesToAchieveRank;
        championBonus = _championBonus;
        // createNftFee = _createNftFee;
        minWeeklyTurnoverPerLeg = _minWeeklyTurnoverPerLeg;
        globalCap = _globalCap;
        subscriptionPercentage = _subscriptionPercentage;
        matchingBonus = _matchingBonus;
        txFee = _txFee;
    }

    function addFounderIfPossibleOnlyAdmin(address addr)
        external
        onlyAdmin
        refundGas
    {
        addFounderIfPossible(addr);
    }

    function addToTreeOnlyAdmin(address rootAddress, address newUser)
        public
        onlyAdmin
        refundGas
    {
        bool isRightLegSelected = addressToIsRightLegSelected[rootAddress];
        addressToSponsor[newUser] = rootAddress;
        addToTree(rootAddress, newUser, isRightLegSelected, 0);
    }

    function safeMint(
        uint256 quantity,
        address to,
        string memory uri,
        uint256 price,
        uint256 subsLength
    ) public payable onlyAdmin {
        // if (
        //     admin != address(0) && msg.sender != owner() && msg.sender != admin
        // ) {
        //     require(msg.value >= createNftFee, "Insufficient BNB value");
        // }

        for (uint256 i; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
            tokenIdToPrice[tokenId] = price;
            tokenIdToSubsLength[tokenId] = subsLength;
        }

        saveAddressIfNeeded(to);
    }

    function setWeeklyEarnings() external onlyAdmin refundGas {
        uint256 totalEarnings = getFoundersBonusAmount() +
            getChampionBonusAmount();
        uint256 capAmount = (globalCap * weekTurnover) / 100;
        uint256 divider = 1;
        uint256 champions = 0;
        uint256 founders = 0;

        for (uint256 i; i < addresses.length; i++) {
            address addr = addresses[i];
            uint256 earnings = getDirectCommissions(addr) +
                getIndirectCommissions(addr);

            if (hasMatchingBonus(addr)) {
                earnings += (matchingBonus * earnings) / 100;
            }

            if (hasChampionBonus(addr)) {
                champions += 1;
            }

            if (isFounder[addr]) {
                founders += 1;
            }

            totalEarnings += earnings;
        }

        if (totalEarnings > capAmount) {
            divider = totalEarnings / capAmount + 1;
        }

        for (uint256 i; i < addresses.length; i++) {
            address addr = addresses[i];

            setDirectCommissions(addr, divider);
            setIndirectCommissions(addr, divider);

            if (hasChampionBonus(addr)) {
                addressToEarnings[addr] +=
                    getChampionBonusAmount() /
                    (divider * champions);
            }

            if (isFounder[addr]) {
                addressToEarnings[addr] +=
                    getFoundersBonusAmount() /
                    (divider * founders);
            }
        }

        resetWeek();
    }

    // function setDirectCommissionsOnlyAdmin(address addr, uint256 divider)
    //     external
    //     onlyAdmin
    //     refundGas
    // {
    //     setDirectCommissions(addr, divider);
    // }

    function setAddressToEarnings(address addr, uint256 earnings)
        external
        onlyAdmin
        refundGas
    {
        addressToEarnings[addr] = earnings;
    }

    function setIndirectCommissionsOnlyAdmin(address addr, uint256 divider)
        external
        onlyAdmin
        refundGas
    {
        setIndirectCommissions(addr, divider);
    }

    function stopSubscription(address addr, uint256 rankPenalty)
        external
        onlyAdmin
        refundGas
    {
        subscriberToTimestamp[addr] = 0;
        setPenalty(addr, rankPenalty);
    }

    function setSubscriberToTimestamp(address addr, uint256 timestamp)
        external
        onlyAdmin
        refundGas
    {
        subscriberToTimestamp[addr] = timestamp;
    }

    function setMinParity(uint256[] calldata _minParity)
        external
        onlyAdmin
        refundGas
    {
        minParity = _minParity;
    }

    function setChampionBonusMinAmount(uint256 _championBonusMinAmount)
        external
        onlyAdmin
        refundGas
    {
        championBonusMinAmount = _championBonusMinAmount;
    }

    function setWeekTurnover(uint256 _weekTurnover)
        external
        onlyAdmin
        refundGas
    {
        weekTurnover = _weekTurnover;
    }

    function resetWeekOnlyAdmin() external onlyAdmin refundGas {
        resetWeek();
    }

    function renewSubscription(address addr, uint256 tokenId)
        external
        onlyAdmin
        refundGas
    {
        uint256 subsPrice = tokenIdToPrice[tokenId];
        uint256 volume = (subsPrice * subscriptionPercentage) / 100;
        address sponsor = addressToSponsor[addr];

        weekTurnover += volume;
        subscriberToTimestamp[addr] =
            block.timestamp +
            tokenIdToSubsLength[tokenId];
        saveAddressIfNeeded(addr);
        updateDirectCustomersVolume(sponsor, volume);
        updatePurchases(addr, volume);
        transferFromBUSD(addr, address(this), subsPrice);
    }

    function setPenalty(address addr, uint256 rankPenalty)
        public
        onlyAdmin
        refundGas
    {
        addressToPenalty[addr] = rankPenalty;
        saveAddressIfNeeded(addr);
    }

    function updateDirectCustomersVolumeOnlyAdmin(
        address sponsor,
        uint256 amount
    ) external onlyAdmin refundGas {
        updateDirectCustomersVolume(sponsor, amount);
    }

    function setAddressToWeeklyPurchases(address addr, uint256 amountInWei)
        external
        onlyAdmin
        refundGas
    {
        saveAddressIfNeeded(addr);
        addressToWeeklyPurchases[addr] = amountInWei;
    }

    function setLegs(
        address rootAddress,
        address leg1Address,
        address leg2Address
    ) external onlyAdmin refundGas {
        require(
            rootAddress != leg1Address && leg1Address != leg2Address,
            "invalid addr"
        );

        if (leg1Address != address(0)) {
            addressToLeg1Address[rootAddress] = leg1Address;
        }

        if (leg2Address != address(0)) {
            addressToLeg2Address[rootAddress] = leg2Address;
        }

        saveAddressIfNeeded(rootAddress);
        saveAddressIfNeeded(leg1Address);
        saveAddressIfNeeded(leg2Address);
    }

    function setWeeklyDirectCustomersVolume(address addr, uint256 amountInWei)
        external
        onlyAdmin
        refundGas
    {
        saveAddressIfNeeded(addr);
        addressToWeeklyDirectCustomersVolume[addr] = amountInWei;
    }

    // function setAddressToMinRank(address addr, uint256 rank)
    //     external
    //     onlyAdmin
    //     refundGas
    // {
    //     addressToMinRank[addr] = rank;
    // }

    function toggleRefundGasEnabled() external onlyAdmin {
        isRefundGasEnabled = !isRefundGasEnabled;
    }

    // function setAddressToLeftTurnover(address addr, uint256 turnover)
    //     external
    //     onlyAdmin
    //     refundGas
    // {
    //     addressToLeftTurnover[addr] = turnover;
    // }

    // function setAddressToRightTurnover(address addr, uint256 turnover)
    //     external
    //     onlyAdmin
    //     refundGas
    // {
    //     addressToRightTurnover[addr] = turnover;
    // }

    function setAddressToSponsor(address addr, address sponsor)
        external
        onlyAdmin
        refundGas
    {
        addressToSponsor[addr] = sponsor;
    }

    function setAddressToLeg1Address(address addr1, address addr2)
        external
        onlyAdmin
        refundGas
    {
        addressToLeg1Address[addr1] = addr2;
    }

    function setAddressToLeg2Address(address addr1, address addr2)
        external
        onlyAdmin
        refundGas
    {
        addressToLeg2Address[addr1] = addr2;
    }

    function setExtraBonus(
        uint256[] calldata _extraBonusMinAmount,
        uint256[] calldata _extraBonusPerc
    ) external virtual onlyAdmin refundGas {
        extraBonusMinAmount = _extraBonusMinAmount;
        extraBonusPerc = _extraBonusPerc;
    }

    function setAdmin(address _admin) external virtual onlyAdmin refundGas {
        if (admin != _admin) {
            admin = _admin;
        }
    }

    function setDefaultReferralAccount(address _defaultReferralAccount)
        external
        virtual
        onlyAdmin
        refundGas
    {
        defaultReferralAccount = _defaultReferralAccount;
    }

    function setFounderBonusPercentage(uint256 _founderBonusPercentage)
        external
        virtual
        onlyAdmin
        refundGas
    {
        founderBonusPercentage = _founderBonusPercentage;
    }

    // function setTokenURIOnlyAdmin(uint256 tokenId, string memory uri)
    //     external
    //     virtual
    //     onlyAdmin
    //     refundGas
    // {
    //     setTokenURI(tokenId, uri);
    // }

    function withdrawBNB() external payable onlyAdmin refundGas {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawBUSD(uint256 busdAmountInWei)
        external
        payable
        onlyAdmin
        refundGas
    {
        if (busdAmountInWei > 0) {
            transferBUSD(busdAmountInWei);
        }
    }

    function saveLegPositionOnlyAdmin(address newUser, uint256 leg)
        external
        onlyAdmin
        refundGas
    {
        saveLegPosition(newUser, leg);
    }

    // Internal
    function transferBUSD(uint256 amount) internal {
        ERC20(busdAddress).transfer(msg.sender, amount);
    }

    function isAdmin() internal view returns (bool) {
        return
            msg.sender == owner() ||
            msg.sender == admin ||
            msg.sender == defaultReferralAccount;
    }

    function addToTreeIfNeeded(address referralAddress)
        internal
        returns (address)
    {
        bool isDefaultReferralAccount = msg.sender == defaultReferralAccount;
        address sponsor = addressToSponsor[msg.sender];

        if (!isDefaultReferralAccount) {
            if (referralAddress == address(0)) {
                referralAddress = defaultReferralAccount;
            }

            require(referralAddress != msg.sender, "invalid addr");

            if (sponsor == address(0)) {
                addressToSponsor[msg.sender] = referralAddress;
                addToTree(
                    referralAddress,
                    msg.sender,
                    addressToIsRightLegSelected[referralAddress],
                    0
                );

                return referralAddress;
            }
        }

        return sponsor;
    }

    function updatePurchases(address addr, uint256 volume) internal {
        saveAddressIfNeeded(addr);

        addressToPurchases[addr] += volume;
        addressToWeeklyPurchases[addr] += volume;
        weekTurnover += volume;
    }

    function resetWeek() internal {
        for (uint256 i; i < addresses.length; i++) {
            address addr = addresses[i];

            if (rankOf(addr) > addressToMinRank[addr]) {
                addressToMinRank[addr] = rankOf(addr);
            }
        }

        weekTurnover = 0;

        for (uint256 i; i < addresses.length; i++) {
            address addr = addresses[i];

            addressToWeeklyDirectCustomersVolume[addr] = 0;
            addressToWeeklyPurchases[addr] = 0;
        }
    }

    function setIndirectCommissions(address addr, uint256 divider) internal {
        uint256[] memory weeklyLegsTurnover = getWeeklyLegsTurnover(addr);
        uint256 leftTurnover = weeklyLegsTurnover[0];
        uint256 rightTurnover = weeklyLegsTurnover[1];
        uint256 commissions = getIndirectCommissions(addr);

        if (commissions == 0) {
            addressToLeftTurnover[addr] = leftTurnover;
            addressToRightTurnover[addr] = rightTurnover;
        } else if (leftTurnover >= rightTurnover) {
            addressToLeftTurnover[addr] = rightTurnover - leftTurnover;
            addressToRightTurnover[addr] = 0;
        } else {
            addressToLeftTurnover[addr] = 0;
            addressToRightTurnover[addr] = leftTurnover - rightTurnover;
        }

        addressToEarnings[addr] += commissions / divider;
    }

    function setDirectCommissions(address addr, uint256 divider) internal {
        uint256 commissions = getDirectCommissions(addr);

        addressToEarnings[addr] += commissions / divider;
    }

    function saveLegPosition(address newUser, uint256 leg) internal {
        require(leg == 1 || leg == 2);
        addressToLegPosition[newUser] = leg;
    }

    function saveLegPositionIfNeeded(address newUser, uint256 leg) internal {
        if (addressToLegPosition[newUser] == 0) {
            saveLegPosition(newUser, leg);
        }
    }

    function saveLegData(
        address rootAddress,
        address newUser,
        uint256 leg
    ) internal {
        saveAddressIfNeeded(rootAddress);
        saveAddressIfNeeded(newUser);
        saveLegPositionIfNeeded(newUser, leg);
    }

    function addToTree(
        address rootAddress,
        address newUser,
        bool isRightLegSelected,
        uint256 count
    ) internal {
        address leftLegAddr = addressToLeg1Address[rootAddress];
        address rightLegAddr = addressToLeg2Address[rootAddress];
        uint256 leftLeg = 1;
        uint256 rightLeg = 2;

        if (count > 800) {
            return;
        }

        if (!isRightLegSelected) {
            if (leftLegAddr == address(0)) {
                saveLegData(rootAddress, newUser, leftLeg);
                addressToLeg1Address[rootAddress] = newUser;
            } else {
                // 2 legs occupied
                saveLegPositionIfNeeded(newUser, leftLeg);
                addToTree(leftLegAddr, newUser, isRightLegSelected, count + 1);
            }
        } else {
            if (rightLegAddr == address(0)) {
                saveLegData(rootAddress, newUser, rightLeg);
                addressToLeg2Address[rootAddress] = newUser;
            } else {
                // 2 legs occupied
                saveLegPositionIfNeeded(newUser, rightLeg);
                addToTree(rightLegAddr, newUser, isRightLegSelected, count + 1);
            }
        }
    }

    function addFounderIfPossible(address addr) internal {
        if (remainingFounders > 0) {
            isFounder[addr] = true;
            remainingFounders--;
        }
    }

    function transferFromBUSD(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(allowanceBUSD(sender, recipient) >= amount, "allowance");

        ERC20(busdAddress).transferFrom(sender, recipient, amount);
    }

    function saveAddressIfNeeded(address addr) internal {
        if (!hasAddress[addr] && addr != address(0)) {
            hasAddress[addr] = true;
            addresses.push(addr);
        }
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        _setTokenURI(tokenId, uri);
    }

    function updateDirectCustomersVolume(address sponsor, uint256 amount)
        internal
    {
        saveAddressIfNeeded(sponsor);
        addressToDirectCustomersVolume[sponsor] += amount;
        addressToWeeklyDirectCustomersVolume[sponsor] += amount;
    }
}