//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "../libraries/openzeppelin/upgradeable/access/OwnableUpgradeable.sol";

contract Settings is OwnableUpgradeable {
    struct GovernorSetting {
        address governor;
        uint256 delayBlock;
        uint256 periodBlock;
    }
    /// @notice the shortest an auction can ever be
    address public weth;
    /// @notice the % bid increase required for a new bid
    uint256 public minBidIncrease;
    ///
    uint256 public auctionLength;
    ///
    uint256 public auctionExtendLength;
    ///
    uint256 public reduceStep;
    /// @notice the % of tokens required to be voting for an auction to start
    uint256 public minVotePercentage;
    /// @notice the max % increase over the initial
    uint256 public maxExitFactor;
    /// @notice the max % decrease from the initial
    uint256 public minExitFactor;
    /// @notice the address who receives auction fees
    address payable public feeReceiver;
    /// @notice fee
    uint256 public feePercentage;
    /// @notice exitFeeForCuratorPercentage
    uint256 public exitFeeForCuratorPercentage;
    /// @notice exitFeeForPlatformPercentage
    uint256 public exitFeeForPlatformPercentage;
    /// @notice exitFeeForPlatformPercentage
    uint256 public presaleFeePercentage;
    //
    uint256 public votingQuorumPercent;
    //
    uint256 public votingMinTokenPercent;
    //
    uint256 public votingDelayBlock;
    //
    uint256 public votingPeriodBlock;
    //
    uint256 public term1Duration;
    //
    uint256 public term2Duration;
    //
    uint256 public epochDuration;
    ///
    address public flashLoanAdmin;
    /// @notice logic for factory
    address public vaultImpl;
    address public vaultTpl;
    /// @notice logic for treasury
    address public treasuryImpl;
    address public treasuryTpl;
    /// @notice logic for staking
    address public stakingImpl;
    address public stakingTpl;
    /// @notice logic for gover
    address public governmentImpl;
    address public governmentTpl;
    /// @notice logic for exchange
    address public exchangeImpl;
    address public exchangeTpl;
    /// @notice logic for bnftImpl
    address public bnftImpl;
    address public bnftTpl;
    //
    string public bnftURI;
    /// @notice the address for reseve oracle price
    address public nftOracle;
    // map voting config
    mapping(address => GovernorSetting) public governorSettings;

    /// @notice for gap, minus 1 if use
    uint256[25] public __number;
    address[25] public __gapAddress;

    constructor() {}

    function initialize(address _weth) external initializer {
        __Ownable_init();
        // store data
        require(_weth != address(0), "no zero address");
        weth = _weth;
        auctionLength = 7 days;
        auctionExtendLength = 30 minutes;
        feeReceiver = payable(msg.sender);
        feePercentage = 8000; //80%
        minExitFactor = 2000; // 20%
        maxExitFactor = 50000; // 500%
        minBidIncrease = 100; // 1%
        minVotePercentage = 2500; // 25%
        reduceStep = 500; //5%
        exitFeeForCuratorPercentage = 125; //1.25%
        exitFeeForPlatformPercentage = 125; //1.25%
        presaleFeePercentage = 90;
        votingQuorumPercent = 5;
        votingMinTokenPercent = 100;
        votingDelayBlock = 14400; // 2 days
        votingPeriodBlock = 36000; // 5 days
        term1Duration = 26 * 7 * 1 days;
        term2Duration = 52 * 7 * 1 days;
        epochDuration = 1 days;
        flashLoanAdmin = msg.sender;
        bnftURI = "https://www.nftdaos.wtf/bnft/";
    }

    function getGovernorSetting(address[] memory nftAddrslist)
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256
        )
    {
        address governor = address(0);
        address nftAddrs = address(0);
        uint256 delayBlock = votingDelayBlock;
        uint256 periodBlock = votingPeriodBlock;
        for (uint i = 0; i < nftAddrslist.length; i++) {
            GovernorSetting memory conf = governorSettings[nftAddrslist[i]];
            if (conf.delayBlock > 0) {
                delayBlock = conf.delayBlock;
            }
            if (conf.periodBlock > 0) {
                periodBlock = conf.periodBlock;
            }
            if (conf.governor != address(0)) {
                governor = conf.governor;
                nftAddrs = nftAddrslist[i];
                return (nftAddrs, governor, delayBlock, periodBlock);
            }
        }
        return (nftAddrs, governor, delayBlock, periodBlock);
    }

    function checkGovernorSetting(address[] memory nftAddrslist)
        external
        view
        returns (bool)
    {
        if (nftAddrslist.length == 1) {
            return true;
        }
        for (uint i = 0; i < nftAddrslist.length - 1; i++) {
            // check if has 2 config
            GovernorSetting memory conf = governorSettings[nftAddrslist[i]];
            GovernorSetting memory confNext = governorSettings[
                nftAddrslist[i + 1]
            ];
            if (conf.governor != confNext.governor) {
                return false;
            }
        }
        return true;
    }

    event GovernorSettingSet(
        address nftAddr,
        address governor,
        uint256 delayBlock,
        uint256 periodBlock
    );

    function setGovernorSetting(
        address nftAddr,
        address governor,
        uint256 delayBlock,
        uint256 periodBlock
    ) external onlyOwner {
        GovernorSetting storage conf = governorSettings[nftAddr];
        conf.governor = governor;
        conf.delayBlock = delayBlock;
        conf.periodBlock = periodBlock;
        emit GovernorSettingSet(nftAddr, governor, delayBlock, periodBlock);
    }

    event PresaleFeePercentageSet(uint256 _presaleFeePercentage);

    function setPresaleFeePercentage(uint256 _presaleFeePercentage)
        external
        onlyOwner
    {
        require(_presaleFeePercentage <= 10000, "too high");
        presaleFeePercentage = _presaleFeePercentage;
        emit PresaleFeePercentageSet(_presaleFeePercentage);
    }

    event FeePercentageSet(uint256 _feePercentage);

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "too high");
        feePercentage = _feePercentage;
        emit FeePercentageSet(_feePercentage);
    }

    event ExitFeeForCuratorPercentageSet(uint256 _exitFeeForCuratorPercentage);

    function setExitFeeForCuratorPercentage(
        uint256 _exitFeeForCuratorPercentage
    ) external onlyOwner {
        require(_exitFeeForCuratorPercentage <= 5000, "too high");
        exitFeeForCuratorPercentage = _exitFeeForCuratorPercentage;
        emit ExitFeeForCuratorPercentageSet(_exitFeeForCuratorPercentage);
    }

    event ExitFeeForPlatformPercentageSet(
        uint256 _exitFeeForPlatformPercentage
    );

    function setExitFeeForPlatformPercentage(
        uint256 _exitFeeForPlatformPercentage
    ) external onlyOwner {
        require(_exitFeeForPlatformPercentage <= 5000, "too high");
        exitFeeForPlatformPercentage = _exitFeeForPlatformPercentage;
        emit ExitFeeForPlatformPercentageSet(_exitFeeForPlatformPercentage);
    }

    event ReduceStepSet(uint256 _reduceStep);

    function setReduceStep(uint256 _reduceStep) external onlyOwner {
        require(reduceStep <= 10000, "too high");
        reduceStep = _reduceStep;
        emit ReduceStepSet(_reduceStep);
    }

    event AuctionLengthSet(uint256 _auctionLength);

    function setAuctionLength(uint256 _auctionLength) external onlyOwner {
        auctionLength = _auctionLength;
        emit AuctionLengthSet(_auctionLength);
    }

    event AuctionExtendLengthSet(uint256 _auctionExtendLength);

    function setAuctionExtendLength(uint256 _auctionExtendLength)
        external
        onlyOwner
    {
        auctionExtendLength = _auctionExtendLength;
        emit AuctionExtendLengthSet(_auctionExtendLength);
    }

    event MinBidIncreaseSet(uint256 _min);

    function setMinBidIncrease(uint256 _min) external onlyOwner {
        require(_min <= 10000, "min bid increase too high");
        require(_min >= 10, "min bid increase too low");
        minBidIncrease = _min;
        emit MinBidIncreaseSet(_min);
    }

    event MinVotePercentageSet(uint256 _min);

    function setMinVotePercentage(uint256 _min) external onlyOwner {
        require(_min <= 10000, "min vote percentage too high");
        minVotePercentage = _min;
        emit MinVotePercentageSet(_min);
    }

    event MaxExitFactorSet(uint256 _factor);

    function setMaxExitFactor(uint256 _factor) external onlyOwner {
        require(_factor > minExitFactor, "max exit factor too low");
        maxExitFactor = _factor;
        emit MaxExitFactorSet(_factor);
    }

    event MinExitFactorSet(uint256 _factor);

    function setMinExitFactor(uint256 _factor) external onlyOwner {
        require(_factor < maxExitFactor, "min exit factor too high");
        minExitFactor = _factor;
        emit MinExitFactorSet(_factor);
    }

    event FeeReceiverSet(address payable _receiver);

    function setFeeReceiver(address payable _receiver) external onlyOwner {
        require(_receiver != address(0), "fees cannot go to 0 address");
        feeReceiver = _receiver;
        emit FeeReceiverSet(_receiver);
    }

    event VotingQuorumPercentSet(uint256 _votingQuorumPercent);

    function setVotingQuorumPercent(uint256 _votingQuorumPercent)
        external
        onlyOwner
    {
        votingQuorumPercent = _votingQuorumPercent;
        emit VotingQuorumPercentSet(_votingQuorumPercent);
    }

    event VotingMinTokenPercentSet(uint256 _votingMinTokenPercent);

    function setVotingMinTokenPercent(uint256 _votingMinTokenPercent)
        external
        onlyOwner
    {
        votingMinTokenPercent = _votingMinTokenPercent;
        emit VotingMinTokenPercentSet(_votingMinTokenPercent);
    }

    event VotingDelayBlockSet(uint256 _votingDelayBlock);

    function setVotingDelayBlock(uint256 _votingDelayBlock) external onlyOwner {
        votingDelayBlock = _votingDelayBlock;
        emit VotingDelayBlockSet(_votingDelayBlock);
    }

    event VotingPeriodBlockSet(uint256 _votingPeriodBlock);

    function setVotingPeriodBlock(uint256 _votingPeriodBlock)
        external
        onlyOwner
    {
        votingPeriodBlock = _votingPeriodBlock;
        emit VotingPeriodBlockSet(_votingPeriodBlock);
    }

    event Term1DurationSet(uint256 _term1Duration);

    function setTerm1Duration(uint256 _term1Duration) external onlyOwner {
        term1Duration = _term1Duration;
        emit Term1DurationSet(_term1Duration);
    }

    event Term2DurationSet(uint256 _term2Duration);

    function setTerm2Duration(uint256 _term2Duration) external onlyOwner {
        term2Duration = _term2Duration;
        emit Term1DurationSet(_term2Duration);
    }

    event EpochDurationSet(uint256 _epochDuration);

    function setEpochDuration(uint256 _epochDuration) external onlyOwner {
        epochDuration = _epochDuration;
        emit EpochDurationSet(_epochDuration);
    }

    event FlashLoanAdminSet(address _flashLoanAdmin);

    function setFlashLoanAdmin(address _flashLoanAdmin) external onlyOwner {
        require(_flashLoanAdmin != address(0), "cannot go to 0 address");
        flashLoanAdmin = _flashLoanAdmin;
        emit FlashLoanAdminSet(_flashLoanAdmin);
    }

    event VaultImplSet(address _vaultImpl);

    function setVaultImpl(address _vaultImpl) external onlyOwner {
        require(_vaultImpl != address(0), "cannot go to 0 address");
        vaultImpl = _vaultImpl;
        emit VaultImplSet(_vaultImpl);
    }

    function setStakingImpl(address _stakingImpl) external onlyOwner {
        require(_stakingImpl != address(0), "cannot go to 0 address");
        stakingImpl = _stakingImpl;
    }

    event TreasuryImplSet(address _treasuryImpl);

    function setTreasuryImpl(address _treasuryImpl) external onlyOwner {
        require(_treasuryImpl != address(0), "cannot go to 0 address");
        treasuryImpl = _treasuryImpl;
        emit TreasuryImplSet(_treasuryImpl);
    }

    event GovernmentImplSet(address _governmentImpl);

    function setGovernmentImpl(address _governmentImpl) external onlyOwner {
        require(_governmentImpl != address(0), "cannot go to 0 address");
        governmentImpl = _governmentImpl;
        emit GovernmentImplSet(_governmentImpl);
    }

    event ExchangeImplSet(address _exchangeImpl);

    function setExchangeImpl(address _exchangeImpl) external onlyOwner {
        require(_exchangeImpl != address(0), "cannot go to 0 address");
        exchangeImpl = _exchangeImpl;
        emit ExchangeImplSet(_exchangeImpl);
    }

    event BnftImplSet(address _bnftImpl);

    function setBnftImpl(address _bnftImpl) external onlyOwner {
        require(_bnftImpl != address(0), "cannot go to 0 address");
        bnftImpl = _bnftImpl;
        emit BnftImplSet(_bnftImpl);
    }

    event VaultTplSet(address _vaultTpl);

    function setVaultTpl(address _vaultTpl) external onlyOwner {
        require(_vaultTpl != address(0), "cannot go to 0 address");
        vaultTpl = _vaultTpl;
        emit VaultTplSet(_vaultTpl);
    }

    function setStakingTpl(address _stakingTpl) external onlyOwner {
        require(_stakingTpl != address(0), "cannot go to 0 address");
        stakingTpl = _stakingTpl;
    }

    event TreasuryTplSet(address _treasuryTpl);

    function setTreasuryTpl(address _treasuryTpl) external onlyOwner {
        require(_treasuryTpl != address(0), "cannot go to 0 address");
        treasuryTpl = _treasuryTpl;
        emit TreasuryTplSet(_treasuryTpl);
    }

    event GovernmentTplSet(address _governmentTpl);

    function setGovernmentTpl(address _governmentTpl) external onlyOwner {
        require(_governmentTpl != address(0), "cannot go to 0 address");
        governmentTpl = _governmentTpl;
        emit GovernmentTplSet(_governmentTpl);
    }

    event ExchangeTplSet(address _exchangeTpl);

    function setExchangeTpl(address _exchangeTpl) external onlyOwner {
        require(_exchangeTpl != address(0), "cannot go to 0 address");
        exchangeTpl = _exchangeTpl;
        emit ExchangeTplSet(_exchangeTpl);
    }

    event BnftTplSet(address _bnftTpl);

    function setBnftTpl(address _bnftTpl) external onlyOwner {
        require(_bnftTpl != address(0), "cannot go to 0 address");
        bnftTpl = _bnftTpl;
        emit BnftTplSet(_bnftTpl);
    }

    event BnftURISet(string _bnftURI);

    function setBnftURI(string memory _bnftURI) external onlyOwner {
        bnftURI = _bnftURI;
        emit BnftURISet(_bnftURI);
    }

    event NftOracleSet(address _nftOracle);

    function setNftOracle(address _nftOracle) external onlyOwner {
        require(_nftOracle != address(0), "cannot go to 0 address");
        nftOracle = _nftOracle;
        emit NftOracleSet(_nftOracle);
    }
}