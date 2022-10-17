// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/Interfaces.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   VoterProxy
 * @author  ConvexFinance -> WombexFinance
 * @notice  VoterProxy whitelisted in the Wombat veWOM whitelist that
 *          participates in Wombat governance. Also handles all deposits since this is
 *          the address that has the voting power.
 */
contract VoterProxy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable wom;
    address public immutable veWom;
    address public weth;

    address public rewardDeposit;
    address public withdrawer;

    address public owner;
    address public operator;
    address public depositor;

    mapping (address => bool) public protectedTokens;
    mapping (bytes32 => bool) public votes;
    mapping (address => mapping (address => uint256)) public lpTokenToPid;
    mapping (address => mapping (address => bool)) public lpTokenPidSet;
    mapping (address => address[]) public gaugeLpTokens;

    bytes4 constant internal EIP1271_MAGIC_VALUE = 0x1626ba7e;

    event SetOwner(address newOwner);
    event SetGaugeLpTokenPid(address gauge, address lptoken, uint256 pid);
    event SetRewardDeposit(address withdrawer, address rewardDeposit);
    event SetDepositor(address depositor);
    event SetOperator(address operator);
    event Deposit(address lptoken, address gauge, uint256 value);
    event Lock(uint256 amount, uint256 lockDays);
    event ReleaseLock(uint256 amount, uint256 slot);
    event Withdraw(address asset, uint256 balance);
    event VoteSet(bytes32 hash, bool valid);

    /**
     * @param _wom              WOM Token address
     * @param _veWom            veWOM address
     *
     */
    constructor(
        address _wom,
        address _veWom,
        address _weth
    ) public {
        wom = _wom;
        veWom = _veWom;
        weth = _weth;
        owner = msg.sender;

        protectedTokens[_wom] = true;
        protectedTokens[_veWom] = true;

        IERC20(_wom).safeApprove(_veWom, type(uint256).max);
    }

    receive() external payable {}

    function getName() external pure returns (string memory) {
        return "WombexVoterProxy";
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;
        emit SetOwner(_owner);
    }

    /**
     * @notice Set lp tokens pid
     * @param _gauge masterWombat address
     */
    function setLpTokensPid(address _gauge) external {
        require(msg.sender == owner, "!auth");
        uint256 poolLength = IMasterWombat(_gauge).poolLength();

        for (uint256 i = 0; i < poolLength; i++) {
            (address lpToken, , , , , , ) = IMasterWombat(_gauge).poolInfo(i);
            lpTokenToPid[_gauge][lpToken] = i;
            if (!lpTokenPidSet[_gauge][lpToken]) {
                gaugeLpTokens[_gauge].push(lpToken);
                lpTokenPidSet[_gauge][lpToken] = true;
                emit SetGaugeLpTokenPid(_gauge, lpToken, i);
            }
        }
    }

    /**
     * @notice Allows dao to set the reward withdrawal address
     * @param _withdrawer Whitelisted withdrawer
     * @param _rewardDeposit Distributor address
     */
    function setRewardDeposit(address _withdrawer, address _rewardDeposit) external {
        require(msg.sender == owner, "!auth");
        withdrawer = _withdrawer;
        rewardDeposit = _rewardDeposit;
        emit SetRewardDeposit(_withdrawer, _rewardDeposit);
    }

    /**
     * @notice Set the operator of the VoterProxy
     * @param _operator Address of the operator (Booster)
     */
    function setOperator(address _operator) external {
        require(msg.sender == owner, "!auth");

        operator = _operator;
        emit SetOperator(_operator);
    }

    /**
     * @notice Set the depositor of the VoterProxy
     * @param _depositor Address of the depositor (womDepositor)
     */
    function setDepositor(address _depositor) external {
        require(msg.sender == owner, "!auth");

        depositor = _depositor;
        emit SetDepositor(_depositor);
    }

    /**
     * @notice Save a vote hash so when snapshot.org asks this contract if
     *          a vote signature is valid we are able to check for a valid hash
     *          and return the appropriate response inline with EIP 1721
     * @param _hash  Hash of vote signature that was sent to snapshot.org
     * @param _valid Is the hash valid
     */
    function setVote(bytes32 _hash, bool _valid) external {
        require(msg.sender == operator, "!auth");
        votes[_hash] = _valid;
        emit VoteSet(_hash, _valid);
    }

    /**
     * @notice  Verifies that the hash is valid
     * @dev     Snapshot Hub will call this function when a vote is submitted using
     *          snapshot.js on behalf of this contract. Snapshot Hub will call this
     *          function with the hash and the signature of the vote that was cast.
     * @param _hash Hash of the message that was sent to Snapshot Hub to cast a vote
     * @return EIP1271 magic value if the signature is value
     */
    function isValidSignature(bytes32 _hash, bytes memory) public view returns (bytes4) {
        if(votes[_hash]) {
            return EIP1271_MAGIC_VALUE;
        } else {
            return 0xffffffff;
        }
    }

    /**
     * @notice  Deposit tokens into the Curve Gauge
     * @dev     Only can be called by the operator (Booster) once this contract has been
     *          whitelisted by the Curve DAO
     * @param _lptoken  Deposit LP token address
     * @param _gauge  Gauge contract to deposit to
     */
    function deposit(address _lptoken, address _gauge) external returns(bool){
        require(lpTokenPidSet[_gauge][_lptoken], "!lp_token_set");
        require(msg.sender == operator, "!auth");
        if (!protectedTokens[_lptoken]){
            protectedTokens[_lptoken] = true;
        }
        if (!protectedTokens[_gauge]){
            protectedTokens[_gauge] = true;
        }
        uint256 balance = IERC20(_lptoken).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_lptoken).safeApprove(_gauge, 0);
            IERC20(_lptoken).safeApprove(_gauge, balance);
            IMasterWombat(_gauge).deposit(lpTokenToPid[_gauge][_lptoken], balance);
        }
        emit Deposit(_lptoken, _gauge, balance);
        return true;
    }

    /**
     * @notice  Lock WOM in veWOM contract
     * @dev     Called by the WomDepositor contract
     * @param _lockDays      Amount of days to lock
     */
    function lock(uint256 _lockDays) external returns(bool){
        require(msg.sender == depositor, "!auth");

        uint256 balance = IERC20(wom).balanceOf(address(this));
        IVeWom(veWom).mint(balance, _lockDays);

        emit Lock(balance, _lockDays);
        return true;
    }

    /**
     * @notice  Release WOM from veWOM contract
     * @dev     Called by the WomDepositor contract
     * @param _slot      Slot to release
     */
    function releaseLock(uint256 _slot) external returns(bool){
        require(msg.sender == depositor, "!auth");

        uint256 balanceBefore = IERC20(wom).balanceOf(address(this));
        IVeWom(veWom).burn(_slot);
        uint256 amount = IERC20(wom).balanceOf(address(this)).sub(balanceBefore);

        IERC20(wom).safeTransfer(msg.sender, amount);

        emit ReleaseLock(amount, _slot);
        return true;
    }

    /**
     * @notice  Withdraw ERC20 tokens that have been distributed as extra rewards
     * @dev     Tokens shouldn't end up here if they can help it. However, dao can
     *          set a withdrawer that can process these to some ExtraRewardDistribution.
     */
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == withdrawer, "!auth");
        require(protectedTokens[address(_asset)] == false, "protected");

        balance = _asset.balanceOf(address(this));
        _asset.safeApprove(rewardDeposit, 0);
        _asset.safeApprove(rewardDeposit, balance);
        IRewardDeposit(rewardDeposit).addReward(address(_asset), balance);
        emit Withdraw(address(_asset), balance);
        return balance;
    }

    /**
     * @notice  Withdraw LP tokens from a gauge
     * @dev     Only callable by the operator
     * @param _lptoken    LP token address
     * @param _gauge    Gauge for this LP token
     * @param _amount   Amount of LP token to withdraw
     */
    function withdrawLp(address _lptoken, address _gauge, uint256 _amount) public returns(bool){
        require(msg.sender == operator, "!auth");
        _withdrawSomeLp(_lptoken, _gauge, _amount);
        IERC20(_lptoken).safeTransfer(msg.sender, IERC20(_lptoken).balanceOf(address(this)));
        return true;
    }

    /**
     * @notice  Withdraw all LP tokens from a gauge
     * @dev     Only callable by the operator
     * @param _lptoken  LP token address
     * @param _gauge  Gauge for this LP token
     */
    function withdrawAllLp(address _lptoken, address _gauge) external returns(bool){
        require(msg.sender == operator, "!auth");
        withdrawLp(_lptoken, _gauge, balanceOfPool(_lptoken, _gauge));
        return true;
    }

    function _withdrawSomeLp(address _lptoken, address _gauge, uint256 _amount) internal returns (uint256) {
        require(lpTokenPidSet[_gauge][_lptoken], "!lp_token_set");
        IMasterWombat(_gauge).withdraw(lpTokenToPid[_gauge][_lptoken], _amount);
        return _amount;
    }

    /**
     * @notice  Claim WOM from Wombat
     * @dev     Claim WOM for LP token staking from the masterWombat contract
     */
    function claimCrv(address _lptoken, address _gauge) external returns (IERC20[] memory tokens) {
        require(msg.sender == operator, "!auth");
        require(lpTokenPidSet[_gauge][_lptoken], "!lp_token_set");
        uint256 pid = lpTokenToPid[_gauge][_lptoken];

        IMasterWombat(_gauge).deposit(pid, 0);
        tokens = getGaugeRewardTokens(_lptoken, _gauge);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (address(tokens[i]) == weth) {
                IWETH(weth).deposit{value: address(this).balance}();
            }
            tokens[i].safeTransfer(operator, tokens[i].balanceOf(address(this)));
        }
    }

    function getGaugeRewardTokens(address _lptoken, address _gauge) public returns (IERC20[] memory tokens) {
        require(lpTokenPidSet[_gauge][_lptoken], "!lp_token_set");
        uint256 pid = lpTokenToPid[_gauge][_lptoken];

        (, , IMasterWombatRewarder rewarder, , , , ) = IMasterWombat(_gauge).poolInfo(pid);

        address[] memory bonusTokenAddresses;
        if (address(rewarder) != address(0)) {
            bonusTokenAddresses = rewarder.rewardTokens();
        }
        tokens = new IERC20[](bonusTokenAddresses.length + 1);

        tokens[0] = IERC20(wom);
        for (uint256 i = 0; i < bonusTokenAddresses.length; i++) {
            IERC20 token = IERC20(bonusTokenAddresses[i]);
            if (address(token) == address(0)) {
                token = IERC20(weth);
            }
            tokens[i + 1] = token;
        }
    }

    function balanceOfPool(address _token, address _gauge) public view returns (uint256 amount) {
        (amount, , ) = IMasterWombat(_gauge).userInfo(lpTokenToPid[_gauge][_token], address(this));
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external payable returns (bool, bytes memory) {
        require(msg.sender == operator, "!auth");
        require(!protectedTokens[_to], "protected");

        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        require(success, "!success");

        return (success, result);
    }

}