// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./hMath.sol";
import "./oracle/libraries/FullMath.sol";

import "./interfaces/VatLike.sol";
import "./interfaces/HayJoinLike.sol";
import "./interfaces/GemJoinLike.sol";
import "./interfaces/JugLike.sol";
import "./interfaces/DogLike.sol";
import "./interfaces/PipLike.sol";
import "./interfaces/SpotLike.sol";
import "./interfaces/IRewards.sol";
import "./interfaces/IAuctionProxy.sol";
import "./ceros/interfaces/IHelioProvider.sol";
import "./ceros/interfaces/IDao.sol";

import "./libraries/AuctionProxy.sol";

uint256 constant WAD = 10 ** 18;
uint256 constant RAD = 10 ** 45;
uint256 constant YEAR = 31556952; //seconds in year (365.2425 * 24 * 3600)

contract Interaction is OwnableUpgradeable, IDao, IAuctionProxy {

    mapping(address => uint) public wards;
    function rely(address usr) external auth {wards[usr] = 1;}
    function deny(address usr) external auth {wards[usr] = 0;}
    modifier auth {
        require(wards[msg.sender] == 1, "Interaction/not-authorized");
        _;
    }

    VatLike public vat;
    SpotLike public spotter;
    IERC20Upgradeable public hay;
    HayJoinLike public hayJoin;
    JugLike public jug;
    address public dog;
    IRewards public helioRewards;

    mapping(address => uint256) public deposits;
    mapping(address => CollateralType) public collaterals;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => address) public helioProviders; // e.g. Auction purchase from ceabnbc to abnbc

    uint256 public whitelistMode;
    address public whitelistOperator;
    mapping(address => uint) public whitelist;
    function enableWhitelist() external auth {whitelistMode = 1;}
    function disableWhitelist() external auth {whitelistMode = 0;}
    // function setWhitelistOperator(address usr) external auth {
    //     whitelistOperator = usr;
    // }
    // function addToWhitelist(address[] memory usrs) external operatorOrWard {
    //     for(uint256 i = 0; i < usrs.length; i++)
    //         whitelist[usrs[i]] = 1;
    // }
    // function removeFromWhitelist(address[] memory usrs) external operatorOrWard {
    //     for(uint256 i = 0; i < usrs.length; i++)
    //         whitelist[usrs[i]] = 0;
    // }
    modifier whitelisted(address participant) {
        if (whitelistMode == 1)
            require(whitelist[participant] == 1, "Interaction/not-in-whitelist");
        _;
    }
    // modifier operatorOrWard {
    //     require(msg.sender == whitelistOperator || wards[msg.sender] == 1, "Interaction/not-operator-or-ward");
    //     _;
    // }
    mapping(address => uint) public blacklist;
    function editBlack(address[] memory users, uint256[] memory flags) external auth {
        require(users.length == flags.length, "Interaction/length-mismatch");
        for(uint256 i = 0; i < users.length; i++)
            blacklist[users[i]] = flags[i];
    }
    modifier blacklisted(address participant) {
        if(blacklist[participant] != 0)
            revert("Blacklisted");
        _;
    }

    function initialize(
        address vat_,
        address spot_,
        address hay_,
        address hayJoin_,
        address jug_,
        address dog_,
        address rewards_
    ) public initializer {
        __Ownable_init();

        wards[msg.sender] = 1;

        vat = VatLike(vat_);
        spotter = SpotLike(spot_);
        hay = IERC20Upgradeable(hay_);
        hayJoin = HayJoinLike(hayJoin_);
        jug = JugLike(jug_);
        dog = dog_;
        helioRewards = IRewards(rewards_);

        vat.hope(hayJoin_);

        hay.approve(hayJoin_, type(uint256).max);
    }

    function setCores(address vat_, address spot_, address hayJoin_,
        address jug_) public auth {
        // Reset previous approval
        hay.approve(address(hayJoin), 0);

        vat = VatLike(vat_);
        spotter = SpotLike(spot_);
        hayJoin = HayJoinLike(hayJoin_);
        jug = JugLike(jug_);

        vat.hope(hayJoin_);

        hay.approve(hayJoin_, type(uint256).max);
    }

    function setHayApprove() public auth {
        hay.approve(address(hayJoin), type(uint256).max);
    }

    function setCollateralType(
        address token,
        address gemJoin,
        bytes32 ilk,
        address clip,
        uint256 mat
    ) external auth {
        require(collaterals[token].live == 0, "Interaction/token-already-init");
        vat.init(ilk);
        jug.init(ilk);
        spotter.file(ilk, "mat", mat);
        collaterals[token] = CollateralType(GemJoinLike(gemJoin), ilk, 1, clip);
        IERC20Upgradeable(token).safeApprove(gemJoin, type(uint256).max);
        vat.rely(gemJoin);
        emit CollateralEnabled(token, ilk);
    }

    function setCollateralDuty(address token, uint data) external auth {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);
        jug.drip(collateralType.ilk);
        jug.file(collateralType.ilk, "duty", data);
    }

    function setHelioProvider(address token, address helioProvider) external auth {
        helioProviders[token] = helioProvider;
    }

    function removeCollateralType(address token) external auth {
        require(collaterals[token].live != 0, "Interaction/token-not-init");
        collaterals[token].live = 2; //STOPPED
        address gemJoin = address(collaterals[token].gem);
        vat.deny(gemJoin);
        IERC20Upgradeable(token).safeApprove(gemJoin, 0);
        emit CollateralDisabled(token, collaterals[token].ilk);
    }

    // function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    //     bytes memory tempEmptyStringTest = bytes(source);
    //     if (tempEmptyStringTest.length == 0) {
    //         return 0x0;
    //     }

    //     assembly {
    //         result := mload(add(source, 32))
    //     }
    // }

    function deposit(
        address participant,
        address token,
        uint256 dink
    ) external whitelisted(participant) blacklisted(participant) returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        require(collateralType.live == 1, "Interaction/inactive-collateral");

        if (helioProviders[token] != address(0)) {
            require(
                msg.sender == helioProviders[token],
                "Interaction/only helio provider can deposit for this token"
            );
        }
        require(dink <= uint256(type(int256).max), "Interaction/too-much-requested");
        drip(token);
        uint256 preBalance = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), dink);
        uint256 postBalance = IERC20Upgradeable(token).balanceOf(address(this));
        require(preBalance + dink == postBalance, "Interaction/deposit-deflated");

        collateralType.gem.join(participant, dink);
        vat.behalf(participant, address(this));
        vat.frob(collateralType.ilk, participant, participant, participant, int256(dink), 0);

        deposits[token] += dink;

        emit Deposit(participant, token, dink, locked(token, participant));
        return dink;
    }

    function borrow(address token, uint256 hayAmount) external blacklisted(msg.sender) returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        require(collateralType.live == 1, "Interaction/inactive-collateral");

        drip(token);
        dropRewards(token, msg.sender);

        (, uint256 rate, , ,) = vat.ilks(collateralType.ilk);
        int256 dart = int256(hayAmount * RAY / rate);
        require(dart >= 0, "Interaction/too-much-requested");

        if (uint256(dart) * rate < hayAmount * RAY) {
            dart += 1; //ceiling
        }

        vat.frob(collateralType.ilk, msg.sender, msg.sender, msg.sender, 0, dart);
        vat.move(msg.sender, address(this), hayAmount * RAY);
        hayJoin.exit(msg.sender, hayAmount);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, msg.sender);
        uint256 liqPrice = liquidationPriceForDebt(collateralType.ilk, ink, art);
        emit Borrow(msg.sender, token, ink, hayAmount, liqPrice);
        return uint256(dart);
    }

    function dropRewards(address token, address usr) public {
        helioRewards.drop(token, usr);
    }

    // Burn user's HAY.
    // N.B. User collateral stays the same.
    function payback(address token, uint256 hayAmount) external blacklisted(msg.sender) returns (int256) {
        CollateralType memory collateralType = collaterals[token];
        // _checkIsLive(collateralType.live); Checking in the `drip` function

        (,uint256 rate,,,) = vat.ilks(collateralType.ilk);
        (,uint256 art) = vat.urns(collateralType.ilk, msg.sender);

        int256 dart;
        uint256 realAmount = hayAmount;

        uint256 debt = rate * art;
        if (realAmount * RAY >= debt) { // Close CDP
            dart = int(art);
            realAmount = debt / RAY;
            realAmount = realAmount * RAY == debt ? realAmount : realAmount + 1;
        } else { // Less/Greater than dust
            dart = int256(FullMath.mulDiv(realAmount, RAY, rate));
        }

        IERC20Upgradeable(hay).safeTransferFrom(msg.sender, address(this), realAmount);
        hayJoin.join(msg.sender, realAmount);
        
        require(dart >= 0, "Interaction/too-much-requested");

        vat.frob(collateralType.ilk, msg.sender, msg.sender, msg.sender, 0, - dart);
        dropRewards(token, msg.sender);
        drip(token);

        (uint256 ink, uint256 userDebt) = vat.urns(collateralType.ilk, msg.sender);
        uint256 liqPrice = liquidationPriceForDebt(collateralType.ilk, ink, userDebt);

        emit Payback(msg.sender, token, realAmount, userDebt, liqPrice);
        return dart;
    }

    // Unlock and transfer to the user `dink` amount of ceABNBc
    function withdraw(
        address participant,
        address token,
        uint256 dink
    ) external blacklisted(participant) returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);
        if (helioProviders[token] != address(0)) {
            require(
                msg.sender == helioProviders[token],
                "Interaction/Only helio provider can call this function for this token"
            );
        } else {
            require(
                msg.sender == participant,
                "Interaction/Caller must be the same address as participant"
            );
        }

        uint256 unlocked = free(token, participant);
        if (unlocked < dink) {
            int256 diff = int256(dink) - int256(unlocked);
            vat.frob(collateralType.ilk, participant, participant, participant, - diff, 0);
            vat.flux(collateralType.ilk, participant, address(this), uint256(diff));
        }
        // Collateral is actually transferred back to user inside `exit` operation.
        // See GemJoin.exit()
        collateralType.gem.exit(msg.sender, dink);
        deposits[token] -= dink;

        emit Withdraw(participant, dink);
        return dink;
    }

    function drip(address token) public {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        jug.drip(collateralType.ilk);
    }

    function poke(address token) public {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        spotter.poke(collateralType.ilk);
    }

    function setRewards(address rewards) external auth {
        helioRewards = IRewards(rewards);
    }

    //    /////////////////////////////////
    //    //// VIEW                    ////
    //    /////////////////////////////////

    // Price of the collateral asset(ceABNBc) from Oracle
    function collateralPrice(address token) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (PipLike pip,) = spotter.ilks(collateralType.ilk);
        (bytes32 price, bool has) = pip.peek();
        if (has) {
            return uint256(price);
        } else {
            return 0;
        }
    }

    // Returns the HAY price in $
    function hayPrice(address token) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (, uint256 rate,,,) = vat.ilks(collateralType.ilk);
        return rate / 10 ** 9;
    }

    // Returns the collateral ratio in percents with 18 decimals
    function collateralRate(address token) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (,uint256 mat) = spotter.ilks(collateralType.ilk);
        require(mat != 0, "Interaction/spot-not-init");
        return 10 ** 45 / mat;
    }

    // Total ceABNBc deposited nominated in $
    function depositTVL(address token) external view returns (uint256) {
        return deposits[token] * collateralPrice(token) / WAD;
    }

    // Total HAY borrowed by all users
    function collateralTVL(address token) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 Art, uint256 rate,,,) = vat.ilks(collateralType.ilk);
        return FullMath.mulDiv(Art, rate, RAY);
    }

    // Not locked user balance in ceABNBc
    function free(address token, address usr) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        return vat.gem(collateralType.ilk, usr);
    }

    // User collateral in ceABNBc
    function locked(address token, address usr) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink,) = vat.urns(collateralType.ilk, usr);
        return ink;
    }

    // Total borrowed HAY
    function borrowed(address token, address usr) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (,uint256 rate,,,) = vat.ilks(collateralType.ilk);
        (, uint256 art) = vat.urns(collateralType.ilk, usr);

        // 100 Wei is added as a ceiling to help close CDP in repay()
        if ((art * rate) / RAY != 0) {
            return ((art * rate) / RAY) + 100;
        }
        else {
            return 0;
        }
    }

    // Collateral minus borrowed. Basically free collateral (nominated in HAY)
    function availableToBorrow(address token, address usr) external view returns (int256 amount) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        (, uint256 rate, uint256 spot,,) = vat.ilks(collateralType.ilk);
        uint256 collateral = ink * spot;
        uint256 debt = rate * art;
        amount = (int256(collateral) - int256(debt)) / 1e27;
        
        if(amount < 0) return 0;
    }

    // Collateral + `amount` minus borrowed. Basically free collateral (nominated in HAY)
    // Returns how much hay you can borrow if provide additional `amount` of collateral
    function willBorrow(address token, address usr, int256 amount) external view returns (int256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        (, uint256 rate, uint256 spot,,) = vat.ilks(collateralType.ilk);
        require(amount >= - (int256(ink)), "Cannot withdraw more than current amount");
        if (amount < 0) {
            ink = uint256(int256(ink) + amount);
        } else {
            ink += uint256(amount);
        }
        uint256 collateral = ink * spot;
        uint256 debt = rate * art;
        return (int256(collateral) - int256(debt)) / 1e27;
    }

    function liquidationPriceForDebt(bytes32 ilk, uint256 ink, uint256 art) internal view returns (uint256) {
        if (ink == 0) {
            return 0; // no meaningful price if user has no debt
        }
        (, uint256 rate,,,) = vat.ilks(ilk);
        (,uint256 mat) = spotter.ilks(ilk);
        uint256 backedDebt = (art * rate / 10 ** 36) * mat;
        return backedDebt / ink;
    }

    // Price of ceABNBc when user will be liquidated
    function currentLiquidationPrice(address token, address usr) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        return liquidationPriceForDebt(collateralType.ilk, ink, art);
    }

    // Price of ceABNBc when user will be liquidated with additional amount of ceABNBc deposited/withdraw
    function estimatedLiquidationPrice(address token, address usr, int256 amount) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        require(amount >= - (int256(ink)), "Cannot withdraw more than current amount");
        if (amount < 0) {
            ink = uint256(int256(ink) + amount);
        } else {
            ink += uint256(amount);
        }
        return liquidationPriceForDebt(collateralType.ilk, ink, art);
    }

    // Price of ceABNBc when user will be liquidated with additional amount of HAY borrowed/payback
    //positive amount mean HAYs are being borrowed. So art(debt) will increase
    function estimatedLiquidationPriceHAY(address token, address usr, int256 amount) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        require(amount >= - (int256(art)), "Cannot withdraw more than current amount");
        (, uint256 rate,,,) = vat.ilks(collateralType.ilk);
        (,uint256 mat) = spotter.ilks(collateralType.ilk);
        uint256 backedDebt = FullMath.mulDiv(art, rate, 10 ** 36);
        if (amount < 0) {
            backedDebt = uint256(int256(backedDebt) + amount);
        } else {
            backedDebt += uint256(amount);
        }
        return FullMath.mulDiv(backedDebt, mat, ink) / 10 ** 9;
    }

    // Returns borrow APR with 20 decimals.
    // I.e. 10% == 10 ethers
    function borrowApr(address token) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 duty,) = jug.ilks(collateralType.ilk);
        uint256 principal = hMath.rpow((jug.base() + duty), YEAR, RAY);
        return (principal - RAY) / (10 ** 7);
    }

    function startAuction(
        address token,
        address user,
        address keeper
    ) external returns (uint256) {
        dropRewards(token, user);
        CollateralType memory collateral = collaterals[token];
        (uint256 ink,) = vat.urns(collateral.ilk, user);
        IHelioProvider provider = IHelioProvider(helioProviders[token]);
        uint256 auctionAmount = AuctionProxy.startAuction(
            user,
            keeper,
            hay,
            hayJoin,
            vat,
            DogLike(dog),
            provider,
            collateral
        );

        emit AuctionStarted(token, user, ink, collateralPrice(token));
        return auctionAmount;
    }

    function buyFromAuction(
        address token,
        uint256 auctionId,
        uint256 collateralAmount,
        uint256 maxPrice,
        address receiverAddress
    ) external {
        CollateralType memory collateral = collaterals[token];
        IHelioProvider helioProvider = IHelioProvider(helioProviders[token]);
        uint256 leftover = AuctionProxy.buyFromAuction(
            auctionId,
            collateralAmount,
            maxPrice,
            receiverAddress,
            hay,
            hayJoin,
            vat,
            helioProvider,
            collateral
        );

        address urn = ClipperLike(collateral.clip).sales(auctionId).usr; // Liquidated address
        dropRewards(address(hay), urn);

        emit Liquidation(urn, token, collateralAmount, leftover);
    }

    function getAuctionStatus(address token, uint256 auctionId) external view returns(bool, uint256, uint256, uint256) {
        return ClipperLike(collaterals[token].clip).getStatus(auctionId);
    }

    function upchostClipper(address token) external {
        ClipperLike(collaterals[token].clip).upchost();
    }

    function getAllActiveAuctionsForToken(address token) external view returns (Sale[] memory sales) {
        return AuctionProxy.getAllActiveAuctionsForClip(ClipperLike(collaterals[token].clip));
    }

    function resetAuction(address token, uint256 auctionId, address keeper) external {
        AuctionProxy.resetAuction(auctionId, keeper, hay, hayJoin, vat, collaterals[token]);
    }

    function totalPegLiquidity() external view returns (uint256) {
        return IERC20Upgradeable(hay).totalSupply();
    }

    function _checkIsLive(uint256 live) internal pure {
        require(live != 0, "Interaction/inactive collateral");
    }

    function rollbackInteraction(address token, uint256 _deposit, address[] memory users, uint256[] memory dink, uint256 _rate) external auth {
        // Must be equal in length
        require(users.length == dink.length, "Interaction/length-mismatch");

        // Rollback token total deposit
        deposits[token] = _deposit;

        // Rollback inks in vat
        IGeneralRollback _vat = IGeneralRollback(address(vat));
        IGeneralRollback _hp = IGeneralRollback(helioProviders[token]);
        for(uint256 i = 0; i < users.length; i++) {
            
            (uint256 diff, uint256 flag) = _vat.rollbackInk(users[i], dink[i]);
            if(flag == 0) {
                _hp.daoBurn(users[i], diff);
                _hp.emitWithdraw(users[i], diff);
                emit Withdraw(users[i], diff);
            }
            else if (flag == 1) {
                _hp.daoMint(users[i], diff);
                _hp.emitDeposit(users[i], diff);
                emit Deposit(users[i], token, diff, locked(token, users[i]));
            }
        }

        // Rollback rate in vat
        _vat.rollbackRate(_rate);

        // Rollback rho in jug
        IGeneralRollback(address(jug)).rollbackJug();   
    }
}

interface IGeneralRollback {
    function rollbackInk(address user, uint256 oldInk) external returns(uint256 diff, uint256 flag);
    function rollbackRate(uint256 rate) external;
    function daoBurn(address account, uint256 value) external;
    function daoMint(address account, uint256 value) external;
    function rollbackJug() external;
    function emitWithdraw(address recipient, uint256 diff) external;
    function emitDeposit(address user, uint256 diff) external;
}