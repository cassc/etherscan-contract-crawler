// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Xocolatl is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    ERC20FlashMintUpgradeable,
    UUPSUpgradeable
{
    /**
     * @dev Emit when FlashFee changes
     * @param newFlashFee Factor
     */
    event FlashFeeChanged(Factor newFlashFee);

    /**
     * @dev Emit when FlashFeeReceiver changes
     * @param newAddress address
     */
    event FlashFeeReceiverChanged(address newAddress);

    struct Factor {
        uint256 numerator;
        uint256 denominator;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    Factor internal _flashFee;
    address public flashFeeReceiver;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("Xocolatl MXN Stablecoin", "XOC");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init("Xocolatl MXN Stablecoin");
        __ERC20FlashMint_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        // Default flash fee 0.01%
        _flashFee.numerator = 1;
        _flashFee.denominator = 10000;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        _mint(to, amount);
    }

    function burn(uint256) public pure override {
        revert("No self burn!");
    }

    function burn(address to, uint256 amount) public onlyRole(BURNER_ROLE) {
        _burn(to, amount);
    }

    function maxFlashLoan(address token)
        public
        view
        override
        returns (uint256)
    {
        return token == address(this) ? totalSupply() : 0;
    }

    function flashFee(address token, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        require(token == address(this), "ERC20FlashMint: wrong token");
        return (amount * _flashFee.numerator) / _flashFee.denominator;
    }

    /**
     * @dev Sets the flash fees as a percentage using Factor struct type.
     * Example: 1% flash fee: struct Factor{numerator:1, denominator:100}.
     * Restrictions:
     *  - Should be restricted to admin function.
     *  - The numerator should be less than denominator.
     */
    function setFlashFee(Factor memory newFlashFee_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            newFlashFee_.numerator < newFlashFee_.denominator,
            "Invalid input!"
        );
        _flashFee = newFlashFee_;
        emit FlashFeeChanged(newFlashFee_);
    }

    /**
     * @dev Sets the flash fees receiver address.
     * If address(0) fees are burned.
     */
    function setFlashFeeReceiver(address _flashFeeReceiverAddr)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        flashFeeReceiver = _flashFeeReceiverAddr;
        emit FlashFeeReceiverChanged(_flashFeeReceiverAddr);
    }

    /** Override from {ERC20FlashMintUpgradeable} to send flash fees to
     *  established 'flashFeeReceiver' address
     */
    function _flashFeeReceiver() internal view override returns (address) {
        return flashFeeReceiver;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}
}