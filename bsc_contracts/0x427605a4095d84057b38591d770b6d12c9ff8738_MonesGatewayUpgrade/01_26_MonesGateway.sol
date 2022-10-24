// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


import "./VerifierUpgradeable.sol";

interface IERC20Mintable is IERC20Upgradeable {
    function mint(address _who, uint256 _amount) external;
}

interface IERC721Heroes is IERC721Upgradeable {
    function getTokenIdCounterCurrent() external returns (uint256);
    function mintHero(address account, uint256 heroId) external;
    function updateHero(uint256 nftId, uint256 heroId, uint8 rarity, uint8 star, uint8 level, uint8 enhancement) external;
}

interface IERC721Equipment is IERC721Upgradeable {
    function getTokenIdCounterCurrent() external returns (uint256);
    function mintEquipment(address account, uint256 equipmentId) external;
}

interface IERC1155Equipment is IERC1155Upgradeable {
    function mintMaterial(address _account, uint256 _itemId, uint256 _amount, bytes memory data) external;
}

interface IChest {
    function mint(address _who, uint256 _id, uint256 _amount, bytes memory data) external;
}

contract MonesGatewayUpgrade is Initializable, MonesVerifierUpgradeable, OwnableUpgradeable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    using SafeERC20Upgradeable for IERC20Mintable;

    struct Collection {
        bool status;
        bool isERC1155;
    }

    mapping(address => Collection) private _collections;
    mapping(address => mapping (uint256 => bool)) public isExec;
    mapping(address => uint256) public lastMove;
    uint256 public cooldownDuration;
    bool constant public IS_NEW = true;

    // Upgrade deposit - withdraw fee
    uint256 public depositFee;
    uint256 public withdrawFee;


    address public feeRecipient;
    address public feeReceiver;

    // mones 10% incentive
    address public incentiveSender;
    address public rewardChest;


    event SingleAssetDeposited (address user, address nftAddress, uint256 nftId, uint256 amount);
    event BatchAssetDeposited (address user, address[] nftAddress, uint256[] nftId, uint256[] amount);
    event TokenDeposited (address user, address tokenAddress, uint256 amount);
    event CooldownUpdated(uint256 newCooldown);
    event CollectionUpdated(address collectionAddress, bool status, bool isERC1155);
