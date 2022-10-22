// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// Utils
import "../utils/Interfaces/IBasisAsset.sol";
import "../utils/Interfaces/IUniswapV2Router02.sol";

import "hardhat/console.sol";

contract RadianceV2 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant EXCLUDED = keccak256("EXCLUDED");
    bytes32 public constant BLACKLIST = keccak256("BLACKLIST");

    address public constant DAO = 0x8ae0A1B6d043faB3e2F71899FDF40CbEd83eb285;

    address public treasury;
    address public stars;
    address public lp;
    address public router;
    address public busd;

    event BigBang(address treasury);
    event LiquidityAdded(
        address indexed user,
        uint256 indexed liquidityAdded,
        address indexed assetB
    );
    event ConvertToBUSD(uint256 amount, address receiver);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        // Initialize
        __ERC20_init("Radiance", "RAD");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();
        __Pausable_init();

        // Mint initial
        _mint(msg.sender, 20 * 10**decimals());

        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(EXCLUDED, address(this));
    }

    function bigBang(
        address _treasury,
        address _stars,
        address _busd,
        address _lp,
        address _router
    ) public onlyRole(OPERATOR_ROLE) returns (bool) {
        // Set Operator Addresses
        treasury = _treasury;
        stars = _stars;
        busd = _busd;
        lp = _lp;
        router = _router;

        _grantRole(OPERATOR_ROLE, _treasury);
        _grantRole(EXCLUDED, treasury);
        emit BigBang(_treasury);
        return true;
    }

    function snapshot() public onlyRole(OPERATOR_ROLE) {
        _snapshot();
    }

    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(OPERATOR_ROLE) {
        _mint(to, amount);
    }

    function addLiquidityTaxFree(
        uint256 _amountA,
        uint256 _amountB,
        address _assetB
    )
        public
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        )
    {
        super._transfer(msg.sender, address(this), _amountA);
        IBasisAsset(_assetB).transferFrom(msg.sender, address(this), _amountB);

        super._approve(address(this), router, _amountA);
        IBasisAsset(_assetB).approve(router, _amountB);

        (amountA, amountB, liquidity) = IUniswapV2Router02(router).addLiquidity(
            address(this),
            _assetB,
            _amountA,
            _amountB,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        // Not worth the gas to recover 1e18 -- USE AT OWN RISK DIRECTLY
        // if (amountA < _amountA) {
        //     super._transfer(address(this), msg.sender, _amountA - amountA);
        // }
        // if (amountB < _amountB) {
        //     IBasisAsset(_assetB).transfer(msg.sender, _amountB - amountB);
        // }
        emit LiquidityAdded(msg.sender, liquidity, _assetB);
        return (amountA, amountB, liquidity);
    }

    function addToBlacklist(address _bot)
        public
        onlyRole(OPERATOR_ROLE)
        returns (bool success)
    {
        _grantRole(BLACKLIST, _bot);
        return true;
    }

    function removeFromBlacklist(address _user)
        public
        onlyRole(OPERATOR_ROLE)
        returns (bool success)
    {
        _revokeRole(BLACKLIST, _user);
        return true;
    }

    function addToExcluded(address _user)
        public
        onlyRole(OPERATOR_ROLE)
        returns (bool success)
    {
        _grantRole(EXCLUDED, _user);
        return true;
    }

    function removeFromExcluded(address _user)
        public
        onlyRole(OPERATOR_ROLE)
        returns (bool success)
    {
        _revokeRole(EXCLUDED, _user);
        return true;
    }

    function convertToBUSD(uint256 amount, address receiver)
        internal
        returns (bool success)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = busd;

        super._approve(address(this), router, amount);

        IUniswapV2Router02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                receiver,
                block.timestamp
            );

        emit ConvertToBUSD(amount, receiver);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (to != DAO) {
            require(!hasRole(BLACKLIST, from), "You're a bot");
        }

        if (to == lp && !hasRole(EXCLUDED, from) && !hasRole(EXCLUDED, to)) {
            // Flat 1% Sales tax
            uint256 tax = amount / 100;
            super._transfer(from, address(this), tax);
            uint256 batteryTax = (tax * 4) / 10;
            uint256 starshipTax = tax - batteryTax;
            // Will be changed to new Treasuries when they are set up
            convertToBUSD(batteryTax, DAO);
            convertToBUSD(starshipTax, DAO);

            amount -= tax;
        }

        super._transfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}