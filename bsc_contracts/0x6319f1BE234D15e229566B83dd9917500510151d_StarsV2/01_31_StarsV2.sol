// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

// Interfaces
import "../utils/Interfaces/IOracle.sol";
import "../utils/Interfaces/IBasisAsset.sol";
import "../utils/Interfaces/ITreasury.sol";
import "../utils/Interfaces/IUniswapV2Router02.sol";

contract StarsV2 is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable
{
    using SafeMathUpgradeable for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant EXCLUDED = keccak256("EXCLUDED");
    bytes32 public constant BLACKLIST = keccak256("BLACKLIST");

    address public constant busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant DAO = 0x8ae0A1B6d043faB3e2F71899FDF40CbEd83eb285;

    address public radiance;
    address public glow;
    address public treasury;

    address public oracle;
    address public lp;
    address public router;

    uint256 public taxPercent;
    bool public taxOn;

    event BigBang(
        address glow,
        address oracle,
        address treasury,
        address lp,
        address router
    );
    event SwapPrinter(address indexed swapper, uint256 indexed amount);
    event RadianceBought(uint256 indexed amountIn, uint256 indexed amountOut);
    event BurnForGlow(
        address indexed user,
        uint256 indexed amountBurned,
        uint256 indexed amountReceived
    );
    event BurnRadiance(uint256 indexed amountBurned);
    event LiquidityAdded(address indexed user, uint256 indexed liquidityAdded);
    event TaxPercentChanged(
        uint256 indexed oldTaxPercent,
        uint256 indexed newTaxPercent
    );
    event TaxStatusUpdated(bool indexed oldStatus, bool indexed newStatus);
    event ConvertToBUSD(uint256 amount, address receiver);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _radiance) public initializer {
        __ERC20_init("Stars", "STARS");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC20Permit_init("Stars");
        __ERC20Votes_init();

        _mint(msg.sender, 10 * 10**decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(EXCLUDED, address(this));
        radiance = _radiance;
    }

    function bigBang(
        address _glow,
        address _oracle,
        address _treasury,
        address _lp,
        address _router,
        bool tax
    ) public onlyRole(OPERATOR_ROLE) returns (bool) {
        // Set Operator Addresses
        _grantRole(OPERATOR_ROLE, _treasury);
        _grantRole(EXCLUDED, _treasury);
        _grantRole(EXCLUDED, radiance);

        oracle = _oracle;
        treasury = _treasury;
        lp = _lp;
        glow = _glow;
        router = _router;

        taxPercent = 100; // 100% of difference
        taxOn = tax;
        emit BigBang(_glow, _oracle, _treasury, _lp, _router);
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

    function buyRadiance(uint256 amount, address from)
        internal
        returns (bool success)
    {
        // Buy radiance with stars - busd - radiance

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = busd;
        path[2] = radiance;

        super._approve(address(this), router, amount);

        IUniswapV2Router02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            );

        uint256 balance = IERC20Upgradeable(radiance).balanceOf(address(this));
        emit RadianceBought(amount, balance);
        tryToBurnForGlow(balance, from);
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

    function getRadiancePrice() public view returns (uint256 radiancePrice) {
        try IOracle(oracle).consult(radiance, 1 ether) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Stars: failed to consult Radiance price from the oracle");
        }
    }

    function tryToBurnForGlow(uint256 amount, address from)
        internal
        returns (bool success)
    {
        // Check if any Radiance can be burned
        uint256 canBuy = ITreasury(treasury).getBurnableRadianceLeft();

        if (canBuy > 0) {
            uint256 maxBuyable;
            if (canBuy > amount) {
                maxBuyable = (amount * 4) / 10;
                amount = amount - maxBuyable;
            } else {
                maxBuyable = canBuy;
                amount = amount - canBuy;
            }

            uint256 targetPrice = getRadiancePrice();
            IBasisAsset(radiance).approve(treasury, maxBuyable);

            // Buy bonds with max amount buyable
            ITreasury(treasury).buyBonds(maxBuyable, targetPrice);
            uint256 glowBalance = IBasisAsset(glow).balanceOf(address(this));

            IBasisAsset(glow).transfer(DAO, glowBalance);

            emit BurnForGlow(from, maxBuyable, glowBalance);
        }
        if (amount > 0) {
            IBasisAsset(radiance).burn(amount);
            emit BurnRadiance(amount);
        }

        return true;
    }

    function addLiquidityTaxFree(uint256 _amountA, uint256 _amountB)
        public
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        )
    {
        super._transfer(msg.sender, address(this), _amountA);
        IBasisAsset(busd).transferFrom(msg.sender, address(this), _amountB);

        super._approve(address(this), router, _amountA);
        IBasisAsset(busd).approve(router, _amountB);

        (amountA, amountB, liquidity) = IUniswapV2Router02(router).addLiquidity(
            address(this),
            busd,
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
        //     IBasisAsset(busd).transfer(msg.sender, _amountB - amountB);
        // }
        emit LiquidityAdded(msg.sender, liquidity);
        return (amountA, amountB, liquidity);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (to != DAO) {
            require(!hasRole(BLACKLIST, from), "You're a bot");
        }

        if (taxOn && to == lp) {
            uint256 twap = getRadiancePrice();

            if (
                twap > 0 &&
                twap < 1 ether &&
                !hasRole(EXCLUDED, from) &&
                !hasRole(EXCLUDED, to)
            ) {
                uint256 tax = ((1e18 - twap) * taxPercent * amount) /
                    100 /
                    1e18;
                super._transfer(from, address(this), tax);
                buyRadiance(tax, from);
                amount -= tax;
            } else if (!hasRole(EXCLUDED, from) && !hasRole(EXCLUDED, to)) {
                // 1% Flat Sales tax above peg
                uint256 tax = amount / 100;
                uint256 winningStarsTax = (tax * 2) / 10;
                uint256 batteryTax = (tax * 2) / 10;
                uint256 starshipTax = tax - winningStarsTax - batteryTax;
                // Send 0.2% to Winning Stars Treasury
                super._transfer(from, DAO, winningStarsTax);
                // Send remaining 0.8% here to convert to BUSD
                super._transfer(from, address(this), tax - winningStarsTax);
                convertToBUSD(batteryTax, DAO);
                convertToBUSD(starshipTax, DAO);
                amount -= tax;
            }
        }

        super._transfer(from, to, amount);
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

    function changeTaxPercent(uint256 _newTaxPercent)
        public
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        uint256 oldTaxPercent = taxPercent;
        taxPercent = _newTaxPercent; // x / 100
        emit TaxPercentChanged(oldTaxPercent, _newTaxPercent);
        return true;
    }

    function updateTaxStatus(bool _status)
        public
        onlyRole(OPERATOR_ROLE)
        returns (bool)
    {
        bool oldStatus = taxOn;
        taxOn = _status; // Turn taxes on or off
        emit TaxStatusUpdated(oldStatus, _status);
        return true;
    }

    function governanceRecoverUnsupported(
        IERC20Upgradeable _token,
        uint256 _amount,
        address _to
    ) external onlyRole(OPERATOR_ROLE) {
        _token.transfer(_to, _amount);
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

    // The following functions are overrides required by Solidity.

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