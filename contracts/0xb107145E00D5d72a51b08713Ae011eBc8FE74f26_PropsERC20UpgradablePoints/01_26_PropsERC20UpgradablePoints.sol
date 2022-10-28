// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/IPropsContract.sol";
import "../interfaces/IPropsAccessRegistry.sol";

contract PropsERC20UpgradablePoints is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    //////////////////////////////////////////////
    // State Vars
    /////////////////////////////////////////////

    bytes32 private constant MODULE_TYPE =
        bytes32("PropsERC20UpgradablePoints");
    uint256 private constant VERSION = 5;

    bytes32 private constant CONTRACT_ADMIN_ROLE =
        keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");

    // @dev reserving space for 10 more roles
    bytes32[32] private __gap;

    address private _owner;
    address private accessRegistry;
    address private assetTokenAddress;
    address public signatureVerifier;
    address public approvedReceiverAddress;
    address public project;
    address[] private trustedForwarders;
    bool public isStakingEnabled;

    mapping(address => uint256) public claimedTokens;
    mapping(address => uint256) public spentTokens;

    uint256 public totalStaked;

    struct StakingTier {
        uint256 tierLevel;
        uint256 periodToAchieve;
        uint256 multiplier;
    }

    struct StakedToken {
        uint256 lockedTier;
        uint256 timer;
        bool isStaked;
    }

    mapping(uint256 => StakedToken) internal stakedTokens;
    mapping(uint256 => StakingTier) public stakingTiers;
    uint256 public numStakingTiers;

    uint256 public SECONDS_IN_ISSUANCE_PERIOD;
    mapping(address => mapping(uint256 => uint256)) public claimTimer;

    mapping(string => bool) public nonces;

    //////////////////////////////////////////////
    // Events / Errors
    /////////////////////////////////////////////

    event Staked(address indexed account, uint256[] id);
    event Unstaked(address indexed account, uint256[] id);
    event Earned(address indexed account, uint256 amount);
    event Spent(address indexed account, uint256 amount);

    error NonTransferable();
    error Unauthorized();

    function initialize(
        address _defaultAdmin,
        string memory name,
        string memory symbol,
        address[] memory _trustedForwarders,
        address _accessRegistry
    ) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        _owner = _defaultAdmin;
        accessRegistry = _accessRegistry;
        SECONDS_IN_ISSUANCE_PERIOD = 86400;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, PRODUCER_ROLE);

        // call registry add here
        // add default admin entry to registry
        IPropsAccessRegistry(accessRegistry).add(_defaultAdmin, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                      Generic contract logic
    //////////////////////////////////////////////////////////////*/

    function decimals() public view override returns (uint8) {
        return 0;
	}

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    function setAssetTokenAddress(address _address)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        assetTokenAddress = _address;
    }

    function setApprovedReceiverAddress(address _address)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        approvedReceiverAddress = _address;
    }

    /// @dev Lets a contract admin set the address for the access registry.
    function setAccessRegistry(address _accessRegistry)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        accessRegistry = _accessRegistry;
    }

    /// @dev Lets a contract admin set the address for the parent project.
    function setProject(address _project) external minRole(PRODUCER_ROLE) {
        project = _project;
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        minRole(CONTRACT_ADMIN_ROLE)
    {
        if (!hasRole(role, account)) {
            super._grantRole(role, account);
            IPropsAccessRegistry(accessRegistry).add(account, address(this));
        }
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override(AccessControlUpgradeable, IAccessControlUpgradeable)
        minRole(CONTRACT_ADMIN_ROLE)
    {
        if (hasRole(role, account)) {
            if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
            super._revokeRole(role, account);
            IPropsAccessRegistry(accessRegistry).remove(account, address(this));
        }
    }

    /**
     * @dev Check if minimum role for function is required.
     */
    modifier minRole(bytes32 _role) {
        require(_hasMinRole(_role), "Not authorized");
        _;
    }

    function hasMinRole(bytes32 _role) public view virtual returns (bool) {
        return _hasMinRole(_role);
    }

    function _hasMinRole(bytes32 _role) internal view returns (bool) {
        // @dev does account have role?
        if (hasRole(_role, _msgSender())) return true;
        // @dev are we checking against default admin?
        if (_role == DEFAULT_ADMIN_ROLE) return false;
        // @dev walk up tree to check if user has role admin role
        return _hasMinRole(getRoleAdmin(_role));
    }

    /*///////////////////////////////////////////////////////////////
                      ERC20 contract logic
    //////////////////////////////////////////////////////////////*/

    function setSignatureVerifier(address _address)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        signatureVerifier = _address;
    }

    function getSignatureVerifier() external view returns (address) {
        return signatureVerifier;
    }

    function mint(address _to, uint256 _amount) public minRole(MINTER_ROLE) {
        claimedTokens[_to] += _amount;
    }

    function spend(
        address _from,
        uint256 _amount,
        string memory _nonce,
        bytes memory _signature
    ) public {
        require(!nonces[_nonce], "Nonce already used");
        require(
            ECDSAUpgradeable.recover(
                keccak256(abi.encodePacked(_from, _amount, _nonce))
                    .toEthSignedMessageHash(),
                _signature
            ) == signatureVerifier,
            "Invalid Signature"
        );
        nonces[_nonce] = true;
        spentTokens[_from] += _amount;
        emit Spent(_from, _amount);
    }

    function earn(
        address _to,
        uint256 _amount,
        string memory _nonce,
        bytes memory _signature
    ) public {
        require(!nonces[_nonce], "Nonce already used");
        require(
            ECDSAUpgradeable.recover(
                keccak256(abi.encodePacked(_to, _amount, _nonce))
                    .toEthSignedMessageHash(),
                _signature
            ) == signatureVerifier,
            "Invalid Signature"
        );
        nonces[_nonce] = true;
        claimedTokens[_to] += _amount;
        emit Earned(_to, _amount);
    }

    function toggleStakingState(bool _isStakingEnabled)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        isStakingEnabled = _isStakingEnabled;
    }

    function issueTokens(address _to, uint256 _amount) internal {
        claimedTokens[_to] += _amount;
    }

    function pause() public minRole(CONTRACT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public minRole(CONTRACT_ADMIN_ROLE) {
        _unpause();
    }

    function balanceOf(address account)
        public
        view
        override
        returns (uint256 balance)
    {
        balance = claimedTokens[account];

        //Retrieve unclaimed balance from 721 contract and add to balance
        //balance += aggregateUnclaimedERC20TokenBalance(account);
    }

    function setIssuancePeriod(uint256 _seconds)
        external
        minRole(CONTRACT_ADMIN_ROLE)
    {
        SECONDS_IN_ISSUANCE_PERIOD = _seconds;
    }

    function getStakingLevel(uint256 _tokenId) external view returns (uint256) {
        return _getStakingLevel(_tokenId);
    }

    function _getStakingLevel(uint256 _tokenId)
        internal
        view
        returns (uint256)
    {
        unchecked {
            if (stakedTokens[_tokenId].isStaked)
                return calcTier(_tokenId, calcTimeDelta(_tokenId));
            return
                stakedTokens[_tokenId].lockedTier > 1
                    ? stakedTokens[_tokenId].lockedTier
                    : 1;
        }
    }

    function calcPreviousTiersTimeElapse(uint256 _tokenId)
        internal
        view
        returns (uint256)
    {
        unchecked {
            uint256 elapsed = 0;
            uint256 stakingLevel = _getStakingLevel(_tokenId);

            for (uint256 i = 0; i < numStakingTiers; i++) {
                if (stakingTiers[i].tierLevel == stakingLevel)
                    elapsed += (stakingTiers[i].periodToAchieve * 86400);
            }
            return elapsed;
        }
    }

    function calcTier(uint256 _tokenId, uint256 _timeDelta)
        public
        view
        returns (uint256)
    {
        uint256 tier = 1;
        unchecked {
            for (uint256 i = 0; i < numStakingTiers; i++) {
                if (_timeDelta >= stakingTiers[i].periodToAchieve * 86400)
                    tier = stakingTiers[i].tierLevel;
            }
        }
        return tier;
    }

    function calcTimeDelta(uint256 _tokenId) public view returns (uint256) {
        if (stakedTokens[_tokenId].timer == 0) return 0;
        unchecked {
            return block.timestamp - stakedTokens[_tokenId].timer;
        }
    }

    function upsertStakingTier(
        uint256 _i,
        uint256 _tierLevel,
        uint256 _periodToAchieve,
        uint256 _multiplier
    ) public {
        require(hasMinRole(PRODUCER_ROLE), "Auth");
        if (stakingTiers[_i].tierLevel == 0) numStakingTiers++;
        stakingTiers[_i].tierLevel = _tierLevel;
        stakingTiers[_i].periodToAchieve = _periodToAchieve;
        stakingTiers[_i].multiplier = _multiplier;
    }

    function _stake(uint256 id) internal {
        require(isStakingEnabled, "Staking is disabled");
        StakedToken storage stakedToken = stakedTokens[id];
        if (!stakedToken.isStaked) {
            stakedToken.timer =
                block.timestamp -
                calcPreviousTiersTimeElapse(id);
            stakedToken.isStaked = true;
            totalStaked++;
        }
    }

    function _unstake(uint256 id) internal {
        require(isStakingEnabled, "Staking is disabled");
        StakedToken storage stakedToken = stakedTokens[id];
        if (stakedToken.isStaked) {
            uint256 stakingLevel = _getStakingLevel(id);
            stakedToken.lockedTier = stakingLevel == 1 ? 1 : stakingLevel - 1;
            stakedToken.isStaked = false;
            stakedToken.timer = 0;
            totalStaked--;
        }
    }

    function stake(uint256[] calldata id) external {
        for (uint256 i = 0; i < id.length; i++) {
            require(
                IERC721EnumerableUpgradeable(assetTokenAddress).ownerOf(
                    id[i]
                ) == _msgSender(),
                "Not Owner"
            );
            _stake(id[i]);
            claimTimer[_msgSender()][id[i]] = block.timestamp;
        }

        emit Staked(_msgSender(), id);
    }

    function unstake(uint256[] calldata id) public {
        unchecked {
            for (uint256 i = 0; i < id.length; i++) {
                require(
                    IERC721EnumerableUpgradeable(assetTokenAddress).ownerOf(
                        id[i]
                    ) == _msgSender(),
                    "Not Owner"
                );
                _forceClaimERC20Tokens(_msgSender(), id[i]);
                _unstake(id[i]);
                claimTimer[_msgSender()][id[i]] = 0;
            }
        }
        emit Unstaked(_msgSender(), id);
    }

    function bridgeUnstake(address from, uint256[] calldata id) external {
        revertOnNonLinkedContract();
        unchecked {
            for (uint256 i = 0; i < id.length; i++) {
                _unstake(id[i]);
                claimTimer[from][id[i]] = 0;
            }
        }
        emit Unstaked(from, id);
    }

    function getStakedToken(uint256 id)
        public
        view
        returns (StakedToken memory)
    {
        return stakedTokens[id];
    }

    function getClaimedTokenBalance(address account)
        public
        view
        returns (uint256 balance)
    {
        balance = claimedTokens[account];
    }

    function _forceClaimERC20Tokens(address from, uint256 tokenId) internal {
        // require msg sender owner of eggs
        require(
            IERC721EnumerableUpgradeable(assetTokenAddress).ownerOf(tokenId) ==
                from,
            "Not Owner"
        );

        // get unstored balance
        uint256 unclaimedERC20Tokens = unclaimedERC20BalanceByToken(
            tokenId,
            from
        );

        // add to current balance
        issueTokens(from, unclaimedERC20Tokens);

        // reset time delta
        claimTimer[from][tokenId] = block.timestamp;
    }

    //@dev, called on beforeTokenTransfers to store unclaimed erc20 tokens to sender of token
    function claimPoints(address from, uint256[] memory tokenId) public {
         for (uint256 i = 0; i < tokenId.length; i++) {
            _forceClaimERC20Tokens(from, tokenId[i]);
         }
        
    }

    //@dev retrieves the number of unclaimed ERC20 tokens for a specific token
    function unclaimedERC20BalanceByToken(uint256 tokenId, address holder)
        public
        view
        returns (uint256)
    {
        uint256 multiplier = stakingTiers[_getStakingLevel(tokenId) - 1]
            .multiplier;
        uint256 acquiredTime = claimTimer[holder][tokenId];

        if (acquiredTime == 0) return 0;

        uint256 timestamp = block.timestamp;

        uint256 timeDelta = timestamp - acquiredTime;

        uint256 unclaimedERC20Tokens = (timeDelta / SECONDS_IN_ISSUANCE_PERIOD); // * (multiplier / 100);
        unclaimedERC20Tokens *= 1000000000000000000;
        unclaimedERC20Tokens = (unclaimedERC20Tokens * multiplier) / 100;
        unclaimedERC20Tokens /= 1000000000000000000;
        return unclaimedERC20Tokens;
    }

    //@dev retrieves the number of unclaimed ERC20 tokens by the holder
    function aggregateUnclaimedERC20TokenBalance(address holder)
        public
        view
        returns (uint256 erc20tokens)
    {
        // retrieve 721 tokens owned
        uint256 numToken = IERC721EnumerableUpgradeable(assetTokenAddress)
            .balanceOf(holder);
        erc20tokens = 0;

        // iterate over owned tokens
        for (uint256 i = 0; i < numToken; i++) {
            erc20tokens += unclaimedERC20BalanceByToken(
                IERC721EnumerableUpgradeable(assetTokenAddress)
                    .tokenOfOwnerByIndex(holder, i),
                holder
            );
        }
    }

    function getSpendableBalance(address holder)
        public
        view
        returns (uint256 erc20tokens)
    {
        if (claimedTokens[holder] > spentTokens[holder]) {
            erc20tokens = claimedTokens[holder] - spentTokens[holder];
        } else {
            erc20tokens = 0;
        }
    }

    //@dev aggregates the number of ERC20 tokens owned/claimed by the holder and the number of unclaimed ERC20 tokens for the holder
    function aggregateTotalERC20TokenBalance(address holder)
        public
        view
        returns (uint256 erc20tokens)
    {
        //retrieve balance of non-transferable ERC20 and add to unclaimed
        erc20tokens = balanceOf(holder);
    }

    function resetClaimTimer(address from, uint256 tokenId) external {
        revertOnNonLinkedContract();
        claimTimer[from][tokenId] = 0;
    }

    function revertOnNonLinkedContract() internal view {
        if (assetTokenAddress != msg.sender) revert Unauthorized();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        revert NonTransferable();
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        revert NonTransferable();
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal override {
        revert NonTransferable();
    }

    /*///////////////////////////////////////////////////////////////
                                Context
    //////////////////////////////////////////////////////////////*/

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    uint256[49] private ___gap;
}