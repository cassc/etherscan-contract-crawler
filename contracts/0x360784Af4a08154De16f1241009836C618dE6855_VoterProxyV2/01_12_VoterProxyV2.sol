// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Interfaces/IGauge.sol";
import "./Interfaces/IVoteEscrow.sol";
import "./Interfaces/IDeposit.sol";
import "./Interfaces/IFeeDistro.sol";
import "./Interfaces/IVoting.sol";
import "./Interfaces/ITokenMinter.sol";

contract VoterProxyV2 is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMath for uint256;

    address public veAsset;
    address public escrow;
    address public gaugeProxy;
    address public minter;

    address public owner;
    address public operator;
    address public depositor;
    string public name;
    IVoteEscrow.EscrowModle public escrowModle;

    mapping(address => bool) private protectedTokens;
    mapping(address => bool) private stashPool;
    mapping(bytes32 => bool) private votes;

    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

    event VoteSet(bytes32 hash, bool valid);

    function __VoterProxyV2_init(
        string memory _name,
        address _veAsset,
        address _escrow,
        address _gaugeProxy,
        address _minter,
        IVoteEscrow.EscrowModle _escrowModle
    ) external {
        name = _name;
        veAsset = _veAsset;
        escrow = _escrow;
        gaugeProxy = _gaugeProxy;
        owner = msg.sender;
        minter = _minter;
        escrowModle = _escrowModle;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;
    }

    function setOperator(address _operator) external {
        require(msg.sender == owner, "!auth");
        require(
            operator == address(0) || IDeposit(operator).isShutdown() == true,
            "needs shutdown"
        );

        operator = _operator;
    }

    function setDepositor(address _depositor) external {
        require(msg.sender == owner, "!auth");

        depositor = _depositor;
    }

    function setStashAccess(address _stash, bool _status) external returns (bool) {
        require(msg.sender == operator, "!auth");
        if (_stash != address(0)) {
            stashPool[_stash] = _status;
        }
        return true;
    }

    function deposit(address _token, address _gauge) external returns (bool) {
        require(msg.sender == operator, "!auth");
        if (protectedTokens[_token] == false) {
            protectedTokens[_token] = true;
        }
        if (protectedTokens[_gauge] == false) {
            protectedTokens[_gauge] = true;
        }
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        if (balance > 0) {
            IERC20Upgradeable(_token).safeApprove(_gauge, 0);
            IERC20Upgradeable(_token).safeApprove(_gauge, balance);
            IGauge(_gauge).deposit(balance);
        }
        return true;
    }

    //stash only function for pulling extra incentive reward tokens out
    function withdraw(IERC20Upgradeable _asset) external returns (uint256 balance) {
        require(stashPool[msg.sender] == true, "!auth");

        //check protection
        if (protectedTokens[address(_asset)] == true) {
            return 0;
        }

        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(msg.sender, balance);
        return balance;
    }

    // Withdraw partial funds
    function withdraw(
        address _token,
        address _gauge,
        uint256 _amount
    ) public returns (bool) {
        require(msg.sender == operator, "!auth");
        uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_gauge, _amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
        return true;
    }

    function withdrawAll(address _token, address _gauge) external returns (bool) {
        require(msg.sender == operator, "!auth");
        uint256 amount = balanceOfPool(_gauge).add(
            IERC20Upgradeable(_token).balanceOf(address(this))
        );
        withdraw(_token, _gauge, amount);
        return true;
    }

    function _withdrawSome(address _gauge, uint256 _amount)
        internal
        returns (uint256 _actualAmount)
    {
        _actualAmount = _amount;

        if (escrowModle == IVoteEscrow.EscrowModle.ANGLE) {
            try IGauge(_gauge).scaling_factor() {
                _amount = _amount.mul(IGauge(_gauge).scaling_factor()).div(10**18);
                _actualAmount = _amount.mul(10**18).div(IGauge(_gauge).scaling_factor());
            } catch {}
        }

        IGauge(_gauge).withdraw(_amount);

        return _actualAmount;
    }

    function createLock(uint256 _value, uint256 _unlockTime) external returns (bool) {
        require(msg.sender == depositor, "!auth");
        IERC20Upgradeable(veAsset).safeApprove(escrow, 0);
        IERC20Upgradeable(veAsset).safeApprove(escrow, _value);
        IVoteEscrow(escrow).create_lock(_value, _unlockTime);
        return true;
    }

    function increaseAmount(uint256 _value) external returns (bool) {
        require(msg.sender == depositor, "!auth");
        IERC20Upgradeable(veAsset).safeApprove(escrow, 0);
        IERC20Upgradeable(veAsset).safeApprove(escrow, _value);
        IVoteEscrow(escrow).increase_amount(_value);
        return true;
    }

    function increaseTime(uint256 _value) external returns (bool) {
        require(msg.sender == depositor, "!auth");
        IVoteEscrow(escrow).increase_unlock_time(_value);
        return true;
    }

    function release() external returns (bool) {
        require(msg.sender == depositor, "!auth");
        IVoteEscrow(escrow).withdraw();
        return true;
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
        if (votes[_hash]) {
            return EIP1271_MAGIC_VALUE;
        } else {
            return 0xffffffff;
        }
    }

    function voteGaugeWeight(address[] calldata _tokenVote, uint256[] calldata _weight)
        external
        returns (bool)
    {
        require(msg.sender == operator, "!auth");

        for (uint256 i = 0; i < _tokenVote.length; i++) {
            IVoting(gaugeProxy).vote_for_gauge_weights(_tokenVote[i], _weight[i]);
        }

        return true;
    }

    function claimVeAsset(address _gauge) external returns (uint256) {
        require(msg.sender == operator, "!auth");

        uint256 _balance = 0;

        if (escrowModle == IVoteEscrow.EscrowModle.IDLE) {
            try ITokenMinter(minter).distribute(_gauge) {} catch {
                return _balance;
            }
        } else if (escrowModle == IVoteEscrow.EscrowModle.ANGLE) {
            try IGauge(_gauge).claim_rewards() {} catch {
                return _balance;
            }
        }

        _balance = IERC20Upgradeable(veAsset).balanceOf(address(this));
        IERC20Upgradeable(veAsset).safeTransfer(operator, _balance);

        return _balance;
    }

    function claimRewards(address _gauge) external returns (bool) {
        require(msg.sender == operator, "!auth");
        IGauge(_gauge).claim_rewards();
        return true;
    }

    function claimFees(address _distroContract, address _token) external returns (uint256) {
        require(msg.sender == operator, "!auth");
        IFeeDistro(_distroContract).claim();
        uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(operator, _balance);
        return _balance;
    }

    function balanceOfPool(address _gauge) public view returns (uint256 _balance) {
        _balance = IGauge(_gauge).balanceOf(address(this));

        if (escrowModle == IVoteEscrow.EscrowModle.ANGLE) {
            try IGauge(_gauge).scaling_factor() {
                _balance = _balance.mul(10**18).div(IGauge(_gauge).scaling_factor());
            } catch {}
        }

        return _balance;
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory) {
        require(msg.sender == operator, "!auth");

        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "!success");

        return (success, result);
    }
}