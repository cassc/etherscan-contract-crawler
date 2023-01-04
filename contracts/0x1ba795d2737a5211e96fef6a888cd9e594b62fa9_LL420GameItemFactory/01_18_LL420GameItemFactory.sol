//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game In-Game Item Factory
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./interfaces/ILL420G0BudLock.sol";
import "./interfaces/ILL420GameItem.sol";
import "./interfaces/ILL420Wallet.sol";
import "./utils/Error.sol";

contract LL420GameItemFactory is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;
    ILL420GameItem public gameItem;

    uint256 public constant DECIMAL_FACTOR = 100;
    uint256 public constant ROLL_PAPER_ID = 1;
    uint256 public constant HOODIE_ID = 2;
    uint256 public constant SERUM_ID = 3;
    uint256 public constant FARMER_PASS_ID = 4;
    uint256 public constant DR_PASS_ID = 5;
    uint256 public constant MAX_PER_TX = 3;
    uint256 public constant OG_TOKEN_ID = 1;
    uint256 public constant MAX_PER_WALLET = 3;

    address public walletAddress;
    address public lockAddress;
    address public ogPassAddress;
    address private _validator;
    uint256 public tokenCount;
    bytes32 public merkleRoot;
    bool public isOGMint;

    mapping(uint256 => uint256) public supplies;
    mapping(uint256 => uint256) public supplyCaps;
    mapping(uint256 => uint256) public prices;
    mapping(address => uint256) public lastMinted;
    mapping(address => uint256) public mintedPerWallet;

    /* ==================== Additional Slots ==================== */

    address public ogTokenAddress;

    /* ==================== METHODS ==================== */

    function initialize(
        address _gameItem,
        address _wallet,
        address _ogPass,
        address _account,
        address _lock,
        bytes32 _ogRoot
    ) external initializer {
        __Context_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        gameItem = ILL420GameItem(_gameItem);

        _validator = _account;
        walletAddress = _wallet;
        lockAddress = _lock;
        ogPassAddress = _ogPass;
        merkleRoot = _ogRoot;

        // [420, 200, 350, 2700, 1000]
        supplyCaps[1] = 420;
        supplyCaps[2] = 200;
        supplyCaps[3] = 350;
        supplyCaps[4] = 2700;
        supplyCaps[5] = 1000;

        // [12600, 42000, 70000, 35000, 42500]
        prices[1] = 12600;
        prices[2] = 42000;
        prices[3] = 70000;
        prices[4] = 35000;
        prices[5] = 42500;

        tokenCount = 5;

        // only OGs can mint
        isOGMint = true;

        // pause
        _pause();
    }

    /**
     * @dev The function allows to buy game items with wallet balance
     *
     * @param _to Game item will be sent to this address
     * @param _id Game item id 2 - 3
     * @param _amount Amount to mint
     * @param _timestamp Timestamp to verify the signature
     * @param _signature Signature is generated from LL backend.
     */
    function buy(
        address _to,
        uint256 _id,
        uint256 _amount,
        uint256 _timestamp,
        bytes memory _signature,
        bytes32[] memory _ogProof
    ) external nonReentrant whenNotPaused {
        // 1. check sender and og mint status
        if (_msgSender() != _to || !canMint(_msgSender())) revert InvalidSender();

        // 2. check if user minted more than max limit
        uint256 mintedAmount = mintedPerWallet[_to];
        uint256 taken = (mintedAmount >> ((_id - 1) * 4)) % 16;
        if (taken + _amount > maxPerWallet(_id) || _amount == 0 || _amount > MAX_PER_TX) revert InvalidAmount();

        // 2.1. update storage with user's round mintedPerWallet
        mintedAmount += (_amount << ((_id - 1) * 4));
        mintedPerWallet[_to] = mintedAmount;

        // 3. check if signature is valid
        if (!_verify(_to, _id, _amount, _timestamp, _signature)) revert FailedVerify();

        // 4. timestamp should be newer and cant use old
        if (lastMinted[_to] >= _timestamp) revert InvalidTimestamp();
        // 4.1. update last minted timestamp
        lastMinted[_to] = _timestamp;

        // 5. additional logic to check mint requirement of each item
        if (_check(_id)) revert WrongCondition();

        // 6. check if user is in og snapshot
        bytes32 node = keccak256(abi.encodePacked(_to));
        bool isOGVerified = MerkleProofUpgradeable.verify(_ogProof, merkleRoot, node);
        if (isOGMint && isOGVerified) revert VerifyFailed();

        // 7. check in-game wallet balance
        ILL420Wallet wallet = ILL420Wallet(walletAddress);
        uint256 totalPrice = prices[_id] * _amount;
        if (wallet.balance(_to) < totalPrice) revert NotEnoughBalance();
        wallet.withdraw(_to, totalPrice);

        // mint game item
        _mint(_to, _id, _amount, "");
    }

    /* ==================== VIEW METHODS ==================== */

    /**
     * @dev check if user is in public or og mint
     */
    function canMint(address who) public view returns (bool) {
        if (isOGMint) {
            return
                IERC1155Upgradeable(ogPassAddress).balanceOf(who, OG_TOKEN_ID) > 0 ||
                IERC20Upgradeable(ogTokenAddress).balanceOf(who) > 0;
        }
        return true;
    }

    /**
     * @dev check if user can buy the amount of token with id
     *
     * @param _user User address
     * @param _id Token id
     * @param _amount Token amount
     */
    function eligibleToBuy(
        address _user,
        uint256 _id,
        uint256 _amount
    ) external view returns (bool) {
        if (_amount == 0 || _amount > MAX_PER_TX) revert InvalidAmount();
        if (_id == ROLL_PAPER_ID) {
            ILL420G0BudLock locker = ILL420G0BudLock(lockAddress);
            uint256 burnt = locker.burntAmount(_user);
            if (burnt < 2) return false;
        }

        ILL420Wallet wallet = ILL420Wallet(walletAddress);
        uint256 totalPrice = prices[_id] * _amount;

        if (wallet.balance(_user) > totalPrice) return true;
        return false;
    }

    /**
     * @dev return the max mintable amount per wallet based on token id
     *
     * @param id token id
     */
    function maxPerWallet(uint256 id) public pure returns (uint256 max) {
        if (id == ROLL_PAPER_ID) max = 2;
        else if (id == HOODIE_ID) max = 1;
        else if (id == SERUM_ID) max = MAX_PER_WALLET;
        else if (id == FARMER_PASS_ID) max = MAX_PER_WALLET;
        else if (id == DR_PASS_ID) max = MAX_PER_WALLET;
        else max = 0;
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev additional check logic of mint requirement
     */
    function _check(uint256 _id) internal view returns (bool) {
        if (_id == ROLL_PAPER_ID) {
            ILL420G0BudLock locker = ILL420G0BudLock(lockAddress);
            uint256 burnt = locker.burntAmount(_msgSender());
            if (burnt < 2) return true;
        }
        return false;
    }

    /**
     * @dev mint game item from GameItem contract
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (supplies[id] + amount > supplyCaps[id]) revert SupplyLimit();

        supplies[id] += amount;
        gameItem.mint(to, id, amount, data);
    }

    /**
     * @dev Verify if the signature is right and available to mint
     *
     * @param _to Game Item will be sent to this address
     * @param _id Game item id 0 - 3
     * @param _amount Amount to mint
     * @param _timestamp Timestamp to verify the signature
     * @param _signature Signature is generated from LL backend
     */
    function _verify(
        address _to,
        uint256 _id,
        uint256 _amount,
        uint256 _timestamp,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 signedHash = keccak256(abi.encodePacked(_to, keccak256("GameItem"), _id, _amount, _timestamp));
        bytes32 messageHash = signedHash.toEthSignedMessageHash();
        address messageSender = messageHash.recover(_signature);

        if (messageSender != _validator) return false;

        return true;
    }

    /* ==================== OWNER METHODS ==================== */
    /**
     * @dev Owner can update the supply capacity of each items
     *
     * @param _caps Array of game item capacities
     */
    function setSupply(uint256[] memory _caps) external onlyOwner {
        tokenCount = _caps.length;
        for (uint256 i = 1; i <= _caps.length; i++) {
            supplyCaps[i] = _caps[i];
        }
    }

    /**
     * @dev Owner can update the each item price
     *
     * @param _prices Array of game item price
     */
    function setPrice(uint256[] memory _prices) external onlyOwner {
        for (uint256 i = 1; i <= _prices.length; i++) {
            prices[i] = _prices[i];
        }
    }

    /**
     * @dev Owner can set wallet contract address
     *
     * @param _wallet Address of wallet smart contract
     */
    function setWalletAddress(address _wallet) external onlyOwner {
        walletAddress = _wallet;
    }

    /**
     * @dev Owner can set wallet contract address
     *
     * @param _address Address of wallet smart contract
     */
    function setLockAddress(address _address) external onlyOwner {
        lockAddress = _address;
    }

    /**
     * @dev Owner can set public/og mint status
     *
     * @param status true/false
     */
    function setOGMint(bool status) external onlyOwner {
        isOGMint = status;
    }

    /**
     * @dev Owner can update og merkle root
     *
     * @param _root new merkle root
     */
    function setOGMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    /**
     * @dev Owner can unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Owner can set og token contract address
     */
    function setOgTokenAddress(address ogToken) external onlyOwner {
        ogTokenAddress = ogToken;
    }
}