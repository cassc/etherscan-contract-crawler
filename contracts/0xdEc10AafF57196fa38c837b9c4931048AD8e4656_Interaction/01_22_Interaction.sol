// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./dMath.sol";
import "./oracle/libraries/FullMath.sol";

import "./interfaces/VatLike.sol";
import "./interfaces/DavosJoinLike.sol";
import "./interfaces/GemJoinLike.sol";
import "./interfaces/JugLike.sol";
import "./interfaces/DogLike.sol";
import "./interfaces/PipLike.sol";
import "./interfaces/SpotLike.sol";
import "./interfaces/IRewards.sol";
import "./ceros/interfaces/IDavosProvider.sol";
import "./ceros/interfaces/IInteraction.sol";

import "./libraries/AuctionProxy.sol";


uint256 constant WAD = 10 ** 18;
uint256 constant RAD = 10 ** 45;
uint256 constant YEAR = 31556952; //seconds in year (365.2425 * 24 * 3600)

contract Interaction is Initializable, IInteraction {

    mapping(address => uint) public wards;

    function rely(address usr) external auth {wards[usr] = 1;}

    function deny(address usr) external auth {wards[usr] = 0;}
    modifier auth {
        require(wards[msg.sender] == 1, "Interaction/not-authorized");
        _;
    }

    VatLike public vat;
    SpotLike public spotter;
    IERC20Upgradeable public davos;
    DavosJoinLike public davosJoin;
    JugLike public jug;
    address public dog;
    IRewards public dgtRewards;

    mapping(address => uint256) public deposits;
    mapping(address => CollateralType) public collaterals;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => address) public davosProviders; // e.g. Auction purchase from ceamaticc to amaticc

    uint256 public whitelistMode;
    address public whitelistOperator;
    mapping(address => uint) public whitelist;
    function enableWhitelist() external auth {whitelistMode = 1;}
    function disableWhitelist() external auth {whitelistMode = 0;}
    function setWhitelistOperator(address usr) external auth {
        whitelistOperator = usr;
    }
    function addToWhitelist(address[] memory usrs) external operatorOrWard {
        for(uint256 i = 0; i < usrs.length; i++) {
            whitelist[usrs[i]] = 1;
            emit AddedToWhitelist(usrs[i]);
        }
    }
    function removeFromWhitelist(address[] memory usrs) external operatorOrWard {
        for(uint256 i = 0; i < usrs.length; i++) {
            whitelist[usrs[i]] = 0;
            emit RemovedFromWhitelist(usrs[i]);
        }
    }
    modifier whitelisted(address participant) {
        if (whitelistMode == 1)
            require(whitelist[participant] == 1, "Interaction/not-in-whitelist");
        _;
    }
    modifier operatorOrWard {
        require(msg.sender == whitelistOperator || wards[msg.sender] == 1, "Interaction/not-operator-or-ward"); 
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    function initialize(
        address vat_,
        address spot_,
        address davos_,
        address davosJoin_,
        address jug_,
        address dog_,
        address rewards_
    ) external initializer {

        wards[msg.sender] = 1;

        vat = VatLike(vat_);
        spotter = SpotLike(spot_);
        davos = IERC20Upgradeable(davos_);
        davosJoin = DavosJoinLike(davosJoin_);
        jug = JugLike(jug_);
        dog = dog_;
        dgtRewards = IRewards(rewards_);

        vat.hope(davosJoin_);

        davos.approve(davosJoin_, type(uint256).max);
    }

    function setCores(address vat_, address spot_, address davosJoin_,
        address jug_) public auth {
        // Reset previous approval
        davos.approve(address(davosJoin), 0);

        vat = VatLike(vat_);
        spotter = SpotLike(spot_);
        davosJoin = DavosJoinLike(davosJoin_);
        jug = JugLike(jug_);

        vat.hope(davosJoin_);

        davos.approve(davosJoin_, type(uint256).max);
    }

    function setDavosApprove() public auth {
        davos.approve(address(davosJoin), type(uint256).max);
    }

    function setCollateralType(
        address token,
        address gemJoin,
        bytes32 ilk,
        address clip,
        uint256 mat
    ) external auth {
        require(collaterals[token].live == 0, "Interaction/token-already-init");
        require(ilk != bytes32(0), "Interaction/empty-ilk");
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

    function setDavosProvider(address token, address davosProvider) external auth {
        require(davosProvider != address(0));
        davosProviders[token] = davosProvider;
        emit ChangeDavosProvider(davosProvider);
    }

    function removeCollateralType(address token) external auth {
        require(collaterals[token].live != 0, "Interaction/token-not-init");
        collaterals[token].live = 2; //STOPPED
        address gemJoin = address(collaterals[token].gem);
        vat.deny(gemJoin);
        IERC20Upgradeable(token).safeApprove(gemJoin, 0);
        emit CollateralDisabled(token, collaterals[token].ilk);
    }

    function reenableCollateralType(address token) external auth {
        collaterals[token].live = 1;
        address gemJoin = address(collaterals[token].gem);
        vat.rely(gemJoin);
        IERC20Upgradeable(token).safeApprove(gemJoin, type(uint256).max);
        emit CollateralEnabled(token, collaterals[token].ilk);
    }

    function stringToBytes32(string memory source) external pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function deposit(
        address participant,
        address token,
        uint256 dink
    ) external whitelisted(participant) returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        require(collateralType.live == 1, "Interaction/inactive-collateral");

        if (davosProviders[token] != address(0)) {
            require(
                msg.sender == davosProviders[token],
                "Interaction/only davos provider can deposit for this token"
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

    function borrow(address token, uint256 davosAmount) external returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        require(collateralType.live == 1, "Interaction/inactive-collateral");
        require(davosAmount > 0,"Interaction/invalid-davosAmount");

        drip(token);
        dropRewards(token, msg.sender);

        (, uint256 rate, , ,) = vat.ilks(collateralType.ilk);
        int256 dart = int256(davosAmount * RAY / rate);
        require(dart >= 0, "Interaction/too-much-requested");
        if (uint256(dart) * rate < davosAmount * RAY) {
            dart += 1; //ceiling
        }
        vat.frob(collateralType.ilk, msg.sender, msg.sender, msg.sender, 0, dart);
        vat.move(msg.sender, address(this), davosAmount * RAY);
        davosJoin.exit(msg.sender, davosAmount);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, msg.sender);
        uint256 liqPrice = liquidationPriceForDebt(collateralType.ilk, ink, art);
        emit Borrow(msg.sender, token, ink, davosAmount, liqPrice);
        return uint256(dart);
    }

    function dropRewards(address token, address usr) public {
        dgtRewards.drop(token, usr);
    }

    // Burn user's DAVOS.
    // N.B. User collateral stays the same.
    function payback(address token, uint256 davosAmount) external returns (int256) {
        require(davosAmount > 0,"Interaction/invalid-davosAmount");
        CollateralType memory collateralType = collaterals[token];
        // _checkIsLive(collateralType.live); Checking in the `drip` function

        (,uint256 rate,,,) = vat.ilks(collateralType.ilk);
        (,uint256 art) = vat.urns(collateralType.ilk, msg.sender);
        int256 dart;
        uint256 realAmount = davosAmount;
        uint256 debt = rate * art;
        if (realAmount * RAY >= debt) { // Close CDP
            dart = int(art);
            realAmount = debt / RAY;
            realAmount = realAmount * RAY == debt ? realAmount : realAmount + 1;
        } else { // Less/Greater than dust
            dart = int256(FullMath.mulDiv(realAmount, RAY, rate));
        }

        IERC20Upgradeable(davos).safeTransferFrom(msg.sender, address(this), realAmount);
        davosJoin.join(msg.sender, realAmount);

        require(dart >= 0, "Interaction/too-much-requested");

        vat.frob(collateralType.ilk, msg.sender, msg.sender, msg.sender, 0, - dart);
        dropRewards(token, msg.sender);

        drip(token);

        (uint256 ink, uint256 userDebt) = vat.urns(collateralType.ilk, msg.sender);
        uint256 liqPrice = liquidationPriceForDebt(collateralType.ilk, ink, userDebt);
        emit Payback(msg.sender, token, realAmount, userDebt, liqPrice);
        return dart;
    }

    // Unlock and transfer to the user `dink` amount of aMATICc
    function withdraw(
        address participant,
        address token,
        uint256 dink
    ) external returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);
        if (davosProviders[token] != address(0)) {
            require(
                msg.sender == davosProviders[token],
                "Interaction/Only davos provider can call this function for this token"
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
        dgtRewards = IRewards(rewards);
        emit ChangeRewards(rewards);
    }

    //    /////////////////////////////////
    //    //// VIEW                    ////
    //    /////////////////////////////////

    // Price of the collateral asset(aMATICc) from Oracle
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

    // Returns the DAVOS price in $
    function davosPrice(address token) external view returns (uint256) {
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

    // Total aMATICc deposited nominated in $
    function depositTVL(address token) external view returns (uint256) {
        return deposits[token] * collateralPrice(token) / WAD;
    }

    // Total DAVOS borrowed by all users
    function collateralTVL(address token) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 Art, uint256 rate,,,) = vat.ilks(collateralType.ilk);
        return FullMath.mulDiv(Art, rate, RAY);
    }

    // Not locked user balance in aMATICc
    function free(address token, address usr) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        return vat.gem(collateralType.ilk, usr);
    }

    // User collateral in aMATICc
    function locked(address token, address usr) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink,) = vat.urns(collateralType.ilk, usr);
        return ink;
    }

    // Total borrowed DAVOS
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

    // Collateral minus borrowed. Basically free collateral (nominated in DAVOS)
    function availableToBorrow(address token, address usr) external view returns (int256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        (, uint256 rate, uint256 spot,,) = vat.ilks(collateralType.ilk);
        uint256 collateral = ink * spot;
        uint256 debt = rate * art;
        return (int256(collateral) - int256(debt)) / 1e27;
    }

    // Collateral + `amount` minus borrowed. Basically free collateral (nominated in DAVOS)
    // Returns how much davos you can borrow if provide additional `amount` of collateral
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

    // Price of aMATICc when user will be liquidated
    function currentLiquidationPrice(address token, address usr) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        return liquidationPriceForDebt(collateralType.ilk, ink, art);
    }

    // Price of aMATICc when user will be liquidated with additional amount of aMATICc deposited/withdraw
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

    // Price of aMATICc when user will be liquidated with additional amount of DAVOS borrowed/payback
    //positive amount mean DAVOSs are being borrowed. So art(debt) will increase
    function estimatedLiquidationPriceDAVOS(address token, address usr, int256 amount) external view returns (uint256) {
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
        uint256 principal = dMath.rpow((jug.base() + duty), YEAR, RAY);
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
        IDavosProvider provider = IDavosProvider(davosProviders[token]);
        uint256 auctionAmount = AuctionProxy.startAuction(
            user,
            keeper,
            davos,
            davosJoin,
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
        IDavosProvider davosProvider = IDavosProvider(davosProviders[token]);
        uint256 leftover = AuctionProxy.buyFromAuction(
            auctionId,
            collateralAmount,
            maxPrice,
            receiverAddress,
            davos,
            davosJoin,
            vat,
            davosProvider,
            collateral
        );

        address urn = ClipperLike(collateral.clip).sales(auctionId).usr; // Liquidated address
        dropRewards(address(davos), urn);

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
        AuctionProxy.resetAuction(auctionId, keeper, davos, davosJoin, vat, collaterals[token]);
    }

    function totalPegLiquidity() external view returns (uint256) {
        return IERC20Upgradeable(davos).totalSupply();
    }

    function _checkIsLive(uint256 live) internal pure {
        require(live != 0, "Interaction/inactive collateral");
    }
}