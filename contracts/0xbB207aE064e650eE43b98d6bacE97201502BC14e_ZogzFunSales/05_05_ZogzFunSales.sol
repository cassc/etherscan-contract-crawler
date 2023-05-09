// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IPepeEditions {
    function burn(address __from, uint256 __id, uint256 __amount) external;
}

interface IZogzEditions {
    function mint(address __account, uint256 __id, uint256 __amount) external;

    function mintBatch(
        address __account,
        uint256[] memory __ids,
        uint256[] memory __amounts
    ) external;
}

contract ZogzFunSales is Ownable, Pausable, ReentrancyGuard {
    error AmountExceedsTransactionLimit();
    error BurnAmountDoesNotMatch();
    error BurnAmountMustBeExact();
    error DayNotFound();
    error FamilySetAlreadyExists();
    error Forbidden();
    error HasEnded();
    error HasNotEnded();
    error HasNotStarted();
    error IncorrectPrice();
    error InvalidAddress();
    error InvalidAmount();
    error InvalidBurnAmount();
    error PepeEditionNotFound();
    error WithdrawFailed();
    error ZogzEditionNotFound();

    event DailySetPurchase(address __account, uint256 __day, uint256 __amount);
    event FamilySets(Family[] __families, uint256[][] __ids);
    event FamilySetPurchase(
        address __account,
        Family __family,
        uint256 __amount
    );
    event FullSetPurchase(address __account, uint256 __amount);
    event Redemption(address __account, Special __special, uint256 __amount);
    event SinglePurchase(
        address __account,
        uint256 __tokenID,
        uint256 __amount
    );
    event TransactionLimit(uint256 __transactionLimit);
    event Withdraw(uint256 __amount);

    struct DailySet {
        uint256 from;
        uint256 start;
        uint256 end;
    }

    enum Family {
        RIPPERZ,
        KILLERZ,
        ALIENZ,
        TRIPPERZ,
        FLIPPERZ,
        TROLLZ,
        PHATTZ,
        SLAPPERZ,
        SMOKERZ,
        LORDZ
    }

    enum Special {
        RIPPER,
        KILLER,
        ALIEN,
        TRIPPER,
        FLIPPER,
        TROLL,
        PHATT,
        SLAPPER,
        SMOKER,
        LORD,
        GREATEST
    }

    struct SpecialData {
        uint256 id;
        uint256 cost;
    }

    uint256 public constant FULL_SET_SUPPLY = 100;
    uint256 public constant DAILY_SET_SUPPLY = 10;

    uint256 public constant MINT_PRICE = 0.01234 ether;

    mapping(uint256 => uint256) public BURN_MULTIPLIERS;

    uint256 public constant SALE_START = 1683565200;
    uint256 public constant SALE_END = 1684601999;

    mapping(uint256 => DailySet) public DAILY_SETS;
    mapping(Family => uint256[]) public FAMILY_SETS;
    mapping(Special => SpecialData) public SPECIAL_ZOGZ;

    mapping(uint256 => uint256) _tokenToDailySet;

    IPepeEditions public _pepeEditionsContract;
    IZogzEditions public _zogzEditionsContract;

    uint256 public transactionLimit = 1000;

    constructor(
        address __pepeEditionsContractAddress,
        address __zogzEditionsContractAddress
    ) {
        if (__pepeEditionsContractAddress == address(0)) {
            revert InvalidAddress();
        }

        if (__zogzEditionsContractAddress == address(0)) {
            revert InvalidAddress();
        }

        _pepeEditionsContract = IPepeEditions(__pepeEditionsContractAddress);
        _zogzEditionsContract = IZogzEditions(__zogzEditionsContractAddress);

        BURN_MULTIPLIERS[1] = 1; // ZOGZ Pepe
        BURN_MULTIPLIERS[3] = 10; // ZOGGED Pepe
        BURN_MULTIPLIERS[2] = 50; // HEDZ Pepe
        BURN_MULTIPLIERS[5] = 500; // RARE PEPZOGZ Pepe
        BURN_MULTIPLIERS[4] = 600; // PEGZOGZ Pepe

        SPECIAL_ZOGZ[Special.RIPPER] = SpecialData({id: 101, cost: 10});
        SPECIAL_ZOGZ[Special.KILLER] = SpecialData({id: 102, cost: 20});
        SPECIAL_ZOGZ[Special.ALIEN] = SpecialData({id: 103, cost: 20});
        SPECIAL_ZOGZ[Special.TRIPPER] = SpecialData({id: 104, cost: 20});
        SPECIAL_ZOGZ[Special.FLIPPER] = SpecialData({id: 105, cost: 5});
        SPECIAL_ZOGZ[Special.TROLL] = SpecialData({id: 106, cost: 5});
        SPECIAL_ZOGZ[Special.PHATT] = SpecialData({id: 107, cost: 7});
        SPECIAL_ZOGZ[Special.SLAPPER] = SpecialData({id: 108, cost: 3});
        SPECIAL_ZOGZ[Special.SMOKER] = SpecialData({id: 109, cost: 9});
        SPECIAL_ZOGZ[Special.LORD] = SpecialData({id: 110, cost: 1});
        SPECIAL_ZOGZ[Special.GREATEST] = SpecialData({id: 111, cost: 100});

        DAILY_SETS[1] = DailySet({from: 1, start: 1683565200, end: 1683651599});
        DAILY_SETS[2] = DailySet({
            from: 11,
            start: 1683651600,
            end: 1683737999
        });
        DAILY_SETS[3] = DailySet({
            from: 21,
            start: 1683738000,
            end: 1683824399
        });
        DAILY_SETS[4] = DailySet({
            from: 31,
            start: 1683824400,
            end: 1683910799
        });
        DAILY_SETS[5] = DailySet({
            from: 41,
            start: 1683910800,
            end: 1683997199
        });
        DAILY_SETS[6] = DailySet({
            from: 51,
            start: 1684170000,
            end: 1684256399
        });
        DAILY_SETS[7] = DailySet({
            from: 61,
            start: 1684256400,
            end: 1684342799
        });
        DAILY_SETS[8] = DailySet({
            from: 71,
            start: 1684342800,
            end: 1684429199
        });
        DAILY_SETS[9] = DailySet({
            from: 81,
            start: 1684429200,
            end: 1684515599
        });
        DAILY_SETS[10] = DailySet({
            from: 91,
            start: 1684515600,
            end: 1684601999
        });

        for (uint256 id = 1; id <= FULL_SET_SUPPLY; id++) {
            if (id > 90) {
                _tokenToDailySet[id] = 10;
            } else if (id > 80) {
                _tokenToDailySet[id] = 9;
            } else if (id > 70) {
                _tokenToDailySet[id] = 8;
            } else if (id > 60) {
                _tokenToDailySet[id] = 7;
            } else if (id > 50) {
                _tokenToDailySet[id] = 6;
            } else if (id > 40) {
                _tokenToDailySet[id] = 5;
            } else if (id > 30) {
                _tokenToDailySet[id] = 4;
            } else if (id > 20) {
                _tokenToDailySet[id] = 3;
            } else if (id > 10) {
                _tokenToDailySet[id] = 2;
            } else {
                _tokenToDailySet[id] = 1;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert Forbidden();
        }
        _;
    }

    modifier onlyExistingDay(uint256 __day) {
        if (__day == 0 || __day > 10) {
            revert DayNotFound();
        }
        _;
    }

    modifier onlyExistingPepeEdition(uint256 __tokenID) {
        if (__tokenID == 0 || __tokenID > 5) {
            revert PepeEditionNotFound();
        }
        _;
    }

    modifier onlyExistingSpecialEdition(Special __special) {
        if (SPECIAL_ZOGZ[__special].id == 0) {
            revert ZogzEditionNotFound();
        }
        _;
    }

    modifier onlyExistingZogzEdition(uint256 __tokenID) {
        if (__tokenID == 0 || __tokenID > 100) {
            revert ZogzEditionNotFound();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // OWNER
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to pause sales.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Used to unpause sales.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Used to set new transaction limit.
     */
    function setTransactionLimit(
        uint256 __transactionLimit
    ) external onlyOwner {
        transactionLimit = __transactionLimit;

        emit TransactionLimit(__transactionLimit);
    }

    /**
     * @dev Used to set family sets.
     */
    function setFamilySets(
        Family[] calldata __familySets,
        uint256[][] calldata __ids
    ) external onlyOwner {
        for (uint256 i = 0; i < __familySets.length; i++) {
            if (FAMILY_SETS[__familySets[i]].length > 0) {
                revert FamilySetAlreadyExists();
            }
            FAMILY_SETS[__familySets[i]] = __ids[i];
        }

        emit FamilySets(__familySets, __ids);
    }

    /**
     * @dev Used to withdraw funds from the contract.
     */
    function withdraw(uint256 __amount) external onlyOwner {
        (bool success, ) = owner().call{value: __amount}("");

        if (!success) revert WithdrawFailed();

        emit Withdraw(__amount);
    }

    /**
     * @dev Used to withdraw all funds from the contract.
     */
    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = owner().call{value: amount}("");

        if (!success) revert WithdrawFailed();

        emit Withdraw(amount);
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNALS
    ////////////////////////////////////////////////////////////////////////////

    function _burn(
        uint256 __burnTokenId,
        uint256 __burnAmount,
        uint256 __burnMultiplier
    ) internal {
        if (__burnAmount == 0) {
            revert InvalidBurnAmount();
        }

        uint256 burnAmountRemainder = __burnMultiplier %
            BURN_MULTIPLIERS[__burnTokenId];

        if (burnAmountRemainder != 0) {
            revert BurnAmountMustBeExact();
        }

        uint256 calculatedBurnAmount = __burnMultiplier /
            BURN_MULTIPLIERS[__burnTokenId];

        if (calculatedBurnAmount == 0) {
            revert InvalidBurnAmount();
        }

        if (calculatedBurnAmount != __burnAmount) {
            revert BurnAmountDoesNotMatch();
        }

        _pepeEditionsContract.burn(
            _msgSender(),
            __burnTokenId,
            calculatedBurnAmount
        );
    }

    function _mint(uint256 __tokenID, uint256 __amount) internal {
        _zogzEditionsContract.mint(_msgSender(), __tokenID, __amount);
    }

    function _mintBatch(
        uint256 __from,
        uint256 __to,
        uint256 __amount
    ) internal {
        uint256 total = __to - __from + 1;

        uint256[] memory ids = new uint256[](total);
        uint256[] memory amounts = new uint256[](total);
        for (uint256 i = 0; i < total; i++) {
            ids[i] = i + __from;
            amounts[i] = __amount;
        }

        _zogzEditionsContract.mintBatch(_msgSender(), ids, amounts);
    }

    function _mintBatchIds(uint256[] memory __ids, uint256 __amount) internal {
        uint256[] memory amounts = new uint256[](__ids.length);
        for (uint256 i = 0; i < __ids.length; i++) {
            amounts[i] = __amount;
        }

        _zogzEditionsContract.mintBatch(_msgSender(), __ids, amounts);
    }

    function _validateTotalAmountAndPrice(uint256 __totalAmount) internal view {
        if (__totalAmount == 0) {
            revert InvalidAmount();
        }

        if (__totalAmount > transactionLimit) {
            revert AmountExceedsTransactionLimit();
        }

        if (msg.value != MINT_PRICE * __totalAmount) {
            revert IncorrectPrice();
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // WRITES
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to buy a Full Set (burn-gating).
     *
     * Requirements:
     *
     * - `__amount` must be greater than `0`.
     * - `__burnTokenId` must be an existing Pepe Edition.
     * - `__burnAmount` must match the burn amount needed for `__amount`.
     *
     * Emits a {FullSetPurchase} event.
     *
     */
    function buyFullSetWithBurn(
        uint256 __amount,
        uint256 __burnTokenId,
        uint256 __burnAmount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyExistingPepeEdition(__burnTokenId)
    {
        uint256 totalAmount = __amount * FULL_SET_SUPPLY;

        _validateTotalAmountAndPrice(totalAmount);

        if (block.timestamp < SALE_START) {
            revert HasNotStarted();
        }

        _burn(__burnTokenId, __burnAmount, totalAmount);
        _mintBatch(1, FULL_SET_SUPPLY, __amount);

        emit FullSetPurchase(_msgSender(), __amount);
    }

    /**
     * @dev Used to buy a Single ZOGZ.
     *
     * Requirements:
     *
     * - `__tokenID` must be a valid ZOGZ (1-100).
     * - `__amount` must be greater than `0`.
     *
     * Emits a {SinglePurchase} event.
     *
     */
    function buySingle(
        uint256 __tokenID,
        uint256 __amount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyExistingZogzEdition(__tokenID)
    {
        _validateTotalAmountAndPrice(__amount);

        DailySet memory dailySet = DAILY_SETS[_tokenToDailySet[__tokenID]];

        if (block.timestamp < dailySet.start) {
            revert HasNotStarted();
        }
        if (block.timestamp > dailySet.end) {
            revert HasEnded();
        }

        _mint(__tokenID, __amount);

        emit SinglePurchase(_msgSender(), __tokenID, __amount);
    }

    /**
     * @dev Used to buy a Single ZOGZ (burn-gating).
     *
     * Requirements:
     *
     * - `__tokenID` must be a valid ZOGZ (1-100).
     * - `__amount` must be greater than `0`.
     * - `__burnTokenId` must be an existing Pepe Edition.
     * - `__burnAmount` must match the burn amount needed for `__amount`.
     *
     * Emits a {SinglePurchase} event.
     *
     */
    function buySingleWithBurn(
        uint256 __tokenID,
        uint256 __amount,
        uint256 __burnTokenId,
        uint256 __burnAmount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyExistingZogzEdition(__tokenID)
        onlyExistingPepeEdition(__burnTokenId)
    {
        _validateTotalAmountAndPrice(__amount);

        DailySet memory dailySet = DAILY_SETS[_tokenToDailySet[__tokenID]];

        if (block.timestamp < dailySet.end) {
            revert HasNotStarted();
        }

        _burn(__burnTokenId, __burnAmount, __amount);
        _mint(__tokenID, __amount);

        emit SinglePurchase(_msgSender(), __tokenID, __amount);
    }

    /**
     * @dev Used to buy a Daily Set.
     *
     * Requirements:
     *
     * - `__day` must be a valid Day (1-10).
     * - `__amount` must be greater than `0`.
     *
     * Emits a {DailySetPurchase} event.
     *
     */
    function buyDailySet(
        uint256 __day,
        uint256 __amount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyExistingDay(__day)
    {
        _validateTotalAmountAndPrice(__amount * DAILY_SET_SUPPLY);

        DailySet memory dailySet = DAILY_SETS[__day];

        if (block.timestamp < dailySet.start) {
            revert HasNotStarted();
        }
        if (block.timestamp > dailySet.end) {
            revert HasEnded();
        }

        _mintBatch(
            dailySet.from,
            dailySet.from + DAILY_SET_SUPPLY - 1,
            __amount
        );

        emit DailySetPurchase(_msgSender(), __day, __amount);
    }

    /**
     * @dev Used to buy a Daily Set (burn-gating).
     *
     * Requirements:
     *
     * - `__day` must be a valid Day (1-10).
     * - `__amount` must be greater than `0`.
     * - `__burnTokenId` must be an existing Pepe Edition.
     * - `__burnAmount` must match the burn amount needed for `__day` x `__amount`.
     *
     * Emits a {DailySetPurchase} event.
     *
     */
    function buyDailySetWithBurn(
        uint256 __day,
        uint256 __amount,
        uint256 __burnTokenId,
        uint256 __burnAmount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyExistingDay(__day)
    {
        DailySet memory dailySet = DAILY_SETS[__day];

        uint256 totalAmount = __amount * DAILY_SET_SUPPLY;

        _validateTotalAmountAndPrice(totalAmount);

        if (block.timestamp < dailySet.end) {
            revert HasNotStarted();
        }

        _burn(__burnTokenId, __burnAmount, totalAmount);
        _mintBatch(
            dailySet.from,
            dailySet.from + DAILY_SET_SUPPLY - 1,
            __amount
        );

        emit DailySetPurchase(_msgSender(), __day, __amount);
    }

    /**
     * @dev Used to buy a Family Set (burn-gating).
     *
     * Requirements:
     *
     * - `__family` must be an existing Family Set.
     * - `__amount` must be greater than `0`.
     * - `__burnTokenId` must be an existing Pepe Edition.
     * - `__burnAmount` must match the burn amount needed for `__family` x `__amount`.
     *
     * Emits a {FamilySetPurchase} event.
     *
     */
    function buyFamilySetWithBurn(
        Family __family,
        uint256 __amount,
        uint256 __burnTokenId,
        uint256 __burnAmount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyExistingPepeEdition(__burnTokenId)
    {
        uint256[] memory ids = FAMILY_SETS[__family];

        if (block.timestamp < SALE_END) {
            revert HasNotStarted();
        }

        uint256 totalAmount = __amount * ids.length;

        _validateTotalAmountAndPrice(totalAmount);

        _burn(__burnTokenId, __burnAmount, totalAmount);
        _mintBatchIds(ids, __amount);

        emit FamilySetPurchase(_msgSender(), __family, __amount);
    }

    /**
     * @dev Used to redeem Special ZOGZ.
     *
     * Requirements:
     *
     * - `__special` must be an existing Special ZOGZ.
     * - `__amount` must be greater than `0`.
     * - `__burnTokenId` must be an existing Pepe Edition.
     * - `__burnAmount` must match the burn amount needed for `__special` x `__amount`.
     *
     * Emits a {Redemption} event.
     *
     */
    function redeemSpecialZogz(
        Special __special,
        uint256 __amount,
        uint256 __burnTokenId,
        uint256 __burnAmount
    )
        external
        nonReentrant
        whenNotPaused
        onlyEOA
        onlyExistingPepeEdition(__burnTokenId)
        onlyExistingSpecialEdition(__special)
    {
        if (block.timestamp < SALE_START) {
            revert HasNotStarted();
        }

        uint256 totalAmount = __amount * SPECIAL_ZOGZ[__special].cost;

        _burn(__burnTokenId, __burnAmount, totalAmount);
        _mint(SPECIAL_ZOGZ[__special].id, __amount);

        emit Redemption(_msgSender(), __special, __amount);
    }
}