// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IPALMTerms} from "../interfaces/IPALMTerms.sol";
import {IArrakisV2Factory} from "../interfaces/IArrakisV2Factory.sol";
import {IArrakisV2Resolver} from "../interfaces/IArrakisV2Resolver.sol";
import {IArrakisV2} from "../interfaces/IArrakisV2.sol";
import {IPALMManager} from "../interfaces/IPALMManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {FullMath} from "@arrakisfi/v3-lib-0.8/contracts/FullMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {
    _getInits,
    _requireTokenMatch,
    _requireIsOwnerOrDelegate,
    _requireIsOwner,
    _getEmolument,
    _requireProjectAllocationGtZero,
    _requireTknOrder,
    _burn
} from "../functions/FPALMTerms.sol";

// solhint-disable-next-line max-states-count
abstract contract PALMTermsStorage is
    IPALMTerms,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    IArrakisV2Factory public immutable v2factory;
    mapping(address => address[]) public vaults;
    address public termTreasury;
    address public manager;
    uint16 public emolument;
    IArrakisV2Resolver public resolver;
    mapping(address => address) public delegateByVaults;

    // #region no left over.

    modifier noLeftOver(IERC20 token0_, IERC20 token1_) {
        uint256 token0Balance = token0_.balanceOf(address(this));
        uint256 token1Balance = token1_.balanceOf(address(this));
        _;
        uint256 leftOver0 = token0_.balanceOf(address(this)) - token0Balance;
        uint256 leftOver1 = token1_.balanceOf(address(this)) - token1Balance;
        if (leftOver0 > 0) token0_.transfer(msg.sender, leftOver0);
        if (leftOver1 > 0) token1_.transfer(msg.sender, leftOver1);
    }

    modifier requireAddressNotZero(address addr) {
        require(addr != address(0), "PALMTerms: address Zero");
        _;
    }

    // #endregion no left over.

    constructor(IArrakisV2Factory v2factory_) {
        v2factory = v2factory_;
    }

    function initialize(
        address owner_,
        address termTreasury_,
        uint16 emolument_,
        IArrakisV2Resolver resolver_
    ) external initializer {
        require(emolument < 10000, "PALMTerms: emolument >= 100%.");
        _transferOwnership(owner_);
        termTreasury = termTreasury_;
        emolument = emolument_;
        resolver = resolver_;
    }

    // #region setter.

    function setEmolument(uint16 emolument_) external onlyOwner {
        require(
            emolument_ < emolument,
            "PALMTerms: new emolument >= old emolument"
        );
        emit SetEmolument(emolument, emolument = emolument_);
    }

    function setTermTreasury(address termTreasury_)
        external
        onlyOwner
        requireAddressNotZero(termTreasury_)
    {
        require(
            termTreasury != termTreasury_,
            "PALMTerms: already term treasury"
        );
        emit SetTermTreasury(termTreasury, termTreasury = termTreasury_);
    }

    function setResolver(IArrakisV2Resolver resolver_)
        external
        onlyOwner
        requireAddressNotZero(address(resolver_))
    {
        require(
            address(resolver) != address(resolver_),
            "PALMTerms: already resolver"
        );
        emit SetResolver(resolver, resolver = resolver_);
    }

    function setManager(address manager_)
        external
        override
        onlyOwner
        requireAddressNotZero(manager_)
    {
        require(manager_ != manager, "PALMTerms: already manager");
        emit SetManager(manager, manager = manager_);
    }

    // #endregion setter.

    // #region vault config as admin.

    function addPools(IArrakisV2 vault_, uint24[] calldata feeTiers_)
        external
        override
        requireAddressNotZero(address(vault_))
    {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        vault_.addPools(feeTiers_);

        emit LogAddPools(msg.sender, vaultAddr, feeTiers_);
    }

    function removePools(IArrakisV2 vault_, address[] calldata pools_)
        external
        override
        requireAddressNotZero(address(vault_))
    {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        vault_.removePools(pools_);

        emit LogRemovePools(msg.sender, vaultAddr, pools_);
    }

    function whitelistRouters(IArrakisV2 vault_, address[] calldata routers_)
        external
        override
        requireAddressNotZero(address(vault_))
    {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        vault_.whitelistRouters(routers_);

        emit LogWhitelistRouters(msg.sender, vaultAddr, routers_);
    }

    function blacklistRouters(IArrakisV2 vault_, address[] calldata routers_)
        external
        override
        requireAddressNotZero(address(vault_))
    {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        vault_.blacklistRouters(routers_);

        emit LogBlacklistRouters(msg.sender, vaultAddr, routers_);
    }

    // #endregion vault config as admin.

    // #region manager config as vault owner.

    function setVaultData(address vault_, bytes calldata data_)
        external
        override
        requireAddressNotZero(vault_)
    {
        address vaultAddr = address(vault_);
        _requireIsOwnerOrDelegate(
            delegateByVaults[vault_],
            vaults[msg.sender],
            vaultAddr
        );
        IPALMManager(manager).setVaultData(vault_, data_);

        emit LogSetVaultData(
            delegateByVaults[vault_] != address(0)
                ? delegateByVaults[vault_]
                : msg.sender,
            vaultAddr,
            data_
        );
    }

    function setVaultStratByName(address vault_, string calldata strat_)
        external
        override
        requireAddressNotZero(vault_)
    {
        address vaultAddr = address(vault_);
        _requireIsOwnerOrDelegate(
            delegateByVaults[vault_],
            vaults[msg.sender],
            vaultAddr
        );
        IPALMManager(manager).setVaultStraByName(vault_, strat_);

        emit LogSetVaultStratByName(
            delegateByVaults[vault_] != address(0)
                ? delegateByVaults[vault_]
                : msg.sender,
            vaultAddr,
            strat_
        );
    }

    function setDelegate(address vault_, address delegate_) external override {
        address vaultAddr = address(vault_);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        _setDelegate(vault_, delegate_);

        emit LogSetDelegate(msg.sender, vaultAddr, delegate_);
    }

    function withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    ) external override requireAddressNotZero(vault_) {
        address vaultAddr = address(vault_);
        IPALMManager manager_ = IPALMManager(manager);
        (uint256 balance, , , , ) = manager_.vaults(vaultAddr);
        _requireIsOwner(vaults[msg.sender], vaultAddr);
        manager_.withdrawVaultBalance(vault_, amount_, to_);

        emit LogWithdrawVaultBalance(msg.sender, vaultAddr, to_, balance);
    }

    // #endregion manager config as vault owner.

    // #region internals setter.

    function _addVault(address creator_, address vault_) internal {
        address[] storage vaultsOfCreator = vaults[creator_];

        for (uint256 i = 0; i < vaultsOfCreator.length; i++) {
            require(vaultsOfCreator[i] != vault_, "PALMTerms: vault exist");
        }

        vaultsOfCreator.push(vault_);
        emit AddVault(creator_, vault_);
    }

    function _setDelegate(address vault_, address delegate_) internal {
        require(
            delegateByVaults[vault_] != delegate_,
            "PALMTerms: already delegate"
        );

        delegateByVaults[vault_] = delegate_;
        emit DelegateVault(msg.sender, vault_, delegate_);
    }

    // #endregion internals setter.
}