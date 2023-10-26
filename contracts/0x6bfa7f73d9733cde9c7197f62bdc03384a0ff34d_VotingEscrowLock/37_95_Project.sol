//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../../core/tokens/VISION.sol";
import "../../core/tokens/COMMIT.sol";
import "../../core/tokens/RIGHT.sol";
import "../../core/work/StableReserve.sol";
import "../../core/work/ContributionBoard.sol";
import "../../core/work/interfaces/IContributionBoard.sol";
import "../../core/governance/TimelockedGovernance.sol";
import "../../core/governance/WorkersUnion.sol";
import "../../core/governance/libraries/VoteCounter.sol";
import "../../core/governance/libraries/VotingEscrowLock.sol";
import "../../core/dividend/DividendPool.sol";
import "../../core/emission/VisionEmitter.sol";
import "../../core/emission/factories/ERC20BurnMiningV1Factory.sol";
import "../../core/emission/libraries/PoolType.sol";
import "../../core/marketplace/Marketplace.sol";

contract Project is ERC721, ERC20Recoverer {
    using Clones for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    struct DAO {
        address multisig;
        address baseCurrency;
        address timelock;
        address vision;
        address commit;
        address right;
        address stableReserve;
        address contributionBoard;
        address marketplace;
        address dividendPool;
        address voteCounter;
        address workersUnion;
        address visionEmitter;
        address votingEscrow;
    }

    struct CommonContracts {
        address pool2Factory;
        address weth;
        address sablier;
        address erc20StakeMiningV1Factory;
        address erc20BurnMiningV1Factory;
        address erc721StakeMiningV1Factory;
        address erc1155StakeMiningV1Factory;
        address erc1155BurnMiningV1Factory;
        address initialContributorShareFactory;
    }

    struct CloneParams {
        address multisig;
        address treasury;
        address baseCurrency;
        // Project
        string projectName;
        string projectSymbol;
        // tokens
        string visionName;
        string visionSymbol;
        string commitName;
        string commitSymbol;
        string rightName;
        string rightSymbol;
        uint256 emissionStartDelay;
        uint256 minDelay; // timelock
        uint256 voteLaunchDelay;
        uint256 initialEmission;
        uint256 minEmissionRatePerWeek;
        uint256 emissionCutRate;
        uint256 founderShare;
    }

    // Metadata for each project
    mapping(uint256 => uint256) private _growth;
    mapping(uint256 => string) private _nameOf;
    mapping(uint256 => string) private _symbolOf;
    mapping(uint256 => bool) private _immortalized;

    // Common contracts and controller(not upgradeable)
    CommonContracts private _commons;
    DAO private _controller;

    // Launched DAO's contracts
    mapping(uint256 => DAO) private _dao;
    uint256[] private _allDAOs;

    mapping(address => uint256) private _daoAddressBook;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _daoProjects; // timelock will be the pointing contract
    EnumerableMap.UintToAddressMap private _belongsTo;
    uint256 private projNum;

    event DAOLaunched(uint256 id);
    event NewProject(uint256 indexed daoId, uint256 id);
    event ProjectMoved(uint256 indexed from, uint256 indexed to);

    constructor(DAO memory controller, CommonContracts memory commons)
        ERC721("WORKHARD DAO", "WORKHARD")
    {
        _setBaseURI("ipfs://");
        _controller = controller;
        _commons = commons;
        uint256 masterDAOId = 0;
        address masterTimelock =
            Clones.predictDeterministicAddress(
                controller.timelock,
                bytes32(masterDAOId),
                address(this)
            );
        createProject(
            masterDAOId,
            "QmTFKqcLx9utcxSDLbfWicLnUDFACbrGjcQ6Yhz13qWDqS"
        );
        ERC20Recoverer.initialize(masterTimelock, new address[](0));
    }

    modifier onlyOwnerOf(uint256 id) {
        require(msg.sender == ownerOf(id), "Not the project owner");
        _;
    }

    /**
     * Creating a project for another forked DAO.
     */
    function createProject(uint256 daoId, string memory uri)
        public
        returns (uint256 id)
    {
        id = projNum;
        projNum++;
        require(_growth[id] < 1, "Already created.");
        require(
            daoId == 0 || _growth[daoId] == 4,
            "Parent project should be a DAO."
        );
        _growth[id] = 1;
        _mint(msg.sender, id);
        _setTokenURI(id, uri);
        address daoAddress = _getGovAddressOfDAO(daoId);
        _daoProjects[daoAddress].add(id);
        _belongsTo.set(id, daoAddress);
        emit NewProject(daoId, id);
        return id;
    }

    function upgradeToDAO(uint256 id, CloneParams memory params)
        public
        onlyOwnerOf(id)
    {
        require(_dao[id].vision == address(0), "Already upgraded.");
        _deploy(id);
        _initialize(id, params);
        _daoAddressBook[_getGovAddressOfDAO(id)] = id;
        // Now it does not belong to any dao. A new dao!
        _daoProjects[_belongsTo.get(id, "owner query for nonexistent token")]
            .remove(id);
        _belongsTo.remove(id);
        _nameOf[id] = params.projectName;
        _symbolOf[id] = params.projectSymbol;
        emit DAOLaunched(id);
        _allDAOs.push(id);
    }

    function launch(
        uint256 id,
        uint256 liquidityMiningRate,
        uint256 commitMiningRate,
        uint256 treasury,
        uint256 caller
    ) public onlyOwnerOf(id) {
        // 1. deploy sushi LP
        DAO storage fork = _dao[id];
        address lp =
            IUniswapV2Factory(_commons.pool2Factory).getPair(
                fork.vision,
                _commons.weth
            );
        if (lp == address(0)) {
            IUniswapV2Factory(_commons.pool2Factory).createPair(
                fork.vision,
                _commons.weth
            );
            lp = IUniswapV2Factory(_commons.pool2Factory).getPair(
                fork.vision,
                _commons.weth
            );
        }
        MiningConfig memory miningConfig;
        miningConfig.pools = new MiningPoolConfig[](2);
        miningConfig.pools[0] = MiningPoolConfig(
            liquidityMiningRate,
            PoolType.ERC20StakeMiningV1,
            lp
        );
        miningConfig.pools[1] = MiningPoolConfig(
            commitMiningRate,
            PoolType.ERC20BurnMiningV1,
            fork.commit
        );
        miningConfig.treasuryWeight = treasury;
        miningConfig.callerWeight = caller;
        _launch(id, miningConfig);
    }

    function immortalize(uint256 id) public onlyOwnerOf(id) {
        _immortalized[id] = true;
    }

    function updateURI(uint256 id, string memory uri) public onlyOwnerOf(id) {
        require(!_immortalized[id], "This project is immortalized.");
        _setTokenURI(id, uri);
    }

    function changeMultisig(uint256 id, address newMultisig) public {
        require(
            msg.sender == _dao[id].multisig,
            "Only the prev owner can change this value."
        );
        _dao[id].multisig = newMultisig;
    }

    function growth(uint256 id) public view returns (uint256) {
        return _growth[id];
    }

    function nameOf(uint256 id) public view returns (string memory) {
        return _nameOf[id];
    }

    function symbolOf(uint256 id) public view returns (string memory) {
        return _symbolOf[id];
    }

    function immortalized(uint256 id) public view returns (bool) {
        return _immortalized[id];
    }

    function daoOf(uint256 id) public view returns (uint256 daoId) {
        address daoAddress =
            _belongsTo.get(id, "owner query for nonexistent token");
        return _getDAOIdOfGov(daoAddress);
    }

    function projectsOf(uint256 daoId) public view returns (uint256 len) {
        return _daoProjects[_getGovAddressOfDAO(daoId)].length();
    }

    function projectsOfDAOByIndex(uint256 daoId, uint256 index)
        public
        view
        returns (uint256 id)
    {
        return _daoProjects[_getGovAddressOfDAO(daoId)].at(index);
    }

    function getMasterDAO() public view returns (DAO memory) {
        return _dao[0];
    }

    function getCommons() public view returns (CommonContracts memory) {
        return _commons;
    }

    function getDAO(uint256 id) public view returns (DAO memory) {
        return _dao[id];
    }

    function getAllDAOs() public view returns (uint256[] memory) {
        return _allDAOs;
    }

    function getController() public view returns (DAO memory) {
        return _controller;
    }

    function _deploy(uint256 id) internal {
        require(msg.sender == ownerOf(id));
        require(_growth[id] < 2, "Already deployed.");
        require(_growth[id] > 0, "Project does not exists.");
        _growth[id] = 2;
        DAO storage fork = _dao[id];
        bytes32 salt = bytes32(id);
        fork.timelock = _controller.timelock.cloneDeterministic(salt);
        fork.vision = _controller.vision.cloneDeterministic(salt);
        fork.commit = _controller.commit.cloneDeterministic(salt);
        fork.right = _controller.right.cloneDeterministic(salt);
        fork.stableReserve = _controller.stableReserve.cloneDeterministic(salt);
        fork.dividendPool = _controller.dividendPool.cloneDeterministic(salt);
        fork.voteCounter = _controller.voteCounter.cloneDeterministic(salt);
        fork.contributionBoard = _controller
            .contributionBoard
            .cloneDeterministic(salt);
        fork.marketplace = _controller.marketplace.cloneDeterministic(salt);
        fork.workersUnion = _controller.workersUnion.cloneDeterministic(salt);
        fork.visionEmitter = _controller.visionEmitter.cloneDeterministic(salt);
        fork.votingEscrow = _controller.votingEscrow.cloneDeterministic(salt);
    }

    function _initialize(uint256 id, CloneParams memory params) internal {
        require(msg.sender == ownerOf(id));

        require(_growth[id] < 3, "Already initialized.");
        require(_growth[id] > 1, "Contracts are not deployed.");
        _growth[id] = 3;
        DAO storage fork = _dao[id];
        fork.multisig = params.multisig;
        fork.baseCurrency = params.baseCurrency;

        DAO storage parentDAO =
            _dao[
                _getDAOIdOfGov(
                    _belongsTo.get(id, "owner query for nonexistent token")
                )
            ];

        require(
            params.founderShare >=
                ContributionBoard(parentDAO.contributionBoard).minimumShare(id),
            "founder share should be greater than the committed minimum share"
        );
        TimelockedGovernance(payable(fork.timelock)).initialize(
            params.minDelay,
            fork.multisig,
            fork.workersUnion
        );
        VISION(fork.vision).initialize(
            params.visionName,
            params.visionSymbol,
            fork.visionEmitter,
            fork.timelock
        );
        COMMIT(fork.commit).initialize(
            params.commitName,
            params.commitSymbol,
            fork.stableReserve
        );
        RIGHT(fork.right).initialize(
            params.rightName,
            params.rightSymbol,
            fork.votingEscrow
        );
        address[] memory stableReserveMinters = new address[](1);
        stableReserveMinters[0] = fork.contributionBoard;
        StableReserve(fork.stableReserve).initialize(
            fork.timelock,
            fork.commit,
            fork.baseCurrency,
            stableReserveMinters
        );
        ContributionBoard(fork.contributionBoard).initialize(
            address(this),
            fork.timelock,
            fork.dividendPool,
            fork.stableReserve,
            fork.commit,
            _commons.sablier
        );
        Marketplace(fork.marketplace).initialize(
            fork.timelock,
            fork.commit,
            fork.dividendPool
        );
        address[] memory _rewardTokens = new address[](2);
        _rewardTokens[0] = fork.commit;
        _rewardTokens[1] = fork.baseCurrency;
        DividendPool(fork.dividendPool).initialize(
            fork.timelock,
            fork.right,
            _rewardTokens
        );
        VoteCounter(fork.voteCounter).initialize(fork.right);
        WorkersUnion(payable(fork.workersUnion)).initialize(
            fork.voteCounter,
            fork.timelock,
            params.voteLaunchDelay
        );
        VisionEmitter(fork.visionEmitter).initialize(
            EmitterConfig(
                id,
                params.initialEmission,
                params.minEmissionRatePerWeek,
                params.emissionCutRate,
                params.founderShare,
                params.emissionStartDelay,
                params.treasury,
                address(this), // gov => will be transfered to timelock
                fork.vision,
                id != 0 ? parentDAO.dividendPool : address(0),
                parentDAO.contributionBoard,
                _commons.erc20BurnMiningV1Factory,
                _commons.erc20StakeMiningV1Factory,
                _commons.erc721StakeMiningV1Factory,
                _commons.erc1155StakeMiningV1Factory,
                _commons.erc1155BurnMiningV1Factory,
                _commons.initialContributorShareFactory
            )
        );
        VotingEscrowLock(fork.votingEscrow).initialize(
            string(abi.encodePacked(params.projectName, " Voting Escrow Lock")),
            string(abi.encodePacked(params.projectSymbol, "-VE-LOCK")),
            fork.vision,
            fork.right,
            fork.timelock
        );
    }

    function _launch(uint256 id, MiningConfig memory config) internal {
        require(_growth[id] < 4, "Already launched.");
        require(_growth[id] > 2, "Not initialized.");
        _growth[id] = 4;

        DAO storage fork = _dao[id];
        // 1. set emission
        VisionEmitter(fork.visionEmitter).setEmission(config);
        // 2. start emission
        VisionEmitter(fork.visionEmitter).start();
        // 3. transfer governance
        VisionEmitter(fork.visionEmitter).setGovernance(fork.timelock);
        // 4. transfer ownership to timelock
        _transfer(msg.sender, fork.timelock, id);
        // 5. No more initial contribution record
        address initialContributorPool =
            VisionEmitter(fork.visionEmitter).initialContributorPool();
        IContributionBoard(IMiningPool(initialContributorPool).baseToken())
            .finalize(id);
    }

    /**
     * @notice it returns timelock governance contract's address.
     */
    function _getGovAddressOfDAO(uint256 id) private view returns (address) {
        return
            Clones.predictDeterministicAddress(
                _controller.timelock,
                bytes32(id),
                address(this)
            );
    }

    /**
     * @notice it can return only launched DAO's token id.
     */
    function _getDAOIdOfGov(address daoAddress)
        private
        view
        returns (uint256 daoId)
    {
        return _daoAddressBook[daoAddress];
    }
}