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

contract Radiance is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    // ---------- CHANGE IN PRODUCTION ----------- //
    address public constant cash = 0x7A7ce628e8200f2EB98eCc10e951b75e0F786701;
    address public constant cbond = 0x2C0F0a995bCD0F2df2B50A8579216b64AaA48c10;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant EXCLUDED = keccak256("EXCLUDED");
    bytes32 public constant BLACKLIST = keccak256("BLACKLIST");

    address public treasury;
    address public stars;
    address public lp;
    address public router;
    address public busd;

    event BigBang(address treasury);
    event SwapCash(address swapper, uint256 amount);
    event SwapBonds(address swapper, uint256 amount);
    event LiquidityAdded(
        address indexed user,
        uint256 indexed liquidityAdded,
        address indexed assetB
    );

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

    function swapCash(uint256 _amount) public returns (bool success) {
        require(
            IERC20Upgradeable(cash).balanceOf(msg.sender) >= _amount,
            "Not enough to swap"
        );

        IERC20Upgradeable(cash).transferFrom(
            msg.sender,
            address(0x000000000000000000000000000000000000dEaD),
            _amount
        );
        _mint(msg.sender, _amount);
        emit SwapCash(msg.sender, _amount);
        return true;
    }

    function swapBonds(uint256 _amount) public returns (bool success) {
        require(
            IERC20Upgradeable(cbond).balanceOf(msg.sender) >= _amount,
            "Not enough to swap"
        );

        IERC20Upgradeable(cbond).transferFrom(
            msg.sender,
            address(0x000000000000000000000000000000000000dEaD),
            _amount
        );
        _mint(msg.sender, _amount);
        emit SwapBonds(msg.sender, _amount);
        return true;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!hasRole(BLACKLIST, from), "You're a bot");
        if (to == lp && !hasRole(EXCLUDED, from) && !hasRole(EXCLUDED, to)) {
            uint256 tax = (amount * 6) / 1000;
            super._burn(from, tax);
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