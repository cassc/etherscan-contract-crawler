// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

import "./interfaces/IStake.sol";
import "./interfaces/IOKXFootballCup.sol";

contract Bonus is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    /**
     * @dev Emitted when fund mint bonus to this contract.
     */
    event FundForMint(address from, uint256 id);

    /**
     * @dev Emitted when refund mint bonus from this contract.
     */
    event RefundForMint(address from, uint256 amount);

    /**
     * @dev Emitted when fund mint bonus to this contract.
     */
    event FundForGroup(address from, uint256 amount);

    /**
     * @dev Emitted when refund mint bonus from this contract.
     */
    event RefundForGroup(address from, uint256 amount);

    /**
     * @dev Emitted when user claim their bonus
     */
    event Claimed(
        address indexed sender,
        uint256[] ids,
        uint256[] amounts,
        uint256[] bonus
    );

    /**
     * @dev Emitted when user withdraw their bonus
     */
    event WithdrawBonus(
        address indexed sender,
        uint256 mintBonus,
        uint256 groupBonus,
        uint256 totalBonus
    );

    /**
     * @dev Emitted when reveive group competition result
     */
    event GroupStageEnds(
        address indexed sender,
        uint256[] winners,
        uint256[] losers
    );

    /**
     * @dev Emitted when receive elimination result
     */
    event Elimination(address indexed sender, uint256 winner, uint256 loser);

    /**
     * @dev Emitted when use this to fix mint bonus
     */
    event SetMintBonus(address indexed sender, uint256 id, uint256 amount);

    /**
     * @dev Emitted when group bonus set
     */
    event SetGroupBonus(
        address indexed sender,
        address[] accounts,
        uint256[] bonus
    );

    address public footballCup;
    address public bonusToken;
    uint256 public bonusPrice;

    uint256 public totalBonus;
    uint256 public totalMintBonus;
    uint256 public totalGroupBonus;
    uint256 public claimedMintBonus;

    mapping(uint256 => uint256) public totalMintBonusMap; //tokenId to token bonus
    EnumerableMapUpgradeable.AddressToUintMap private _groupBonusMap; //Bonus address to amount
    EnumerableMapUpgradeable.AddressToUintMap private _eliminationBonusMap; //Bonus address to amount

    address private _admin;

    // ---- modifierr ----//
    modifier onlyFootballCup() {
        require(msg.sender == footballCup, "Bonus: only footballCup");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(
            msg.sender == _admin || msg.sender == owner(),
            "Bonus: only admin or owner"
        );
        _;
    }

    function initialize(address _bonusToken, uint256 _mintBonusPrice)
        public
        initializer
    {
        __Ownable_init();
        __UUPSUpgradeable_init();
        bonusToken = _bonusToken;
        bonusPrice = _mintBonusPrice;
    }

    function setFootballCup(address _footballCup) external onlyOwner {
        footballCup = _footballCup;
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    // ---- fund method ----//
    function fundForMint(address from) external onlyAdminOrOwner {
        uint256 fundAmount = (IOKXFootballCup(footballCup).totalSupply() -
            totalMintBonus /
            bonusPrice) * bonusPrice;

        require(fundAmount > 0, "Bonus: no need to fund");

        IERC20Upgradeable(bonusToken).safeTransferFrom(
            from,
            address(this),
            fundAmount
        );

        totalMintBonus += fundAmount;
        totalBonus += fundAmount;

        emit FundForMint(from, fundAmount);
    }

    function refundForMint(address to, uint256 amount)
        external
        onlyAdminOrOwner
    {
        uint256 balance = IERC20Upgradeable(bonusToken).balanceOf(
            address(this)
        );

        require(balance >= amount, "Bonus: balance not enough for refound");

        IERC20Upgradeable(bonusToken).safeTransfer(to, amount);

        totalMintBonus -= amount;
        totalBonus -= amount;

        emit RefundForMint(to, amount);
    }

    function fundForGroup(address from, uint256 amount)
        external
        onlyAdminOrOwner
    {
        IERC20Upgradeable(bonusToken).safeTransferFrom(
            from,
            address(this),
            amount
        );

        totalGroupBonus += amount;
        totalBonus += amount;

        emit FundForGroup(from, amount);
    }

    function refundForGroup(address to, uint256 amount)
        external
        onlyAdminOrOwner
    {
        uint256 balance = IERC20Upgradeable(bonusToken).balanceOf(
            address(this)
        );

        require(balance >= amount, "Bonus: balance not enough for refound");

        IERC20Upgradeable(bonusToken).safeTransfer(to, amount);

        totalGroupBonus -= amount;
        totalBonus -= amount;

        emit RefundForGroup(to, amount);
    }

    // ---- bonus rebase ----//
    function groupStageEnds(uint256[] memory winners, uint256[] memory losers)
        external
        onlyFootballCup
    {
        require(
            winners.length == losers.length,
            "Bonus: winners and losers has different length"
        );

        require(
            winners.length == 16,
            "Bonus: group winners should be 16 teams"
        );

        uint256 length = winners.length;
        IOKXFootballCup okxFootballCup = IOKXFootballCup(footballCup);

        for (uint256 i = 0; i < length; ) {
            uint256 bonusToMerge = ((okxFootballCup.totalSupply(losers[i]) +
                okxFootballCup.totalSupply(losers[i + 1])) * bonusPrice) / 2;

            totalMintBonusMap[winners[i]] =
                okxFootballCup.totalSupply(winners[i]) *
                bonusPrice +
                bonusToMerge;
            totalMintBonusMap[winners[i + 1]] =
                okxFootballCup.totalSupply(winners[i + 1]) *
                bonusPrice +
                bonusToMerge;

            totalMintBonusMap[losers[i]] = 0;
            totalMintBonusMap[losers[i + 1]] = 0;

            unchecked {
                i = i + 2;
            }
        }

        emit GroupStageEnds(msg.sender, winners, losers);
    }

    function elimination(uint256 winner, uint256 loser)
        external
        onlyFootballCup
    {
        totalMintBonusMap[winner] += totalMintBonusMap[loser];
        totalMintBonusMap[loser] = 0;

        emit Elimination(msg.sender, winner, loser);
    }

    function setMintBonus(uint256 id, uint256 bonus) external onlyFootballCup {
        totalMintBonusMap[id] = bonus;
        emit SetMintBonus(msg.sender, id, bonus);
    }

    function setGroupBonus(address[] memory accounts, uint256[] memory bonus)
        external
        onlyFootballCup
    {
        require(
            accounts.length == bonus.length,
            "Bonus: accounts and bonus length not match"
        );

        uint256 length = accounts.length;

        for (uint256 i = 0; i < length; ) {
            uint256 userBonus = bonus[i];
            address account = accounts[i];

            (bool success, uint256 value) = _groupBonusMap.tryGet(account);
            //if account exist in the set, should remove it first then set again
            if (success) {
                _groupBonusMap.remove(account);
                userBonus += value;
            }

            success = _groupBonusMap.set(account, userBonus);
            require(success, "Bonus: set group bonus fail");
            unchecked {
                ++i;
            }
        }

        emit SetGroupBonus(msg.sender, accounts, bonus);
    }

    // ---- claim & withdraw ----//

    function claim(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyFootballCup {
        uint256 length = ids.length;
        uint256[] memory bonus = new uint256[](length);
        uint32 bitmap = 0;

        for (uint256 i = 0; i < length; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            // id already restrict in 1-32
            uint32 idBit = uint32(1 << (id - 1));
            if ((bitmap & idBit) != 0) revert("Bonus: id can not be duplicate");

            bitmap = bitmap | idBit;

            uint256 userBalance = IOKXFootballCup(footballCup).balanceOf(
                owner,
                id
            );
            require(userBalance >= amount, "Bonus: not enough amount to claim");

            uint256 userBonus = (amount * totalMintBonusMap[id]) /
                IOKXFootballCup(footballCup).totalSupply(id);

            totalMintBonusMap[id] = totalMintBonusMap[id] - userBonus;
            claimedMintBonus += userBonus;
            bonus[i] = userBonus;

            (bool success, uint256 value) = _eliminationBonusMap.tryGet(owner);
            if (success) {
                // key found
                userBonus += value;
                _eliminationBonusMap.remove(owner);
            }
            require(
                _eliminationBonusMap.set(owner, userBonus),
                "Bonus: set mint bonus fail"
            );

            unchecked {
                i++;
            }
        }

        emit Claimed(owner, ids, amounts, bonus);
    }

    function withdraw(address owner, uint256 withdrawRate)
        public
        onlyFootballCup
    {
        uint256 userTotalBonus;

        bool success = false;
        uint256 mintBounsAmount;
        (success, mintBounsAmount) = _eliminationBonusMap.tryGet(owner);
        if (success) {
            userTotalBonus += mintBounsAmount;
            require(
                _eliminationBonusMap.remove(owner),
                "Bonus: remove withdraw mint bonus owner  fail"
            );
        }

        uint256 groupBounsAmount;
        (success, groupBounsAmount) = _groupBonusMap.tryGet(owner);
        if (success) {
            userTotalBonus += groupBounsAmount;
            require(
                _groupBonusMap.remove(owner),
                "Bonus: remove withdraw group bonus owner  fail"
            );
        }

        if (userTotalBonus > 0) {
            uint256 balance = IERC20Upgradeable(bonusToken).balanceOf(
                address(this)
            );
            require(
                balance >= userTotalBonus,
                "Bonus: balance not enough for withdraw"
            );

            if (withdrawRate != 0) {
                userTotalBonus = (userTotalBonus * withdrawRate) / 10_000;
            }

            IERC20Upgradeable(bonusToken).safeTransfer(owner, userTotalBonus);

            emit WithdrawBonus(
                owner,
                mintBounsAmount,
                groupBounsAmount,
                userTotalBonus
            );
        }
    }

    //
    function getGroupBonus(uint256 pageSize, uint256 pageIndex)
        external
        view
        onlyAdminOrOwner
        returns (
            address[] memory accounts,
            uint256[] memory amounts,
            uint256 groupBonusSize
        )
    {
        uint256 length = _groupBonusMap.length();
        uint256 skip = pageSize * pageIndex;
        require(skip < length, "Bonus: get group bonus out of bound");
        uint256 unread = length - skip;

        if (unread > pageSize) {
            unread = pageSize;
        }
        accounts = new address[](unread);
        amounts = new uint256[](unread);

        for (uint256 i = 0; i < unread; ++i) {
            (accounts[i], amounts[i]) = _groupBonusMap.at(i + skip);
        }
        groupBonusSize = length;
    }

    function getGroupBonusByAddress(address _addr)
        public
        view
        returns (uint256)
    {
        (bool success, uint256 amount) = _groupBonusMap.tryGet(_addr);
        if (success) {
            return amount;
        }
        return 0;
    }

    function getEliminationBonus(uint256 pageSize, uint256 pageIndex)
        external
        view
        onlyAdminOrOwner
        returns (
            address[] memory accounts,
            uint256[] memory amounts,
            uint256 eliminationBonusSize
        )
    {
        uint256 length = _eliminationBonusMap.length();
        uint256 skip = pageSize * pageIndex;
        require(skip < length, "Bonus: get elimination bonus out of bound");
        uint256 unread = length - skip;
        if (unread > pageSize) {
            unread = pageSize;
        }
        accounts = new address[](unread);
        amounts = new uint256[](unread);

        for (uint256 i = 0; i < unread; ++i) {
            (accounts[i], amounts[i]) = _eliminationBonusMap.at(i + skip);
        }
        eliminationBonusSize = length;
    }

    function getEliminationBonusByAddress(address _addr)
        public
        view
        returns (uint256)
    {
        (bool success, uint256 amount) = _eliminationBonusMap.tryGet(_addr);
        if (success) {
            return amount;
        }
        return 0;
    }
}