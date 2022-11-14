// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Tax.sol";
import "../ERC20/interfaces/IOperable.sol";

contract WosPackages is ReentrancyGuard, Ownable, Tax {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _itemIds;
    Counters.Counter private _total;
    IERC20 private wosContract;

    struct WosPackage {
        uint256 itemId;
        uint256 price;
        uint256 wosAmount;
        uint256 amount;
    }

    event NewWosPackage(
        uint256 indexed itemId,
        uint256 price,
        uint256 wosAmount,
        uint256 amount
    );

    event WosPackageSold(
        uint256 indexed itemId,
        address indexed buyer,
        uint256 amount,
        uint256 totalWos,
        uint256 totalPrice,
        uint256 wosAmount,
        uint256 unitPrice
    );

    mapping(uint256 => WosPackage) private wosPackageId;

    constructor(
        IERC20 _wos_contract_address,
        address _collateral,
        address _aggAddress,
        address _signatureCollateral
    ) Tax(address(0), _collateral, _aggAddress, _signatureCollateral) {
        require(
            address(_wos_contract_address) != address(0),
            "_wos_contract_address address can not be zero"
        );

        wosContract = _wos_contract_address;
    }

    function createWosPackage(
        uint256 price,
        uint256 wosAmount,
        uint256 amount
    ) external onlyOwner {
        require(price > 0, "price must be greater than 0");
        require(wosAmount > 0, "wosAmount must be greater than 0");
        require(amount > 0, "amount must be greater than 0");

        _total.increment();
        _itemIds.increment();

        uint256 itemId = _itemIds.current();

        wosPackageId[itemId] = WosPackage(itemId, price, wosAmount, amount);

        IOperable(address(wosContract)).mint(wosAmount * amount);

        emit NewWosPackage(itemId, price, wosAmount, amount);
    }

    function buyWosPackage(uint256 itemId, uint256 amount)
        external
        checkPackage(itemId)
        nonReentrant
    {
        require(itemId > 0, "itemId cannot be 0");
        require(amount > 0, "amount must be greater than 0");
        require(
            wosPackageId[itemId].amount >= amount,
            "There are not enough such packages."
        );

        uint256 price = wosPackageId[itemId].price;
        uint256 wosAmount = wosPackageId[itemId].wosAmount;
        uint256 totalWos = wosAmount * amount;
        uint256 totalPrice = price * amount;

        wosPackageId[itemId].amount -= amount;

        _ctSign("BWP_TF_STEP_1");
        _collateralTransferFrom(msg.sender, address(this), totalPrice);

        _ctSign("BWP_T_STEP_2");
        _taxDistributionPreSales(totalPrice);

        wosContract.safeTransfer(msg.sender, totalWos);

        emit WosPackageSold(
            itemId,
            msg.sender,
            amount,
            totalWos,
            totalPrice,
            wosAmount,
            price
        );
    }

    function addPackages(uint256 itemId, uint256 amount) external checkPackage(itemId) onlyOwner {
        require(amount > 0, "amount must be greater than 0");
        wosPackageId[itemId].amount += amount;
    }

    function getPackageData(uint256 itemId)
        external
        view
        returns (WosPackage memory)
    {
        return wosPackageId[itemId];
    }

    function totalWosPackages() external view returns (uint256) {
        uint256 total = _itemIds.current();
        return total;
    }

    modifier checkPackage(uint256 itemId) {
        require(itemId > 0, "itemId cannot be 0");
        require(wosPackageId[itemId].itemId == itemId, "Wrong or missing package");
        _;
    }
}