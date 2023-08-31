/**
 *Submitted for verification at Etherscan.io on 2023-07-15
*/

contract finance_bank {
    function Deposit(uint _unlockTime) public payable {
        Holder storage acc = Accounts[msg.sender];
        acc.balance += msg.value;
        acc.unlockTime = _unlockTime > block.timestamp ? _unlockTime : block.timestamp;
        LogFile.AddMessage(msg.sender, msg.value, "Put");
    }

    function Collect(uint _am) public payable {
        Holder storage acc = Accounts[msg.sender];
        if (acc.balance > MinSum && acc.balance >= _am && block.timestamp > acc.unlockTime) {
            (bool success, ) = msg.sender.call{value: _am}("");
            if (success) {
                acc.balance -= _am;
                LogFile.AddMessage(msg.sender, _am, "Collect");
            }
        }
    }

    struct Holder {
        uint unlockTime;
        uint balance;
    }

    mapping(address => Holder) public Accounts;

    Log LogFile;

    uint public MinSum = 1 ether;

    constructor(address log) {
        LogFile = Log(log);
    }

    fallback() external payable {
        Deposit(0);
    }

    receive() external payable {
        Deposit(0);
    }
}

contract Log {
    event Message(address indexed Sender, string Data, uint Val, uint Time);

    function AddMessage(address _adr, uint _val, string memory _data) external {
        emit Message(_adr, _data, _val, block.timestamp);
    }
}