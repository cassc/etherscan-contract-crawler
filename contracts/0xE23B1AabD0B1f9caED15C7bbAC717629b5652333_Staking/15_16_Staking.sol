// SPDX-License-Identifier:MIT	
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interface/IRewardPool.sol";
import "hardhat/console.sol";

error InvalidRewardPoolAddress();

contract Staking is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC20Upgradeable
{
    using SafeMathUpgradeable for uint256;
    IERC20MetadataUpgradeable public ectAddress;
    address public rewardPoolAddress;
    uint256 public unstakeFee;
    uint256 public minECT;
    bool public isRewardPoolAddressSet;
    uint256 public constant decimalPrecision = 100;
    uint256 public constant MAX_UNSTAKE_FEE = 10 * decimalPrecision;

    mapping(address => uint256) public totalStaked;

    //Events
    event StakeECT(address indexed staker, uint256 amount);
    event UnstakeECT(address indexed staker, uint256 amount);

    // Modifiers
    modifier isRewardSet() {
        if (!isRewardPoolAddressSet) {
            revert InvalidRewardPoolAddress();
        }
        _;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function initialize(
        IERC20MetadataUpgradeable _ectAddress,
        uint256 _unstakeFee
    ) public initializer {
        __ERC20_init("Staking", "xECT");
        __Ownable_init();
        ectAddress = _ectAddress;
        unstakeFee = _unstakeFee;
        minECT = 10000 * (10**ectAddress.decimals());
        isRewardPoolAddressSet = false;
    }

    /**
     * @dev Method for User to Stake ECT Tokens
     * @notice This method allow user to stake ECT tokens
     * @param _amount Amount to stake
     */
    function stake(uint256 _amount) external isRewardSet {
        require(_amount >= minECT, "Minimum staking amount required!");
        console.log("line 69");
        IRewardPool(rewardPoolAddress).wave();
        console.log("line 71");
        uint256 totalToken = ectAddress.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalToken == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalToken);
            _mint(msg.sender, what);
        }
         console.log("line 79");
        ectAddress.transferFrom(msg.sender, address(this), _amount);

        totalStaked[msg.sender] += _amount;
        emit StakeECT(msg.sender, _amount);
    }

    /**
     * @dev Method for user to calculate their rewards
     * @notice This method allow user to calculate their rewards
     * @param _account Address of the user to see rewards
     */
    function calculateReward(address _account) external view returns (uint256) {
        uint256 totalReward = (
            balanceOf(_account)
                .mul(
                    ectAddress.balanceOf(address(this)).add(
                        IRewardPool(rewardPoolAddress).waveAmount()
                    )
                )
                .div(totalSupply())
        );
        if (totalReward > totalStaked[_account]) {
            return totalReward.sub(totalStaked[_account]);
        }
        return 0;
    }

    /**
     * @dev Method for User to Unstake ECT Tokens
     * @notice This method allow user to Unstake ECT tokens
     * @param _share Amount to Unstake
     */
    function unstake(uint256 _share) external isRewardSet {
        IRewardPool(rewardPoolAddress).wave();
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(ectAddress.balanceOf(address(this))).div(
            totalShares
        );
        require(
            _share <= balanceOf(msg.sender),
            "ECT-Staking: Insufficient Balance"
        );

        uint256 unstakeCharges;
        if (msg.sender == owner()) {
            unstakeCharges = 0;
        } else {
            unstakeCharges = ((what * unstakeFee) / (100 * decimalPrecision));
        }
        if(what>0){
        ectAddress.transfer(msg.sender, what - unstakeCharges);
        ectAddress.transfer(rewardPoolAddress, unstakeCharges);
        }
        
        totalStaked[msg.sender] -= _share.mul(totalStaked[msg.sender]).div(
            balanceOf(msg.sender)
        );
        _burn(msg.sender, _share);
        emit UnstakeECT(msg.sender, what);
    }

    /**
    * @dev Method to Set Unstake Fee  by Owner Only
    @ @notice This method allow to set new Unstake Fee
    * @param _newFee New Fee to Be Set
    */
    function setUnstakeFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= MAX_UNSTAKE_FEE, "Unstake Fee must be in range");
        unstakeFee = _newFee;
    }

    /**
     * @notice This method allow owner to set minimum ECT Stake.
     * @dev Method to set MinECT only by Owner
     * @param _newMinECT New Minimum Fee to Be Set
     */
    function setMinECT(uint256 _newMinECT) external onlyOwner {
        minECT = _newMinECT;
    }

    /**
     * @notice This method allow to set Ocean Address
     * @dev Method to set Ocean Address By Owner
     * @param _rewardPoolAddress Address of Ocean Contract Set by Owner
     */
    function setRewardPoolAddress(address _rewardPoolAddress)
        external
        onlyOwner
    {
        rewardPoolAddress = _rewardPoolAddress;
        isRewardPoolAddressSet = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
}