// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IDynamic.sol";
import "./interfaces/INft.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DynamicNft is AccessControl, IDynamic {
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant NFT_ROLE = keccak256("NFT_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public merkleRoot = 0xa0fd9888b738d87f115429a3520fdbd602fbe89c095c2a6f2f1f5af661dfc43d;
    bytes32 public constant ZEROSTATE = 0x0000000000000000000000000000000000000000000000000000000000000000;

    address public immutable treasuryAddress;
    address private cap3Wallet;
    address public genesisContractAddress;
    address public subsContractAddress;

    uint256 public genesisPrice = 2 ether;
    uint256 private projectId = 1;
    uint256 public genesisSupply = 2000;
    uint256 public subscriptionSupply = 7000;
    uint256 private genesisVotingPower = 2;
    uint256 private subscriptionVotingPower = 1;
    uint256 private treasuryLimit = 1e6;
    uint256 public projectFund = 1e5;

    bool public genesisStatus;
    bool public subscriptionStatus;
    SubscriptionStage public subsStage;
    SubscriptionTierDetails public subscriptionDetails;
    bool public distributeFlag;
    bool public refundFlag;

    struct Genesis {
        uint256 tokenId;
        address owner;
        bool claimed;
    }

    struct Subscription {
        uint256 tokenId;
        uint256 renewalExpire;
        uint256 price;
        address owner;
        bool expired;
        bool renewed;
    }

    struct Project {
        string id;
        string description;
        address author;
        bool funded;
    }

    struct SubscriptionTierDetails {
        uint256 tierOnePrice;
        uint256 tierTwoPrice;
        uint256 tierThreePrice;
        uint256 tierFourPrice;
        uint256 tierOneQuantities;
        uint256 tierTwoQuantities;
        uint256 tierThreeQuantities;
        uint256 tierFourQuantities;
    }

    enum TOKEN {
        GENESIS,
        SUBSCRIPTION
    }

    enum SubscriptionStage {
        TIER_ONE,
        TIER_TWO,
        TIER_THREE,
        TIER_FOUR
    }

    /*------ Events -------*/

    event SubscriptionMintStateUpdated(bool state);
    event GenesisMintStateUpdated(bool state);
    event GenesisMinted(address to, uint256 id, uint16 quantity);
    event SubscriptionMinted(address to, uint256 id, uint16 quantity);
    event SubscriptionRenewed(address holder, uint256 tokenId);
    event ExpiredSubscription(address holder, uint256 renewalExpire, uint256 tokenId);
    event MerkleRootSet(bytes32 _merkleRoot);
    event TreasuryLimitSet(uint256 newLimit, uint256 oldLimit);
    event SubscriptionBalanceUpdated(uint256 TokenSupply, uint256 tokenId);
    event ProposalApproved(string id, string _title, address author, uint256 amount);
    event ProposalFunded(string id, uint256 amount);
    event UpdatedBackendAddress(address backendAddress, string Role);
    event DistributionActive();
    event NftTransfered(address to, uint256 tokenId, bool isGenesis);
    event SubscriptionStageUpdated(uint256 newStage);
    event SubscriptionPriceUpdated(uint256 stage, uint256 newPrice);
    event SubscriptionQuantitesUpdated(uint256 stage, uint256 newQuantity);
    event Refunded(address sender, uint256[] tokenIds, uint256 amount);

    mapping(string => Project) private proposals;
    mapping(uint256 => Genesis) public genesisHolder;
    mapping(uint256 => Subscription) public subsHolder;
    mapping(address => uint256) public referralCodes;
    mapping(uint256 => address) public codeToAddress;
    mapping(address => uint8) public toRefund;

    AggregatorV3Interface internal priceFeed;

    constructor(
        address _genesis,
        address _subscription,
        address _treasury,
        address _cap3Wallet,
        address _priceFeedAggregator,
        address[] memory _admins
    ) {
        require(_genesis != address(0), "ADDRESS ZERO");
        require(_subscription != address(0), "ADDRESS ZERO");
        require(_treasury != address(0), "ADDRESS ZERO");
        require(_cap3Wallet != address(0), "ADDRESS ZERO");
        require(_priceFeedAggregator != address(0), "ADDRESS ZER0");

        subsContractAddress = _subscription;
        genesisContractAddress = _genesis;
        treasuryAddress = _treasury;
        cap3Wallet = _cap3Wallet;

        priceFeed = AggregatorV3Interface(_priceFeedAggregator);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _admins[0]);
        _setupRole(ADMIN_ROLE, _admins[1]);
        _setupRole(ADMIN_ROLE, address(this));
        _setupRole(NFT_ROLE, _genesis);
        _setupRole(NFT_ROLE, _subscription);

        subscriptionDetails.tierOnePrice = 0.2 ether;
        subscriptionDetails.tierTwoPrice = 0.22 ether;
        subscriptionDetails.tierThreePrice = 0.24 ether;
        subscriptionDetails.tierFourPrice = 0.26 ether;
        subscriptionDetails.tierOneQuantities = 1750;
        subscriptionDetails.tierTwoQuantities = 1750;
        subscriptionDetails.tierThreeQuantities = 1750;
        subscriptionDetails.tierFourQuantities = 1750;
    }

    /*------- State Changing Functions ------*/

    function mintGenesis(
        address _to,
        bytes32[] calldata _merkleProof,
        uint256 _quantity
    ) public payable {
        INft GenesisNft = INft(genesisContractAddress);
        require((GenesisNft.totalSupply() + _quantity) <= (genesisSupply / 4), "MAX QUANTITY REACHED");
        require(msg.value >= (genesisPrice * _quantity), "INSUFFICIENT MINTING VALUE");
        require(genesisStatus, "GENESIS MINT CURRENTLY INACTIVE");
        require(GenesisNft.totalSupply() < 500, "INSUFICIENT GENESIS STOCK");

        if (merkleRoot != ZEROSTATE) {
            require(verifyMerkleProof(_to, _merkleProof), "INVALID MERKLE PROOF");
        }

        uint256 _id = GenesisNft.currentIndex();

        for (uint256 x = _id; x < (_quantity + _id); x++) {
            genesisHolder[x] = Genesis({tokenId: _id, owner: _to, claimed: false});
        }

        GenesisNft.mint(_to, _quantity);

        (bool success, ) = cap3Wallet.call{value: msg.value}("");
        require(success, "MINT:ETH TRANSFER FAILED");

        if (GenesisNft.totalSupply() == (genesisSupply / 4)) {
            genesisStatus = false;
        }
        emit GenesisMinted(_to, _id, uint16(_quantity));
    }

    function mintGiftGenesis(address _to) public onlyRole(ADMIN_ROLE) {
        INft GenesisNft = INft(genesisContractAddress);
        require(genesisStatus, "GENESIS MINT CURRENTLY INACTIVE");
        require(GenesisNft.totalSupply() < 500, "INSUFICIENT GENESIS STOCK");

        uint256 _id = GenesisNft.currentIndex();
        genesisHolder[_id] = Genesis({tokenId: _id, owner: _to, claimed: false});

        GenesisNft.mint(_to, 1);

        if (GenesisNft.totalSupply() == 500) {
            genesisStatus = false;
        }

        emit GenesisMinted(_to, _id, 1);
    }

    function mintSubscription(
        address _to,
        uint256 _quantity,
        uint256 _referralCode
    ) public payable {
        INft SubscriptionNft = INft(subsContractAddress);
        uint256 amountPaidPerNFT;

        require(subscriptionStatus, "SUBS MINT CURRENTLY INACTIVE");
        require(SubscriptionNft.totalSupply() + _quantity <= subscriptionSupply, "INSUFICIENT SUBSCRIPTION STOCK");

        if (subsStage == SubscriptionStage.TIER_ONE) {
            if (_quantity + SubscriptionNft.totalSupply() <= subscriptionDetails.tierOneQuantities) {
                require(msg.value >= (subscriptionDetails.tierOnePrice * _quantity), "INSUFFICIENT MINTING VALUE");
                amountPaidPerNFT = subscriptionDetails.tierOnePrice;
            } else {
                uint256 amountLeftOfTierOne = subscriptionDetails.tierOneQuantities - SubscriptionNft.totalSupply();
                uint256 amountToPayTierOne = amountLeftOfTierOne * subscriptionDetails.tierOnePrice;
                uint256 amountOfTierTwoMinted = _quantity - amountLeftOfTierOne;
                uint256 amountToPayTierTwo = amountOfTierTwoMinted * subscriptionDetails.tierTwoPrice;
                require(msg.value == (amountToPayTierOne + amountToPayTierTwo), "INSUFFICIENT MINTING VALUE");
                amountPaidPerNFT = subscriptionDetails.tierOnePrice;
            }
        } else if (subsStage == SubscriptionStage.TIER_TWO) {
            if (
                _quantity + SubscriptionNft.totalSupply() <=
                subscriptionDetails.tierTwoQuantities + subscriptionDetails.tierOneQuantities
            ) {
                require(msg.value == (subscriptionDetails.tierTwoPrice * _quantity), "INSUFFICIENT MINTING VALUE");
                amountPaidPerNFT = subscriptionDetails.tierTwoPrice;
            } else {
                uint256 amountLeftOfTierTwo = (subscriptionDetails.tierTwoQuantities +
                    subscriptionDetails.tierOneQuantities) - SubscriptionNft.totalSupply();
                uint256 amountToPayTierTwo = amountLeftOfTierTwo * subscriptionDetails.tierTwoPrice;
                uint256 amountOfTierThreeMinted = _quantity - amountLeftOfTierTwo;
                uint256 amountToPayTierThree = amountOfTierThreeMinted * subscriptionDetails.tierThreePrice;
                require(msg.value == (amountToPayTierTwo + amountToPayTierThree), "INSUFFICIENT MINTING VALUE");
                amountPaidPerNFT = subscriptionDetails.tierTwoPrice;
            }
        } else if (subsStage == SubscriptionStage.TIER_THREE) {
            if (
                _quantity + SubscriptionNft.totalSupply() <=
                subscriptionDetails.tierThreeQuantities +
                    subscriptionDetails.tierTwoQuantities +
                    subscriptionDetails.tierOneQuantities
            ) {
                require(msg.value == (subscriptionDetails.tierThreePrice * _quantity), "INSUFFICIENT MINTING VALUE");
                amountPaidPerNFT = subscriptionDetails.tierThreePrice;
            } else {
                uint256 amountLeftOfTierThree = (subscriptionDetails.tierTwoQuantities +
                    subscriptionDetails.tierOneQuantities +
                    subscriptionDetails.tierThreeQuantities) - SubscriptionNft.totalSupply();
                uint256 amountToPayTierThree = amountLeftOfTierThree * subscriptionDetails.tierThreePrice;
                uint256 amountOfTierFourMinted = _quantity - amountLeftOfTierThree;
                uint256 amountToPayTierFour = amountOfTierFourMinted * subscriptionDetails.tierFourPrice;
                require(msg.value == (amountToPayTierThree + amountToPayTierFour), "INSUFFICIENT MINTING VALUE");
                amountPaidPerNFT = subscriptionDetails.tierThreePrice;
            }
        } else if (subsStage == SubscriptionStage.TIER_FOUR) {
            require(msg.value == (subscriptionDetails.tierFourPrice * _quantity), "INSUFFICIENT MINTING VALUE");
            amountPaidPerNFT = subscriptionDetails.tierFourPrice;
        }

        uint256 _id = SubscriptionNft.currentIndex();

        do {
            subsHolder[_id] = Subscription({
                tokenId: _id,
                owner: _to,
                price: amountPaidPerNFT,
                expired: false,
                renewed: false,
                renewalExpire: 0
            });

            unchecked {
                ++_id;
            }
        } while (_id < (_quantity + SubscriptionNft.currentIndex()));

        SubscriptionNft.mint(_to, _quantity);

        if (
            SubscriptionNft.totalSupply() >=
            (subscriptionDetails.tierThreeQuantities +
                subscriptionDetails.tierTwoQuantities +
                subscriptionDetails.tierOneQuantities)
        ) {
            subsStage = SubscriptionStage.TIER_FOUR;
        } else if (
            SubscriptionNft.totalSupply() >=
            (subscriptionDetails.tierTwoQuantities + subscriptionDetails.tierOneQuantities)
        ) {
            subsStage = SubscriptionStage.TIER_THREE;
        } else if (SubscriptionNft.totalSupply() >= subscriptionDetails.tierOneQuantities) {
            subsStage = SubscriptionStage.TIER_TWO;
        }

        if (referralCodes[msg.sender] == 0) {
            uint256 referralCode = _generateReferralCode(msg.sender, _quantity);
            referralCodes[msg.sender] = referralCode;
            codeToAddress[referralCode] = msg.sender;
        }

        if (_referralCode != 0) {
            require(isCodeValid(_referralCode), "INVALID REFERRAL CODE");
            address referee = codeToAddress[_referralCode];
            ITreasury treasury = ITreasury(payable(treasuryAddress));
            treasury.payReward(referee);
        }

        cap3TreasuryFundShare(msg.value);

        emit SubscriptionMinted(_to, _id, uint16(_quantity));

    }

    function refund(bool _state) public onlyRole(ADMIN_ROLE) {
        require(genesisStatus == false, "GENESIS MINT STILL OPEN");
        string memory boolString = _state == true ? "true" : "false";
        require(refundFlag != _state, string(abi.encodePacked("Refund Flag already ", boolString)));
        refundFlag = _state;
    }

    function claimRefund(uint256[] calldata tokenIds) public {
        INft GenesisNft = INft(genesisContractAddress);
        ITreasury treasury = ITreasury(treasuryAddress);
        require(genesisStatus == false, "GENESIS MINT STILL OPEN");
        require(refundFlag == true, "REFUND NOT OPEN");
        uint256 arrayLength = tokenIds.length;
        uint256[] memory refundedTokens = new uint256[](arrayLength);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (GenesisNft.ownerOf(tokenId) == msg.sender) {
                uint256 refundAmount = genesisPrice;
                GenesisNft.burn(tokenId);
                delete (genesisHolder[tokenId]);
                treasury.payRefund(msg.sender, refundAmount);
                refundedTokens[i] = tokenId;
            }
        }

        emit Refunded(msg.sender, refundedTokens, genesisPrice);
    }

    function isCodeValid(uint256 _code) public view returns (bool) {
        address referee = codeToAddress[_code];
        if (referee == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    function setDistibuteGenesisTokensActive() public onlyRole(ADMIN_ROLE) {
        require(genesisStatus == false, "GENESIS MINT STILL OPEN");
        require(distributeFlag != true, "PHASE ALREADY ACTIVE");
        distributeFlag = true;
        emit DistributionActive();
    }

    function claimDistributedTokens(uint256 _tokenID) public {
        INft GenesisNft = INft(genesisContractAddress);

        require(distributeFlag == true, "DISTRIBUTION NOT OPEN");
        require(!genesisHolder[_tokenID].claimed, "ALREADY CLAIMED");
        require(msg.sender == genesisHolder[_tokenID].owner, "NOT NFT OWNER");

        uint256 _id = GenesisNft.currentIndex();

        do {
            genesisHolder[_id] = Genesis({tokenId: _id, owner: msg.sender, claimed: true});
            unchecked {
                ++_id;
            }
        } while (_id < (3 + GenesisNft.currentIndex()));

        genesisHolder[_tokenID].claimed = true;
        GenesisNft.mint(msg.sender, 3);

        emit GenesisMinted(msg.sender, _id, 3);

    }

    function burnToken(uint256 _tokenId) public {
        INft GenesisNft = INft(genesisContractAddress);

        require(GenesisNft.totalSupply() < 500, "TOKENS SOLDOUT");
        require(GenesisNft.ownerOf(_tokenId) == msg.sender, "NOT TOKEN HOLDER");
        GenesisNft.burn(_tokenId);
        delete (genesisHolder[_tokenId]);

        unchecked {
            toRefund[msg.sender] += 1;
        }
    }

    function transferNft(address _to, uint256 _tokenId) public onlyRole(NFT_ROLE) {
        INft GenesisNft = INft(genesisContractAddress);
        INft SubscriptionNft = INft(subsContractAddress);

        if (msg.sender == genesisContractAddress) {
            require(_tokenId <= GenesisNft.totalSupply(), "INVALID ID");
            Genesis storage token = genesisHolder[_tokenId];
            token.owner = _to;
            emit NftTransfered(_to, _tokenId, true);
        } else if (msg.sender == subsContractAddress) {
            require(_tokenId <= SubscriptionNft.totalSupply(), "INVALID ID");
            Subscription storage token = subsHolder[_tokenId];
            token.owner = _to;
            emit NftTransfered(_to, _tokenId, false);
        }
    }

    function subscriptionExpiry(uint256 _tokenId) external onlyRole(EXECUTOR_ROLE) {
        INft SubscriptionNft = INft(subsContractAddress);
        require(_tokenId <= SubscriptionNft.currentIndex(), "INVALID ID");
        Subscription storage token = subsHolder[_tokenId];
        require(token.expired == false, "TOKEN ALREADY EXPIRED");
        token.expired = true;
        if (token.renewed == true) {
            _updateSubscriptionMintBalance(_tokenId);
            token.renewalExpire = 0;
        } else token.renewalExpire = block.timestamp + 7 days;

        emit ExpiredSubscription(token.owner, token.renewalExpire, token.tokenId);
    }

    function renewSubscription(uint256 _tokenId) public payable {
        Subscription storage token = subsHolder[_tokenId];

        require(msg.value == (token.price), "INSUFFICIENT AMOUNT SENT");
        require(token.renewalExpire > 0, "SUBSCRIPTION NOT EXPIRED");
        require(block.timestamp <= token.renewalExpire, "RENEWAL DATE HAS EXPIRED");
        require(token.renewed == false, "ALREADY RENEWED");

        cap3TreasuryFundShare(msg.value);
        token.renewed = true;
        token.expired = false;
        emit SubscriptionRenewed(msg.sender, token.tokenId);
    }

    function updateSubscriptionMintBalance(uint256 _tokenId) public onlyRole(EXECUTOR_ROLE) {
        _updateSubscriptionMintBalance(_tokenId);
    }

    function _updateSubscriptionMintBalance(uint256 _tokenId) internal {
        Subscription storage token = subsHolder[_tokenId];
        require(token.expired == true, "NON EXPIRED TOKEN");
        require(block.timestamp >= token.renewalExpire, "RENEWAL DATELINE NOT PASSED");
        unchecked {
            subscriptionSupply++;
        }
        emit SubscriptionBalanceUpdated(subscriptionSupply, _tokenId);
    }

    function addApprovedProposal(
        string memory _id,
        string memory _title,
        address _author
    ) public onlyRole(ADMIN_ROLE) {
        proposals[_id] = Project({id: _id, description: _title, author: _author, funded: false});
        ITreasury treasury = ITreasury(payable(treasuryAddress));

        uint256 dollarValueOfEth = getLatestPrice();
        uint256 _funds = (projectFund * 10**18) / dollarValueOfEth;

        treasury.setProjectBalance(_author, _funds);
        emit ProposalApproved(_id, _title, _author, _funds);
    }

    function fundProposal(string memory _id, uint256 _amount) public onlyRole(ADMIN_ROLE) {
        Project memory proposal = proposals[_id];
        require(proposal.funded == false, "PROJECT HAS BEEN FUNDED");
        ITreasury treasury = ITreasury(treasuryAddress);

        treasury.withdrawToProjectWallet(proposal.author, _amount);

        if (treasury.getProjectBalance(proposal.author) == 0) {
            proposal.funded = true;
        }
        emit ProposalFunded(_id, _amount);
    }

    function cap3TreasuryFundShare(uint256 _amount) internal {
        uint256 dollarValueOfEth = getLatestPrice();
        uint256 limitInEth = (treasuryLimit * 10**18) / dollarValueOfEth;

        if (address(treasuryAddress).balance > limitInEth) {
            uint256 extraBalance = address(treasuryAddress).balance - limitInEth;

            ITreasury treasury = ITreasury(payable(treasuryAddress));
            treasury.payRefund(cap3Wallet, extraBalance);

            (bool success, ) = cap3Wallet.call{value: _amount}("");
            require(success, "MINT:ETH TRANSFER FAILED");
        } else if (address(treasuryAddress).balance == limitInEth) {
            (bool success, ) = cap3Wallet.call{value: _amount}("");
            require(success, "MINT:ETH TRANSFER FAILED");
        } else if ((address(treasuryAddress).balance + _amount) > limitInEth) {
            uint256 treasuryAmount = limitInEth - address(treasuryAddress).balance;
            uint256 cap3amount = _amount - treasuryAmount;

            (bool success, ) = treasuryAddress.call{value: treasuryAmount}("");
            require(success, "MINT:ETH TRANSFER FAILED");

            (success, ) = cap3Wallet.call{value: cap3amount}("");
            require(success, "MINT:ETH TRANSFER FAILED");
        } else if ((address(treasuryAddress).balance + _amount) <= limitInEth) {
            (bool success, ) = treasuryAddress.call{value: _amount}("");
            require(success, "MINT:ETH TRANSFER FAILED");
        }
    }

    function setTreasuryLimit(uint256 _newLimit) public onlyRole(ADMIN_ROLE) {
        _setTreasuryLimit(_newLimit);
    }

    function switchGenesisMint(bool _state) public onlyRole(ADMIN_ROLE) {
        string memory boolString = _state == true ? "true" : "false";
        require(genesisStatus != _state, string(abi.encodePacked("Genesis Flag already ", boolString)));
        genesisStatus = _state;
        emit GenesisMintStateUpdated(_state);
    }

    function switchSubscriptionMint(bool _state) public onlyRole(ADMIN_ROLE) {
        string memory boolString = _state == true ? "true" : "false";
        require(subscriptionStatus != _state, string(abi.encodePacked("Subscription Flag already ", boolString)));
        subscriptionStatus = _state;
        emit SubscriptionMintStateUpdated(_state);
    }

    function switchSubscriptionStage(uint256 _stage) public onlyRole(ADMIN_ROLE) {
        require(_stage <= 4, "Invalid stage");
        require(_stage > 0, "Invalid stage");

        if (_stage == 1) {
            subsStage = SubscriptionStage.TIER_ONE;
        } else if (_stage == 2) {
            subsStage = SubscriptionStage.TIER_TWO;
        } else if (_stage == 3) {
            subsStage = SubscriptionStage.TIER_THREE;
        } else {
            subsStage = SubscriptionStage.TIER_FOUR;
        }

        emit SubscriptionStageUpdated(_stage);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyRole(ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
        emit MerkleRootSet(_merkleRoot);
    }

    function setBackendAdress(address _backendAddress) public onlyRole(ADMIN_ROLE) {
        require(_backendAddress != address(0), "ADDRESS ZERO");
        _setupRole(EXECUTOR_ROLE, _backendAddress);
        emit UpdatedBackendAddress(_backendAddress, "EXECUTOR_ROLE");
    }

    function setGenesisVotingPower(uint256 newVotingPower) public onlyRole(ADMIN_ROLE) {
        genesisVotingPower = newVotingPower;
    }

    function setAdminRole(address _adminAddress) public onlyRole(ADMIN_ROLE) {
        _setupRole(ADMIN_ROLE, _adminAddress);
    }

    function setGenesisPrice(uint256 price) public onlyRole(ADMIN_ROLE) {
        genesisPrice = price;
    }

    function setSubscriptionPrice(uint256 price, uint256 tier) public onlyRole(ADMIN_ROLE) {
        if (tier == 1) {
            subscriptionDetails.tierOnePrice = price;
        } else if (tier == 2) {
            subscriptionDetails.tierTwoPrice = price;
        } else if (tier == 3) {
            subscriptionDetails.tierThreePrice = price;
        } else if (tier == 4) {
            subscriptionDetails.tierFourPrice = price;
        }

        emit SubscriptionPriceUpdated(tier, price);
    }

    function setSubscriptionQuantities(uint256 quantity, uint256 tier) public onlyRole(ADMIN_ROLE) {
        if (tier == 1) {
            subscriptionDetails.tierOneQuantities = quantity;
        } else if (tier == 2) {
            subscriptionDetails.tierTwoQuantities = quantity;
        } else if (tier == 3) {
            subscriptionDetails.tierThreeQuantities = quantity;
        } else if (tier == 4) {
            subscriptionDetails.tierFourQuantities = quantity;
        }

        emit SubscriptionQuantitesUpdated(tier, quantity);
    }

    function setProjectFundDollars(uint256 price) public onlyRole(ADMIN_ROLE) {
        projectFund = price;
    }

    function setSubscriptionVotingPower(uint256 newVotingPower) public onlyRole(ADMIN_ROLE) {
        subscriptionVotingPower = newVotingPower;
    }

    function setCap3Wallet(address _wallet) public onlyRole(ADMIN_ROLE) {
        cap3Wallet = _wallet;
    }

    function setGenesisSupply(uint256 _newGenesisSupply) public onlyRole(ADMIN_ROLE) {
        INft GenesisNft = INft(genesisContractAddress);
        require(_newGenesisSupply >= GenesisNft.totalSupply());
        genesisSupply = _newGenesisSupply;
    }

    function setGenesisMintPublic() public onlyRole(ADMIN_ROLE) {
        merkleRoot = ZEROSTATE;
        emit MerkleRootSet(merkleRoot);
    }

    function setSubscriptionSupply(uint256 _newSubscriptionSupply) public onlyRole(ADMIN_ROLE) {
        INft SubscriptionNft = INft(subsContractAddress);
        require(_newSubscriptionSupply >= SubscriptionNft.totalSupply());
        subscriptionSupply = _newSubscriptionSupply;
    }

    /*------ View Functions -------*/

    function verifyMerkleProof(address _user, bytes32[] calldata _merkleProof) public view returns (bool) {
        return MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_user)));
    }

    function getGenesisSupply() public view returns (uint256) {
        return genesisSupply;
    }

    function getSubscriptionSupply() public view returns (uint256) {
        return subscriptionSupply;
    }

    function getProposal(string memory _tokenId) public view returns (Project memory) {
        return proposals[_tokenId];
    }

    function getGenesisHolder(uint256 _tokenId) public view returns (Genesis memory) {
        return genesisHolder[_tokenId];
    }

    function getSubscriptionHolder(uint256 _tokenId) public view returns (Subscription memory) {
        return subsHolder[_tokenId];
    }

    function getTreasuryLimit() public view returns (uint256) {
        return treasuryLimit;
    }

    function getCap3WalletAddress() public view returns (address) {
        return cap3Wallet;
    }

    function subscriptionHasExpired(uint256 _tokenId) public view returns (bool) {
        Subscription storage token = subsHolder[_tokenId];
        return token.expired;
    }

    function userVotingPower(address _holder) public view returns (uint256) {
        INft GenesisNft = INft(genesisContractAddress);
        uint256 votingPower = 0;
        votingPower += getValidSubscriptions(_holder) * subscriptionVotingPower;
        votingPower += GenesisNft.balanceOf(_holder) * genesisVotingPower;
        return votingPower;
    }

    function getValidSubscriptions(address _holder) public view returns (uint256) {
        INft SubscriptionNft = INft(subsContractAddress);
        uint256 subscriptionsValid = 0;
        uint256 subscriptionsIndex = 1;
        uint256 subscriptionsChecked = 0;

        while (subscriptionsChecked < SubscriptionNft.balanceOf(_holder)) {
            if (SubscriptionNft.ownerOf(subscriptionsIndex) == _holder) {
                if (!subscriptionHasExpired(subscriptionsIndex)) {
                    subscriptionsValid++;
                }
                subscriptionsChecked++;
            }
            subscriptionsIndex++;
        }

        return subscriptionsValid;
    }

    function getLatestPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price / 10**8);
    }

    function getReferralCode(address _referee) public view returns (uint256) {
        return referralCodes[_referee];
    }

    /*------ Internal Functions -------*/

    function _setTreasuryLimit(uint256 _newLimit) internal {
        uint256 oldLimit = treasuryLimit;
        treasuryLimit = _newLimit;
        emit TreasuryLimitSet(_newLimit, oldLimit);
    }

    function _generateReferralCode(address _sender, uint256 _numberOfTokensMinted) internal view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encode(_sender, _numberOfTokensMinted, block.timestamp)));
        uint256 code = randomHash % 10000000;
        return code;
    }
}