pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT
import "Auth.sol";
import "IERC20.sol";

contract OperaPool is Auth {
    uint256 public totalEthLent;
    uint256 public totalAvailableEth;
    uint256 public numberOfLenders;
    uint256 public borrowLimit = 3;
    uint256 public _tokenDecimals = 1 * 10 ** 18;
    bool public borrowingEnable = true;
    mapping(address => uint256) public usersCurrentLentAmount;
    mapping(uint256 => address) public lenderIdToAddress;
    mapping(address => uint256) public lenderAddressToId;
    mapping(address => bool) public authorizedFactoryAddresses;

    event ethMoved(
        address account,
        uint256 amount,
        uint256 code,
        uint256 blocktime
    ); // 1 lent 2 borrowed 3 returned 4 withdrawn

    event factoryStatusChange(address factoryAddress, bool status);

    constructor() Auth(msg.sender) {}

    modifier onlyFactoryAuthorized() {
        require(
            authorizedFactoryAddresses[msg.sender],
            "only factory contracts can borrow eth"
        );
        _;
    }

    function updateFactoryAuthorization(
        address addy,
        bool status
    ) external onlyOwner {
        authorizedFactoryAddresses[addy] = status;
        emit factoryStatusChange(addy, status);
    }

    function updateBorrowLimit(uint256 limit) external onlyOwner {
        borrowLimit = limit;
    }

    function updateBorrowingEnabled(bool status) external onlyOwner {
        borrowingEnable = status;
    }

    function lendForAddress(address addy) external payable returns (bool) {
        require(
            msg.value > 0 && msg.value % _tokenDecimals == 0,
            "Only send full ether."
        );
        if (lenderAddressToId[addy] == 0) {
            lenderAddressToId[addy] = numberOfLenders + 1;
            lenderIdToAddress[numberOfLenders + 1] = addy;
            numberOfLenders += 1;
        }
        uint256 amountReceived = msg.value / _tokenDecimals;
        emit ethMoved(addy, amountReceived, 1, block.timestamp);
        totalEthLent += amountReceived;

        usersCurrentLentAmount[addy] += amountReceived;
        totalAvailableEth += amountReceived;

        return true;
    }

    receive() external payable {}

    function lendEth() external payable returns (bool) {
        require(
            msg.value > 0 && msg.value % _tokenDecimals == 0,
            "Only send full ether."
        );
        if (lenderAddressToId[msg.sender] == 0) {
            lenderAddressToId[msg.sender] = numberOfLenders + 1;
            lenderIdToAddress[numberOfLenders + 1] = msg.sender;
            numberOfLenders += 1;
        }
        uint256 amountReceived = msg.value / _tokenDecimals;
        emit ethMoved(msg.sender, amountReceived, 1, block.timestamp);
        totalEthLent += amountReceived;

        usersCurrentLentAmount[msg.sender] += amountReceived;
        totalAvailableEth += amountReceived;

        return true;
    }

    function borrowEth(uint256 _amount) external onlyFactoryAuthorized {
        require(_amount <= totalAvailableEth, "Not Enough eth to borrow");
        require(_amount > 0, "Cannot borrow 0");
        require(borrowingEnable, "Borrowing is not enabled.");
        require(_amount <= borrowLimit, "Can't borrow that much.");
        totalAvailableEth -= _amount;
        payable(msg.sender).transfer(_amount * _tokenDecimals);
        emit ethMoved(msg.sender, _amount, 2, block.timestamp);
    }

    function returnLentEth(uint256 amountEth) external payable returns (bool) {
        require(
            (amountEth * _tokenDecimals) - msg.value == 0,
            "Did not send enough eth."
        );

        emit ethMoved(msg.sender, amountEth, 3, block.timestamp);
        totalAvailableEth += amountEth;

        return true;
    }

    function withdrawLentEth(uint256 _amountEther) external payable {
        require(
            usersCurrentLentAmount[msg.sender] >= _amountEther,
            "You Did not lend that much."
        );

        require(_amountEther > 0, "Cant withdraw 0.");
        require(_amountEther <= totalAvailableEth, "Not enough eth available.");
        if (usersCurrentLentAmount[msg.sender] == _amountEther) {
            uint256 tempIdOfUser = lenderAddressToId[msg.sender];
            address addressOfLastUser = lenderIdToAddress[numberOfLenders];
            if (addressOfLastUser != msg.sender) {
                delete lenderAddressToId[msg.sender];
                lenderAddressToId[addressOfLastUser] = tempIdOfUser;
                lenderIdToAddress[tempIdOfUser] = addressOfLastUser;
                delete lenderIdToAddress[numberOfLenders];
                numberOfLenders -= 1;
            } else {
                delete lenderAddressToId[msg.sender];
                delete lenderIdToAddress[tempIdOfUser];
                numberOfLenders -= 1;
            }
        }
        usersCurrentLentAmount[msg.sender] -= _amountEther;
        totalAvailableEth -= _amountEther;
        totalEthLent -= _amountEther;
        payable(msg.sender).transfer(_amountEther * _tokenDecimals);
        emit ethMoved(msg.sender, _amountEther, 4, block.timestamp);
    }

    //safe gaurd so no funds get locked
    function withdraw(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    function rescueToken(address token, uint256 amount) external onlyOwner {
        IERC20 tokenToRescue = IERC20(token);
        tokenToRescue.transfer(owner, amount);
    }

    function removeExcess() external payable onlyOwner {
        require(
            address(this).balance > totalAvailableEth * _tokenDecimals,
            "There is no excess eth"
        );
        uint256 excessAmount = address(this).balance -
            (totalAvailableEth * _tokenDecimals);
        payable(owner).transfer(excessAmount);
    }
}