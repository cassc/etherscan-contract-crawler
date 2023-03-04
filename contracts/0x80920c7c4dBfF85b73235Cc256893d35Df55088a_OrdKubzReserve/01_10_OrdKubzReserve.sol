// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OrdKubzReserve is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public RESERVE_PRICE;
    address public signer;
    uint256 public reserveTotal;
    uint256 public reserveState;

    EnumerableSet.AddressSet reservedUsers;
    mapping(address => uint256) public itemsUserReserved;
    mapping(address => bool) public isUserRefunded;

    uint256 public totalAirdroppedItems;
    uint256 public withdrawed;

    event UserReserved(
        address indexed user,
        uint256 amount,
        uint256 newAmt,
        uint256 max
    );
    event UserRefunded(address indexed user, uint256 wonAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _signer) public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        RESERVE_PRICE = 0.0169 ether;
        signer = _signer;
    }

    function checkValidity(bytes calldata signature, string memory action)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signer,
            "invalid signature"
        );
        return true;
    }

    function reserve(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable nonReentrant {
        require(reserveState == 1, "Reservation not open");
        require(msg.value == amount * RESERVE_PRICE, "Incorrect ETH amount");
        require(amount > 0, "Amount must be > 0");
        checkValidity(
            signature,
            string.concat("ordkubz-reserve-max-", Strings.toString(max))
        );
        uint256 newAmt = itemsUserReserved[msg.sender] + amount;
        require(newAmt <= max, "newAmt exceeds max");

        itemsUserReserved[msg.sender] = newAmt;
        reserveTotal += amount;
        reservedUsers.add(msg.sender);

        emit UserReserved(msg.sender, amount, newAmt, max);
    }

    function refund(uint256 wonAmount, bytes calldata signature)
        external
        nonReentrant
    {
        require(
            reserveState == 2 || reserveState == 3,
            "Reservation not in concluding or finished state"
        );
        require(itemsUserReserved[msg.sender] > 0, "No reservation record");
        require(!isUserRefunded[msg.sender], "Already refunded");
        checkValidity(
            signature,
            string.concat(
                "ordkubz-refund-won_amount-",
                Strings.toString(wonAmount)
            )
        );

        uint256 loseAmount = itemsUserReserved[msg.sender] - wonAmount;
        uint256 refundAvailable = loseAmount * RESERVE_PRICE;
        require(refundAvailable > 0, "Nothing to refund");
        
        isUserRefunded[msg.sender] = true;

        emit UserRefunded(msg.sender, wonAmount);
        _withdraw(msg.sender, refundAvailable);
    }

    // =============== Admin ===============
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function withdrawSales() public onlyOwner {
        require(
            reserveState == 2 || reserveState == 3,
            "Reservation not in concluding or finished state"
        );

        require(totalAirdroppedItems > 0, "totalAirdroppedItems not set");

        // uint256 balance = address(this).balance;
        uint256 sales = totalAirdroppedItems * RESERVE_PRICE;
        uint256 available = sales - withdrawed;

        require(available > 0, "No balance to withdraw");

        withdrawed += available;
        _withdraw(owner(), available);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }

    function changeReservePrice(uint256 price) external onlyOwner {
        require(reserveState == 0, "Reservation already started");
        RESERVE_PRICE = price;
    }

    function setReserveState(uint8 state) external onlyOwner {
        reserveState = state;
    }

    function setTotalAirdroppedItems(uint256 tai) external onlyOwner {
        totalAirdroppedItems = tai;
    }

    function getReservedUsersCount() external view returns (uint256) {
        return reservedUsers.length();
    }

    function getReservedUsers(uint256 fromIdx, uint256 toIdx)
        external
        view
        returns (address[] memory)
    {
        toIdx = Math.min(toIdx, reservedUsers.length());
        address[] memory part = new address[](toIdx - fromIdx);
        for (uint256 i = 0; i < toIdx - fromIdx; i++) {
            part[i] = reservedUsers.at(i + fromIdx);
        }
        return part;
    }
}