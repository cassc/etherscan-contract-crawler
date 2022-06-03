// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./StakingPool.sol";
import "../Interface/IReferralManager.sol";
import "../Interface/IFeeManager.sol";
import "../Interface/IMinimalProxy.sol";
import "../library/CloneBase.sol";
import "../library/TransferHelper.sol";

contract StakingPoolFactory is Ownable, CloneBase {
    using SafeMath for uint256;

    /// @notice information of deployed pool
    struct StakingPoolInfo {
        address poolAddress;
        IERC20 rewardToken;
        IERC20 inputToken;
        uint256 blockReward;
    }

    StakingPoolInfo[] public pools;

    uint256 public poolsIndex;

    IFeeManager public feeManager;

    //Trigger for ReferralManager mode
    bool public isReferralManagerEnabled;

    IReferralManager public referralManager;

    mapping(uint256 => address) public implementationIdVsImplementation;
    uint256 public nextId;

    event PoolsLaunched(
        uint256 id,
        uint256 indexed poolsIndex,
        address indexed poolsAddress
    );

    event ImplementationLaunched(uint256 _id, address _implementation);
    event ImplementationUpdated(uint256 _id, address _implementation);

    function addImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "Invalid implementation");
        implementationIdVsImplementation[nextId] = _newImplementation;

        emit ImplementationLaunched(nextId, _newImplementation);

        nextId = nextId.add(1);
    }

    function updateImplementation(uint256 _id, address _newImplementation)
        external
        onlyOwner
    {
        address currentImplementation = implementationIdVsImplementation[_id];
        require(currentImplementation != address(0), "Incorrect Id");

        implementationIdVsImplementation[_id] = _newImplementation;
        emit ImplementationUpdated(_id, _newImplementation);
    }

    function _handleFeeManager()
        private
        returns (uint256 feeAmount_, address feeToken_)
    {
        require(address(feeManager) != address(0), "Add FeeManager");

        (feeAmount_, feeToken_) = getFeeInfo();
        if (feeToken_ != address(0)) {
            TransferHelper.safeTransferFrom(
                feeToken_,
                msg.sender,
                address(this),
                feeAmount_
            );

            TransferHelper.safeApprove(
                feeToken_,
                address(feeManager),
                feeAmount_
            );

            feeManager.fetchFees();
        } else {
            require(msg.value == feeAmount_, "Invalid value sent for fee");
            feeManager.fetchFees{value: msg.value}();
        }

        return (feeAmount_, feeToken_);
    }

    function getFeeInfo() public view returns (uint256, address) {
        return feeManager.getFactoryFeeInfo(address(this));
    }

    function _handleReferral(address referrer, uint256 feeAmount) private {
        if (isReferralManagerEnabled && referrer != address(0)) {
            referralManager.handleReferralForUser(
                referrer,
                msg.sender,
                feeAmount
            );
        }
    }

    function _launchStakingPool(uint256 _id, bytes memory _encodedData)
        internal
        returns (address)
    {
        IERC20 _rewardToken;
        IERC20 _inputToken;
        uint256 _startBlock;
        uint256 _endBlock;
        uint256 _amount;
        uint256 blockReward;
        (
            _rewardToken,
            _inputToken,
            _startBlock,
            _endBlock,
            _amount,
            blockReward
        ) = abi.decode(
            _encodedData,
            (IERC20, IERC20, uint256, uint256, uint256, uint256)
        );

        require(
            address(_rewardToken) != address(0) &&
                address(_inputToken) != address(0),
            "Cant be Zero address"
        );
        require(
            _startBlock >= block.number,
            "Start block should be greater than current"
        ); // ideally at least 24 hours more to give investors time
        require(
            _endBlock > _startBlock,
            "End Block should be greater than StartBlock"
        ); //_crowdsaleEndTime = 0 means crowdsale would be concluded manually by owner
        require(_amount > 0, "Allocate some amount for Pool");
        require(blockReward > 0, "Block Rewards cant be zero");

        address stakingPoolLibrary = implementationIdVsImplementation[_id];
        require(stakingPoolLibrary != address(0), "Invalid implementation id");

        address stakingPool = createClone(stakingPoolLibrary);

        TransferHelper.safeTransferFrom(
            address(_rewardToken),
            msg.sender,
            address(this),
            _amount
        );

        TransferHelper.safeApprove(
            address(_rewardToken),
            address(stakingPool),
            _amount
        );

        IMinimalProxy(stakingPool).init(_encodedData);

        //stacking up necessary pool info ever made to pools variable
        pools.push(
            StakingPoolInfo({
                poolAddress: address(stakingPool),
                rewardToken: _rewardToken,
                inputToken: _inputToken,
                blockReward: blockReward
            })
        );
        emit PoolsLaunched(_id, poolsIndex, address(stakingPool));
        poolsIndex++;

        return address(stakingPool);
    }

    /**
     * @notice Creates a new Staking Pool contract and registers it in the Factory
     */
    function launchStakingPool(uint256 _id, bytes memory _encodedData)
        external
        payable
        returns (address)
    {
        address stakingPool = _launchStakingPool(_id, _encodedData);
        _handleFeeManager();

        return address(stakingPool);
    }

    /**
     * @notice Creates a new Staking Pool contract and registers it in the Factory
     */
    function launchStakingPoolWithReferral(
        uint256 _id,
        address _referrer,
        bytes memory _encodedData
    ) external payable returns (address) {
        address stakingPool = _launchStakingPool(_id, _encodedData);
        (uint256 feeAmount, ) = _handleFeeManager();
        _handleReferral(_referrer, feeAmount);
        return address(stakingPool);
    }

    function withdrawERC20(IERC20 _token) external onlyOwner {
        TransferHelper.safeTransfer(
            address(_token),
            msg.sender,
            _token.balanceOf(address(this))
        );
    }

    function updateFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Fee Manager address cant be zero");
        feeManager = IFeeManager(_feeManager);
    }

    function updateReferralManagerMode(
        bool _isReferralManagerEnabled,
        address _referralManager
    ) external onlyOwner {
        require(
            _referralManager != address(0),
            "Referral Manager address cant be zero"
        );
        isReferralManagerEnabled = _isReferralManagerEnabled;
        referralManager = IReferralManager(_referralManager);
    }
}