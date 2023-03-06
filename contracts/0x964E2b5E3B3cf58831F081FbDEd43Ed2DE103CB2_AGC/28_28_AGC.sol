// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

/// @title AGC is the token to be used and managed by Augmentlabs in the ecosystem with restricted permissions for normal users.
/// @author Huy Tran
contract AGC is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
    bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');
    /// @dev the company address that is the actual holder of all AGC tokens
    address public companyAddress;

    /// @dev the list of users that owns AGC token.
    address[] private _users;

    /// @dev determines if a user is already whitelisted
    mapping(address => bool) private _userExistence;

    /* ========== EVENTS ========== */
    event RebasementPerformed(
        uint256 dividend,
        uint256 divisor,
        uint256 fromIndex,
        uint256 toIndex
    );

    /* ========== MODIFIERS ========== */
    modifier updateUserAddress(address _address) {
        require(
            _address != address(0),
            'updateUserAddress: cannot update zero address'
        );

        if (!_userExistence[_address]) {
            _users.push(_address);
            _userExistence[_address] = true;
        }

        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev The initialize function for upgradeable smart contract's initialization phase
    /// @param _companyAddress is the address that is the actual holder of all AGC supply.
    /// @param _initialAmount is the amount that gets minted to the company address initially.
    /// @notice we make sure the backend which is the deployer, is granted OPERATOR role.
    function initialize(address _companyAddress, uint256 _initialAmount)
        external
        initializer
        updateUserAddress(_companyAddress)
    {
        require(
            _companyAddress != address(0),
            'company address must not be empty'
        );
        require(_initialAmount > 0, 'initial amount must be larger than zero');

        __ERC20_init('AGC', 'AGC');
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init('AGC');
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

        companyAddress = _companyAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        // Mints actual AGC tokens to the company address. The initial totalSupply will be the balance of companyAddress.
        // This also records the logical balance of company address in the _userBalances mapping.
        mint(companyAddress, _initialAmount);
    }

    /// @dev Pause the smart contract in case of emergency
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @dev unpause the smart contract when everything is safe
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev Multiply every user balance with a ratio = divident / divisor. Must provide start and end indices to prevent out-of-gas issue.
    /// @notice this operation is intended to control the total supply of AGC tokens, to reduce the price should it goes too high.
    /// Automatically checks if toIndex is larger than current count of all users to provide flexibility.
    function performRebasement(
        uint256 dividend,
        uint256 divisor,
        uint256 fromIndex,
        uint256 toIndex
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        require(dividend > 0, 'rebasement: dividend must not be zero');
        require(divisor > 0, 'rebasement: divisor must not be zero');
        require(
            dividend != divisor,
            'rebasement: divident must be different from divisor'
        );
        require(
            fromIndex <= toIndex,
            'rebasement: start index must be less than end index'
        );

        uint256 maxIndex = countAllUsers();

        uint256 endIndex = toIndex >= maxIndex ? maxIndex : toIndex;

        for (uint256 i = fromIndex; i < endIndex; i++) {
            address userAddress = _users[i];
            uint256 userOldBalance = balanceOf(userAddress);

            if (userOldBalance > 0) {
                // Apply the ratio to user balance
                uint256 userNewBalance = (userOldBalance * dividend) / divisor;

                if (userNewBalance > userOldBalance) {
                    // mints new AGC tokens to the user, also increases the actual totalSupply.
                    mint(userAddress, userNewBalance - userOldBalance);
                } else {
                    if (userAddress == companyAddress) {
                        burn(userOldBalance - userNewBalance);
                    } else {
                        // reduce user's AGC tokens, also reduces totalSupply.
                        burnFrom(userAddress, userOldBalance - userNewBalance);
                    }
                }
            }
        }

        emit RebasementPerformed(dividend, divisor, fromIndex, toIndex);
    }

    /// @dev Mints new tokens to a user.
    function mint(address _userAddress, uint256 _amount)
        public
        onlyRole(OPERATOR_ROLE)
        updateUserAddress(_userAddress)
    {
        require(_userAddress != address(0), "mint: can't mint to zero address");
        require(_amount > 0, 'mint: cannot mint zero token');

        return _mint(_userAddress, _amount);
    }

    /// @dev Transfers AGC from company balance to user.
    /// @notice No user can transfer AGC to another user. We only transfer from company to a user.
    function transfer(address _toUser, uint256 _amount)
        public
        override
        onlyRole(OPERATOR_ROLE)
        updateUserAddress(_toUser)
        returns (bool)
    {
        require(
            _toUser != address(0),
            'transfer: cannot transfer to zero address'
        );
        require(
            _toUser != companyAddress,
            'transfer: cannot transfer to companyAddress'
        );
        require(_amount > 0, 'transfer: cannot transfer zero token');
        require(
            balanceOf(companyAddress) >= _amount,
            'transfer: insufficient company balance'
        );

        _transfer(companyAddress, _toUser, _amount);

        return true;
    }

    /// @dev Transfers AGC from a user to another as a result of an off-chain market transaction.
    /// @notice Only the operator can perform this action.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyRole(OPERATOR_ROLE) returns (bool) {
        super._transfer(from, to, amount);

        return true;
    }

    /// @dev Destroys an amount of AGC tokens from the user address.
    /// @notice Cannot burnFrom using company address.
    function burnFrom(address _userAddress, uint256 _amount)
        public
        override
        onlyRole(OPERATOR_ROLE)
    {
        require(_userAddress != address(0), 'ERC20: burn from zero address');
        require(
            _userAddress != companyAddress,
            'burnFrom: user address must not be company address'
        );
        require(_amount > 0, 'burnFrom: cannot burn zero token');
        require(
            _amount <= balanceOf(_userAddress),
            'AGC: insufficient AGC to burn'
        );

        _burn(_userAddress, _amount);
    }

    /// @dev Burn the company balance and reduce totalSupply.
    /// @notice Only the company can burn its AGC. Does not affect other user's AGC balance.
    function burn(uint256 _amount) public override onlyRole(OPERATOR_ROLE) {
        require(_amount > 0, 'burn: cannot burn zero amount');
        require(
            _amount <= balanceOf(companyAddress),
            'burn: insufficient company balance'
        );

        _burn(companyAddress, _amount);
    }

    /// @dev returns total count of AGC holders.
    function countAllUsers() public view returns (uint256) {
        return _users.length;
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }
}