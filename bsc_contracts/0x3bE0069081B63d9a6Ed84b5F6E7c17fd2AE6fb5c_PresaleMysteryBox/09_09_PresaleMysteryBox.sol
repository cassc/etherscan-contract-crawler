// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PresaleMysteryBox is Context, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant MAX_ANIMAL_SELL = 2000;
    uint256 public constant MAX_STAFF_SELL = 600;
    uint256 public constant MAX_SELL_PER_TX = 10;

    IERC20 public sellToken;
    address public treasury;

    uint256 public totalAnimalBoxSell;
    uint256 public totalStaffBoxSell;

    uint256 private animalBoxPrice;
    uint256 private staffBoxPrice;

    mapping(address => uint256) public userAnimalSold;
    mapping(address => uint256) public userStaffSold;

    event SetAnimalBoxPrice(uint256 price);
    event SetStaffBoxPrice(uint256 price);
    event AnimalSale(
        address to,
        uint256 amount,
        uint256 totalUserAmount,
        uint256 totalSold,
        uint256 price
    );
    event StaffSale(
        address to,
        uint256 amount,
        uint256 totalUserAmount,
        uint256 totalSold,
        uint256 price
    );

    constructor(
        IERC20 _sellToken,
        uint256 _animalBoxPrice,
        uint256 _staffBoxPrice,
        address _treasuryAddress
    ) {
        sellToken = _sellToken;
        treasury = _treasuryAddress;
        animalBoxPrice = _animalBoxPrice;
        staffBoxPrice = _staffBoxPrice;
    }

    modifier onlyEOA() {
        require(tx.origin == _msgSender(), "MysteryBoxSell: onlyEOA");
        _;
    }

    function getAnimalBoxPrice() public view returns (uint256) {
        return animalBoxPrice;
    }

    function getStaffBoxPrice() public view returns (uint256) {
        return staffBoxPrice;
    }

    function setAnimalBoxPrice(uint256 _price) external onlyOwner {
        animalBoxPrice = _price;

        emit SetAnimalBoxPrice(_price);
    }

    function setStaffBoxPrice(uint256 _price) external onlyOwner {
        staffBoxPrice = _price;

        emit SetStaffBoxPrice(_price);
    }

    function buyAnimalBox(uint256 n) external onlyEOA whenNotPaused {
        require(n <= MAX_SELL_PER_TX, "AnimalSell: Reach tx limit");

        totalAnimalBoxSell += n;
        userAnimalSold[_msgSender()] += n;

        require(
            totalAnimalBoxSell <= MAX_ANIMAL_SELL,
            "AnimalSell: Reach user limit"
        );

        sellToken.safeTransferFrom(
            _msgSender(),
            treasury,
            getAnimalBoxPrice() * n
        );

        emit AnimalSale(
            _msgSender(),
            n,
            userAnimalSold[_msgSender()],
            totalAnimalBoxSell,
            getAnimalBoxPrice() * n
        );
    }

    function buyStaffBox(uint256 n) external onlyEOA whenNotPaused {
        require(n <= MAX_SELL_PER_TX, "StaffSell: Reach tx limit");

        totalStaffBoxSell += n;
        userStaffSold[_msgSender()] += n;

        require(
            totalStaffBoxSell <= MAX_STAFF_SELL,
            "StaffSell: Reach user limit"
        );

        sellToken.safeTransferFrom(
            _msgSender(),
            treasury,
            getStaffBoxPrice() * n
        );

        emit StaffSale(
            _msgSender(),
            n,
            userStaffSold[_msgSender()],
            totalStaffBoxSell,
            getStaffBoxPrice() * n
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}