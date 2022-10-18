// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IRewards.sol";
import "./interfaces/IStaker.sol";
import "./interfaces/ocean/IVeFeeDistributor.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Booster
 * @author Convex / H2O
 *
 * Contract for claiming and managing distribution of rewards/fees between staking pools.
 * All rewards flowing through this contract comes in form of Ocean, collected either from
 * veFeeDistributor (Ocean marketplace fees) or DFRewards (rewards coming from veAllocate voting)
 */
contract Booster {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ============ Constants ============= */

    uint256 public constant FEE_DENOMINATOR = 10000;

    /* ============ State Variables ============ */

    address public immutable ocean;

    // Fees and rewards distribution
    uint256 public lpStakerIncentive = 7720; //incentive to psdn stakers
    uint256 public psdnOceanStakerIncentive = 1447; //incentive to psdn stakers
    uint256 public earmarkIncentive = 50; //incentive to users who spend gas to make calls
    uint256 public platformFee = 300; //possible fee to build treasury
    address public psdnStakersRewards; //psdn rewards
    address public psdnOceanStakersRewards; //psdnOcean rewards
    address public lpStakersRewards; //psdnOcean/Ocean lp token rewards

    // Permissions
    address public owner;
    address public feeManager;

    // Address of VoterProxy, responsible for interacting with veOcean
    address public immutable staker;
    address public rewardArbitrator;
    address public treasury;
    address public feeDistro;
    address public feeToken;

    bool public isShutdown;

    /* ============ Modifiers ============ */

    modifier onlyOwner() {
        require(msg.sender == owner, "auth!");
        _;
    }

    modifier onlyFeeManager() {
        require(msg.sender == feeManager, "auth!");
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Sets various contract addresses
     *
     * @param _staker                Address of VoterProxy contract
     * @param _ocean                 Address of ocean token
     */
    constructor(address _staker, address _ocean) {
        staker = _staker;
        ocean = _ocean;
        isShutdown = false;
        owner = msg.sender;
        feeManager = msg.sender;
        feeDistro = address(0);
        feeToken = address(0);
        treasury = address(0);
    }

    /* ============ External Functions ============ */

    /* ====== Setters ====== */

    /**
     * Sets new owner of the contract
     *
     * @param _owner                 Address of the new owner
     */
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /**
     * Sets fee manager address
     *
     * @param _feeManager            Address of the new fee manager
     */
    function setFeeManager(address _feeManager) external onlyOwner {
        feeManager = _feeManager;
    }

    /**
     * Sets rewards pools addresses
     *
     * @param _psdnOceanStakersRewards       Address of the new psdnOcean stakers rewards pool
     * @param _psdnStakersRewards            Address of the new psdn stakers rewards pool
     * @param _lpStakersRewards              Address of the new lp stakers rewards pool
     */
    function setRewardContracts(
        address _psdnOceanStakersRewards,
        address _psdnStakersRewards,
        address _lpStakersRewards
    ) external onlyOwner {
        psdnOceanStakersRewards = _psdnOceanStakersRewards;
        psdnStakersRewards = _psdnStakersRewards;
        lpStakersRewards = _lpStakersRewards;
    }

    /**
     * Sets address of fees distribution contract
     *
     * @param _feeDistro       Address of the new Ocean Marketplace fees distribution contract
     */
    function setFeeInfo(address _feeDistro) external onlyFeeManager {
        feeDistro = _feeDistro;
        feeToken = IVeFeeDistributor(feeDistro).token();
    }

    /**
     * Sets fees & rewards distribution split, while psdn stakers gets the remaining part
     *
     * @param _psdnOceanStakerFee   Part of fees & rewards distributed to psdnOCEAN stakers
     * @param _lpStakerFee   Part of fees & rewards distributed to psdnOCEAN/OCEAN lp stakers
     * @param _callerFee            Part of fees & rewards distributed to entity calling earmarkFees/earmarkRewards methods
     * @param _platformFee          Part of fees & rewards distributed to platform treasury
     */
    function setFees(
        uint256 _psdnOceanStakerFee,
        uint256 _lpStakerFee,
        uint256 _callerFee,
        uint256 _platformFee
    ) external onlyFeeManager {
        uint256 total = _psdnOceanStakerFee
            .add(_callerFee)
            .add(_platformFee)
            .add(_psdnOceanStakerFee);
        require(
            total <= FEE_DENOMINATOR,
            "Fees exceeding total amount of fees"
        );

        //values must be within certain ranges
        if (_callerFee >= 10 && _callerFee <= 100 && _platformFee <= 1000) {
            psdnOceanStakerIncentive = _psdnOceanStakerFee;
            lpStakerIncentive = _lpStakerFee;
            earmarkIncentive = _callerFee;
            platformFee = _platformFee;
        }
    }

    /**
     * Sets platform treasury address
     *
     * @param _treasury   Address of platform treasury
     */
    function setTreasury(address _treasury) external onlyFeeManager {
        treasury = _treasury;
    }

    /* ====== Actions ====== */

    /**
     * Claims rewards coming from DFRewards contract, after weekly distribution from Ocean, and distributes them between fees/rewards receipients
     *
     * @return True if call was successfull
     */
    function earmarkRewards() external returns (bool) {
        require(!isShutdown, "shutdown");

        //claim ocean
        IStaker(staker).claimRewards(ocean, address(this));

        //ocean balance
        uint256 oceanBal = IERC20(ocean).balanceOf(address(this));

        _distributeToken(IERC20(ocean), oceanBal);
        return true;
    }

    /**
     * Claims fees coming from veFeeDistributor contract and distributes them between fees/rewards receipients
     *
     * @return True if call was successfull
     */
    function earmarkFees() external returns (bool) {
        require(!isShutdown, "shutdown");

        //claim fee rewards
        IStaker(staker).claimFees(feeDistro, feeToken, address(this));

        //send fee rewards to reward contract
        uint256 _balance = IERC20(feeToken).balanceOf(address(this));

        _distributeToken(IERC20(feeToken), _balance);
        return true;
    }

    /**
     * Votes on selected Data NFTs on voter proxy contract
     *
     * @param amount                Array of shares, that we want to allocate to given Data Nft
     * @param nft                   Array of addresses of selected Data Nfts
     * @param chainId               Array of chain ids of selected Data Nfts
     *
     * @return True if call was successfull
     */
    function voteAllocations(
        uint256[] calldata amount,
        address[] calldata nft,
        uint256[] calldata chainId
    ) external onlyOwner returns (bool) {
        IStaker(staker).voteAllocations(amount, nft, chainId);
        return true;
    }

    /**
     * Shuts down this contract
     */
    function shutdownSystem() external onlyOwner {
        isShutdown = true;
    }

    /* ============ Internal Functions ============ */

    /**
     * Distribute reward/fee token to relevant parties
     *
     * @param _token            Token, that will be distributed
     * @param _amount           Amount of token to distribute
     */
    function _distributeToken(IERC20 _token, uint256 _amount) internal {
        if (_amount > 0) {
            uint256 _psdnOceanStakerIncentive = _amount
                .mul(psdnOceanStakerIncentive)
                .div(FEE_DENOMINATOR);
            uint256 _lpStakerIncentive = _amount.mul(lpStakerIncentive).div(
                FEE_DENOMINATOR
            );
            uint256 _callIncentive = _amount.mul(earmarkIncentive).div(
                FEE_DENOMINATOR
            );

            //send to treasury
            if (
                treasury != address(0) &&
                treasury != address(this) &&
                platformFee > 0
            ) {
                //only subtract after address condition check
                uint256 _platform = _amount.mul(platformFee).div(
                    FEE_DENOMINATOR
                );
                _amount = _amount.sub(_platform);
                _token.safeTransfer(treasury, _platform);
            }

            //remove incentives from balance
            _amount = _amount
                .sub(_callIncentive)
                .sub(_psdnOceanStakerIncentive)
                .sub(_lpStakerIncentive);

            //send incentives for calling
            _token.safeTransfer(msg.sender, _callIncentive);

            //send psdn stakers share of ocean to reward contract
            _token.safeTransfer(psdnStakersRewards, _amount);
            IRewards(psdnStakersRewards).queueNewRewards(_amount);

            //send psdnOcean stakers's share of ocean to reward contract
            _token.safeTransfer(
                psdnOceanStakersRewards,
                _psdnOceanStakerIncentive
            );
            IRewards(psdnOceanStakersRewards).queueNewRewards(
                _psdnOceanStakerIncentive
            );

            //send lp stakers's share of ocean to reward contract
            _token.safeTransfer(lpStakersRewards, _lpStakerIncentive);
            IRewards(lpStakersRewards).queueNewRewards(_lpStakerIncentive);
        }
    }
}