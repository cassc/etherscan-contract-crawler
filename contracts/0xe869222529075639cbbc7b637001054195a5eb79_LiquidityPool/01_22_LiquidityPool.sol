// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/cryptography/MerkleProofUpgradeable.sol";

import "./interfaces/IStakingManager.sol";
import "./interfaces/IEtherFiNodesManager.sol";
import "./interfaces/IeETH.sol";
import "./interfaces/IStakingManager.sol";
import "./interfaces/IRegulationsManager.sol";
import "./interfaces/IMembershipManager.sol";
import "./interfaces/ITNFT.sol";

contract LiquidityPool is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    //--------------------------------------------------------------------------------------
    //---------------------------------  STATE-VARIABLES  ----------------------------------
    //--------------------------------------------------------------------------------------

    IStakingManager public stakingManager;
    IEtherFiNodesManager public nodesManager;
    IRegulationsManager public regulationsManager;
    IMembershipManager public membershipManager;
    ITNFT public tNft;
    IeETH public eETH; 

    bool public eEthliquidStakingOpened;

    uint128 public totalValueOutOfLp;
    uint128 public totalValueInLp;

    address public admin;

    uint32 public numPendingDeposits; // number of deposits to the staking manager, which needs 'registerValidator'

    //--------------------------------------------------------------------------------------
    //-------------------------------------  EVENTS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, address recipient, uint256 amount);

    error InvalidAmount();

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        require(totalValueOutOfLp >= msg.value, "rebase first before collecting the rewards");
        if (msg.value > type(uint128).max) revert InvalidAmount();
        totalValueOutOfLp -= uint128(msg.value);
        totalValueInLp += uint128(msg.value);
    }

    function initialize(address _regulationsManager) external initializer {
        require(_regulationsManager != address(0), "No zero addresses");

        __Ownable_init();
        __UUPSUpgradeable_init();
        regulationsManager = IRegulationsManager(_regulationsManager);
        eEthliquidStakingOpened = false;
    }

    function deposit(address _user, bytes32[] calldata _merkleProof) external payable {
        deposit(_user, _user, _merkleProof);
    }

    /// @notice deposit into pool
    /// @dev mints the amount of eETH 1:1 with ETH sent
    function deposit(address _user, address _recipient, bytes32[] calldata _merkleProof) public payable {
        if(msg.sender == address(membershipManager)) {
            isWhitelistedAndEligible(_user, _merkleProof);
        } else {
            require(eEthliquidStakingOpened, "Liquid staking functions are closed");
            isWhitelistedAndEligible(msg.sender, _merkleProof);
        }
        require(_recipient == msg.sender || _recipient == address(membershipManager), "Wrong Recipient");
        
        totalValueInLp += uint128(msg.value);
        uint256 share = _sharesForDepositAmount(msg.value);
        if (msg.value > type(uint128).max || msg.value == 0 || share == 0) revert InvalidAmount();

        eETH.mintShares(_recipient, share);

        emit Deposit(_recipient, msg.value);
    }

    /// @notice withdraw from pool
    /// @dev Burns user balance from msg.senders account & Sends equal amount of ETH back to the recipient
    /// @param _recipient the recipient who will receives the ETH
    /// @param _amount the amount to withdraw from contract
    function withdraw(address _recipient, uint256 _amount) external {
        require(totalValueInLp >= _amount, "Not enough ETH in the liquidity pool");
        require(_recipient != address(0), "Cannot withdraw to zero address");
        require(eETH.balanceOf(msg.sender) >= _amount, "Not enough eETH");

        uint256 share = sharesForWithdrawalAmount(_amount);
        totalValueInLp -= uint128(_amount);
        if (_amount > type(uint128).max || _amount == 0 || share == 0) revert InvalidAmount();

        eETH.burnShares(msg.sender, share);

        (bool sent, ) = _recipient.call{value: _amount}("");
        require(sent, "Failed to send Ether");

        emit Withdraw(msg.sender, _recipient, _amount);
    }

    /*
     * During ether.fi's phase 1 road map,
     * ether.fi's multi-sig will perform as a B-NFT holder which generates the validator keys and initiates the launch of validators
     * - {batchDepositWithBidIds, batchRegisterValidators} are used to launch the validators
     *  - ether.fi multi-sig should bring 2 ETH which is combined with 30 ETH from the liquidity pool to launch a validator
     * - {processNodeExit, sendExitRequests} are used to perform operational tasks to manage the liquidity
    */

    /// @notice ether.fi multi-sig (Owner) brings 2 ETH which is combined with 30 ETH from the liquidity pool and deposits 32 ETH into StakingManager
    function batchDepositWithBidIds(
        uint256 _numDeposits, 
        uint256[] calldata _candidateBidIds, 
        bytes32[] calldata _merkleProof
        ) payable external onlyAdmin returns (uint256[] memory) {
        require(msg.value == 2 ether * _numDeposits, "B-NFT holder must deposit 2 ETH per validator");
        require(totalValueInLp + msg.value >= 32 ether * _numDeposits, "Not enough balance");

        uint256 amountFromLp = 30 ether * _numDeposits;
        if (amountFromLp > type(uint128).max) revert InvalidAmount();

        totalValueOutOfLp += uint128(amountFromLp);
        totalValueInLp -= uint128(amountFromLp);
        numPendingDeposits += uint32(_numDeposits);

        uint256[] memory newValidators = stakingManager.batchDepositWithBidIds{value: 32 ether * _numDeposits}(_candidateBidIds, _merkleProof);

        if (_numDeposits > newValidators.length) {
            uint256 returnAmount = 2 ether * (_numDeposits - newValidators.length);
            totalValueOutOfLp += uint128(returnAmount);
            totalValueInLp -= uint128(returnAmount);

            (bool sent, ) = address(msg.sender).call{value: returnAmount}("");
            require(sent, "Failed to send Ether");
        }
        
        return newValidators;
    }

    function batchRegisterValidators(
        bytes32 _depositRoot,
        uint256[] calldata _validatorIds,
        IStakingManager.DepositData[] calldata _depositData
        ) external onlyAdmin
    {
        numPendingDeposits -= uint32(_validatorIds.length);
        stakingManager.batchRegisterValidators(_depositRoot, _validatorIds, owner(), address(this), _depositData);
    }

    function batchCancelDeposit(uint256[] calldata _validatorIds) external onlyAdmin {
        uint256 returnAmount = 2 ether * _validatorIds.length;

        totalValueOutOfLp += uint128(returnAmount);
        numPendingDeposits -= uint32(_validatorIds.length);

        stakingManager.batchCancelDeposit(_validatorIds);

        totalValueInLp -= uint128(returnAmount);

        (bool sent, ) = address(msg.sender).call{value: returnAmount}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice Send the exit requests as the T-NFT holder
    function sendExitRequests(uint256[] calldata _validatorIds) external onlyAdmin {
        for (uint256 i = 0; i < _validatorIds.length; i++) {
            uint256 validatorId = _validatorIds[i];
            nodesManager.sendExitRequest(validatorId);
        }
    }

    /// @notice Allow interactions with the eEth token
    function openEEthLiquidStaking() external onlyAdmin {
        eEthliquidStakingOpened = true;
    }

    /// @notice Disallow interactions with the eEth token
    function closeEEthLiquidStaking() external onlyAdmin {
        eEthliquidStakingOpened = false;
    }

    /// @notice Rebase by ether.fi
    /// @param _tvl total value locked in ether.fi liquidity pool
    /// @param _balanceInLp the balance of the LP contract when 'tvl' was calculated off-chain
    function rebase(uint256 _tvl, uint256 _balanceInLp) external onlyAdmin {
        require(address(this).balance == _balanceInLp, "the LP balance has changed.");
        require(getTotalPooledEther() > 0, "rebasing when there is no pooled ether is not allowed.");
        if (_tvl > type(uint128).max) revert InvalidAmount();
        totalValueOutOfLp = uint128(_tvl - _balanceInLp);
        totalValueInLp = uint128(_balanceInLp);
    }

    /// @notice swap T-NFTs for ETH
    /// @param _tokenIds the token Ids of T-NFTs
    function swapTNftForEth(uint256[] calldata _tokenIds) external onlyAdmin {
        require(totalValueInLp >= 30 ether * _tokenIds.length, "not enough ETH in LP");
        uint128 amount = uint128(30 ether * _tokenIds.length);
        totalValueOutOfLp += amount;
        totalValueInLp -= amount;
        address owner = owner();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tNft.transferFrom(owner, address(this), _tokenIds[i]);
        }
        (bool sent, ) = address(owner).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice sets the contract address for eETH
    /// @param _eETH address of eETH contract
    function setTokenAddress(address _eETH) external onlyOwner {
        require(_eETH != address(0), "No zero addresses");
        eETH = IeETH(_eETH);
    }

    function setStakingManager(address _address) external onlyOwner {
        require(_address != address(0), "No zero addresses");
        stakingManager = IStakingManager(_address);
    }

    function setEtherFiNodesManager(address _nodeManager) public onlyOwner {
        require(_nodeManager != address(0), "No zero addresses");
        nodesManager = IEtherFiNodesManager(_nodeManager);
    }

    function setMembershipManager(address _address) external onlyOwner {
        require(_address != address(0), "Cannot be address zero");
        membershipManager = IMembershipManager(_address);
    }

    function setTnft(address _address) external onlyOwner {
        require(_address != address(0), "Cannot be address zero");
        tNft = ITNFT(_address);
    }

    /// @notice Updates the address of the admin
    /// @param _newAdmin the new address to set as admin
    function updateAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Cannot be address zero");
        admin = _newAdmin;
    }
    
    //--------------------------------------------------------------------------------------
    //------------------------------  INTERNAL FUNCTIONS  ----------------------------------
    //--------------------------------------------------------------------------------------

    function isWhitelistedAndEligible(address _user, bytes32[] calldata _merkleProof) internal view{
        stakingManager.verifyWhitelisted(_user, _merkleProof);
        require(regulationsManager.isEligible(regulationsManager.whitelistVersion(), _user) == true, "User is not eligible to participate");
    }

    function _sharesForDepositAmount(uint256 _depositAmount) internal view returns (uint256) {
        uint256 totalPooledEther = getTotalPooledEther() - _depositAmount;
        if (totalPooledEther == 0) {
            return _depositAmount;
        }
        return (_depositAmount * eETH.totalShares()) / totalPooledEther;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    //--------------------------------------------------------------------------------------
    //------------------------------------  GETTERS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    function getTotalEtherClaimOf(address _user) external view returns (uint256) {
        uint256 staked;
        uint256 totalShares = eETH.totalShares();
        if (totalShares > 0) {
            staked = (getTotalPooledEther() * eETH.shares(_user)) / totalShares;
        }
        return staked;
    }

    function getTotalPooledEther() public view returns (uint256) {
        return totalValueOutOfLp + totalValueInLp;
    }

    function sharesForAmount(uint256 _amount) public view returns (uint256) {
        uint256 totalPooledEther = getTotalPooledEther();
        if (totalPooledEther == 0) {
            return 0;
        }
        return (_amount * eETH.totalShares()) / totalPooledEther;
    }

    /// @dev withdrawal rounding errors favor the protocol by rounding up
    function sharesForWithdrawalAmount(uint256 _amount) public view returns (uint256) {
        uint256 totalPooledEther = getTotalPooledEther();
        if (totalPooledEther == 0) {
            return 0;
        }

        // ceiling division so rounding errors favor the protocol
        uint256 numerator = _amount * eETH.totalShares();
        return (numerator + totalPooledEther - 1) / totalPooledEther;
    }

    function amountForShare(uint256 _share) public view returns (uint256) {
        uint256 totalShares = eETH.totalShares();
        if (totalShares == 0) {
            return 0;
        }
        return (_share * getTotalPooledEther()) / totalShares;
    }

    function getImplementation() external view returns (address) {return _getImplementation();}

    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier whenLiquidStakingOpen() {
        require(eEthliquidStakingOpened, "Liquid staking functions are closed");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }
}