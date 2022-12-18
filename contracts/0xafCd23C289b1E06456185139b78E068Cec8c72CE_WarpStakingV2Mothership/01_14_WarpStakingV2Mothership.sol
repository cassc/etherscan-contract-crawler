// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./WarpStakingV2.sol";
import "./WarpStakingV2ChildCreator.sol";

contract WarpStakingV2Mothership is AccessControl, Pausable {
    using SafeMath for uint256;

    bytes32 public constant SETTINGS_ROLE = keccak256("SETTINGS_ROLE");
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");
    bytes32 public constant CHILD_MANAGER_ROLE =
        keccak256("CHILD_MANAGER_ROLE");
    bytes32 public constant FUNDS_MANAGER_ROLE =
        keccak256("FUNDS_MANAGER_ROLE");
    bytes32 public constant CHILD_ROLE = keccak256("CHILD_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address private _fundsWithdrawReceiver;

    address private _feeReceiver;
    uint256 private _baseFee; // denom = 10000 ; eg. 0.25% = 25 / denom
    uint256 private _nativeFee; // BNB

    WarpStakingV2ChildCreator private _childCreator;

    WarpStakingV2[] private _stakingContracts;
    mapping(address => uint256) private _stakingContractIndexes;

    mapping(address => uint256) private _stakingContractDeposits;
    mapping(address => uint256) private _stakingContractHarvests;

    constructor(
        address admin_,
        address fundsWithdrawReceiver_,
        address feeReceiver_,
        uint256 baseFee_,
        uint256 nativeFee_
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);

        _grantRole(SETTINGS_ROLE, admin_);
        _grantRole(RESCUER_ROLE, admin_);
        _grantRole(FUNDS_MANAGER_ROLE, admin_);
        _grantRole(CHILD_MANAGER_ROLE, admin_);
        _grantRole(PAUSER_ROLE, admin_);

        _childCreator = new WarpStakingV2ChildCreator(address(this));
        _fundsWithdrawReceiver = fundsWithdrawReceiver_;
        _feeReceiver = feeReceiver_;
        _baseFee = baseFee_;
        _nativeFee = nativeFee_;
    }

    /// @notice Return fee receiver
    function fundsWithdrawReceiver() public view returns (address) {
        return _fundsWithdrawReceiver;
    }

    /// @notice Return fee receiver
    function feeReceiver() public view returns (address) {
        return _feeReceiver;
    }

    /// @notice Return base fee
    function baseFee() public view returns (uint256) {
        return _baseFee;
    }

    /// @notice Return native fee
    function nativeFee() public view returns (uint256) {
        return _nativeFee;
    }

    /// @notice Return current child creator
    function childCreator() public view returns (WarpStakingV2ChildCreator) {
        return _childCreator;
    }

    /// @notice Return all WarpStaking contract managed by mothership
    function stakingContracts() public view returns (WarpStakingV2[] memory) {
        return _stakingContracts;
    }

    /// @notice Childs current deposit in child stake token
    function childsCurrentDeposit(address child_)
        public
        view
        returns (uint256 deposit)
    {
        return _stakingContractDeposits[child_];
    }

    /// @notice Childs total harvests in child reward token
    function childsTotalHarvest(address child_)
        public
        view
        returns (uint256 deposit)
    {
        return _stakingContractHarvests[child_];
    }

    function updateFundsWithdrawReceiver(address fundsWithdrawReceiver_)
        public
        onlyRole(SETTINGS_ROLE)
    {
        _fundsWithdrawReceiver = fundsWithdrawReceiver_;
    }

    function updateBaseFee(uint256 baseFee_) public onlyRole(SETTINGS_ROLE) {
        _baseFee = baseFee_;
    }

    function updateNativeFee(uint256 nativeFee_) public onlyRole(SETTINGS_ROLE) {
        _nativeFee = nativeFee_;
    }

    function updateFeeReceiver(address feeReceiver_)
        public
        onlyRole(SETTINGS_ROLE)
    {
        _feeReceiver = feeReceiver_;
    }

    /// @notice Create a new WarpStaking contract
    /// @dev New WarpStaking contract generated with the _childCreator
    function addWarpStaking(
        IERC20 token_,
        IERC20 rewardToken_,
        IPancakePair lp_,
        string memory name_,
        string memory symbol_,
        uint256 apr_,
        uint256 period_,
        bytes memory data
    ) public onlyRole(CHILD_MANAGER_ROLE) returns (WarpStakingV2) {
        require(
            address(_childCreator) != address(0),
            "WSM: Missing child creator"
        );
        WarpStakingV2 newContract = _childCreator.newWarpStaking(
            token_,
            rewardToken_,
            lp_,
            name_,
            symbol_,
            apr_,
            period_,
            data
        );
        address contractAddress = address(newContract);
        _stakingContractIndexes[contractAddress] = _stakingContracts.length;
        _stakingContracts.push(newContract);

        _grantRole(CHILD_ROLE, contractAddress);

        emit WarpStakingAdded(contractAddress);

        return newContract;
    }

    /// @notice Add an already existing WarpStaking contract
    /// @param warpStaking_ contract which already exists
    function addExistingWarpStaking(WarpStakingV2 warpStaking_)
        public
        onlyRole(CHILD_MANAGER_ROLE)
    {
        require(
            address(warpStaking_) != address(0),
            "WSM: Cant be null address"
        );

        for (uint256 i = 0; i < _stakingContracts.length; i++) {
            require(
                address(_stakingContracts[i]) != address(warpStaking_),
                "WSM: Already added"
            );
        }
        _stakingContractIndexes[address(warpStaking_)] = _stakingContracts
            .length;
        _stakingContracts.push(warpStaking_);

        warpStaking_.setMother(this);

        _grantRole(CHILD_ROLE, address(warpStaking_));

        emit WarpStakingAdded(address(warpStaking_));
    }

    /// @notice Remove a WarpStaking contract from the mothership
    /// @param staking_ contract to remove from mothership
    function removeStakingContract(WarpStakingV2 staking_)
        public
        onlyRole(CHILD_MANAGER_ROLE)
    {
        uint256 index = _stakingContractIndexes[address(staking_)];
        require(
            index >= 0 && index < _stakingContracts.length,
            "WSM: Invalid staking contract"
        );
        require(
            address(_stakingContracts[index]) == address(staking_),
            "WSM: Address mismatch"
        );

        uint256 newIndex = _stakingContracts.length - 1;
        _stakingContractIndexes[address(_stakingContracts[newIndex])] = index;
        _stakingContracts[index] = _stakingContracts[newIndex];
        _stakingContracts.pop();

        _revokeRole(CHILD_ROLE, address(staking_));

        delete _stakingContractIndexes[address(staking_)];
        emit WarpStakingRemoved(address(staking_));
    }

    /// @notice Update the WarpStaking creator contract
    /// @param childCreator_ the new WarpStaking creator
    function updateChildCreator(WarpStakingV2ChildCreator childCreator_)
        public
        onlyRole(CHILD_MANAGER_ROLE)
    {
        _childCreator = childCreator_;
        emit ChildCreatorUpdated(address(_childCreator));
    }

    function childDeposit(uint256 amount_) public onlyRole(CHILD_ROLE) {
        WarpStakingV2 child = WarpStakingV2(msg.sender);
        IERC20 token = IERC20(child.token());

        token.transferFrom(msg.sender, address(this), amount_);

        uint256 newDepositAmount = _stakingContractDeposits[msg.sender].add(
            amount_
        );
        _stakingContractDeposits[msg.sender] = _stakingContractDeposits[
            msg.sender
        ].add(amount_);
        token.approve(msg.sender, newDepositAmount);
    }

    function childHarvest(uint256 amount_)
        public
        onlyRole(CHILD_ROLE)
        whenNotPaused
    {
        WarpStakingV2 child = WarpStakingV2(msg.sender);
        IERC20 rewardToken = IERC20(child.rewardToken());

        rewardToken.transfer(msg.sender, amount_);
        _stakingContractHarvests[msg.sender] = _stakingContractHarvests[
            msg.sender
        ].add(amount_);
    }

    function childWithdraw(uint256 amount_)
        public
        onlyRole(CHILD_ROLE)
        whenNotPaused
    {
        WarpStakingV2 child = WarpStakingV2(msg.sender);
        IERC20 token = IERC20(child.token());

        token.transfer(msg.sender, amount_);
        _stakingContractDeposits[msg.sender] = _stakingContractDeposits[
            msg.sender
        ].sub(amount_);
    }

    function stopChild(WarpStakingV2 child_, uint256 timestamp)
        external
        onlyRole(PAUSER_ROLE)
    {
        child_.stop(timestamp);
    }

    function stopChildNow(WarpStakingV2 child_)
        external
        onlyRole(PAUSER_ROLE)
    {
        child_.stop(block.timestamp);
    }

    function resumeChild(WarpStakingV2 child_) external onlyRole(PAUSER_ROLE) {
        child_.resume();
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Withdraw tokens out of the contract
    /// @param token_ to withdraw
    /// @param amount_ to rescue out of the contract
    function withdrawToken(IERC20 token_, uint256 amount_)
        external
        onlyRole(FUNDS_MANAGER_ROLE)
    {
        require(
            _fundsWithdrawReceiver != address(0),
            "WSM: Withdraw to null address"
        );
        token_.transfer(_fundsWithdrawReceiver, amount_);
    }

    /// @notice Withdraw all staked tokens out of the contract
    function withdrawAllChildTokens() external onlyRole(FUNDS_MANAGER_ROLE) {
        require(
            _fundsWithdrawReceiver != address(0),
            "WSM: Withdraw to null address"
        );
        for (uint256 i = 0; i < _stakingContracts.length; i++) {
            IERC20 token = IERC20(_stakingContracts[i].token());
            token.transfer(
                _fundsWithdrawReceiver,
                token.balanceOf(address(this))
            );
        }
    }

    function forceChildUnstake(
        WarpStakingV2 child_,
        address account_,
        uint256 amount_,
        bool ignoreHarvest_
    ) external onlyRole(RESCUER_ROLE) {
        child_.forceUnstake(account_, amount_, ignoreHarvest_);
    }

    /// @notice Rescue tokens out of the contract
    /// @param token_ to rescue
    /// @param to_ receiver of the amount
    /// @param amount_ to rescue out of the contract
    function rescueToken(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external onlyRole(RESCUER_ROLE) {
        token_.transfer(to_, amount_);
    }

    /// @notice Rescue tokens out of a child contract
    /// @param child_ to rescue from
    /// @param token_ to rescue
    /// @param to_ receiver of the amount
    /// @param amount_ to rescue out of the contract
    function rescueTokenFromChild(
        WarpStakingV2 child_,
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external onlyRole(RESCUER_ROLE) {
        child_.rescueToken(token_, to_, amount_);
    }

    event ChildCreatorUpdated(address indexed childCreatorAddress);
    event WarpStakingAdded(address indexed warpStakingAddress);
    event WarpStakingRemoved(address indexed warpStakingAddress);
}