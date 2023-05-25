// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "./AbsGauge.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

contract PoolGauge is AbsGauge, ReentrancyGuard {
    uint256 private constant _MAX_REWARDS = 8;
    string public name;
    string public symbol;
    uint256 public decimals;
    // permit2 contract
    address public permit2Address;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;

    // user -> [uint128 claimable amount][uint128 claimed amount]
    mapping(address => mapping(address => uint256)) public claimData;
    // For tracking external rewards
    uint256 public rewardCount;
    address[_MAX_REWARDS] public rewardTokens;
    mapping(address => Reward) public rewardData;
    // reward token -> claiming address -> integral
    mapping(address => mapping(address => uint256)) public rewardIntegralFor;
    // claimant -> default reward receiver
    mapping(address => address) public rewardsReceiver;
    address public factory;

    struct Reward {
        address token;
        address distributor;
        uint256 periodFinish;
        uint256 rate;
        uint256 lastUpdate;
        uint256 integral;
    }

    // Claim pending rewards and checkpoint rewards for a user
    struct CheckPointRewardsVars {
        uint256 userBalance;
        address receiver;
        uint256 _rewardCount;
        address token;
        uint256 integral;
        uint256 lastUpdate;
        uint256 duration;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event AddReward(address indexed sender, address indexed rewardToken, address indexed distributorAddress);
    event ChangeRewardDistributor(
        address sender,
        address indexed rewardToken,
        address indexed newDistributorAddress,
        address oldDistributorAddress
    );

    constructor() {
        factory = address(0xdead);
    }

    // called once by the factory at time of deployment
    function initialize(address _lpAddr, address _minter, address _permit2Address, address _owner) external {
        require(factory == address(0), "GP002");
        // sufficient check
        factory = msg.sender;

        _init(_lpAddr, _minter, _owner);

        permit2Address = _permit2Address;
        symbol = IERC20Metadata(_lpAddr).symbol();
        decimals = IERC20Metadata(_lpAddr).decimals();
        name = string(abi.encodePacked(symbol, " Gauge"));
    }

    /***
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _addr Address to deposit for
     */
    function _deposit(
        uint256 _value,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature,
        address _addr,
        bool _claimRewards_
    ) private {
        _checkpoint(_addr);

        if (_value != 0) {
            bool isRewards = rewardCount != 0;
            uint256 _totalSupply = totalSupply;
            if (isRewards) {
                _checkpointRewards(_addr, _totalSupply, _claimRewards_, address(0));
            }

            _totalSupply += _value;
            uint256 newBalance = balanceOf[_addr] + _value;
            balanceOf[_addr] = newBalance;
            totalSupply = _totalSupply;

            _updateLiquidityLimit(_addr, newBalance, _totalSupply);

            TransferHelper.doTransferIn(permit2Address, lpToken, _value, msg.sender, _nonce, _deadline, _signature);
        }

        emit Deposit(_addr, _value);
        emit Transfer(address(0), _addr, _value);
    }

    /***
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _nonce
     * @param _deadline
     * @param _signature
     */
    function deposit(uint256 _value, uint256 _nonce, uint256 _deadline, bytes memory _signature) external nonReentrant {
        _deposit(_value, _nonce, _deadline, _signature, msg.sender, false);
    }

    /***
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _nonce
     * @param _deadline
     * @param _signature
     * @param _addr Address to deposit for
     */
    function deposit(uint256 _value, uint256 _nonce, uint256 _deadline, bytes memory _signature, address _addr) external nonReentrant {
        _deposit(_value, _nonce, _deadline, _signature, _addr, false);
    }

    /***
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _nonce
     * @param _deadline
     * @param _signature
     * @param _addr Address to deposit for
     * @param _claimRewards_ receiver
     */
    function deposit(
        uint256 _value,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature,
        address _addr,
        bool _claimRewards_
    ) external nonReentrant {
        _deposit(_value, _nonce, _deadline, _signature, _addr, _claimRewards_);
    }

    /***
     * @notice Withdraw `_value` LP tokens
     * @dev Withdrawing also claims pending reward tokens
     * @param _value Number of tokens to withdraw
     */
    function _withdraw(uint256 _value, bool _claimRewards_) private {
        _checkpoint(msg.sender);

        if (_value != 0) {
            bool isRewards = rewardCount != 0;
            uint256 _totalSupply = totalSupply;
            if (isRewards) {
                _checkpointRewards(msg.sender, _totalSupply, _claimRewards_, address(0));
            }

            _totalSupply -= _value;
            uint256 newBalance = balanceOf[msg.sender] - _value;
            balanceOf[msg.sender] = newBalance;
            totalSupply = _totalSupply;

            _updateLiquidityLimit(msg.sender, newBalance, _totalSupply);

            TransferHelper.doTransferOut(lpToken, msg.sender, _value);
        }

        emit Withdraw(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }

    function withdraw(uint256 _value) external nonReentrant {
        _withdraw(_value, false);
    }

    function withdraw(uint256 _value, bool _claimRewards_) external nonReentrant {
        _withdraw(_value, _claimRewards_);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        _checkpoint(_from);
        _checkpoint(_to);
        if (_value != 0) {
            uint256 _totalSupply = totalSupply;
            bool isRewards = rewardCount != 0;
            if (isRewards) {
                _checkpointRewards(_from, _totalSupply, false, address(0));
            }
            uint256 newBalance = balanceOf[_from] - _value;
            balanceOf[_from] = newBalance;
            _updateLiquidityLimit(_from, newBalance, _totalSupply);

            if (isRewards) {
                _checkpointRewards(_to, _totalSupply, false, address(0));
            }
            newBalance = balanceOf[_to] + _value;
            balanceOf[_to] = newBalance;
            _updateLiquidityLimit(_to, newBalance, _totalSupply);
        }

        emit Transfer(_from, _to, _value);
    }

    /***
     * @notice Transfer token for a specified address
     * @dev Transferring claims pending reward tokens for the sender and receiver
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) external nonReentrant returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /***
    * @notice Transfer tokens from one address to another.
    * @dev Transferring claims pending reward tokens for the sender and receiver
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    """
    */
    function transferFrom(address _from, address _to, uint256 _value) external nonReentrant returns (bool) {
        uint256 _allowance = allowance[_from][msg.sender];
        if (_allowance != type(uint256).max) {
            allowance[_from][msg.sender] = _allowance - _value;
        }

        _transfer(_from, _to, _value);
        return true;
    }

    /***
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "CE000");
        require(spender != address(0), "CE000");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /***
     * @notice Approve the passed address to transfer the specified amount of
            tokens on behalf of msg.sender
     * @dev Beware that changing an allowance via this method brings the risk
         that someone may use both the old and new allowance by unfortunate
         transaction ordering. This may be mitigated with the use of
         {incraseAllowance} and {decreaseAllowance}.
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will transfer the funds
     * @param _value The amount of tokens that may be transferred
     * @return bool success
    */
    function approve(address _spender, uint256 _value) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, _spender, _value);
        return true;
    }

    /***
     * @notice Increase the allowance granted to `_spender` by the caller
     * @dev This is alternative to {approve} that can be used as a mitigation for the potential race condition
     * @param _spender The address which will transfer the funds
     * @param _addedValue The amount of to increase the allowance
     * @return bool success
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, _spender, allowance[owner][_spender] + _addedValue);
        return true;
    }

    /***
     * @notice Decrease the allowance granted to `_spender` by the caller
     * @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
     * @param _spender The address which will transfer the funds
     * @param _subtractedValue The amount of to decrease the allowance
     * @return bool success
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance[owner][_spender];
        require(currentAllowance >= _subtractedValue, "GP003");
        unchecked {
            _approve(owner, _spender, currentAllowance - _subtractedValue);
        }
        return true;
    }

    /***
     * @notice Set the active reward contract
     */
    function addReward(address _rewardToken, address _distributor) external onlyOwner {
        uint256 _rewardCount = rewardCount;
        require(_rewardCount < _MAX_REWARDS, "GP004");
        require(rewardData[_rewardToken].distributor == address(0), "GP005");
        rewardData[_rewardToken].distributor = _distributor;
        rewardTokens[_rewardCount] = _rewardToken;
        rewardCount = _rewardCount + 1;
        emit AddReward(msg.sender, _rewardToken, _distributor);
    }

    function setRewardDistributor(address _rewardToken, address _distributor) external {
        address currentDistributor = rewardData[_rewardToken].distributor;
        require(msg.sender == currentDistributor || msg.sender == owner(), "GP006");
        require(currentDistributor != address(0), "GP007");
        require(_distributor != address(0), "GP008");
        rewardData[_rewardToken].distributor = _distributor;
        emit ChangeRewardDistributor(msg.sender, _rewardToken, _distributor, currentDistributor);
    }

    function depositRewardToken(address _rewardToken, uint256 _amount) external payable nonReentrant {
        require(msg.sender == rewardData[_rewardToken].distributor, "GP009");

        _checkpointRewards(address(0), totalSupply, false, address(0));

        uint256 spendAmount = TransferHelper.doTransferFrom(_rewardToken, msg.sender, address(this), _amount);

        uint256 periodFinish = rewardData[_rewardToken].periodFinish;
        if (block.timestamp >= periodFinish) {
            rewardData[_rewardToken].rate = spendAmount / _WEEK;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardData[_rewardToken].rate;
            rewardData[_rewardToken].rate = (spendAmount + leftover) / _WEEK;
        }

        rewardData[_rewardToken].lastUpdate = block.timestamp;
        rewardData[_rewardToken].periodFinish = block.timestamp + _WEEK;
    }

    function _checkpointRewards(address _user, uint256 _totalSupply, bool _claim, address _receiver) internal {
        CheckPointRewardsVars memory vars;
        vars.userBalance = 0;
        vars.receiver = _receiver;
        if (_user != address(0)) {
            vars.userBalance = balanceOf[_user];
            if (_claim && _receiver == address(0)) {
                // if receiver is not explicitly declared, check if a default receiver is set
                vars.receiver = rewardsReceiver[_user];
                if (vars.receiver == address(0)) {
                    // if no default receiver is set, direct claims to the user
                    vars.receiver = _user;
                }
            }
        }

        vars._rewardCount = rewardCount;
        for (uint256 i = 0; i < _MAX_REWARDS; i++) {
            if (i == vars._rewardCount) {
                break;
            }
            vars.token = rewardTokens[i];

            vars.integral = rewardData[vars.token].integral;
            vars.lastUpdate = Math.min(block.timestamp, rewardData[vars.token].periodFinish);
            vars.duration = vars.lastUpdate - rewardData[vars.token].lastUpdate;
            if (vars.duration != 0) {
                rewardData[vars.token].lastUpdate = vars.lastUpdate;
                if (_totalSupply != 0) {
                    vars.integral += (vars.duration * rewardData[vars.token].rate * 10 ** 18) / _totalSupply;
                    rewardData[vars.token].integral = vars.integral;
                }
            }

            if (_user != address(0)) {
                uint256 _integralFor = rewardIntegralFor[vars.token][_user];
                uint256 newClaimable = 0;

                if (_integralFor < vars.integral) {
                    rewardIntegralFor[vars.token][_user] = vars.integral;
                    newClaimable = (vars.userBalance * (vars.integral - _integralFor)) / 10 ** 18;
                }

                uint256 _claimData = claimData[_user][vars.token];
                uint256 totalClaimable = (_claimData >> 128) + newClaimable;
                // shift(claim_data, -128)
                if (totalClaimable > 0) {
                    uint256 totalClaimed = _claimData % 2 ** 128;
                    if (_claim) {
                        claimData[_user][vars.token] = totalClaimed + totalClaimable;
                        TransferHelper.doTransferOut(vars.token, vars.receiver, totalClaimable);
                    } else if (newClaimable > 0) {
                        claimData[_user][vars.token] = totalClaimed + (totalClaimable << 128);
                    }
                }
            }
        }
    }

    /***
     * @notice Get the number of already-claimed reward tokens for a user
     * @param _addr Account to get reward amount for
     * @param _token Token to get reward amount for
     * @return uint256 Total amount of `_token` already claimed by `_addr`
     */
    function claimedReward(address _addr, address _token) external view returns (uint256) {
        return claimData[_addr][_token] % 2 ** 128;
    }

    /***
     * @notice Get the number of claimable reward tokens for a user
     * @param _user Account to get reward amount for
     * @param _reward_token Token to get reward amount for
     * @return uint256 Claimable reward token amount
     */
    function claimableReward(address _user, address _reward_token) external view returns (uint256) {
        uint256 integral = rewardData[_reward_token].integral;
        uint256 _totalSupply = totalSupply;
        if (_totalSupply != 0) {
            uint256 lastUpdate = Math.min(block.timestamp, rewardData[_reward_token].periodFinish);
            uint256 duration = lastUpdate - rewardData[_reward_token].lastUpdate;
            integral += ((duration * rewardData[_reward_token].rate * 10 ** 18) / _totalSupply);
        }

        uint256 integralFor = rewardIntegralFor[_reward_token][_user];
        uint256 newClaimable = (balanceOf[_user] * (integral - integralFor)) / 10 ** 18;

        return (claimData[_user][_reward_token] >> 128) + newClaimable;
    }

    /***
     * @notice Set the default reward receiver for the caller.
     * @dev When set to ZERO_ADDRESS, rewards are sent to the caller
     * @param _receiver Receiver address for any rewards claimed via `claim_rewards`
     */
    function setRewardsReceiver(address _receiver) external {
        rewardsReceiver[msg.sender] = _receiver;
    }

    /**
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external onlyOwner {
        require(newAddress != address(0), "CE000");
        address oldAddress = permit2Address;
        permit2Address = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }

    /***
     * @notice Claim available reward tokens for `_addr`
     * @param _addr Address to claim for
     * @param _receiver Address to transfer rewards to - if set to
                     ZERO_ADDRESS, uses the default reward receiver
                     for the caller
     */
    function _claimRewards(address _addr, address _receiver) private {
        if (_receiver != address(0)) {
            require(_addr == msg.sender, "GP011");
            // dev: cannot redirect when claiming for another user
        }
        _checkpointRewards(_addr, totalSupply, true, _receiver);
    }

    function claimRewards() external nonReentrant {
        _claimRewards(msg.sender, address(0));
    }

    function claimRewards(address _addr) external nonReentrant {
        _claimRewards(_addr, address(0));
    }

    function claimRewards(address _addr, address _receiver) external nonReentrant {
        _claimRewards(_addr, _receiver);
    }

    function lpBalanceOf(address addr) public view override returns (uint256) {
        return balanceOf[addr];
    }

    function lpTotalSupply() public view override returns (uint256) {
        return totalSupply;
    }
}