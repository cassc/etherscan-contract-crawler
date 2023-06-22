/*
ERC20BondStakingModule

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./interfaces/IStakingModule.sol";
import "./interfaces/IConfiguration.sol";
import "./interfaces/IMetadata.sol";
import "./OwnerController.sol";
import "./TokenUtils.sol";

/**
 * @title ERC20 bond staking module
 *
 * @notice this staking module allows users to permanently sell an ERC20 token
 * in exchange for bond shares credited to their address. When the user
 * unstakes, these shares will be burned and a reward will be distributed.
 */
contract ERC20BondStakingModule is IStakingModule, OwnerController, ERC721 {
    using SafeERC20 for IERC20;
    using TokenUtils for IERC20;

    // events
    event MarketOpened(
        address indexed token,
        uint256 price,
        uint256 coeff,
        uint256 max,
        uint256 capacity
    );
    event MarketClosed(address indexed token);
    event MarketAdjusted(
        address indexed token,
        uint256 price,
        uint256 coeff,
        uint256 max,
        uint256 capacity
    );
    event MarketBalanceWithdrawn(address indexed token, uint256 amount);

    // bond market
    struct Market {
        uint256 price;
        uint256 coeff; // pricing coefficient
        uint256 max; // max debt for single stake
        uint256 capacity; // remaining debt capacity
        uint256 principal;
        uint256 vested;
        uint256 debt;
        uint128 start; // start of current vesting/decay period
        uint128 updated; // last incremental update to vesting/decay
    }

    // bond position
    struct Bond {
        address market;
        uint64 timestamp;
        uint256 principal; // shares
        uint256 debt; // shares
    }

    // adjustment
    struct Adjustment {
        uint256 price;
        uint256 coeff;
        uint256 timestamp;
    }

    // constant
    uint256 public constant MAX_MARKETS = 16;
    uint256 public constant MAX_BONDS = 128; // only for viewing balances
    uint256 public constant MIN_PERIOD = 3600;

    // members: config
    uint256 public immutable period;
    bool public immutable burndown;
    address private immutable _factory;
    IConfiguration private immutable _config;

    // members: bonds
    mapping(address => Market) public markets;
    address[] private _markets;
    mapping(address => uint256) _marketIndex;
    mapping(uint256 => Bond) public bonds;
    mapping(address => Adjustment) public adjustments;

    // members: indexing
    mapping(address => mapping(uint256 => uint256)) public ownerBonds;
    mapping(uint256 => uint256) public bondIndex;
    uint256 public nonce;

    /**
     * @param period_ bond vesting period
     * @param burndown_ enable burndown period and opt-out for deposited user funds
     * @param config_ address for configuration contract
     * @param factory_ address of module factory
     */
    constructor(
        uint256 period_,
        bool burndown_,
        address config_,
        address factory_
    ) ERC721("GYSR Bond Position", "GYSR-BOND") {
        require(period_ > MIN_PERIOD, "bsm1");
        period = period_;
        burndown = burndown_;
        _config = IConfiguration(config_);
        _factory = factory_;

        nonce = 1;
    }

    // -- IStakingModule -------------------------------------------------

    /**
     * @inheritdoc IStakingModule
     */
    function tokens()
        external
        view
        override
        returns (address[] memory tokens_)
    {
        return _markets;
    }

    /**
     * @inheritdoc IStakingModule
     *
     * @dev user balances will dynamically decrease as bonds vest to reflect
     * the amount that can actually be withdrawn
     */
    function balances(
        address user
    ) external view override returns (uint256[] memory balances_) {
        balances_ = new uint256[](_markets.length);
        if (!burndown) return balances_;
        uint256 count = balanceOf(user);
        if (count > MAX_BONDS) count = MAX_BONDS;
        for (uint256 i; i < count; ++i) {
            Bond storage b = bonds[ownerBonds[user][i]];
            uint256 dt = block.timestamp - b.timestamp;
            if (dt > period) {
                continue;
            }
            uint256 s = (b.principal * (period - dt)) / period;
            uint256 amount = _amount(b.market, s);
            balances_[_marketIndex[b.market]] += amount;
        }
    }

    /**
     * @inheritdoc IStakingModule
     */
    function factory() external view override returns (address) {
        return _factory;
    }

    /**
     * @inheritdoc IStakingModule
     */
    function totals()
        external
        view
        override
        returns (uint256[] memory totals_)
    {
        totals_ = new uint256[](_markets.length);
        for (uint256 i; i < _markets.length; ++i) {
            totals_[i] = IERC20(_markets[i]).balanceOf(address(this));
        }
    }

    /**
     * @inheritdoc IStakingModule
     */
    function stake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, uint256) {
        // validate
        require(amount > 0, "bsm2");
        require(data.length == 32 || data.length == 64, "bsm3");
        address token;
        assembly {
            token := calldataload(132)
        }
        uint256 minimum;
        if (data.length == 64) {
            assembly {
                minimum := calldataload(164)
            }
        }
        Market storage m = markets[token];
        uint256 capacity = m.capacity;
        require(capacity > 0, "bsm4");

        // update
        _update(token);

        // transfer and process fees
        uint256 minted;
        {
            (address receiver, uint256 rate) = _config.getAddressUint96(
                keccak256("gysr.core.bond.stake.fee")
            );
            minted = IERC20(token).receiveWithFee(
                m.principal,
                sender,
                amount,
                receiver,
                rate
            );
        }

        // pricing
        uint256 debt = (minted * 1e18) / (m.price + (m.coeff * m.debt) / 1e24);
        require(debt <= m.max, "bsm5");
        require(debt <= capacity, "bsm6");
        require(debt > minimum, "bsm7");

        // create new bond
        uint256 id = nonce;
        nonce = id + 1;
        bonds[id] = Bond({
            market: token,
            timestamp: uint64(block.timestamp),
            principal: burndown ? minted : 0, // only need to store if burndown enabled
            debt: debt
        });

        // update bond market
        m.debt += debt;
        m.capacity = capacity - debt;
        m.principal += minted;
        if (!burndown) {
            m.vested += minted;
        }
        m.start = uint128(block.timestamp);

        // mint position
        _safeMint(sender, id);

        // external
        emit Staked(bytes32(id), sender, token, amount, debt);

        return (bytes32(id), debt);
    }

    /**
     * @inheritdoc IStakingModule
     *
     * @dev pass amount zero to unstake all or to unstake fully vested bond
     */
    function unstake(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, address, uint256) {
        // validate
        require(data.length == 32, "bsm8");
        uint256 id;
        assembly {
            id := calldataload(132)
        }
        require(_ownerOf(id) == sender, "bsm9");

        // default unstake with no principal returned
        Bond storage b = bonds[id];
        address token = b.market;
        uint256 shares;
        uint256 debt = b.debt;
        uint256 elapsed = block.timestamp - b.timestamp;
        require(elapsed > 0, "bsm10");

        // update
        _update(token);

        if (amount > 0) {
            // unstake specific amount
            require(burndown, "bsm11");

            // timing
            require(elapsed < period, "bsm12");

            // convert to shares
            shares = IERC20(token).getShares(markets[token].principal, amount); // must have non zero unvested balance
            require(shares > 0, "bsm13");
            uint256 bprincipal = b.principal;
            uint256 bdebt = debt;

            // compute burned principal and debt shares
            uint256 burned = (shares * period) / (period - elapsed);
            require(burned < bprincipal, "bsm14"); // strictly less than total principal
            debt = (bdebt * burned) / bprincipal;

            // decrease bond position
            b.principal = bprincipal - burned;
            b.debt = bdebt - debt;
        } else {
            // unstake all
            if (burndown) {
                if (elapsed < period) {
                    // return any unvested principal
                    shares = (b.principal * (period - elapsed)) / period;
                    amount = IERC20(token).getAmount(
                        markets[token].principal,
                        shares
                    );
                }
            }
            // delete bond position
            delete bonds[id];
            _burn(id);
        }

        // transfer principal back to user
        if (shares > 0) {
            // note: unwinding debt here does introduce a price drop and frontrunning opportunity,
            // but it also prevents manipulation of debt via repeated staking and unstaking
            uint256 udebt = (debt * (period - elapsed)) / period;
            markets[token].debt -= udebt;
            markets[token].capacity += udebt;
            markets[token].principal -= shares;
            IERC20(token).safeTransfer(sender, amount);
        }

        // external
        emit Unstaked(bytes32(id), sender, token, amount, debt);
        return (bytes32(id), sender, debt);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function claim(
        address sender,
        uint256,
        bytes calldata data
    ) external override onlyOwner returns (bytes32, address, uint256) {
        // validate
        require(data.length == 32, "bsm15");
        uint256 id;
        assembly {
            id := calldataload(132)
        }
        require(_ownerOf(id) == sender, "bsm16");

        Bond storage b = bonds[id];
        address token = b.market;
        uint256 debt = b.debt;

        // update
        _update(token);

        // external
        emit Claimed(bytes32(id), sender, token, 0, debt);
        return (bytes32(id), sender, debt);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function update(
        address sender,
        bytes calldata data
    ) external override returns (bytes32) {
        // validate
        requireOwner();
        require(data.length == 32, "bsm17");
        uint256 id;
        assembly {
            id := calldataload(100)
        }
        require(_ownerOf(id) == sender, "bsm18");

        // update
        _update(bonds[id].market);

        return bytes32(id);
    }

    /**
     * @inheritdoc IStakingModule
     */
    function clean(bytes calldata) external override {}

    // -- ERC20BondStakingModule -----------------------------------------

    /**
     * @notice open a new bond market
     * @param token the principal token that will be deposited
     * @param price minimum and starting price of the bond in tokens
     * @param coeff bond pricing coefficient in price increase per debt shares (24 decimals)
     * @param max maximum size for an individual bond in debt shares
     * @param capacity the total debt available for this market in shares
     */
    function open(
        address token,
        uint256 price,
        uint256 coeff,
        uint256 max,
        uint256 capacity
    ) external {
        requireController();
        require(markets[token].max == 0, "bsm19");
        require(_markets.length < MAX_MARKETS, "bsm20");
        require(price > 0, "bsm21");
        require(max > 0, "bsm22");
        require(capacity > 0, "bsm23");

        markets[token] = Market({
            price: price,
            coeff: coeff,
            max: max,
            capacity: capacity,
            principal: 0,
            vested: 0,
            debt: 0,
            start: uint128(block.timestamp),
            updated: uint128(block.timestamp)
        });
        _markets.push(token);
        _marketIndex[token] = _markets.length - 1;

        emit MarketOpened(token, price, coeff, max, capacity);
    }

    /**
     * @notice close an existing bond market
     * @param token the token address of the market to close
     */
    function close(address token) external {
        requireController();
        require(markets[token].capacity > 0, "bsm24");
        markets[token].capacity = 0;
        emit MarketClosed(token);
    }

    /**
     * @notice adjust the configuration of an existing bond market
     * @param token the token address of the market to adjust
     * @param price minimum and starting price of the bond in tokens
     * @param coeff bond pricing coefficient
     * @param max maximum size for an individual bond in debt shares
     * @param capacity the total debt available for this market in shares
     */
    function adjust(
        address token,
        uint256 price,
        uint256 coeff,
        uint256 max,
        uint256 capacity
    ) external {
        requireController();
        require(markets[token].max > 0, "bsm25");
        require(price > 0, "bsm26");
        require(max > 0, "bsm27");
        require(capacity > 0, "bsm28");

        // update
        _update(token);

        // adjust market
        markets[token].max = max;
        markets[token].capacity = capacity;

        // gradual adjustment for price related params
        adjustments[token] = Adjustment({
            price: price,
            coeff: coeff,
            timestamp: block.timestamp
        });

        emit MarketAdjusted(token, price, coeff, max, capacity);
    }

    /**
     * @notice withdraw vested principal token from market
     * @param token the principal token address
     * @param amount number of tokens to withdraw
     */
    function withdraw(address token, uint256 amount) external {
        requireController();
        // validate
        Market storage m = markets[token];
        require(m.max > 0, "bsm29");
        require(amount > 0, "bsm30");

        // update
        _update(token);

        IERC20 tkn = IERC20(token);
        uint256 shares = tkn.getShares(m.principal, amount);
        require(shares > 0);
        require(shares <= m.vested, "bsm31");

        // withdraw
        m.vested -= shares;
        m.principal -= shares;
        tkn.safeTransfer(msg.sender, amount);

        emit MarketBalanceWithdrawn(token, amount);
    }

    // -- ERC721 ---------------------------------------------------------

    /**
     * @inheritdoc IERC721Metadata
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        address metadata = _config.getAddress(
            keccak256("gysr.core.bond.metadata")
        );
        return IMetadata(metadata).metadata(address(this), tokenId, "");
    }

    // -- ERC20BondStakingModule internal --------------------------------

    /**
     * @dev internal helper to get token amount from shares
     * @param token address of token
     * @param shares number of shares
     */
    function _amount(
        address token,
        uint256 shares
    ) private view returns (uint256) {
        return IERC20(token).getAmount(markets[token].principal, shares);
    }

    /**
     * @dev internal market update helper for principal vesting, debt decay, and parameter tuning
     * @param token the token address of the market to update
     */
    function _update(address token) private {
        Market storage m = markets[token];

        uint256 updated = m.updated;
        uint256 elapsed = block.timestamp - updated;
        uint256 end = m.start + period;
        if (block.timestamp < end) {
            uint256 remaining = end - updated;

            // vest principal
            if (burndown) {
                uint256 vested = m.vested;
                m.vested =
                    vested +
                    ((m.principal - vested) * elapsed) /
                    remaining; // approximation, exact value upper bound
            }

            // decay debt
            uint256 debt = m.debt;
            m.debt = debt - (debt * elapsed) / remaining; // approximation, exact value lower bound
        } else {
            // vest principal
            if (burndown) m.vested = m.principal;

            // decay debt
            m.debt = 0;
        }

        // adjustments
        uint256 start = adjustments[token].timestamp;
        if (start > 0) {
            if (block.timestamp < start + period) {
                // interpolate
                uint256 target = adjustments[token].price;
                uint256 curr = m.price;
                uint256 remaining = start + period + elapsed - block.timestamp;
                if (target > curr) {
                    m.price = curr + ((target - curr) * elapsed) / remaining;
                } else {
                    m.price = curr - ((curr - target) * elapsed) / remaining;
                }
                target = adjustments[token].coeff;
                curr = m.coeff;
                if (target > curr) {
                    m.coeff = curr + ((target - curr) * elapsed) / remaining;
                } else {
                    m.coeff = curr - ((curr - target) * elapsed) / remaining;
                }
            } else {
                // complete adjustment
                m.price = adjustments[token].price;
                m.coeff = adjustments[token].coeff;
                delete adjustments[token];
            }
        }

        m.updated = uint128(block.timestamp);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) internal override {
        if (from != address(0)) _remove(from, tokenId);
        if (to != address(0)) _append(to, tokenId);
    }

    /**
     * @dev internal helper function to add bond position
     */
    function _append(address user, uint256 id) private {
        uint256 len = balanceOf(user);
        ownerBonds[user][len] = id;
        bondIndex[id] = len;
    }

    /**
     * @dev internal helper function to delete and reindex bond position
     */
    function _remove(address user, uint256 id) private {
        uint256 index = bondIndex[id];
        uint256 lastIndex = balanceOf(user) - 1;
        if (index != lastIndex) {
            uint256 lastId = ownerBonds[user][lastIndex];
            ownerBonds[user][index] = lastId;
            bondIndex[lastId] = index;
        }
        delete ownerBonds[user][lastIndex];
        delete bondIndex[id];
    }
}