// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import {IFireCatRegistryProxy} from "../src/interfaces/IFireCatRegistryProxy.sol";
import {FireCatTransfer} from "../src/utils/FireCatTransfer.sol";
import {ModifyControl} from "../src/utils/ModifyControl.sol";
import {IFireCatNFT} from "../src/interfaces/IFireCatNFT.sol";
import {IFireCatGate} from "../src/interfaces/IFireCatGate.sol";
import {IFireCatTreasury} from "../src/interfaces/IFireCatTreasury.sol";


interface IFireCatVault {
    function migrateIn(uint256 tokenId_, uint256 amount_) external returns(uint256);
    function migrateOut(uint256 tokenId_, uint256 amount_) external returns (uint256);
    function exitFunds(uint256 tokenId_, address user_) external returns (uint256);
    function staked(uint256 tokenId_) external view returns (uint256);
    function stakeToken() external view returns (address);
}

/**
 * @title FireCat's FireCatGate contract
 * @notice main: stake, claim
 * @author FireCat Finance
 */
contract FireCatGate is IFireCatGate, FireCatTransfer, ModifyControl {
    IFireCatRegistryProxy fireCatRegistryProxy;
    IFireCatNFT fireCatNFT;
    IFireCatTreasury fireCatTreasury;

    address public fireCatRegistry;
    uint256[] public vaultVersions;
    address[] public vaultAddress;
    mapping(address => bool) public isVault;

    uint256 private _totalStaked;
    mapping(uint256 => address) private _vaults;
    mapping(address => uint256) private _staked;
    mapping(uint256 => address) private _owner;
    mapping(address => bool) private _hasStaked;
    mapping(address => bool) private blackList;

    event Staked(address indexed user_, uint256 tokenId);
    event Claimed(address indexed user_, uint256 tokenId);
    event Destroy(address indexed user_, uint256 tokenId, uint256 totalExitFunds, uint256 actualTreasuryAmount);
    event SetMigrateOn(bool isMigrateOn_);
    event SetDestroyOn(bool isDestroyOn);

    /**
    * @dev switch on/off the stake function.
    */
    bool public isMigrateOn = false;
    bool public isDestroyOn = false;

    modifier beforeMigrate() {
        require(isMigrateOn, "GATE:E09");
        _;
    }

    modifier beforeDestroy() {
        require(isDestroyOn, "GATE:E09");
        _;
    }

    function initialize(address fireCatNFT_, address fireCatRegistry_, address fireCatTreasury_) initializer public {
        fireCatTreasury = IFireCatTreasury(fireCatTreasury_);
        fireCatRegistryProxy = IFireCatRegistryProxy(fireCatRegistry_);
        fireCatNFT = IFireCatNFT(fireCatNFT_);
        fireCatRegistry = fireCatRegistry_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);   
    }

    /// @inheritdoc IFireCatGate
    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    /// @inheritdoc IFireCatGate
    function vaultOf(uint256 version) public view returns (address) {
        return _vaults[version];
    }

    /// @inheritdoc IFireCatGate
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owner[tokenId];
    }

    /// @inheritdoc IFireCatGate
    function stakedOf(address user_) public view returns (uint256) {
        return _staked[user_];
    }

    /// @inheritdoc IFireCatGate
    function hasStaked(address user_) public view returns (bool) {
        return _hasStaked[user_];
    }

    /// @inheritdoc IFireCatGate
    function vaultStakedOf(uint256 tokenId_) public view returns(uint256) {
        uint256 totalVaultStaked = 0;
        if (tokenId_ != 0) {
            for (uint256 i = 0; i < vaultAddress.length; ++i) {
                totalVaultStaked += IFireCatVault(vaultAddress[i]).staked(tokenId_);
            }
        } 
        return totalVaultStaked;
    }

    /// @inheritdoc IFireCatGate
    function migrate(address vaultFrom, address vaultTo) external beforeMigrate {
        require(_hasStaked[msg.sender], "GATE:E00");
        require(vaultFrom != vaultTo, "GATE:E06");
        require(isVault[vaultFrom] && isVault[vaultTo], "GATE:E07");

        uint256 tokenId = _staked[msg.sender];
        uint256 stakeAmount = IFireCatVault(vaultFrom).staked(tokenId);
        require(stakeAmount > 0, "GATE:E08");
        IFireCatVault(vaultFrom).migrateOut(tokenId, stakeAmount);    
        IERC20(IFireCatVault(vaultFrom).stakeToken()).approve(address(vaultTo), stakeAmount);
        IFireCatVault(vaultTo).migrateIn(tokenId, stakeAmount);
    }

    /// @inheritdoc IFireCatGate
    function setMigrateOn(bool isMigrateOn_) external onlyRole(DATA_ADMIN) {
        isMigrateOn = isMigrateOn_;
        emit SetMigrateOn(isMigrateOn_);
    }

    /// @inheritdoc IFireCatGate
    function setDestroyOn(bool isDestroyOn_) external onlyRole(DATA_ADMIN) {
        isDestroyOn = isDestroyOn_;
        emit SetDestroyOn(isDestroyOn_);
    }

    /// @inheritdoc IFireCatGate
    function setVault(uint256[] calldata vaultVersions_, address[] calldata vaultAddress_) external onlyRole(DATA_ADMIN) {
        require(vaultVersions_.length == vaultAddress_.length);
        vaultVersions = vaultVersions_;
        vaultAddress = vaultAddress_;
        for (uint256 i = 0; i < vaultAddress_.length; ++i) {
            _vaults[vaultVersions_[i]] = vaultAddress_[i];
            isVault[vaultAddress_[i]] = true;
        }
    }

    /// @inheritdoc IFireCatGate
    function setBlackList(address[] calldata blackList_, bool blocked_) external onlyRole(DATA_ADMIN) {
        for (uint256 i = 0; i < blackList_.length; ++i) {
            blackList[blackList_[i]] = blocked_;
        }
    }

    /// @inheritdoc IFireCatGate
    function stake(uint256 tokenId_) external beforeStake {
        require(fireCatRegistryProxy.isRegistered(msg.sender), "GATE:E02");
        require(!blackList[msg.sender], "GATE:E03");   
        require(!_hasStaked[msg.sender], "GATE:E04");
        require(IFireCatNFT(fireCatNFT).ownerOf(tokenId_) == msg.sender, "GATE:E05");

        fireCatNFT.transferFrom(msg.sender, address(this), tokenId_);
        require(fireCatNFT.ownerOf(tokenId_) == address(this), "GATE:E01");
        _totalStaked += 1;
        _staked[msg.sender] = tokenId_;
        _owner[tokenId_] = msg.sender;
        _hasStaked[msg.sender] = true;
        emit Staked(msg.sender, tokenId_);
    }

    /// @inheritdoc IFireCatGate
    function claim() external nonReentrant beforeClaim returns (uint256) {
        require(_hasStaked[msg.sender], "GATE:E00");

        uint256 tokenId = _staked[msg.sender];
        fireCatNFT.transferFrom(address(this), msg.sender, tokenId);
        require(fireCatNFT.ownerOf(tokenId) == msg.sender, "GATE:E01");   

        _totalStaked -= 1;
        _staked[msg.sender] = 0;
        _owner[tokenId] = address(0);
        _hasStaked[msg.sender] = false;
        emit Claimed(msg.sender, tokenId);
        return tokenId;
    }

    /// @inheritdoc IFireCatGate
    function destroy() external nonReentrant beforeDestroy {
        require(_hasStaked[msg.sender], "GATE:E00");

        uint256 tokenId = _staked[msg.sender];
        uint256 totalExitFunds = 0;
        for (uint256 i = 0; i < vaultAddress.length; ++i) {
            if (IFireCatVault(vaultAddress[i]).staked(tokenId) > 0) {
                totalExitFunds += IFireCatVault(vaultAddress[i]).exitFunds(tokenId, msg.sender);
            }
        }

        address treasuryToken = fireCatTreasury.treasuryToken();
        uint256 actualTreasuryAmount = 0;
        if (fireCatTreasury.treasuryOf(tokenId) > 0) {
            uint256 swapTeasuryAmount = fireCatTreasury.swapTreasury(tokenId);
            IERC20(treasuryToken).approve(msg.sender, swapTeasuryAmount);
            actualTreasuryAmount = doTransferOut(treasuryToken, msg.sender, swapTeasuryAmount);
        }
        
        fireCatNFT.transferFrom(address(this), address(1), tokenId);
        require(fireCatNFT.ownerOf(tokenId) == address(1), "GATE:E01");   

        _totalStaked -= 1;
        _staked[msg.sender] = 0;
        _owner[tokenId] = address(1);
        _hasStaked[msg.sender] = false;
        emit Destroy(msg.sender, tokenId, totalExitFunds, actualTreasuryAmount);
    }
}