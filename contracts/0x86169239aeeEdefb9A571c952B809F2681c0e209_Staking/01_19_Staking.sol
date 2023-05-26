// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IOutputReceiver.sol";
import "../../interfaces/IOutputReceiverV2.sol";
import "../../interfaces/IOutputReceiverV3.sol";
import "../../interfaces/IRevest.sol";
import "../../interfaces/IAddressRegistry.sol";
import "../../interfaces/IRewardsHandler.sol";
import "../../interfaces/IFNFTHandler.sol";
import "../../interfaces/IAddressLock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract Staking is Ownable, IOutputReceiverV3, ERC165, IAddressLock {
    using SafeERC20 for IERC20;

    address private revestAddress;
    address public lpAddress;
    address public rewardsHandlerAddress;
    address public addressRegistry;

    address public oldStakingContract;
    uint public previousStakingIDCutoff;

    bool public additionalEnabled;

    uint private constant ONE_DAY = 86400;

    uint private constant WINDOW_ONE = ONE_DAY;
    uint private constant WINDOW_THREE = ONE_DAY*5;
    uint private constant WINDOW_SIX = ONE_DAY*9;
    uint private constant WINDOW_TWELVE = ONE_DAY*14;
    uint private constant MAX_INT = 2**256 - 1;

    // For tracking if a given contract has approval for token
    mapping (address => mapping (address => bool)) private approvedContracts;

    address internal immutable WETH;

    uint[4] internal interestRates = [4, 13, 27, 56];
    string public customMetadataUrl = "https://revest.mypinata.cloud/ipfs/QmdaJso83dhA5My9gz3ewXBxoWveo95utJJqY99ZSGEpRc";
    string public addressMetadataUrl = "https://revest.mypinata.cloud/ipfs/QmWUyvkGFtFRXWxneojvAfBMy8QpewSvwQMQAkAUV42A91";

    event StakedRevest(uint indexed timePeriod, bool indexed isBasic, uint indexed amount, uint fnftId);

    struct StakingData {
        uint timePeriod;
        uint dateLockedFrom;
        uint amount;
    }

    // fnftId -> timePeriods
    mapping(uint => StakingData) public stakingConfigs;

    constructor(
        address revestAddress_,
        address lpAddress_,
        address rewardsHandlerAddress_,
        address addressRegistry_,
        address wrappedEth_
    ) {
        revestAddress = revestAddress_;
        lpAddress = lpAddress_;
        addressRegistry = addressRegistry_;
        rewardsHandlerAddress = rewardsHandlerAddress_;
        WETH = wrappedEth_;
        previousStakingIDCutoff = IFNFTHandler(IAddressRegistry(addressRegistry).getRevestFNFT()).getNextId() - 1;

        address revest = address(getRevest());
        IERC20(lpAddress).approve(revest, MAX_INT);
        IERC20(revestAddress).approve(revest, MAX_INT);
        approvedContracts[revest][lpAddress] = true;
        approvedContracts[revest][revestAddress] = true;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC165, IERC165) returns (bool) {
        return (
            interfaceId == type(IOutputReceiver).interfaceId
            || interfaceId == type(IAddressLock).interfaceId
            || interfaceId == type(IOutputReceiverV2).interfaceId
            || interfaceId == type(IOutputReceiverV3).interfaceId
            || super.supportsInterface(interfaceId)
        );
    }

    function stakeBasicTokens(uint amount, uint monthsMaturity) public returns (uint) {
        return _stake(revestAddress, amount, monthsMaturity);
    }

    function stakeLPTokens(uint amount, uint monthsMaturity) public returns (uint) {
        return _stake(lpAddress, amount, monthsMaturity);
    }

    function claimRewards(uint fnftId) external {
        // Check to make sure user owns the fnftId
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(_msgSender(), fnftId) == 1, 'E061');
        // Receive rewards
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, _msgSender());
    }

    ///
    /// Address Lock Features
    ///

    function updateLock(uint fnftId, uint, bytes memory) external override {
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(_msgSender(), fnftId) == 1, 'E061');
        // Receive rewards
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, _msgSender());
    }

    // This function not utilized
    function createLock(uint, uint, bytes memory) external pure override {
        return;
    }

    ///
    /// Output Recevier Functions
    ///

    function receiveRevestOutput(
        uint fnftId,
        address asset,
        address payable owner,
        uint quantity
    ) external override {
        address vault = getRegistry().getTokenVault();
        require(_msgSender() == vault, "E016");
        require(quantity == 1, 'ONLY SINGULAR');
        // Strictly limit access
        require(fnftId <= previousStakingIDCutoff || stakingConfigs[fnftId].timePeriod > 0, 'Nonexistent!');

        uint totalQuantity = getValue(fnftId);
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, owner);
        if (asset == revestAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, 0);
        } else if (asset == lpAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, 0);
        } else {
            require(false, "E072");
        }
        IERC20(asset).safeTransfer(owner, totalQuantity);
        emit WithdrawERC20OutputReceiver(_msgSender(), asset, totalQuantity, fnftId, '');
    }

    function handleTimelockExtensions(uint fnftId, uint expiration, address caller) external override {}

    function handleAdditionalDeposit(uint fnftId, uint amountToDeposit, uint quantity, address caller) external override {
        require(_msgSender() == getRegistry().getRevest(), "E016");
        require(quantity == 1);
        require(additionalEnabled, 'Not allowed!');
        _depositAdditionalToStake(fnftId, amountToDeposit, caller);
    }

    function handleSplitOperation(uint fnftId, uint[] memory proportions, uint quantity, address caller) external override {}

    // Future proofing for secondary callbacks during withdrawal
    // Could just use triggerOutputReceiverUpdate and call withdrawal function
    // But deliberately using reentry is poor form and reminds me too much of OAuth 2.0 
    function receiveSecondaryCallback(
        uint fnftId,
        address payable owner,
        uint quantity,
        IRevest.FNFTConfig memory config,
        bytes memory args
    ) external payable override {}

    // Allows for similar function to address lock, updating state while still locked
    // Called by the user directly
    function triggerOutputReceiverUpdate(
        uint fnftId,
        bytes memory args
    ) external override {}

    // This function should only ever be called when a split or additional deposit has occurred 
    function handleFNFTRemaps(uint, uint[] memory, address, bool) external pure override {
        revert();
    }


    function _stake(address stakeToken, uint amount, uint monthsMaturity) private returns (uint){
        require (stakeToken == lpAddress || stakeToken == revestAddress, "E079");
        require(monthsMaturity == 1 || monthsMaturity == 3 || monthsMaturity == 6 || monthsMaturity == 12, 'E055');
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);

        IRevest.FNFTConfig memory fnftConfig;
        fnftConfig.asset = stakeToken;
        fnftConfig.depositAmount = amount;
        fnftConfig.isMulti = true;

        fnftConfig.pipeToContract = address(this);

        address[] memory recipients = new address[](1);
        recipients[0] = _msgSender();

        uint[] memory quantities = new uint[](1);
        quantities[0] = 1;

        address revest = getRegistry().getRevest();
        if(!approvedContracts[revest][stakeToken]){
            IERC20(stakeToken).approve(revest, MAX_INT);
            approvedContracts[revest][stakeToken] = true;
        }
        uint fnftId = IRevest(revest).mintAddressLock(address(this), '', recipients, quantities, fnftConfig);

        uint interestRate = getInterestRate(monthsMaturity);
        uint allocPoint = amount * interestRate;

        StakingData memory cfg = StakingData(monthsMaturity, block.timestamp, amount);
        stakingConfigs[fnftId] = cfg;

        if(stakeToken == lpAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, allocPoint);
        } else if (stakeToken == revestAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, allocPoint);
        }
        
        emit StakedRevest(monthsMaturity, stakeToken == revestAddress, amount, fnftId);
        emit DepositERC20OutputReceiver(_msgSender(), stakeToken, amount, fnftId, '');
        return fnftId;
    }

    function _depositAdditionalToStake(uint fnftId, uint amount, address caller) private {
        //Prevent unauthorized access
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(caller, fnftId) == 1, 'E061');
        require(fnftId > previousStakingIDCutoff, 'E080');
        uint time = stakingConfigs[fnftId].timePeriod;
        require(time > 0, 'E078');
        address asset = ITokenVault(getRegistry().getTokenVault()).getFNFT(fnftId).asset;
        require(asset == revestAddress || asset == lpAddress, 'E079');

        //Claim rewards owed
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, _msgSender());

        //Write new, extended unlock date
        stakingConfigs[fnftId].dateLockedFrom = block.timestamp;
        stakingConfigs[fnftId].amount = stakingConfigs[fnftId].amount + amount;
        //Retreive current allocation points – WETH and RVST implicitly have identical alloc points
        uint oldAllocPoints = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, asset == revestAddress);
        uint allocPoints = amount * getInterestRate(time) + oldAllocPoints;
        if(asset == revestAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, allocPoints);
        } else if (asset == lpAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, allocPoints);
        }
        emit DepositERC20OutputReceiver(_msgSender(), asset, amount, fnftId, '');
    }


    ///
    /// VIEW FUNCTIONS
    ///

    /// Custom view function

    function getInterestRate(uint months) public view returns (uint) {
        if (months <= 1) {
            return interestRates[0];
        } else if (months <= 3) {
            return interestRates[1];
        } else if (months <= 6) {
            return interestRates[2];
        } else {
            return interestRates[3];
        }
    }

    function getRevest() private view returns (IRevest) {
        return IRevest(getRegistry().getRevest());
    }

    function getRegistry() public view returns (IAddressRegistry) {
        return IAddressRegistry(addressRegistry);
    }

    function getWindow(uint timePeriod) public pure returns (uint window) {
        if(timePeriod == 1) {
            window = WINDOW_ONE;
        }
        if(timePeriod == 3) {
            window = WINDOW_THREE;
        }
        if(timePeriod == 6) {
            window = WINDOW_SIX;
        }
        if(timePeriod == 12) {
            window = WINDOW_TWELVE;
        }
    }

    /// ADDRESS REGISTRY VIEW FUNCTIONS

    /// Does the address lock need an update? 
    function needsUpdate() external pure override returns (bool) {
        return true;
    }

    /// Get the metadata URL for an address lock
    function getMetadata() external view override returns (string memory) {
        return addressMetadataUrl;
    }

    /// Can the stake be unlocked?
    function isUnlockable(uint fnftId, uint) external view override returns (bool) {
        if(fnftId <= previousStakingIDCutoff) {
            return Staking(oldStakingContract).isUnlockable(fnftId, 0);
        }
        uint timePeriod = stakingConfigs[fnftId].timePeriod;
        uint depositTime = stakingConfigs[fnftId].dateLockedFrom;

        uint window = getWindow(timePeriod);
        bool mature = block.timestamp - depositTime > (timePeriod * 30 * ONE_DAY);
        bool window_open = (block.timestamp - depositTime) % (timePeriod * 30 * ONE_DAY) < window;
        return mature && window_open;
    }

    // Retrieve encoded data on the state of the stake for the address lock component
    function getDisplayValues(uint fnftId, uint) external view override returns (bytes memory) {
        if(fnftId <= previousStakingIDCutoff) {
            return IAddressLock(oldStakingContract).getDisplayValues(fnftId, 0);
        }
        uint allocPoints;
        {
            uint revestTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, true);
            uint lpTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, false);
            allocPoints = revestTokenAlloc > 0 ? revestTokenAlloc : lpTokenAlloc;
        }
        uint timePeriod = stakingConfigs[fnftId].timePeriod;
        return abi.encode(allocPoints, timePeriod);
    }

    /// OUTPUT RECEVIER VIEW FUNCTIONS

    function getCustomMetadata(uint fnftId) external view override returns (string memory) {
        if(fnftId <= previousStakingIDCutoff) {
            return Staking(oldStakingContract).getCustomMetadata(fnftId);
        } else {
            return customMetadataUrl;
        }
    }

    function getOutputDisplayValues(uint fnftId) external view override returns (bytes memory) {
        if(fnftId <= previousStakingIDCutoff) {
            return IOutputReceiver(oldStakingContract).getOutputDisplayValues(fnftId);
        }
        bool isRevestToken;
        {
            // Will be zero if this is an LP stake
            uint revestTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, true);
            uint wethTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, WETH, true);
            isRevestToken = revestTokenAlloc > 0 || wethTokenAlloc > 0;
        }
        uint revestRewards = IRewardsHandler(rewardsHandlerAddress).getRewards(fnftId, revestAddress);
        uint wethRewards = IRewardsHandler(rewardsHandlerAddress).getRewards(fnftId, WETH);
        uint timePeriod = stakingConfigs[fnftId].timePeriod;
        uint nextUnlock = block.timestamp + ((timePeriod * 30 days) - ((block.timestamp - stakingConfigs[fnftId].dateLockedFrom)  % (timePeriod * 30 days)));
        //This parameter has been modified for new stakes
        return abi.encode(revestRewards, wethRewards, timePeriod, stakingConfigs[fnftId].dateLockedFrom, isRevestToken ? revestAddress : lpAddress, nextUnlock);
    }

    function getAddressRegistry() external view override returns (address) {
        return addressRegistry;
    }

    function getValue(uint fnftId) public view override returns (uint) {
        if(fnftId <= previousStakingIDCutoff) {
            return ITokenVault(getRegistry().getTokenVault()).getFNFT(fnftId).depositAmount;
        } else {
            return stakingConfigs[fnftId].amount;
        }
    }

    function getAsset(uint fnftId) external view override returns (address) {
        return ITokenVault(getRegistry().getTokenVault()).getFNFT(fnftId).asset;
    }

    ///
    /// ADMIN FUNCTIONS
    ///

    // Allows us to set a new output receiver metadata URL
    function setCustomMetadata(string memory _customMetadataUrl) external onlyOwner {
        customMetadataUrl = _customMetadataUrl;
    }

    function setLPAddress(address lpAddress_) external onlyOwner {
        lpAddress = lpAddress_;
    }

    function setAddressRegistry(address addressRegistry_) external override onlyOwner {
        addressRegistry = addressRegistry_;
    }

    // Set a new metadata url for address lock
    function setMetadata(string memory _addressMetadataUrl) external onlyOwner {
        addressMetadataUrl = _addressMetadataUrl;
    }

    // What contract will handle staking rewards
    function setRewardsHandler(address _handler) external onlyOwner {
        rewardsHandlerAddress = _handler;
    }

    function setCutoff(uint cutoff) external onlyOwner {
        previousStakingIDCutoff = cutoff;
    }

    function setOldStaking(address stake) external onlyOwner {
        oldStakingContract = stake;
    }

    function setAdditionalDepositsEnabled(bool enabled) external onlyOwner {
        additionalEnabled = enabled;
    }

}