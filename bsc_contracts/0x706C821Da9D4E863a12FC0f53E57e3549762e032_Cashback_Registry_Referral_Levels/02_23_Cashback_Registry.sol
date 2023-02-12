// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IBlacklist.sol";
import "./CZUsd.sol";

//import "hardhat/console.sol";

contract Cashback_Registry is AccessControlEnumerable {
    bytes32 public constant MANAGER_REGISTRY = keccak256("MANAGER_REGISTRY");

    enum LEVEL {
        TREASURY,
        DIAMOND,
        GOLD,
        SILVER,
        BRONZE,
        MEMBER
    }

    uint256[6] public levelFees = [
        type(uint256).max, //Treasury, cannot upgrade to this level
        2500 ether,
        750 ether,
        125 ether,
        5 ether,
        0 ether
    ];

    uint16[6] public totalWeightAtLevel = [100, 90, 70, 50, 30, 10];

    struct Node {
        LEVEL depth;
        uint64 accountId;
        uint64 parentNodeId;
    }

    mapping(uint64 => Node) nodes;

    struct Account {
        LEVEL level;
        address signer;
        uint64[6] levelNodeIds;
        uint64 referrerAccountId;
        string code;
        uint64[] referralAccountIds;
    }

    mapping(uint64 => Account) accounts;
    mapping(address => uint64) public signerToAccountId;
    mapping(string => uint64) public codeToAccountId;

    mapping(address => uint256) public pendingCzusdToDistribute;
    mapping(address => uint256) public pendingRewards;

    uint64 public accountIdNonce = 1;
    uint64 public nodeIdNonce = 1;

    CZUsd public czusd = CZUsd(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);

    IBlacklist public blacklistChecker =
        IBlacklist(0x8D82235e48Eeb0c5Deb41988864d14928B485bac);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_REGISTRY, msg.sender);
        Account storage treasuryAccount = accounts[accountIdNonce];
        treasuryAccount.level = LEVEL.TREASURY;
        treasuryAccount.signer = msg.sender;
        treasuryAccount.code = "TREASURY";
        signerToAccountId[msg.sender] = accountIdNonce;
        codeToAccountId[treasuryAccount.code] = accountIdNonce;

        nodes[nodeIdNonce] = Node(LEVEL.TREASURY, accountIdNonce, 0);
        treasuryAccount.levelNodeIds[uint256(LEVEL.TREASURY)] = nodeIdNonce;

        nodes[nodeIdNonce + 1] = Node(
            LEVEL.DIAMOND,
            accountIdNonce,
            nodeIdNonce
        );
        treasuryAccount.levelNodeIds[uint256(LEVEL.DIAMOND)] = nodeIdNonce + 1;

        nodes[nodeIdNonce + 2] = Node(
            LEVEL.GOLD,
            accountIdNonce,
            nodeIdNonce + 1
        );
        treasuryAccount.levelNodeIds[uint256(LEVEL.GOLD)] = nodeIdNonce + 2;

        nodes[nodeIdNonce + 3] = Node(
            LEVEL.SILVER,
            accountIdNonce,
            nodeIdNonce + 2
        );
        treasuryAccount.levelNodeIds[uint256(LEVEL.SILVER)] = nodeIdNonce + 3;

        nodes[nodeIdNonce + 4] = Node(
            LEVEL.BRONZE,
            accountIdNonce,
            nodeIdNonce + 3
        );
        treasuryAccount.levelNodeIds[uint256(LEVEL.BRONZE)] = nodeIdNonce + 4;

        nodes[nodeIdNonce + 5] = Node(
            LEVEL.MEMBER,
            accountIdNonce,
            nodeIdNonce + 4
        );
        treasuryAccount.levelNodeIds[uint256(LEVEL.MEMBER)] = nodeIdNonce + 5;

        accountIdNonce++;
        nodeIdNonce += 6;
    }

    function isValidNewCode(string calldata _code) public view returns (bool) {
        return
            !isCodeRegistered(_code) &&
            keccak256(abi.encodePacked(_code)) !=
            keccak256(abi.encodePacked(""));
    }

    function isCodeRegistered(string calldata _code)
        public
        view
        returns (bool)
    {
        return codeToAccountId[_code] != 0;
    }

    function claimRewards(address _for) public {
        _transferCzusdWithBlacklistCheck(_for, pendingRewards[_for]);
        pendingRewards[_for] = 0;
    }

    function claimCashback(address _for) public {
        uint64 accountId = signerToAccountId[_for];
        Account storage account = accounts[accountId];
        require(accountId != 0, "CBR: Not Member");
        uint256 feesToDistribute = pendingCzusdToDistribute[_for];

        uint256 cashbackWad = (totalWeightAtLevel[uint256(account.level)] *
            feesToDistribute) / totalWeightAtLevel[uint8(LEVEL.TREASURY)];
        _transferCzusdWithBlacklistCheck(_for, cashbackWad);
        _addRewardsToReferrerChain(
            nodes[account.levelNodeIds[uint8(account.level)]].parentNodeId,
            feesToDistribute - cashbackWad
        );
        pendingCzusdToDistribute[_for] = 0;
    }

    function addCzusdToDistribute(address _to, uint256 _wad) public {
        czusd.transferFrom(msg.sender, address(this), _wad);
        pendingCzusdToDistribute[_to] += _wad;
    }

    function becomeMember(string calldata _referralCode) external {
        require(signerToAccountId[msg.sender] == 0, "CBR: Already Registered");
        require(isCodeRegistered(_referralCode), "CBR: Code Not Registered");
        Account storage newAccount = accounts[accountIdNonce];
        newAccount.level = LEVEL.MEMBER;
        newAccount.signer = msg.sender;
        newAccount.referrerAccountId = codeToAccountId[_referralCode];
        newAccount.levelNodeIds[uint256(LEVEL.MEMBER)] = nodeIdNonce;
        signerToAccountId[msg.sender] = accountIdNonce;

        Account storage referrerAccount = accounts[
            newAccount.referrerAccountId
        ];
        referrerAccount.referralAccountIds.push(accountIdNonce);

        nodes[nodeIdNonce] = Node(
            LEVEL.MEMBER,
            accountIdNonce,
            referrerAccount.levelNodeIds[uint256(LEVEL.BRONZE)]
        );

        nodeIdNonce++;
        accountIdNonce++;
    }

    function upgradeTierAndSetCode(string calldata _code) external {
        _upgradeTier();
        setCodeTo(_code);
    }

    function upgradeTier() external {
        _upgradeTier();
    }

    function _upgradeTier() internal {
        uint64 accountId = signerToAccountId[msg.sender];
        Account storage account = accounts[accountId];
        require(accountId != 0, "CBR: Not Registered");
        require(account.level > LEVEL.DIAMOND, "CBR: Max Tier");
        uint8 prevLevel = uint8(account.level);
        uint8 newLevel = prevLevel - 1;

        uint64 prevParentNodeId = nodes[account.levelNodeIds[prevLevel]]
            .parentNodeId;

        addCzusdToReferrerChain(prevParentNodeId, levelFees[newLevel]);

        //Create new node for upgraded level
        account.levelNodeIds[newLevel] = nodeIdNonce;
        nodes[nodeIdNonce] = Node(
            LEVEL(newLevel),
            accountId,
            nodes[prevParentNodeId].parentNodeId
        );
        account.level = LEVEL(newLevel);
        //Set old level's node parent to new node
        nodes[account.levelNodeIds[prevLevel]].parentNodeId = nodeIdNonce;

        nodeIdNonce++;
    }

    function addCzusdToReferrerChain(uint64 _referrerNodeId, uint256 _wad)
        public
    {
        czusd.transferFrom(msg.sender, address(this), _wad);
        _addRewardsToReferrerChain(_referrerNodeId, _wad);
    }

    function transferAccountTo(address _newSigner) external {
        uint64 accountId = signerToAccountId[msg.sender];
        require(accountId != 0, "CBR: Account not registered");
        Account storage account = accounts[accountId];
        account.signer = _newSigner;
    }

    function setCodeTo(string calldata _code) public {
        require(isValidNewCode(_code), "CBR: Code Invalid");
        uint64 accountId = signerToAccountId[msg.sender];
        Account storage account = accounts[accountId];
        require(accountId != 0, "CBR: Account not registered");
        require(account.level != LEVEL.MEMBER, "CBR: Members Cannot Set Code");
        delete codeToAccountId[account.code];
        account.code = _code;
        codeToAccountId[_code] = accountId;
    }

    function _addRewardsToReferrerChain(uint64 _referrerNodeId, uint256 _wad)
        internal
    {
        uint64 nodeIdProcessing = _referrerNodeId;
        uint8 minLevel = uint8(nodes[_referrerNodeId].depth);
        uint16 combinedReferrerWeight = totalWeightAtLevel[0] -
            totalWeightAtLevel[minLevel + 1];
        uint256 feesPerWeight = _wad / combinedReferrerWeight;

        for (uint8 prevLevel = minLevel + 1; prevLevel > 0; prevLevel--) {
            uint8 level = prevLevel - 1;
            Node storage node = nodes[nodeIdProcessing];
            pendingRewards[accounts[node.accountId].signer] +=
                (totalWeightAtLevel[level] - totalWeightAtLevel[prevLevel]) *
                feesPerWeight;
            nodeIdProcessing = node.parentNodeId;
        }
    }

    function _transferCzusdWithBlacklistCheck(address _for, uint256 _wad)
        internal
    {
        if (!blacklistChecker.isBlacklisted(_for)) {
            czusd.transfer(_for, _wad);
        } else {
            czusd.transfer(accounts[1].signer, _wad);
        }
    }

    function getNodeInfo(uint64 _nodeId)
        external
        view
        returns (
            LEVEL depth_,
            uint64 accountId_,
            uint64 parentNodeId_
        )
    {
        Node storage node = nodes[_nodeId];
        depth_ = node.depth;
        accountId_ = node.accountId;
        parentNodeId_ = node.parentNodeId;
    }

    function getSignerInfo(address _signer)
        external
        view
        returns (
            LEVEL level_,
            uint64 accoundId_,
            uint64[6] memory levelNodeIds_,
            uint64 referrerAccountId_,
            string memory code_,
            uint256 totalReferrals_,
            uint256 pendingCzusdToDistribute_,
            uint256 pendingRewards_
        )
    {
        accoundId_ = signerToAccountId[_signer];
        Account storage account = accounts[accoundId_];
        level_ = account.level;
        levelNodeIds_ = account.levelNodeIds;
        referrerAccountId_ = account.referrerAccountId;
        code_ = account.code;
        totalReferrals_ = account.referralAccountIds.length;
        pendingCzusdToDistribute_ = pendingCzusdToDistribute[_signer];
        pendingRewards_ = pendingRewards[_signer];
    }

    function getAccountInfo(uint64 _accountId)
        external
        view
        returns (
            LEVEL level_,
            address signer_,
            uint64[6] memory levelNodeIds_,
            uint64 referrerAccountId_,
            string memory code_,
            uint256 totalReferrals_,
            uint256 pendingCzusdToDistribute_,
            uint256 pendingRewards_
        )
    {
        Account storage account = accounts[_accountId];
        level_ = account.level;
        signer_ = account.signer;
        levelNodeIds_ = account.levelNodeIds;
        referrerAccountId_ = account.referrerAccountId;
        code_ = account.code;
        totalReferrals_ = account.referralAccountIds.length;
        pendingCzusdToDistribute_ = pendingCzusdToDistribute[signer_];
        pendingRewards_ = pendingRewards[signer_];
    }

    function getAccountReferrals(
        uint64 _accountId,
        uint256 _start,
        uint256 _count
    ) external view returns (uint64[] memory referralAccountIds_) {
        referralAccountIds_ = new uint64[](_count);
        Account storage account = accounts[_accountId];
        for (uint256 i = _start; i < _count; i++) {
            referralAccountIds_[i] = account.referralAccountIds[i];
        }
    }

    function setLevelFee(LEVEL _level, uint256 _to)
        external
        onlyRole(MANAGER_REGISTRY)
    {
        levelFees[uint8(_level)] = _to;
    }

    function setTotalWeightAtLevel(LEVEL _level, uint16 _to)
        external
        onlyRole(MANAGER_REGISTRY)
    {
        totalWeightAtLevel[uint8(_level)] = _to;
    }

    function setCzusd(CZUsd _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        czusd = _to;
    }

    function setBlacklist(IBlacklist _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        blacklistChecker = _to;
    }

    function recaptureAccounts(uint64[] calldata _referralAccountIdIndexes)
        external
    {
        uint64 accountId = signerToAccountId[msg.sender];
        Account storage account = accounts[accountId];
        require(accountId != 0, "CBR: Not Member");
        require(
            uint8(LEVEL.BRONZE) > uint8(account.level),
            "CBR: Must Be Higher Than Bronze"
        );
        for (uint256 i; i < _referralAccountIdIndexes.length; i++) {
            uint64 referredAccountId = account.referralAccountIds[
                _referralAccountIdIndexes[i]
            ];
            Account storage referredAccount = accounts[referredAccountId];
            require(referredAccountId != 0, "CBR: Referred Not Member");
            require(
                uint8(referredAccount.level) > uint8(account.level),
                "CBR: Referred Must Be Below Referrer"
            );
            uint64 newParentNodeId = account.levelNodeIds[
                uint256(referredAccount.level) - 1
            ];
            Node storage referredNode = nodes[
                referredAccount.levelNodeIds[uint256(referredAccount.level)]
            ];
            require(
                referredNode.parentNodeId != newParentNodeId,
                "CBR: Already parented"
            );
            referredNode.parentNodeId = newParentNodeId;
        }
    }
}