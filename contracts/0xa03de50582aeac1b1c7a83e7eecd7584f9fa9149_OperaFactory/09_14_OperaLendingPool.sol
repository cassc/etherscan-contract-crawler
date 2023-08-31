pragma solidity ^0.8.17;
//SPDX-License-Identifier: MIT
import "Auth.sol";
import "OperaStaking.sol";

contract OperaPool is Auth {
    uint256 public totalEthLent;
    uint256 public totalAvailableEth;
    uint256 public lendingStakingRequirement;
    uint256 public borrowLimit = 3;
    uint256 public _tokenDecimals = 1 * 10 ** 18;
    bool public borrowingEnable = true;
    address public operaStakingAddress;
    mapping(address => uint256) public usersCurrentLentAmount;
    mapping(address => uint256) public usersPendingReturnAmount;
    mapping(address => bool) public authorizedFactoryAddresses;
    mapping(uint256 => QueuePosition) public withdrawQueue;

    struct QueuePosition {
        address lender;
        uint256 amount;
    }

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

    function updateLendingStakeRequirement(uint256 limit) external onlyOwner {
        lendingStakingRequirement = limit;
    }

    function updateStakingAddress(address addy) external onlyOwner {
        operaStakingAddress = addy;
    }

    function updateBorrowingEnabled(bool status) external onlyOwner {
        borrowingEnable = status;
    }

    receive() external payable {}

    function lendEth() external payable returns (bool) {
        require(
            msg.value > 0 && msg.value % _tokenDecimals == 0,
            "Only send full ether."
        );
        if (lendingStakingRequirement > 0) {
            OperaStaking operaStaking = OperaStaking(
                payable(operaStakingAddress)
            );
            require(
                operaStaking.getStakedAmount(msg.sender) >=
                    lendingStakingRequirement,
                "You are not staking enough to lend."
            );
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
        usersCurrentLentAmount[msg.sender] -= _amountEther;
        totalAvailableEth -= _amountEther;
        totalEthLent -= _amountEther;
        payable(msg.sender).transfer(_amountEther * _tokenDecimals);
        emit ethMoved(msg.sender, _amountEther, 4, block.timestamp);
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