//
    event ERC20Claimed(address user, address erc20, uint256 amount, uint256 txNonce);
    event ERC721Withdrawed(address user, address nftAddress, uint256 tokenId, uint256 txNonce);
    event ERC721UpgradedAndWithdrawed(address user, address nftAddress, uint256 tokenId, uint256 heroId, uint8 rarity, uint8 star, uint8 level, uint8 enhancement, uint256 txNonce);
    event ERC721Claimed(address user, address nftAddress, uint256 tokenId, uint256 heroId, uint256 txNonce);
    event ERC1155Claimed(address user, address nftAddress, uint256 tokenId, uint256 tokenAmount, uint256 txNonce);
    event ERC1155Withdrawed(address user, address nftAddress, uint256 tokenId, uint256 tokenAmount, uint256 txNonce);

    event AirdropClaimed(address user, address erc20, uint256 amount, uint256 txNonce);
    event ReferIncentiveClaimed(address user, address erc20, uint256 amount, uint256 txNonce);

    event ReferChestClaimed(address user, address chestAddress, uint256 chestId, uint256 amount, uint256 configId, uint256 txNonce);
    event EventChestClaimed(address user, address chestAddress, uint256 chestId, uint256 amount, uint256 configId, uint256 txNonce);
    event WalletChestRewardClaimed(address user, address chestAddress, uint256 chestId, uint256 amount, uint256 txNonce);
    event RewardChestUpdated(address rewardChest);
    event IncentiveSenderUpdated(address sender);

    event MyriadClaimed(address user, address erc20, uint256 amount, uint256 txNonce);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address signer) initializer public {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __SignatureVerifier_init(signer);
        __ERC721Holder_init();
        __ERC1155Holder_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        depositFee = 0.001 ether;
        withdrawFee = 0.001 ether;
    }

    function txHasExecuted(address user, uint256 nonce) public view returns (bool) {
        return isExec[user][nonce];
    }

    function getSigner() external view returns (address) {
        return signer;
    }

    function setupCooldownDuration(uint256 newCooldown) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cooldownDuration = newCooldown;
        emit CooldownUpdated(newCooldown);
    }

    function depositSingle(address nftAddress, uint256 nftId, uint256 amount, bytes memory data) public payable {
        _getTransactionFee(true);
        _transferSingleAsset(nftAddress, nftId, amount, msg.sender, address(this), data);
        emit SingleAssetDeposited(msg.sender, nftAddress, nftId, amount);
    }

    function depositBatch(address[] memory nftAddress, uint256[] memory nftId, uint256[] memory amount, bytes memory data) public payable {
        _getTransactionFee(true);
        for (uint256 i = 0; i < nftAddress.length; i ++) {
            _transferSingleAsset(nftAddress[i], nftId[i], amount[i], msg.sender, address(this), data);
        }
        emit BatchAssetDeposited(msg.sender, nftAddress, nftId, amount);
    }

    function depositToken(address tokenAddress, uint256 tokenAmount) external payable{
        _getTransactionFee(true);
        IERC20Mintable(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenAmount);
        emit TokenDeposited (msg.sender, tokenAddress, tokenAmount);
    }

    function claimERC20(address tokenAddress, uint256 amount, uint256 nonce, bytes memory signature) external payable{
        require(verifyERC20(msg.sender, tokenAddress, amount, nonce, signature), "MonesGW: Wrong signature!");
        require(!isExec[msg.sender][nonce], "MonesGW: Duplicate nonce!");
        require(lastMove[msg.sender] + cooldownDuration < block.timestamp, "MonesGW: Insufficient cooldown!");
        _getTransactionFee(false);
        lastMove[msg.sender] = block.timestamp;
        isExec[msg.sender][nonce] = true;
        IERC20Mintable(tokenAddress).mint(msg.sender, amount);
        emit ERC20Claimed(msg.sender, tokenAddress, amount, nonce);
    }

    function withdrawERC20(address tokenAddress, uint256 amount, uint256 nonce, bytes memory signature) external payable{
        require(verifyERC20(msg.sender, tokenAddress, amount, nonce, signature), "MonesGW: Wrong signature!");
        require(!isExec[msg.sender][nonce], "MonesGW: Duplicate nonce!");
        require(lastMove[msg.sender] + cooldownDuration < block.timestamp, "MonesGW: Insufficient cooldown!");
        _getTransactionFee(false);
        lastMove[msg.sender] = block.timestamp;
        isExec[msg.sender][nonce] = true;
        IERC20Mintable(tokenAddress).transfer(msg.sender, amount);
        emit ERC20Claimed(msg.sender, tokenAddress, amount, nonce);
    }

    function withdrawERC721(address tokenAddress, uint256 tokenId, uint256 nonce, bytes memory signature) external payable{
        require(verifyERC721(msg.sender, tokenAddress, tokenId, !IS_NEW, nonce, signature), "MonesGW: Wrong signature!");
        require(!isExec[msg.sender][nonce], "MonesGW: Duplicate nonce!");
        require(lastMove[msg.sender] + cooldownDuration < block.timestamp, "MonesGW: Insufficient cooldown!");
        _getTransactionFee(false);
        lastMove[msg.sender] = block.timestamp;
        isExec[msg.sender][nonce] = true;
        IERC721Upgradeable(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        emit ERC721Withdrawed(msg.sender, tokenAddress, tokenId, nonce);
    }

    function upgradeAndWithdrawERC721(address tokenAddress, uint256 tokenId, uint256 heroId, uint8 rarity, uint8 star, uint8 level, uint8 enhancement, uint256 nonce, bytes memory signature) external payable{
        require(verifyERC721WithAttribute(msg.sender, tokenAddress, tokenId, heroId, rarity, star, level, enhancement, nonce, signature), "MonesGW: Wrong signature!");
        require(!isExec[msg.sender][nonce], "MonesGW: Duplicate nonce!");
        require(lastMove[msg.sender] + cooldownDuration < block.timestamp, "MonesGW: Insufficient cooldown!");
        _getTransactionFee(false);
        lastMove[msg.sender] = block.timestamp;
        isExec[msg.sender][nonce] = true;
        IERC721Heroes(tokenAddress).updateHero(tokenId, heroId, rarity, star, level, enhancement);
        IERC721Heroes(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        emit ERC721UpgradedAndWithdrawed(msg.sender, tokenAddress, tokenId, heroId, rarity, star, level, enhancement, nonce);
    }

    function claimHero(address tokenAddress, uint256 heroId, uint256 nonce, bytes memory signature) external payable{
        require(verifyERC721(msg.sender, tokenAddress, heroId, IS_NEW, nonce, signature), "MonesGW: Wrong signature!");
        require(!isExec[msg.sender][nonce], "MonesGW: Duplicate nonce!");
        require(lastMove[msg.sender] + cooldownDuration < block.timestamp, "MonesGW: Insufficient cooldown!");
        _getTransactionFee(false);
        lastMove[msg.sender] = block.timestamp;
        isExec[msg.sender][nonce] = true;
        uint256 willMintId = IERC721Heroes(tokenAddress).getTokenIdCounterCurrent();
        IERC721Heroes(tokenAddress).mintHero(msg.sender, heroId);
        emit ERC721Claimed(msg.sender, tokenAddress, willMintId, heroId, nonce);
    }

    function claimEquipment(address tokenAddress, uint256 equipmentId, uint256 nonce, bytes memory signature) external payable{
        require(verifyERC721(msg.sender, tokenAddress, equipmentId, IS_NEW, nonce, signature), "MonesGW: Wrong signature!");
        require(!isExec[msg.sender][nonce], "MonesGW: Duplicate nonce!");
        require(lastMove[msg.sender] + cooldownDuration < block.timestamp, "MonesGW: Insufficient cooldown!");
        _getTransactionFee(false);
        lastMove[msg.sender] = block.timestamp;
        isExec[msg.sender][nonce] = true;
        uint256 willMintId = IERC721Equipment(tokenAddress).getTokenIdCounterCurrent();
        IERC721Equipment(tokenAddress).mintEquipment(msg.sender, equipmentId);
        emit ERC721Claimed(msg.sender, tokenAddress, willMintId, equipmentId, nonce);
    }

    function withdrawERC1155(address tokenAddress, uint256 tokenId, uint256 tokenAmount, uint256 nonce, bytes memory signature) external payable {
        require(verifyERC1155(msg.sender, tokenAddress, tokenId, tokenAmount, !IS_NEW, nonce, signature), "MonesGW: Wrong signature!");
        require(!isExec[msg.sender][nonce], "MonesGW: Duplicate nonce!");
        require(lastMove[msg.sender] + cooldownDuration < block.timestamp, "MonesGW: Insufficient cooldown!");
        _getTransactionFee(false);
        lastMove[msg.sender] = block.timestamp;
        isExec[msg.sender][nonce] = true;
        IERC1155Upgradeable(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId, tokenAmount, "0x00");
        emit ERC1155Withdrawed(msg.sender, tokenAddress, tokenId, tokenAmount, nonce);
    }

    function claimMaterial(address tokenAddress, uint256 tokenId, uint256 tokenAmount, uint256 nonce, bytes memory signature) external payable{
        require(verifyERC1155(msg.sender, tokenAddress, tokenId, tokenAmount, IS_NEW, nonce, signature), "MonesGW: Wrong signature!");
        require(!isExec[msg.sender][nonce], "MonesGW: Duplicate nonce!");
        require(lastMove[msg.sender] + cooldownDuration < block.timestamp, "MonesGW: Insufficient cooldown!");
        _getTransactionFee(false);
        lastMove[msg.sender] = block.timestamp;
        isExec[msg.sender][nonce] = true;
        // function mintMaterial(address _account, uint256 _itemId, uint256 _amount, bytes memory data) external;
        IERC1155Equipment(tokenAddress).mintMaterial(msg.sender, tokenId, tokenAmount, "0x00");
        emit ERC1155Claimed(msg.sender, tokenAddress, tokenId, tokenAmount, nonce);
    }

    //AUX
    function _transferSingleAsset(
        address nftAddress,
        uint256 nftId,
        uint256 amount,
        address from,
        address to,
        bytes memory data
    ) internal {
        if (_collections[nftAddress].isERC1155) {
            IERC1155Upgradeable(nftAddress).safeTransferFrom(from, to, nftId, amount, data);
        } else {
            require(amount == 1, "NFT: ERC721 should be unique!");
            IERC721Upgradeable(nftAddress).safeTransferFrom(from, to, nftId, data);
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC1155ReceiverUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function updateCollection(address collectionAddress, bool status, bool isERC1155)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _collections[collectionAddress].status = status;
        _collections[collectionAddress].isERC1155 = isERC1155;
        emit CollectionUpdated(collectionAddress, status, isERC1155);
    }

    // Upgrade deposit - withdraw fee
    function claimMoney(address _to, address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_token == address(0)) {
            (bool success,) = _to.call{value : address(this).balance}("");
            require(success, "Withdraw-failed");
        } else {
            IERC20Upgradeable(_token).transfer(_to, IERC20Upgradeable(_token).balanceOf(address(this)));

        }
    }

    function claimToWallets(address _token, address[] memory users, uint256[] memory amounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < users.length; i ++) {
            if (_token == address(0)) {
                (bool success,) = users[i].call{value : amounts[i]}("");
                require(success, "Withdraw-failed");
            } else {
                IERC20Upgradeable(_token).transfer(users[i], amounts[i]);
            }
        }
    }

    function updateGatewayFee(uint256 _depositFee, uint256 _withdrawFee) external onlyRole(DEFAULT_ADMIN_ROLE){
        depositFee = _depositFee;
        withdrawFee = _withdrawFee;
    }

    function updateFeeReceiver(address _feeReceiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeReceiver = _feeReceiver;
    }


    function updateIncentiveSender(address _sender) external onlyRole(DEFAULT_ADMIN_ROLE) {
        incentiveSender = _sender;
        emit IncentiveSenderUpdated(_sender);
    }

    function updateRewardChest(address _rewardChestAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardChest = _rewardChestAddress;
        emit RewardChestUpdated(_rewardChestAddress);
    }

    function _getTransactionFee(bool isDeposited) internal{
        uint256 fee = isDeposited ? depositFee : withdrawFee;
        if (fee > 0) {
            require(msg.value ==  fee, "Invalid payment fee");
            if (feeReceiver != address(0))  {
                payable(feeReceiver).transfer(fee);
            }
        }
    }


    function claimAirdrop(address _token, uint256 amount, uint256 nonce, bytes memory signature) external payable{
        require(verifyERC20(msg.sender, _token, amount, nonce, signature), "Wrong signature!");
        require(!isExec[msg.sender][nonce], "Duplicate nonce!");
        _getTransactionFee(false);
        isExec[msg.sender][nonce] = true;
        if (_token == address(0)) {
            (bool success,) = msg.sender.call{value : amount}("");
            require(success, "Claim-failed");
        } else {
            IERC20Upgradeable(_token).transfer(msg.sender, amount);
        }
        emit AirdropClaimed(msg.sender, _token, amount, nonce);
    }


    function claimReferIncentive(address _token, uint256 amount, uint256 nonce, bytes memory signature) public payable {
        require(verifyERC20(msg.sender, _token, amount, nonce, signature), "Wrong signature!");
        require(!isExec[msg.sender][nonce], "Duplicate nonce!");
        _getTransactionFee(false);
        isExec[msg.sender][nonce] = true;
        IERC20Upgradeable(_token).transferFrom(incentiveSender, msg.sender, amount);
        emit ReferIncentiveClaimed(msg.sender, _token, amount, nonce);
    }

    function claimReferChest(uint256 chestId, uint256 amount, uint256 rewardConfigId, uint256 nonce, bytes memory signature, bytes memory data) public payable {
        require(verifyReferChest(msg.sender, rewardChest, chestId, amount, rewardConfigId, nonce, signature), "Wrong signature!");
        require(!isExec[msg.sender][nonce], "Duplicate nonce!");
        _getTransactionFee(true);
        isExec[msg.sender][nonce] = true;
        IChest(rewardChest).mint(msg.sender, chestId, amount, data);
        emit ReferChestClaimed(
            msg.sender,
            rewardChest,
            chestId,
            amount,
            rewardConfigId,
            nonce
        );
    }

    function claimEventChest(uint256 chestId, uint256 amount, uint256 rewardConfigId, uint256 nonce, bytes memory signature, bytes memory data) public payable {
        require(verifyReferChest(msg.sender, rewardChest, chestId, amount, rewardConfigId, nonce, signature), "Wrong signature!");
        require(!isExec[msg.sender][nonce], "Duplicate nonce!");
        _getTransactionFee(true);
        isExec[msg.sender][nonce] = true;
        IChest(rewardChest).mint(msg.sender, chestId, amount, data);
        emit EventChestClaimed(
            msg.sender,
            rewardChest,
            chestId,
            amount,
            rewardConfigId,
            nonce
        );
    }

    function claimWalletRewardChest(uint256 chestId, uint256 amount, uint256 deadline, uint256 nonce, bytes memory signature) public payable {
        require(deadline >= block.timestamp, "Timeout claimed!");
        require(verifyWalletRewardChest(msg.sender, rewardChest, chestId, amount, deadline, nonce, signature), "Wrong signature!");
        require(!isExec[msg.sender][nonce], "Tx was executed!");
        isExec[msg.sender][nonce] = true;
//        _getTransactionFee(true);
        IChest(rewardChest).mint(msg.sender, chestId, amount, "0x00");
        emit WalletChestRewardClaimed(
            msg.sender,
            rewardChest,
            chestId,
            amount,
            nonce
        );
    }

    function claimMyriadCommission(address tokenAddress, uint256 amount, uint256 deadline, uint256 nonce, bytes memory signature) public payable {
        require(deadline >= block.timestamp, "Timeout claimed!");
        require(verifyERC20Deadline(msg.sender, tokenAddress, amount, deadline, nonce, signature), "Wrong signature!");
        require(!isExec[msg.sender][nonce], "Duplicate nonce!");
//        _getTransactionFee(true);
        isExec[msg.sender][nonce] = true;
        if (tokenAddress == address(0)) {
            (bool success,) = msg.sender.call{value : amount}("");
            require(success, "Claim-failed");
        } else {
            IERC20Upgradeable(tokenAddress).transfer(msg.sender, amount);
        }
        emit MyriadClaimed(msg.sender, tokenAddress, amount, nonce);
    }

}