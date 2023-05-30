// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IAlpaToken.sol";
import "../interfaces/IAlpaSupplier.sol";
import "../interfaces/ICryptoAlpaca.sol";
import "../interfaces/CryptoAlpacaEnergyListener.sol";

// Alpaca Farm manages your LP and takes good care of you alpaca!
contract AlpacaFarmV2 is
    Ownable,
    ReentrancyGuard,
    ERC1155Receiver,
    CryptoAlpacaEnergyListener
{
    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 amount);

    /* ========== STRUCT ========== */

    // Info of each user.
    struct UserInfo {
        // How many LP tokens the user has provided.
        uint256 amount;
        // Reward debt. What has been paid so far
        uint256 rewardDebt;
        // alpaca user transfered to AlpacaFarm to manage the LP assets
        uint256 alpacaID;
        // alpaca's energy
        uint256 alpacaEnergy;
    }

    // Info of each pool.
    struct PoolInfo {
        // Address of LP token contract.
        IERC20 lpToken;
        // Last block number that ALPAs distribution occurs.
        uint256 lastRewardBlock;
        // Accumulated ALPAs per share. Share is determined by LP deposit and total alpaca's energy
        uint256 accAlpaPerShare;
        // Accumulated Share
        uint256 accShare;
    }

    /* ========== STATES ========== */

    // The ALPA ERC20 token
    IAlpaToken public alpa;

    // Crypto alpaca contract
    ICryptoAlpaca public cryptoAlpaca;

    // Alpa Supplier
    IAlpaSupplier public supplier;

    // Energy if user does not have any alpaca transfered to AlpacaFarm to manage the LP assets
    uint256 public constant EMPTY_ALPACA_ENERGY = 1;

    // farm pool info
    PoolInfo public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    // map that keep tracks of the alpaca's original owner so contract knows where to send back when
    // users swapped or retrieved their alpacas
    EnumerableMap.UintToAddressMap private alpacaOriginalOwner;

    uint256 public constant SAFE_MULTIPLIER = 1e16;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IAlpaToken _alpa,
        ICryptoAlpaca _cryptoAlpaca,
        IAlpaSupplier _supplier,
        IERC20 lpToken,
        uint256 _startBlock
    ) public {
        alpa = _alpa;
        cryptoAlpaca = _cryptoAlpaca;
        supplier = _supplier;
        poolInfo = PoolInfo({
            lpToken: lpToken,
            lastRewardBlock: block.number.max(_startBlock),
            accAlpaPerShare: 0,
            accShare: 0
        });
    }

    /* ========== PUBLIC ========== */

    /**
     * @dev View `_user` pending ALPAs
     */
    function pendingAlpa(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];

        uint256 accAlpaPerShare = poolInfo.accAlpaPerShare;
        uint256 lpSupply = poolInfo.lpToken.balanceOf(address(this));

        if (block.number > poolInfo.lastRewardBlock && lpSupply != 0) {
            uint256 total = supplier.preview(
                address(this),
                poolInfo.lastRewardBlock
            );

            accAlpaPerShare = accAlpaPerShare.add(
                total.mul(SAFE_MULTIPLIER).div(poolInfo.accShare)
            );
        }
        return
            user
                .amount
                .mul(sqrt(_safeUserAlpacaEnergy(user)))
                .mul(accAlpaPerShare)
                .div(SAFE_MULTIPLIER)
                .sub(user.rewardDebt);
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     */
    function updatePool() public {
        if (block.number <= poolInfo.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = poolInfo.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            poolInfo.lastRewardBlock = block.number;
            return;
        }

        uint256 reward = supplier.distribute(poolInfo.lastRewardBlock);
        poolInfo.accAlpaPerShare = poolInfo.accAlpaPerShare.add(
            reward.mul(SAFE_MULTIPLIER).div(poolInfo.accShare)
        );

        poolInfo.lastRewardBlock = block.number;
    }

    /**
     * @dev Retrieve caller's Alpaca.
     */
    function retrieve() public nonReentrant {
        address sender = _msgSender();

        UserInfo storage user = userInfo[sender];
        require(user.alpacaID != 0, "AlpacaFarm: you do not have any alpaca");

        if (user.amount > 0) {
            updatePool();
            uint256 pending = user
                .amount
                .mul(sqrt(user.alpacaEnergy))
                .mul(poolInfo.accAlpaPerShare)
                .div(SAFE_MULTIPLIER)
                .sub(user.rewardDebt);
            if (pending > 0) {
                _safeAlpaTransfer(msg.sender, pending);
            }

            user.rewardDebt = user
                .amount
                .mul(EMPTY_ALPACA_ENERGY)
                .mul(poolInfo.accAlpaPerShare)
                .div(SAFE_MULTIPLIER);

            poolInfo.accShare = poolInfo.accShare.sub(
                (sqrt(user.alpacaEnergy).sub(1)).mul(user.amount)
            );
        }

        uint256 prevAlpacaID = user.alpacaID;
        user.alpacaID = 0;
        user.alpacaEnergy = 0;

        // Remove alpaca id to original user mapping
        alpacaOriginalOwner.remove(prevAlpacaID);

        cryptoAlpaca.safeTransferFrom(
            address(this),
            msg.sender,
            prevAlpacaID,
            1,
            ""
        );
    }

    /**
     * @dev Deposit LP tokens to AlpacaFarm for ALPA allocation.
     */
    function deposit(uint256 _amount) public nonReentrant {
        updatePool();

        UserInfo storage user = userInfo[msg.sender];
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(sqrt(_safeUserAlpacaEnergy(user)))
                .mul(poolInfo.accAlpaPerShare)
                .div(SAFE_MULTIPLIER)
                .sub(user.rewardDebt);
            if (pending > 0) {
                _safeAlpaTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            poolInfo.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            poolInfo.accShare = poolInfo.accShare.add(
                sqrt(_safeUserAlpacaEnergy(user)).mul(_amount)
            );
        }

        user.rewardDebt = user
            .amount
            .mul(sqrt(_safeUserAlpacaEnergy(user)))
            .mul(poolInfo.accAlpaPerShare)
            .div(SAFE_MULTIPLIER);
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev Withdraw LP tokens from AlpacaFarm.
     */
    function withdraw(uint256 _amount) public nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "AlpacaFarm: invalid amount");

        updatePool();
        uint256 pending = user
            .amount
            .mul(sqrt(_safeUserAlpacaEnergy(user)))
            .mul(poolInfo.accAlpaPerShare)
            .div(SAFE_MULTIPLIER)
            .sub(user.rewardDebt);

        if (pending > 0) {
            _safeAlpaTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            poolInfo.lpToken.safeTransfer(address(msg.sender), _amount);
            poolInfo.accShare = poolInfo.accShare.sub(
                sqrt(_safeUserAlpacaEnergy(user)).mul(_amount)
            );
        }

        user.rewardDebt = user
            .amount
            .mul(sqrt(_safeUserAlpacaEnergy(user)))
            .mul(poolInfo.accAlpaPerShare)
            .div(SAFE_MULTIPLIER);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards.
    // EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "AlpacaFarm: insufficient balance");

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        poolInfo.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    /* ========== PRIVATE ========== */

    function _safeUserAlpacaEnergy(UserInfo storage info)
        private
        view
        returns (uint256)
    {
        if (info.alpacaEnergy == 0) {
            return EMPTY_ALPACA_ENERGY;
        }
        return info.alpacaEnergy;
    }

    // Safe alpa transfer function, just in case if rounding error causes pool to not have enough ALPAs.
    function _safeAlpaTransfer(address _to, uint256 _amount) private {
        uint256 alpaBal = alpa.balanceOf(address(this));
        if (_amount > alpaBal) {
            alpa.transfer(_to, alpaBal);
        } else {
            alpa.transfer(_to, _amount);
        }
    }

    /* ========== ERC1155Receiver ========== */

    /**
     * @dev onERC1155Received implementation per IERC1155Receiver spec
     */
    function onERC1155Received(
        address,
        address _from,
        uint256 _id,
        uint256,
        bytes calldata
    ) external override nonReentrant returns (bytes4) {
        require(
            msg.sender == address(cryptoAlpaca),
            "AlpacaFarm: received alpaca from unauthenticated contract"
        );

        require(_id != 0, "AlpacaFarm: invalid alpaca");

        UserInfo storage user = userInfo[_from];

        // Fetch alpaca energy
        (, , , , , , , , , , , uint256 energy, ) = cryptoAlpaca.getAlpaca(_id);
        require(energy > 0, "AlpacaFarm: invalid alpaca energy");

        if (user.amount > 0) {
            updatePool();

            uint256 pending = user
                .amount
                .mul(sqrt(_safeUserAlpacaEnergy(user)))
                .mul(poolInfo.accAlpaPerShare)
                .div(SAFE_MULTIPLIER)
                .sub(user.rewardDebt);
            if (pending > 0) {
                _safeAlpaTransfer(_from, pending);
            }
            // Update user reward debt with new energy
            user.rewardDebt = user
                .amount
                .mul(sqrt(energy))
                .mul(poolInfo.accAlpaPerShare)
                .div(SAFE_MULTIPLIER);

            poolInfo.accShare = poolInfo
                .accShare
                .add(sqrt(energy).mul(user.amount))
                .sub(sqrt(_safeUserAlpacaEnergy(user)).mul(user.amount)); // 减去原来的
        }

        // update user global
        uint256 prevAlpacaID = user.alpacaID;
        user.alpacaID = _id;
        user.alpacaEnergy = energy;

        // keep track of alpaca owner
        alpacaOriginalOwner.set(_id, _from);

        // Give original owner the right to breed
        cryptoAlpaca.grandPermissionToBreed(_from, _id);

        if (prevAlpacaID != 0) {
            // Transfer alpaca back to owner
            cryptoAlpaca.safeTransferFrom(
                address(this),
                _from,
                prevAlpacaID,
                1,
                ""
            );
        }

        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /**
     * @dev onERC1155BatchReceived implementation per IERC1155Receiver spec
     * User should not send using batch.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external override returns (bytes4) {
        require(
            false,
            "AlpacaFarm: only supports transfer single alpaca at a time (e.g safeTransferFrom)"
        );
    }

    /* ========== ICryptoAlpacaEnergyListener ========== */

    /**
        @dev Handles the Alpaca energy change callback.
        @param _id The id of the Alpaca which the energy changed
        @param _newEnergy The new alpaca energy it changed to
    */
    function onCryptoAlpacaEnergyChanged(
        uint256 _id,
        uint256,
        uint256 _newEnergy
    ) external override {
        require(
            msg.sender == address(cryptoAlpaca),
            "AlpacaFarm: received alpaca from unauthenticated contract"
        );

        require(
            alpacaOriginalOwner.contains(_id),
            "AlpacaFarm: original owner not found"
        );

        address originalOwner = alpacaOriginalOwner.get(_id);
        UserInfo storage user = userInfo[originalOwner];

        if (user.amount > 0) {
            updatePool();

            uint256 pending = user
                .amount
                .mul(sqrt(_safeUserAlpacaEnergy(user)))
                .mul(poolInfo.accAlpaPerShare)
                .div(SAFE_MULTIPLIER)
                .sub(user.rewardDebt);

            if (pending > 0) {
                _safeAlpaTransfer(originalOwner, pending);
            }

            // Update user reward debt with new energy
            user.rewardDebt = user
                .amount
                .mul(sqrt(_newEnergy))
                .mul(poolInfo.accAlpaPerShare)
                .div(SAFE_MULTIPLIER);

            poolInfo.accShare = poolInfo
                .accShare
                .add(sqrt(_newEnergy).mul(user.amount))
                .sub(sqrt(_safeUserAlpacaEnergy(user)).mul(user.amount));
        }

        // update alpaca energy
        user.alpacaEnergy = _newEnergy;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    // https://github.com/Uniswap/v2-core/blob/v1.0.1/contracts/libraries/Math.sol
    //function sqrt(uint256 y) internal pure returns (uint256 z) {
    function sqrt(uint256 y) public pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}