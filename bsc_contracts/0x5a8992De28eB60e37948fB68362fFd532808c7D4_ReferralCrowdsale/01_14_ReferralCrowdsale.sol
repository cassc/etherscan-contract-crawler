//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./interfaces/IPair.sol";
import "./interfaces/IStaking.sol";

import "./pancake-swap/libraries/TransferHelper.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ReferralCrowdsale is AccessControl {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant MAX_ENABLED_LINKS = 5;
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant BACKEND_ROLE = keccak256("BACKEND_ROLE");

    address public immutable BTCMT;
    IStaking public immutable AUTOFARM;
    IStakingOwn public immutable STAKING;

    DexInfo public dexInfo;
    LevelInfo[] public levels;

    EnumerableSet.AddressSet private paymentsTokens;

    mapping(address => KidStatistic) public kidStatistic;
    mapping(bytes32 => LinkStatistic) public linkStatistic;
    mapping(address => FatherStatistic) public fatherStatistic;

    mapping(address => KidInfo) public kids;
    mapping(bytes32 => LinkInfo) public links;
    mapping(address => FatherInfo) private fathers;

    mapping(uint256 => bool) private availableFatherPercents;

    struct FatherInfo {
        address[] allKids;
        bytes32[] allLinks;
        EnumerableSet.Bytes32Set linksEndbled;
    }

    struct KidInfo {
        bool registered;
        bool comeSecondTime;
        bytes32 fatherLink;
    }

    struct LinkInfo {
        bool enabled;
        address owner;
        uint256 ownerPercent;
    }

    struct LevelInfo {
        uint256 threshold;
        uint256 bonusPercent;
    }

    struct DexInfo {
        bool enabled;
        address pair;
        address token0;
        address token1;
        uint256 floorPrice;
    }

    struct LinkStatistic {
        uint256 totalSons;
        uint256 totalSonsTwice;
        uint256 totalBought;
        uint256 totalBonuses;
    }

    struct FatherStatistic {
        uint256 totalKids;
        uint256 btcmtKidBought;
        uint256 usdtKidSpent;
        uint256 totalBonuses;
    }

    struct KidStatistic {
        uint256 numOfPurchases;
        uint256 sumOfPurchases;
        uint256 sumOfBonuses;
        uint256 firstPurchaseDate;
    }

    struct LinkParameters {
        bytes32 linkHash;
        address linkFather;
        address linkSon;
        uint256 fatherPercent;
        bytes linkSignature;
    }

    struct PurchaseParameters {
        bool give;
        address paymentToken;
        uint256 usdtAmount;
        uint256 btcmtAmount;
        uint256 expirationTime;
        bytes buySignature;
    }

    event PurchaseWithBonuses(
        bytes32 linkHash,
        uint256 boughtAmount,
        uint256 fatherBonus,
        address fatherAddress,
        uint256 sonBonus,
        address sonAddress,
        uint256 amountLeft
    );

    event NewLinkCreated(
        bytes32 link,
        address linkFather,
        uint256 fatherPercent,
        uint256 sonPercent
    );

    event NewUserRegistered(address newUser, address father, bytes32 link);

    event LinkDeactivated(bytes32 linkHash, address linkFather);

    // 0 - BTCMT, 1 - USDT, 2 - regular staking, 3 - autofarm, 4 - BTCMT-USDT pair, 5 - signer, 6 - backend
    constructor(
        address[7] memory _addresses,
        LevelInfo[] memory _levels,
        uint256 _floorPrice
    ) {
        require(
            _addresses[0] != address(0) &&
                _addresses[1] != address(0) &&
                _addresses[2] != address(0) &&
                _addresses[3] != address(0) &&
                _addresses[4] != address(0) &&
                _addresses[5] != address(0) &&
                _addresses[6] != address(0),
            "0x00..."
        );
        BTCMT = _addresses[0];
        STAKING = IStakingOwn(_addresses[2]);
        AUTOFARM = IStaking(_addresses[3]);
        dexInfo = DexInfo(
            true,
            _addresses[4],
            IPair(_addresses[4]).token0(),
            IPair(_addresses[4]).token1(),
            _floorPrice
        );
        require(
            BTCMT == dexInfo.token0 || BTCMT == dexInfo.token1,
            "Wrong pair address"
        );

        for (uint256 i; i < _levels.length; i++) {
            if (i > 0)
                require(
                    _levels[i - 1].threshold < _levels[i].threshold,
                    "Wrong order"
                );
            levels.push(_levels[i]);
        }
        availableFatherPercents[0] = true;
        availableFatherPercents[2500] = true;
        availableFatherPercents[5000] = true;
        availableFatherPercents[7500] = true;
        availableFatherPercents[10000] = true;

        links[bytes32(0)].enabled = true;

        paymentsTokens.add(_addresses[1]);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _addresses[5]);
        _setupRole(BACKEND_ROLE, _addresses[6]);
    }

    /** @dev Allows an admin to claim @param _token from this contract
     * @notice available for admin only
     */
    function claimTokens(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_token != address(0), "0x00...");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) {
            TransferHelper.safeTransfer(_token, _msgSender(), balance);
        }
    }

    /** @dev Allows an admin to change pair address
     * @param _pair address (BTCMT-USDT)
     * @notice available for admin only
     */
    function changePairAddress(address _pair)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_pair != address(0), "0x00...");
        dexInfo.pair = _pair;
        dexInfo.token0 = IPair(_pair).token0();
        dexInfo.token1 = IPair(_pair).token1();
        require(
            (dexInfo.token0 == address(BTCMT) ||
                dexInfo.token1 == address(BTCMT)) &&
                (dexInfo.token0 != dexInfo.token1),
            "Wrong pair address"
        );
    }

    /** @dev Allows an admin to change dex status
     * (get price from pair or from backend)
     * @notice available for admin only
     */
    function changeDexStatus() external onlyRole(DEFAULT_ADMIN_ROLE) {
        dexInfo.enabled = !dexInfo.enabled;
    }

    /** @dev Allows an admin to add payment token
     * @notice available for admin only
     */
    function addPaymentToken(address _token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _token != address(0) &&
                !paymentsTokens.contains(_token) &&
                _token != BTCMT,
            "Wrong token address"
        );
        paymentsTokens.add(_token);
    }

    /** @dev Allows an admin to remove payment token
     * @notice available for admin only
     */
    function removePaymentToken(address _token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(paymentsTokens.contains(_token), "Wrong token address");
        paymentsTokens.remove(_token);
    }

    /** @dev Allows an admin to change floor price
     * @param _value new value for floor price
     * @notice available for admin only
     */
    function changeFloorPrice(uint256 _value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        dexInfo.floorPrice = _value;
    }

    /** @dev Allows an admin to change levels
     * @param _levels an array of new level's values
     * @notice available for admin only
     */
    function changeLevels(LevelInfo[] memory _levels)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_levels.length == levels.length, "Wrong length");
        for (uint256 i; i < _levels.length; i++) {
            if (i > 0)
                require(
                    _levels[i - 1].threshold < _levels[i].threshold,
                    "Wrong order"
                );
            levels[i] = _levels[i];
        }
    }

    /** @dev Allows an admin or link owner deactivate link
     * @param linkHash link to deactivate
     * @notice available for admin or link owner only
     */
    function deactivateLink(bytes32 linkHash) external {
        LinkInfo storage link = links[linkHash];
        require(
            link.owner == _msgSender() ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Wrong sender"
        );
        require(link.enabled, "Already disabled");
        link.enabled = false;
        fathers[link.owner].linksEndbled.remove(linkHash);
        emit LinkDeactivated(linkHash, link.owner);
    }

    /** @dev Allows to buy BTCMT tokens and get bonuses
     * @notice if give is true, available for backend only
     * @param linkParams parameters of referral link (hash, owner, percent, etc.).
     * For more information, see LinkParameters structure.
     * @param purchaseParams parameters of purchase (payment token, amount to pay, amount to buy, etc.).
     * For more information, see PurchaseParameters structure.
     */
    function buyTokens(
        LinkParameters memory linkParams,
        PurchaseParameters memory purchaseParams
    ) external {
        require(purchaseParams.usdtAmount > 0, "Wrong amount");

        if (purchaseParams.give) {
            require(
                hasRole(BACKEND_ROLE, _msgSender()),
                "Only back provides give"
            );
            require(linkParams.linkSon != address(0), "Wrong son address");
            require(purchaseParams.btcmtAmount > 0, "Zero BTCMT amount");
            _checkLink(linkParams);
        } else {
            linkParams.linkSon = _msgSender();
            _checkLink(linkParams);
        }

        uint256 bonusPercent = (linkParams.linkHash == bytes32(0))
            ? 0
            : getUserBonusPercent(links[linkParams.linkHash].owner);

        if (purchaseParams.give) {
            _give(
                linkParams.linkSon,
                purchaseParams.usdtAmount,
                purchaseParams.btcmtAmount,
                bonusPercent,
                linkParams.linkHash
            );
        } else {
            require(
                paymentsTokens.contains(purchaseParams.paymentToken),
                "Wrong paymentToken"
            );
            if (dexInfo.enabled) {
                _buyFromDex(
                    purchaseParams.paymentToken,
                    purchaseParams.usdtAmount,
                    bonusPercent,
                    linkParams.linkHash
                );
            } else {
                _buyFromCex(
                    purchaseParams.paymentToken,
                    purchaseParams.usdtAmount,
                    purchaseParams.btcmtAmount,
                    purchaseParams.expirationTime,
                    purchaseParams.buySignature,
                    bonusPercent,
                    linkParams.linkHash
                );
            }
        }
    }

    /** @dev View function to get the list of all payment tokens
     * @return list of all payment tokens
     */
    function getAllPaymentTokens() external view returns (address[] memory) {
        return paymentsTokens.values();
    }

    /** @dev Get stake amounts of @param user from STAKING and AUTOFARM contracts
     * @return sum of user's stake amounts
     */
    function getUserTotalStake(address user) public view returns (uint256) {
        (uint256 autofarmStake, , ) = AUTOFARM.userStake(user);
        return STAKING.userStakes(user).totalAmount + autofarmStake;
    }

    /** @dev Get user bonus percent according to his level (his stake amount)
     * @param user address
     * @return user bonus percent
     */
    function getUserBonusPercent(address user) public view returns (uint256) {
        uint256 totalStake = getUserTotalStake(user);
        for (uint256 i = levels.length - 1; ; i--) {
            if (totalStake >= levels[i].threshold) {
                return levels[i].bonusPercent;
            }
            if (i == 0) break;
        }
        return 0;
    }

    /** @dev Get price from BTCMT-USDT pair and calculate output BTCMT amount
     * @param payAmount USDT
     * @return BTCMT output amount (0 if empty reserves/payAmount == 0/ dexInfo.enabled == false)
     */
    function getPrice(uint256 payAmount) public view returns (uint256) {
        if (payAmount == 0) return 0;
        if (dexInfo.enabled) {
            (uint112 reserve0, uint112 reserve1, ) = IPair(dexInfo.pair)
                .getReserves();

            if (reserve0 == 0 || reserve1 == 0) return 0;

            uint256 reserveUsdt;
            uint256 reserveBtcmt;
            if (address(BTCMT) == dexInfo.token0) {
                reserveBtcmt = reserve0;
                reserveUsdt = reserve1;
            } else {
                reserveBtcmt = reserve1;
                reserveUsdt = reserve0;
            }

            return (payAmount * reserveBtcmt) / (reserveUsdt);
        } else return 0;
    }

    /** Get amount to pay from output BTCMT amount
     * @param receiveAmount BTCMT
     * @return USDT input amount (0 if empty reserves/receiveAmount == 0/ dexInfo.enabled == false)
     */
    function getAmountToPay(uint256 receiveAmount)
        public
        view
        returns (uint256)
    {
        if (receiveAmount == 0) return 0;
        if (dexInfo.enabled) {
            (uint112 reserve0, uint112 reserve1, ) = IPair(dexInfo.pair)
                .getReserves();

            if (reserve0 == 0 || reserve1 == 0) return 0;

            uint256 reserveUsdt;
            uint256 reserveBtcmt;
            if (address(BTCMT) == dexInfo.token0) {
                reserveBtcmt = reserve0;
                reserveUsdt = reserve1;
            } else {
                reserveBtcmt = reserve1;
                reserveUsdt = reserve0;
            }

            return (reserveUsdt * receiveAmount) / reserveBtcmt;
        } else return 0;
    }

    /** @dev Get available BTCMT amount to buy
     * @param user buyer address
     * @param linkHash user link
     * @return available BTCMT amount to buy (0 if wrong link/new user + disabled link;
     * contract balance if zero bonus percent/link doesn't exist in contract)
     */
    function availableTokensToBuy(address user, bytes32 linkHash)
        public
        view
        returns (uint256)
    {
        KidInfo memory kid = kids[user];
        uint256 bonusPercent;
        if (kid.registered) {
            if (kid.fatherLink != linkHash) return 0;
            bonusPercent = (kid.fatherLink == bytes32(0))
                ? 0
                : getUserBonusPercent(links[kid.fatherLink].owner);
        } else {
            if (!links[linkHash].enabled && links[linkHash].owner != address(0))
                return 0;
            bonusPercent = (links[linkHash].owner == address(0))
                ? 0
                : getUserBonusPercent(links[linkHash].owner);
        }
        return
            (IERC20(BTCMT).balanceOf(address(this)) * DENOMINATOR) /
            (DENOMINATOR + bonusPercent);
    }

    /** @dev Get detail info for purchasing (buyAmount, bonus amount, sum of these two params)
     * @param payAmount USDT input amount
     * @param user address of buyer
     * @param linkHash link
     * @return buyAmount (BTCMT output amount)
     * @return bonus (BTCMT buyer bonus amount)
     * @return sum of these two params
     * @notice will return (0,0,0) if not enough BTCMT/buyAmount == 0/payAmount == 0
     * @notice will return (n,0,n) if zero bonus percent/link doesn't exist on the contract
     */
    function detailing(
        uint256 payAmount,
        address user,
        bytes32 linkHash
    )
        external
        view
        returns (
            uint256 buyAmount,
            uint256 bonus,
            uint256 sum
        )
    {
        buyAmount = getPrice(payAmount);
        if (
            availableTokensToBuy(user, linkHash) < buyAmount ||
            payAmount == 0 ||
            buyAmount == 0
        ) return (0, 0, 0);
        KidInfo memory kid = kids[user];
        uint256 bonusPercent;
        uint256 sonPercent;
        if (kid.registered) {
            if (kid.fatherLink == bytes32(0)) {
                bonusPercent = 0;
                sonPercent = 0;
            } else {
                bonusPercent = getUserBonusPercent(links[kid.fatherLink].owner);
                sonPercent = DENOMINATOR - links[kid.fatherLink].ownerPercent;
            }
        } else {
            //link not exists || zero link (no link means)
            if ((links[linkHash].owner == address(0))) {
                bonusPercent = 0;
                sonPercent = 0;
            } else {
                bonusPercent = getUserBonusPercent(links[linkHash].owner);
                sonPercent = DENOMINATOR - links[linkHash].ownerPercent;
            }
        }
        bonus =
            (((buyAmount * bonusPercent) / DENOMINATOR) * sonPercent) /
            DENOMINATOR;
        sum = buyAmount + bonus;
    }

    /** @dev Get all link's owner information
     * @param _father link's owner address
     * @return fatherBonus (see getUserBonusPercent())
     * @return activeLinks all enabled links list
     * @return allLinks list of all added links
     * @return allLinkInfo list of all added links information
     * @return allLinkStatistic list of all added links statistic information
     */
    function getAllFatherLinkStatistic(address _father)
        external
        view
        returns (
            uint256 fatherBonus,
            bytes32[] memory activeLinks,
            bytes32[] memory allLinks,
            LinkInfo[] memory allLinkInfo,
            LinkStatistic[] memory allLinkStatistic
        )
    {
        fatherBonus = getUserBonusPercent(_father);
        activeLinks = fathers[_father].linksEndbled.values();
        allLinks = fathers[_father].allLinks;
        allLinkInfo = new LinkInfo[](allLinks.length);
        allLinkStatistic = new LinkStatistic[](allLinks.length);
        for (uint256 i; i < allLinks.length; i++) {
            allLinkInfo[i] = links[allLinks[i]];
            allLinkStatistic[i] = linkStatistic[allLinks[i]];
        }
    }

    /** @dev Get all father kids
     * @param _father links' owner address
     * @return list of all his referrals
     */
    function getFatherKids(address _father)
        external
        view
        returns (address[] memory)
    {
        return fathers[_father].allKids;
    }

    function _buyFromCex(
        address payToken,
        uint256 payAmount,
        uint256 buyAmount,
        uint256 expirationTime,
        bytes memory signature,
        uint256 bonusPercent,
        bytes32 link
    ) internal {
        require(
            hasRole(
                SIGNER_ROLE,
                ECDSA.recover(
                    ECDSA.toEthSignedMessageHash(
                        keccak256(
                            abi.encodePacked(
                                _msgSender(),
                                payAmount,
                                buyAmount,
                                expirationTime
                            )
                        )
                    ),
                    signature
                )
            ),
            "Wrong buy signature"
        );
        require(block.timestamp < expirationTime, "Time passed");
        require(buyAmount > 0, "Zero buyAmount");

        _buy(payToken, payAmount, buyAmount, bonusPercent, link);
    }

    function _buyFromDex(
        address payToken,
        uint256 payAmount,
        uint256 bonusPercent,
        bytes32 link
    ) internal {
        _buy(payToken, payAmount, getPrice(payAmount), bonusPercent, link);
    }

    function _buy(
        address payToken,
        uint256 payAmount,
        uint256 buyAmount,
        uint256 bonusPercent,
        bytes32 link
    ) internal {
        require(
            (10**IERC20Metadata(BTCMT).decimals() * payAmount) / buyAmount >=
                dexInfo.floorPrice,
            "Under floor price"
        );

        _give(_msgSender(), payAmount, buyAmount, bonusPercent, link);

        TransferHelper.safeTransferFrom(
            payToken,
            _msgSender(),
            address(this),
            payAmount
        );
    }

    function _give(
        address sender,
        uint256 payAmount,
        uint256 buyAmount,
        uint256 bonusPercent,
        bytes32 link
    ) internal {
        uint256 bonusAmount = (buyAmount * bonusPercent) / DENOMINATOR;
        require(
            buyAmount + bonusAmount <= IERC20(BTCMT).balanceOf(address(this)),
            "Not enough BTCMT"
        );
        uint256 fatherAmount = (bonusAmount * links[link].ownerPercent) /
            DENOMINATOR;

        linkStatistic[link].totalBought += buyAmount;
        linkStatistic[link].totalBonuses += bonusAmount;
        fatherStatistic[links[link].owner].btcmtKidBought += buyAmount;
        fatherStatistic[links[link].owner].usdtKidSpent += payAmount;
        fatherStatistic[links[link].owner].totalBonuses += fatherAmount;
        kidStatistic[sender].sumOfPurchases += buyAmount;
        kidStatistic[sender].sumOfBonuses += (bonusAmount - fatherAmount);

        if (fatherAmount > 0)
            TransferHelper.safeTransfer(BTCMT, links[link].owner, fatherAmount);
        TransferHelper.safeTransfer(
            BTCMT,
            sender,
            (bonusAmount - fatherAmount) + buyAmount
        );

        emit PurchaseWithBonuses(
            link,
            buyAmount,
            fatherAmount,
            links[link].owner,
            bonusAmount - fatherAmount,
            sender,
            IERC20(BTCMT).balanceOf(address(this))
        );
    }

    function _checkLink(LinkParameters memory linkParams) internal {
        if (
            linkParams.linkHash == bytes32(0) ||
            links[linkParams.linkHash].owner != address(0)
        ) {
            require(
                links[linkParams.linkHash].owner != linkParams.linkSon,
                "Wrong sender"
            );
            if (kids[linkParams.linkSon].registered) {
                require(
                    kids[linkParams.linkSon].fatherLink == linkParams.linkHash,
                    "Wrong link"
                );
                if (!kids[linkParams.linkSon].comeSecondTime) {
                    kids[linkParams.linkSon].comeSecondTime = true;
                    linkStatistic[linkParams.linkHash].totalSonsTwice++;
                }
            } else {
                require(links[linkParams.linkHash].enabled, "Unactive link");
                _register(
                    links[linkParams.linkHash].owner,
                    linkParams.linkSon,
                    linkParams.linkHash
                );
            }
        } else {
            // create new link
            require(
                hasRole(
                    SIGNER_ROLE,
                    ECDSA.recover(
                        ECDSA.toEthSignedMessageHash(
                            keccak256(
                                abi.encodePacked(
                                    linkParams.linkHash,
                                    linkParams.linkFather,
                                    linkParams.fatherPercent
                                )
                            )
                        ),
                        linkParams.linkSignature
                    )
                ),
                "Wrong link signature"
            );

            require(
                linkParams.linkFather != address(0) &&
                    linkParams.linkFather != linkParams.linkSon,
                "Wrong father's address"
            );
            require(
                availableFatherPercents[linkParams.fatherPercent],
                "Wrong father's percent value"
            );
            require(!kids[linkParams.linkSon].registered, "Not new user");

            require(
                fathers[linkParams.linkFather].linksEndbled.length() <
                    MAX_ENABLED_LINKS,
                "Limit of active links"
            );
            fathers[linkParams.linkFather].linksEndbled.add(
                linkParams.linkHash
            );
            fathers[linkParams.linkFather].allLinks.push(linkParams.linkHash);

            links[linkParams.linkHash].enabled = true;
            links[linkParams.linkHash].owner = linkParams.linkFather;
            links[linkParams.linkHash].ownerPercent = linkParams.fatherPercent;

            _register(
                linkParams.linkFather,
                linkParams.linkSon,
                linkParams.linkHash
            );

            emit NewLinkCreated(
                linkParams.linkHash,
                linkParams.linkFather,
                linkParams.fatherPercent,
                DENOMINATOR - linkParams.fatherPercent
            );
        }

        kidStatistic[linkParams.linkSon].numOfPurchases++;
    }

    function _register(
        address _father,
        address _kid,
        bytes32 _link
    ) internal {
        kids[_kid].registered = true;
        kids[_kid].fatherLink = _link;

        linkStatistic[_link].totalSons++;
        fathers[_father].allKids.push(_kid);
        fatherStatistic[_father].totalKids++;
        kidStatistic[_kid].firstPurchaseDate = block.timestamp;

        emit NewUserRegistered(_kid, _father, _link);
    }
}