/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

abstract contract VRFConsumerBaseV2Upgradeable is Initializable {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    function __VRFConsumerBaseV2_init(address _vrfCoordinator)
        internal
        initializer
    {
        vrfCoordinator = _vrfCoordinator;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;

    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

interface NFT {
    function addAirdrop(address to, uint256 quantity) external;

    function totalSupply() external view returns (uint256);

    function mint(
        address to,
        string memory nodeName,
        uint256 tier,
        uint256 value
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function updateValue(uint256 id, uint256 rewards) external;

    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function updateClaimTimestamp(uint256 id) external;

    function updateName(uint256 id, string memory nodeName) external;

    function updateTotalClaimed(uint256 id, uint256 rewards) external;

    function players(address user)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function _nodes(uint256 id)
        external
        view
        returns (
            uint256,
            string memory,
            uint8,
            uint256,
            uint256,
            uint256,
            uint256
        );
}

abstract contract ManageableUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _managers;
    event ManagerAdded(address indexed manager_);
    event ManagerRemoved(address indexed manager_);

    function managers(address manager_) public view virtual returns (bool) {
        return _managers[manager_];
    }

    modifier onlyManager() {
        require(_managers[_msgSender()], "Manageable: caller is not the owner");
        _;
    }

    function removeManager(address manager_) public virtual onlyOwner {
        _managers[manager_] = false;
        emit ManagerRemoved(manager_);
    }

    function addManager(address manager_) public virtual onlyOwner {
        require(
            manager_ != address(0),
            "Manageable: new owner is the zero address"
        );
        _managers[manager_] = true;
        emit ManagerAdded(manager_);
    }
}

interface ITeams {
    function getReferrer(address) external view returns (address);

    function addRewards(address user, uint256 amount) external;
}

interface IBank {
    function addRewards(address token, uint256 amount) external;
}

contract Manager is
    Initializable,
    OwnableUpgradeable,
    ManageableUpgradeable,
    VRFConsumerBaseV2Upgradeable
{
    VRFCoordinatorV2Interface COORDINATOR;
    address constant vrfCoordinator =
        0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
    address constant link_token_contract =
        0x404460C6A5EdE2D891e8297795264fDe62ADBB75;

    bytes32 constant keyHash =
        0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;
    uint16 constant requestConfirmations = 3;
    uint32 constant callbackGasLimit = 2e6;
    uint32 constant numWords = 1;
    uint64 subscriptionId;

    struct Request {
        uint256 result;
        uint256 depositAmount;
        address userAddress;
        string nodeName;
    }

    uint256[2] public tierTwoExtremas;
    uint256[2] public tierThreeExtremas;

    uint256 public tierTwoProbs;
    uint256 public tierThreeProbs;

    uint256 public maxTierTwo;
    uint256 public currentTierTwo;

    uint256 public maxTierThree;
    uint256 public currentTierThree;

    NFT public NFT_CONTRACT;
    IERC20 public TOKEN_CONTRACT;
    ITeams public TEAMS_CONTRACT;
    address public POOL;
    address public BANK;

    uint256 public startingPrice;

    uint16[3] public tiers;

    struct Fees {
        uint8 create;
        uint8 compound;
        uint8 claim;
    }

    Fees public fees;

    struct FeesDistribution {
        uint8 bank;
        uint8 rewards;
        uint8 upline;
    }

    FeesDistribution public createFeesDistribution;

    FeesDistribution public claimFeesDistribution;

    FeesDistribution public compoundFeesDistribution;

    uint256 public priceStep;
    uint256 public difference;
    uint256 public maxDeposit;
    uint256 public maxPayout;

    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public pendingMint;
    mapping(uint256 => Request) public requests;
    mapping(uint256 => uint256) public requestTimestamp;

    event GeneratedRandomNumber(uint256 requestId, uint256 randomNumber);
    event TierResult(address indexed player, uint256 tier, uint256 chances);

    function initialize(
        address TOKEN_CONTRACT_,
        address POOL_,
        address BANK_,
        uint64 _subscriptionId
    ) public initializer {
        __Ownable_init();
        __VRFConsumerBaseV2_init(vrfCoordinator);
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        TOKEN_CONTRACT = IERC20(TOKEN_CONTRACT_);
        POOL = POOL_;
        BANK = BANK_;
        subscriptionId = _subscriptionId;

        tierTwoExtremas = [300, 500];
        tierThreeExtremas = [500, 1000];

        tierTwoProbs = 20;
        tierThreeProbs = 20;

        maxTierTwo = 300;
        currentTierTwo = 0;

        maxTierThree = 200;
        currentTierThree = 0;

        startingPrice = 10e18;

        tiers = [100, 150, 200];

        fees = Fees({create: 10, compound: 5, claim: 10});

        createFeesDistribution = FeesDistribution({
            bank: 20,
            rewards: 30,
            upline: 50
        });

        claimFeesDistribution = FeesDistribution({
            bank: 20,
            rewards: 80,
            upline: 0
        });

        compoundFeesDistribution = FeesDistribution({
            bank: 0,
            rewards: 50,
            upline: 50
        });

        priceStep = 100;
        difference = 0;
        maxDeposit = 4110e18;
        maxPayout = 15000e18;
    }

    function updateTokenContract(address value) public onlyOwner {
        TOKEN_CONTRACT = IERC20(value);
    }

    function updateNftContract(address value) public onlyOwner {
        NFT_CONTRACT = NFT(value);
    }

    function updateTeamsContract(address value) public onlyOwner {
        TEAMS_CONTRACT = ITeams(value);
    }

    function updatePool(address value) public onlyOwner {
        POOL = value;
    }

    function updateBank(address value) public onlyOwner {
        BANK = value;
    }

    function updateMaxDeposit(uint256 value) public onlyOwner {
        maxDeposit = value;
    }

    function updateMaxPayout(uint256 value) public onlyOwner {
        maxPayout = value;
    }

    function updatePriceStep(uint256 value) public onlyOwner {
        priceStep = value;
    }

    function updateDifference(uint256 value) public onlyOwner {
        difference = value;
    }

    function updateTierTwoExtremas(uint256[2] memory value) public onlyOwner {
        tierTwoExtremas = value;
    }

    function updateTierThreeExtremas(uint256[2] memory value) public onlyOwner {
        tierThreeExtremas = value;
    }

    function updateTierTwoProbs(uint256 value) public onlyOwner {
        tierTwoProbs = value;
    }

    function updateTierThreeProbs(uint256 value) public onlyOwner {
        tierThreeProbs = value;
    }

    function updateMaxTierTwo(uint256 value) public onlyOwner {
        maxTierTwo = value;
    }

    function updateMaxTierThree(uint256 value) public onlyOwner {
        maxTierThree = value;
    }

    function updateCurrentTierTwo(uint256 value) public onlyOwner {
        currentTierTwo = value;
    }

    function updateCurrentTierThree(uint256 value) public onlyOwner {
        currentTierThree = value;
    }

    function currentPrice() public view returns (uint256) {
        return
            startingPrice +
            ((1 * NFT_CONTRACT.totalSupply()) / priceStep) *
            1e18 -
            difference;
    }

    function mintNode(string memory nodeName, uint256 amount) public payable {
        require(amount >= currentPrice(), "MINT: Amount too low");
        require(amount <= maxDeposit, "MINT: Amount too high");
        require(!pendingMint[_msgSender()], "MINT: You have an ongoing mint");

        TOKEN_CONTRACT.transferFrom(_msgSender(), POOL, amount);
        uint256 fees_ = (amount * fees.create) / 100;
        amount -= fees_;
        TOKEN_CONTRACT.transferFrom(
            POOL,
            BANK,
            (fees_ * createFeesDistribution.bank) / 100
        );
        IBank(BANK).addRewards(
            address(TOKEN_CONTRACT),
            (fees_ * createFeesDistribution.bank) / 100
        );
        address ref = TEAMS_CONTRACT.getReferrer(_msgSender());
        TEAMS_CONTRACT.addRewards(
            ref,
            (fees_ * createFeesDistribution.upline) / 100
        );
        if (
            amount < tierTwoExtremas[0] * 1e18 ||
            (amount <= tierTwoExtremas[1] * 1e18 &&
                currentTierTwo + 1 >= maxTierTwo) ||
            (amount > tierThreeExtremas[0] * 1e18 &&
                currentTierThree + 1 >= maxTierThree)
        ) {
            NFT_CONTRACT.mint(_msgSender(), nodeName, 0, amount);
        } else {
            require(msg.value >= 0.01 ether, "MINT: Please fund the LINK");
            pendingMint[_msgSender()] = true;
            uint256 requestId = requestRandomWords();
            requests[requestId].userAddress = _msgSender();
            requests[requestId].depositAmount = amount + fees_;
            requests[requestId].nodeName = nodeName;
            requestTimestamp[requestId] = block.timestamp;
        }
    }

    function closeMint() public {
        pendingMint[_msgSender()] = false;
    }

    function refundMint(uint256 requestId) public onlyOwner {
        pendingMint[requests[requestId].userAddress] = false;
        TOKEN_CONTRACT.transferFrom(
            POOL,
            requests[requestId].userAddress,
            requests[requestId].depositAmount
        );
    }

    function requestRandomWords() public returns (uint256) {
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 randomResult = _randomWords[0] % 10000;
        requests[_requestId].result = randomResult;

        emit GeneratedRandomNumber(_requestId, randomResult);
        checkResult(_requestId);
    }

    function checkResult(uint256 _requestId) private returns (uint256) {
        Request memory request = requests[_requestId];
        address user = requests[_requestId].userAddress;
        uint256 tier;
        uint256[2] memory extremas;
        uint256 probability;

        if (request.depositAmount <= tierTwoExtremas[1] * 1e18) {
            tier = 1;
            extremas = tierTwoExtremas;
            probability = tierTwoProbs;
        } else {
            tier = 2;
            extremas = tierThreeExtremas;
            probability = tierThreeProbs;
        }

        uint256 gap = request.depositAmount - extremas[0] * 1e18;
        uint256 diff = (extremas[1] - extremas[0]) * 1e18;
        uint256 chances;
        if (gap >= diff) {
            chances = probability * 100;
        } else {
            chances = ((gap * 100) / diff) * probability;
        }

        if (request.result > chances) {
            tier = 0;
        }

        uint256 fees_ = (request.depositAmount * fees.create) / 100;

        emit TierResult(user, tier, chances);
        NFT_CONTRACT.mint(
            user,
            request.nodeName,
            tier,
            request.depositAmount - fees_
        );

        pendingMint[user] = false;

        delete (requests[_requestId]);
        return tier;
    }

    function depositMore(uint256 id, uint256 amount) public {
        require(
            NFT_CONTRACT.ownerOf(id) == _msgSender(),
            "CLAIMALL: Not your NFT"
        );
        compound(id);
        (, , , uint256 value, , , ) = NFT_CONTRACT._nodes(id);
        require(value + amount <= maxDeposit, "DEPOSITMORE: Amount too high");
        uint256 fees_ = (amount * fees.create) / 100;
        amount -= fees_;
        TOKEN_CONTRACT.transferFrom(
            _msgSender(),
            BANK,
            (fees_ * createFeesDistribution.bank) / 100
        );
        IBank(BANK).addRewards(
            address(TOKEN_CONTRACT),
            (fees_ * createFeesDistribution.bank) / 100
        );
        address ref = TEAMS_CONTRACT.getReferrer(_msgSender());
        TEAMS_CONTRACT.addRewards(
            ref,
            (fees_ * createFeesDistribution.upline) / 100
        );
        TOKEN_CONTRACT.transferFrom(_msgSender(), POOL, amount);
        NFT_CONTRACT.updateValue(id, amount);
    }

    function availableRewards(uint256 id) public view returns (uint256) {
        (
            ,
            ,
            uint8 tier,
            uint256 value,
            uint256 totalClaimed,
            ,
            uint256 claimTimestamp
        ) = NFT_CONTRACT._nodes(id);
        uint256 rewards = (value *
            (block.timestamp - claimTimestamp) *
            tiers[tier]) /
            86400 /
            10000;
        if (totalClaimed + rewards > maxPayout) {
            rewards = maxPayout - totalClaimed;
        } else if (totalClaimed + rewards > (value * 365) / 100) {
            rewards = (value * 365) / 100 - totalClaimed;
        }
        return rewards;
    }

    function availableRewardsOfUser(address user)
        public
        view
        returns (uint256)
    {
        uint256 balance = NFT_CONTRACT.balanceOf(user);
        if (balance == 0) return 0;
        uint256 sum = 0;
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = NFT_CONTRACT.tokenOfOwnerByIndex(user, i);
            sum += availableRewards(id);
        }
        return sum;
    }

    function _claimRewards(
        uint256 id,
        address recipient,
        bool skipFees
    ) private {
        if (!managers(_msgSender())) {
            require(
                NFT_CONTRACT.ownerOf(id) == _msgSender(),
                "CLAIMALL: Not your NFT"
            );
        }
        uint256 rewards_ = availableRewards(id);
        require(rewards_ > 0, "CLAIM: No rewards available yet");
        NFT_CONTRACT.updateClaimTimestamp(id);
        uint256 fees_ = 0;
        if (!skipFees) {
            fees_ = (rewards_ * fees.claim) / 100;
            TOKEN_CONTRACT.transferFrom(
                POOL,
                BANK,
                (fees_ * claimFeesDistribution.bank) / 100
            );
            IBank(BANK).addRewards(
                address(TOKEN_CONTRACT),
                (fees_ * claimFeesDistribution.bank) / 100
            );
        }
        NFT_CONTRACT.updateTotalClaimed(id, rewards_);
        TOKEN_CONTRACT.transferFrom(POOL, recipient, rewards_ - fees_);
    }

    function claimRewards(uint256 id) public {
        require(
            NFT_CONTRACT.balanceOf(_msgSender()) > 0,
            "CLAIMALL: You don't own a NFT"
        );
        _claimRewards(id, _msgSender(), false);
    }

    function claimRewards() public {
        uint256 balance = NFT_CONTRACT.balanceOf(_msgSender());
        require(balance > 0, "CLAIMALL: You don't own a NFT");
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = NFT_CONTRACT.tokenOfOwnerByIndex(_msgSender(), i);
            _claimRewards(id, _msgSender(), false);
        }
    }

    function claimRewardsHelper(
        uint256 id,
        address recipient,
        bool skipFees
    ) public onlyManager {
        _claimRewards(id, recipient, skipFees);
    }

    function claimRewardsHelper(
        address user,
        address recipient,
        bool skipFees
    ) public onlyManager {
        uint256 balance = NFT_CONTRACT.balanceOf(user);
        require(balance > 0, "CLAIMALL: You don't own a NFT");
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = NFT_CONTRACT.tokenOfOwnerByIndex(user, i);
            _claimRewards(id, recipient, skipFees);
        }
    }

    function compoundHelper(
        uint256 id,
        uint256 externalRewards,
        address user
    ) public onlyManager {
        require(NFT_CONTRACT.ownerOf(id) == user, "CH: Not your NFT");
        uint256 rewards_ = availableRewards(id);
        require(rewards_ > 0, "CH: No rewards available yet");
        _compound(id, rewards_, user);
        (, , , uint256 value, , , ) = NFT_CONTRACT._nodes(id);
        require(value + externalRewards <= maxDeposit, "CH: Amount too high");
        NFT_CONTRACT.updateValue(id, externalRewards);
    }

    function _compound(
        uint256 id,
        uint256 rewards_,
        address user
    ) internal {
        require(NFT_CONTRACT.ownerOf(id) == user, "COMPOUND: Not your NFT");
        (, , , uint256 value, , , ) = NFT_CONTRACT._nodes(id);
        uint256 fees_ = (rewards_ * fees.compound) / 100;
        rewards_ -= fees_;
        require(value + rewards_ <= maxDeposit, "COMPOUND: Amount too high");
        NFT_CONTRACT.updateClaimTimestamp(id);
        NFT_CONTRACT.updateTotalClaimed(id, rewards_);
        TOKEN_CONTRACT.transferFrom(
            POOL,
            BANK,
            (fees_ * compoundFeesDistribution.bank) / 100
        );
        IBank(BANK).addRewards(
            address(TOKEN_CONTRACT),
            (fees_ * compoundFeesDistribution.bank) / 100
        );
        address ref = TEAMS_CONTRACT.getReferrer(user);
        TEAMS_CONTRACT.addRewards(
            ref,
            (fees_ * createFeesDistribution.upline) / 100
        );
        NFT_CONTRACT.updateValue(id, rewards_);
    }

    function compound(uint256 id) public {
        require(
            NFT_CONTRACT.balanceOf(_msgSender()) > 0,
            "COMPOUND: You don't own a NFT"
        );
        uint256 rewards_ = availableRewards(id);
        require(rewards_ > 0, "COMPOUND: No rewards available yet");
        _compound(id, rewards_, _msgSender());
    }

    function compoundAll() public {
        uint256 balance = NFT_CONTRACT.balanceOf(_msgSender());
        require(balance > 0, "COMPOUNDALL: You don't own a NFT");
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = NFT_CONTRACT.tokenOfOwnerByIndex(_msgSender(), i);
            uint256 rewards_ = availableRewards(id);
            if (rewards_ > 0) {
                _compound(id, rewards_, _msgSender());
            }
        }
    }

    // function compoundAllToSpecific(uint256 toId) public {
    //     uint256 balance = NFT_CONTRACT.balanceOf(_msgSender());
    //     require(balance > 0, "CTS: You don't own a NFT");
    //     require(
    //         NFT_CONTRACT.ownerOf(toId) == _msgSender(),
    //         "CTS: Not your NFT"
    //     );
    //     uint256 sum = 0;
    //     for (uint256 i = 0; i < balance; i++) {
    //         uint256 id = NFT_CONTRACT.tokenOfOwnerByIndex(_msgSender(), i);
    //         uint256 rewards_ = availableRewards(id);
    //         if (rewards_ > 0) {
    //             NFT_CONTRACT.updateClaimTimestamp(id);
    //         }
    //     }
    //     uint256 fees_ = (sum * fees.compound) / 100;
    //     NFT_CONTRACT.updateValue(toId, sum - fees_);
    // }

    function updateName(uint256 id, string memory name) public {
        require(
            NFT_CONTRACT.ownerOf(id) == _msgSender(),
            "CLAIMALL: Not your NFT"
        );
        NFT_CONTRACT.updateName(id, name);
    }

    function aidrop(uint256 quantity, address[] memory receivers) public {
        TOKEN_CONTRACT.transferFrom(_msgSender(), POOL, quantity);
        NFT_CONTRACT.addAirdrop(_msgSender(), quantity);
        for (uint256 i = 0; i < receivers.length; i++) {
            TEAMS_CONTRACT.addRewards(
                receivers[i],
                quantity / receivers.length
            );
        }
    }

    function getNetDeposit(address user) public view returns (int256) {
        (
            uint256 totalDeposit,
            uint256 totalAirdrop,
            uint256 totalClaimed
        ) = NFT_CONTRACT.players(user);
        return
            int256(totalDeposit) + int256(totalAirdrop) - int256(totalClaimed);
    }

    /***********************************|
  |         Owner Functions           |
  |__________________________________*/

    function setStartingPrice(uint256 value) public onlyOwner {
        startingPrice = value;
    }

    function setTiers(uint16[3] memory tiers_) public onlyOwner {
        tiers = tiers_;
    }

    function setIsBlacklisted(address user, bool value) public onlyOwner {
        isBlacklisted[user] = value;
    }

    function setFees(
        uint8 create_,
        uint8 compound_,
        uint8 claim_
    ) public onlyOwner {
        fees = Fees({create: create_, compound: compound_, claim: claim_});
    }

    function setCreateFeesDistribution(
        uint8 bank_,
        uint8 rewards_,
        uint8 upline_
    ) public onlyOwner {
        createFeesDistribution = FeesDistribution({
            bank: bank_,
            rewards: rewards_,
            upline: upline_
        });
    }

    function setClaimFeesDistribution(
        uint8 bank_,
        uint8 rewards_,
        uint8 upline_
    ) public onlyOwner {
        claimFeesDistribution = FeesDistribution({
            bank: bank_,
            rewards: rewards_,
            upline: upline_
        });
    }

    function setCompoundFeesDistribution(
        uint8 bank_,
        uint8 rewards_,
        uint8 upline_
    ) public onlyOwner {
        compoundFeesDistribution = FeesDistribution({
            bank: bank_,
            rewards: rewards_,
            upline: upline_
        });
    }

    function withdrawNative() public onlyOwner {
        (bool sent, ) = payable(owner()).call{
            value: (payable(address(this))).balance
        }("");
        require(sent, "Failed to send Ether to growth");
    }

    function withdrawNativeTwo() public onlyOwner {
        payable(owner()).transfer((payable(address(this))).balance);
    }

    function changeSubId(uint64 id) public onlyOwner {
        subscriptionId = id;
    }
}