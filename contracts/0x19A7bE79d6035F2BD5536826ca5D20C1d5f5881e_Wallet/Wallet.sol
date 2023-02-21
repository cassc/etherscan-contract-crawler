/**
 *Submitted for verification at Etherscan.io on 2023-02-20
*/

pragma solidity ^0.6.2;

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256);
}

contract Account {
    address payable public reciever;
    string public user;
    address public owner;

    constructor(
        address token,
        address payable _reciever,
        string memory _user
    ) public {
        reciever = _reciever;
        user = _user;
        owner = msg.sender;
        withdraw();
        if (token != address(0)) {
            withdrawToken(token);
        }
        destory();
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            return;
        }
        reciever.transfer(balance);
    }

    function withdrawToken(address token) public {
        uint256 balance = ERC20(token).balanceOf(address(this));
        if (balance == 0) {
            return;
        }
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, reciever, balance)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Failed"
        );
    }

    function destory() public {
        require(msg.sender == owner, "403");
        selfdestruct(msg.sender);
    }
}

contract Wallet {
    address public admin;
    address public manager;

    event Create(address);

    constructor(address _manager) public {
        admin = msg.sender;
        manager = _manager;
    }

    modifier OnlyAdmin() {
        require(msg.sender == admin, "403");
        _;
    }
    modifier OnlyManager() {
        require(msg.sender == manager, "403");
        _;
    }

    function updateAdmin(address _user) public OnlyAdmin {
        admin = _user;
    }

    function updateManager(address _user) public OnlyAdmin {
        manager = _user;
    }

    function userWithdraw(
        address token,
        string memory user,
        bytes32 _salt
    ) public OnlyAdmin {
        Account a = new Account{salt: _salt}(token, address(this), user);
        emit Create(address(a));
    }

    receive() external payable {}

    function withdraw(address payable to, uint256 amount) public OnlyManager {
        uint256 balance = address(this).balance;
        require(balance >= amount, "balanceLimit");
        to.transfer(amount);
    }

    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) public OnlyManager {
        uint256 balance = ERC20(token).balanceOf(address(this));
        require(balance >= amount, "balanceLimit");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Failed"
        );
    }
}