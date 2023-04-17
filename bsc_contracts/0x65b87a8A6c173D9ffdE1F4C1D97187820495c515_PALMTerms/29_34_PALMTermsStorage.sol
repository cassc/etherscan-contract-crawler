// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IPALMTerms} from "../interfaces/IPALMTerms.sol";
import {
    IArrakisV2Factory
} from "@arrakisfi/v2-core/contracts/interfaces/IArrakisV2Factory.sol";
import {
    IArrakisV2Resolver
} from "@arrakisfi/v2-core/contracts/interfaces/IArrakisV2Resolver.sol";
import {
    IArrakisV2
} from "@arrakisfi/v2-core/contracts/interfaces/IArrakisV2.sol";
import {IPALMManager} from "../interfaces/IPALMManager.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// solhint-disable-next-line max-states-count
abstract contract PALMTermsStorage is
    IPALMTerms,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => EnumerableSet.AddressSet) internal _vaults;

    IArrakisV2Factory public immutable v2factory;
    address public termTreasury;
    address public manager;
    uint16 public emolument;
    /// @dev can be used in the future
    IArrakisV2Resolver public resolver;
    mapping(address => address) public delegateByVaults;

    // #region no left over.

    modifier collectLeftOver(IERC20 token0_, IERC20 token1_) {
        uint256 token0Balance = token0_.balanceOf(address(this));
        uint256 token1Balance = token1_.balanceOf(address(this));
        _;
        uint256 leftOver0 = token0_.balanceOf(address(this)) - token0Balance;
        uint256 leftOver1 = token1_.balanceOf(address(this)) - token1Balance;
        if (leftOver0 > 0) token0_.safeTransfer(msg.sender, leftOver0);
        if (leftOver1 > 0) token1_.safeTransfer(msg.sender, leftOver1);
    }

    modifier requireAddressNotZero(address addr) {
        require(addr != address(0), "PALMTerms: address Zero");
        _;
    }

    modifier requireIsOwner(address vault_) {
        require(_vaults[msg.sender].contains(vault_), "PALMTerms: not owner");
        _;
    }

    modifier requireDelegateWhenDelegateExistsOtherwiseRequireIsOwner(
        address vault_
    ) {
        address delegate = delegateByVaults[vault_];
        if (delegate != address(0))
            require(msg.sender == delegate, "PALMTerms: no delegate");
        else
            require(
                _vaults[msg.sender].contains(vault_),
                "PALMTerms: not owner"
            );
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
        require(owner_ != address(0), "PALMTerms: owner is address zero.");
        require(
            termTreasury_ != address(0),
            "PALMTerms: term treasury is address zero."
        );
        _transferOwnership(owner_);
        termTreasury = termTreasury_;
        emolument = emolument_;
        resolver = resolver_;
        emit SetTermTreasury(address(0), termTreasury_);
        emit SetEmolument(0, emolument_);
        emit SetResolver(IArrakisV2Resolver(address(0)), resolver_);
    }

    // #region setter.

    /// @notice sets emolument percentage
    /// @param emolument_ new emolument
    /// @dev only callable by owner
    function setEmolument(uint16 emolument_) external onlyOwner {
        require(
            emolument_ < emolument,
            "PALMTerms: new emolument >= old emolument"
        );
        emit SetEmolument(emolument, emolument = emolument_);
    }

    /// @notice sets term treasury
    /// @param termTreasury_ address of fess receiver
    /// @dev only callable by owner
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

    /// @notice sets resolver address
    /// @param resolver_ new resolver
    /// @dev only callable by owner
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

    /// @notice sets manager_ address
    /// @param manager_ new manager
    /// @dev only callable by owner
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

    /// @notice for adding new Pools on Arrakis V2 vault
    /// @param vault_ Arrakis V2 vault
    /// @param feeTiers_ feeTiers to add
    /// @dev only callable by owner of the vault
    function addPools(IArrakisV2 vault_, uint24[] calldata feeTiers_)
        external
        override
        requireAddressNotZero(address(vault_))
        requireIsOwner(address(vault_))
    {
        vault_.addPools(feeTiers_);

        emit LogAddPools(msg.sender, address(vault_), feeTiers_);
    }

    /// @notice for removing Pools on Arrakis V2 vault
    /// @param vault_ Arrakis V2 vault
    /// @param pools_ pools to remove
    /// @dev only callable by owner of the vault
    function removePools(IArrakisV2 vault_, address[] calldata pools_)
        external
        override
        requireAddressNotZero(address(vault_))
        requireIsOwner(address(vault_))
    {
        vault_.removePools(pools_);

        emit LogRemovePools(msg.sender, address(vault_), pools_);
    }

    /// @notice for whitelisting routers on Arrakis V2 vault
    /// @param vault_ Arrakis V2 vault
    /// @param routers_ routers to whitelist
    /// @dev only callable by owner of the vault
    function whitelistRouters(IArrakisV2 vault_, address[] calldata routers_)
        external
        override
        requireAddressNotZero(address(vault_))
        requireIsOwner(address(vault_))
    {
        vault_.whitelistRouters(routers_);

        emit LogWhitelistRouters(msg.sender, address(vault_), routers_);
    }

    /// @notice for blacklist routers on Arrakis V2 vault
    /// @param vault_ Arrakis V2 vault
    /// @param routers_ routers to blacklist
    /// @dev only callable by owner of the vault
    function blacklistRouters(IArrakisV2 vault_, address[] calldata routers_)
        external
        override
        requireAddressNotZero(address(vault_))
        requireIsOwner(address(vault_))
    {
        vault_.blacklistRouters(routers_);

        emit LogBlacklistRouters(msg.sender, address(vault_), routers_);
    }

    // #endregion vault config as admin.

    // #region manager config as vault owner.
    /// @notice set Arrakis V2 vault meta data
    /// @param vault_ Arrakis V2 vault
    /// @param data_ metadata to use during market making
    /// @dev only callable by delegate of the vault by default or otherwise owner
    function setVaultData(address vault_, bytes calldata data_)
        external
        override
        requireAddressNotZero(vault_)
        requireDelegateWhenDelegateExistsOtherwiseRequireIsOwner(vault_)
    {
        IPALMManager(manager).setVaultData(vault_, data_);

        address delegate = delegateByVaults[vault_];

        emit LogSetVaultData(
            delegate != address(0) ? delegate : msg.sender,
            vault_,
            data_
        );
    }

    /// @notice set Arrakis V2 vault strategy
    /// @param vault_ Arrakis V2 vault
    /// @param strat_ strategy to apply during market making
    /// @dev only callable by delegate of the vault by default or otherwise owner
    function setVaultStratByName(address vault_, string calldata strat_)
        external
        override
        requireAddressNotZero(vault_)
        requireDelegateWhenDelegateExistsOtherwiseRequireIsOwner(vault_)
    {
        IPALMManager(manager).setVaultStratByName(vault_, strat_);

        address delegate = delegateByVaults[vault_];

        emit LogSetVaultStratByName(
            delegate != address(0) ? delegate : msg.sender,
            vault_,
            strat_
        );
    }

    /// @notice set delegate for managing strategy of Arrakis V2 vault
    /// @param vault_ Arrakis V2 vault
    /// @param delegate_ delegated strategy setter of Arrakis V2 vault
    /// @dev only callable by owner of vault
    function setDelegate(address vault_, address delegate_)
        external
        override
        requireIsOwner(vault_)
    {
        _setDelegate(vault_, delegate_);

        emit LogSetDelegate(msg.sender, vault_, delegate_);
    }

    /// @notice for withdrawing vault balance
    /// @param vault_ Arrakis V2 vault
    /// @param amount_ amount of balance that receiver will get back
    /// @param to_ address of the receiver of balance
    /// @dev only callable by owner of vault
    function withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    ) external override requireAddressNotZero(vault_) requireIsOwner(vault_) {
        IPALMManager manager_ = IPALMManager(manager);
        manager_.withdrawVaultBalance(vault_, amount_, to_);

        emit LogWithdrawVaultBalance(msg.sender, vault_, to_, amount_);
    }

    // #endregion manager config as vault owner.

    /// @notice get vault of creator
    /// @param creator_ creator of Arrakis V2 vault
    /// @param index index on the list of vaults
    /// @return address of the Arrakis Vault V2
    function vaults(address creator_, uint256 index)
        external
        view
        returns (address)
    {
        require(_vaults[creator_].length() > index, "PALMTerms: out of bonds.");

        return _vaults[creator_].at(index);
    }

    // #region internals setter.

    function _addVault(address creator_, address vault_) internal {
        require(!_vaults[creator_].contains(vault_), "PALMTerms: vault exist");

        _vaults[creator_].add(vault_);
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