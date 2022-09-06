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
    bytes32 public merkleRoot;
    bytes32 public constant ZEROSTATE = 0x0000000000000000000000000000000000000000000000000000000000000000;

    address public immutable treasuryAddress;
    address private cap3Wallet;
    address public genesisContractAddress;
    address public subsContractAddress;

    uint256 public genesisPrice = 2 ether;
    uint256 public subscriptionPrice = 1 ether;
    uint256 private projectId = 1;
    uint256 public genesisSupply = 2000;
    uint256 public subscriptionSupply = 7000;
    uint256 private genesisVotingPower = 2;
    uint256 private subscriptionVotingPower = 1;
    uint256 private treasuryLimit = 5e6;

    bool public genesisStatus = true;
    bool public subscriptionStatus;
    bool public refundFlag;

    struct Genesis {
        uint256 tokenId;
        address owner;
    }

    struct Subscription {
        uint256 tokenId;
        uint256 renewalExpire;
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

    enum TOKEN {
        GENESIS,
        SUBSCRIPTION
    }

    /*------ Events -------*/

    event SubscriptionMintStateUpdated(bool state);
    event GenesisMintStateUpdated(bool state);
    event GenesisMinted(address to, uint256 id);
    event SubscriptionMinted(address to, uint256 id);
    event SubscriptionRenewed(address holder, uint256 tokenId);
    event ExpiredSubscription(address holder, uint256 renewalExpire, uint256 tokenId);
    event MerkleRootSet(bytes32 _merkleRoot);
    event Refunded(address owner, uint256[] tokenIds);
    event TreasuryLimitSet(uint256 newLimit, uint256 oldLimit);
    event SubscriptionBalanceUpdated(uint256 TokenSupply, uint256 tokenId);
    event ProposalApproved(string id, string _title, address author, uint256 amount);
    event ProposalFunded(string id, uint256 amount);
    event UpdatedBackendAddress(address backendAddress, string Role);
    event RefundStateUpdated(bool _state);
    event NftTransfered(address to, uint256 tokenId, bool isGenesis);

    mapping(string => Project) private proposals;
    mapping(uint256 => Genesis) public genesisHolder;
    mapping(uint256 => Subscription) public subsHolder;

    AggregatorV3Interface internal priceFeed;

    constructor(
        address _genesis,
        address _subscription,
        address _treasury,
        address _cap3Wallet,
        address _priceFeedAggregator
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
        _setupRole(ADMIN_ROLE, address(this));
        _setupRole(NFT_ROLE, _genesis);
        _setupRole(NFT_ROLE, _subscription);
    }

    /*------- State Changing Functions ------*/

    function mintGenesis(address _to, bytes32[] calldata _merkleProof, uint256 amount) public payable {

        INft GenesisNft = INft(genesisContractAddress);
        require(msg.value >= (genesisPrice * amount), "INSUFFICIENT MINTING VALUE");
        require(genesisStatus, "GENESIS MINT CURRENTLY INACTIVE");
        require(GenesisNft.totalSupply() + amount <= genesisSupply, "INSUFICIENT GENESIS STOCK");
        if (merkleRoot != ZEROSTATE){
        require(MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(_to))), "INVALID MERKLE PROOF");
        } 

        for (uint256 _id = GenesisNft.currentIndex(); _id < (amount + GenesisNft.currentIndex()); _id++) {
            genesisHolder[_id] = Genesis({tokenId: _id, owner: _to});
            emit GenesisMinted(_to, _id);
        }

        GenesisNft.mint(_to, amount);
        
        (bool success, ) = treasuryAddress.call{value: msg.value}("");
        require(success, "MINT:ETH TRANSFER FAILED");

        ITreasury treasury = ITreasury(payable(treasuryAddress));
        if (GenesisNft.totalSupply() == genesisSupply) {
            treasury.moveFundsOutOfTreasury();
            genesisStatus = false;
        }

    }


    function mintSubscription(address _to, uint256 amount) public payable {
        INft SubscriptionNft = INft(subsContractAddress);
        require(msg.value >= (subscriptionPrice * amount), "INSUFFICIENT MINTING VALUE");
        require(subscriptionStatus, "SUBS MINT CURRENTLY INACTIVE");
        require(SubscriptionNft.totalSupply() + amount <= subscriptionSupply, "INSUFICIENT SUBSCRIPTION STOCK");

        for (uint256 _id = SubscriptionNft.currentIndex(); _id < (amount + SubscriptionNft.currentIndex()); _id++) {
            subsHolder[_id] = Subscription({
                tokenId: _id,
                owner: _to,
                expired: false,
                renewed: false,
                renewalExpire: 0
            });
            emit SubscriptionMinted(_to, _id);

        }

        SubscriptionNft.mint(_to, amount);
        cap3TreasuryFundShare(msg.value);
    }

    function refund(bool _state) public onlyRole(ADMIN_ROLE) {
        require(genesisStatus == false, "GENESIS MINT STILL OPEN");
        string memory boolString = _state == true ? "true" : "false";
        require(refundFlag != _state, string(abi.encodePacked("Refund Flag already ", boolString)));
        refundFlag = _state;
        emit RefundStateUpdated(_state);
    }

    function claimRefund(uint256[] calldata tokenIds) public {
        INft GenesisNft = INft(genesisContractAddress);
        ITreasury treasury = ITreasury(treasuryAddress);
        require(genesisStatus == false, "GENESIS MINT STILL OPEN");
        require(refundFlag == true, "REFUND NOT OPEN");
        uint256 arrayLength = tokenIds.length;
        uint256[] memory refundedTokens = new uint256[](arrayLength);

        for (uint256 i = 0; i < tokenIds.length; i++){
            uint256 tokenId = tokenIds[i];
            if (GenesisNft.ownerOf(tokenId) == msg.sender){
                uint256 toRefund = genesisPrice;
                GenesisNft.burn(tokenId);
                delete (genesisHolder[tokenId]);
                treasury.payRefund(msg.sender, toRefund);
                refundedTokens[i] = tokenId;
            }
            
        }
        
        emit Refunded(msg.sender, refundedTokens);
    }

    function transferNft(address _to, uint256 _tokenId) public onlyRole(NFT_ROLE) {

        if (msg.sender == genesisContractAddress) {
            Genesis storage token = genesisHolder[_tokenId];
            token.owner = _to;
            emit NftTransfered(_to, _tokenId, true);
        } else if (msg.sender == subsContractAddress) {
            Subscription storage token = subsHolder[_tokenId];
            token.owner = _to;
            emit NftTransfered(_to, _tokenId, false);
        }
    }

    function subscriptionExpiry(uint256 _tokenId) external onlyRole(EXECUTOR_ROLE) {
        Subscription storage token = subsHolder[_tokenId];
        require(token.expired == false, "CANT CALL ON ALREADY EXPIRED TOKEN");
        token.expired = true;
        if (token.renewed == true) {
            _updateSubscriptionMintBalance(_tokenId);
            token.renewalExpire = 0;
        } else token.renewalExpire = block.timestamp + 7 days;

        emit ExpiredSubscription(token.owner, token.renewalExpire, token.tokenId);
    }

    function renewSubscription(uint256 _tokenId) public payable {
        require(msg.value >= (subscriptionPrice), "INSUFFICIENT MINTING VALUE");

        Subscription storage token = subsHolder[_tokenId];
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
        address _author,
        uint256 _funds
    ) public onlyRole(ADMIN_ROLE) {
        proposals[_id] = Project({id: _id, description: _title, author: _author, funded: false});
        ITreasury treasury = ITreasury(payable(treasuryAddress));
        treasury.setProjectBalance(_author, _funds);
        emit ProposalApproved(_id, _title, _author, _funds);
    }

    function fundProposal(string memory _id, uint256 _amount) public onlyRole(ADMIN_ROLE) {
        Project memory proposal = proposals[_id];
        require(proposal.funded == false, "PROJECT HAS BEEN FUNDED");
        proposal.funded = true;
        ITreasury treasury = ITreasury(treasuryAddress);
        treasury.withdrawToProjectWallet(proposal.author, _amount);

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
        genesisPrice = price * 10**18 ;
    
    }

    function setSubscriptionPrice(uint256 price) public onlyRole(ADMIN_ROLE) {
        subscriptionPrice = price * 10**18;
    }

    function setSubscriptionVotingPower(uint256 newVotingPower) public onlyRole(ADMIN_ROLE) {
        subscriptionVotingPower = newVotingPower;
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
    function getGenesisSupply() public view returns (uint256) {
        return genesisSupply;
    }

    function getSubscriptionSupply() public view returns (uint256) {
        return subscriptionSupply;
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

    /*------ Internal Functions -------*/

    function _setTreasuryLimit(uint256 _newLimit) internal {
        uint256 oldLimit = treasuryLimit;
        treasuryLimit = _newLimit;
        emit TreasuryLimitSet(_newLimit, oldLimit);
    }
}