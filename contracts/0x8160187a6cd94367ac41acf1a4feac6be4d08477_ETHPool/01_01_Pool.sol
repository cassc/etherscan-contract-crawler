// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract ETHPool {
    struct Depositor {
        uint256 firstDepositTime;
        uint256 totalDeposited;
        bool refunded;
        bool winner;
    }

    IERC20 public prizeToken;
    address public admin;
    bytes32 public commitment;
    address public winner;
    uint256 public prizeValue;

    string public prizeName;
    string public prizeDescription;
    uint256 public prizeDrawEndTime;
    uint256 public totalPrizePool;
    uint256 public uniqueDepositorsCount;
    uint256 public burnedPRIZE;

    mapping(address => Depositor) public depositors;
    mapping(address => bool) private uniqueDepositors;

    address[] public participants;

    event Deposited(address indexed user, uint256 amount);
    event WinnerSet(address winner);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    modifier beforeDraw() {
        require(block.timestamp < prizeDrawEndTime, "Draw has ended");
        _;
    }

    modifier onlyPrizeToken() {
    require(msg.sender == address(prizeToken), "Only prizeToken can call this");
    _;
}

    constructor(
        string memory _prizeName,
        string memory _prizeDescription,
        uint256 _prizeDrawEndTime,
        IERC20 _prizeToken,
        bytes32 _commitment,
        uint256 _prizeValue
    ) {
        prizeName = _prizeName;
        prizeDescription = _prizeDescription;
        prizeDrawEndTime = _prizeDrawEndTime;
        prizeToken = _prizeToken;
        commitment = _commitment;
        admin = msg.sender;
        prizeValue = _prizeValue;
    }

function deposit(address depositor, uint256 amount) external onlyPrizeToken beforeDraw {
    require(amount > 0, "Amount should be greater than 0");
    
    // Update depositor info
    depositors[depositor].totalDeposited += amount;
    totalPrizePool += amount;

    if (!uniqueDepositors[depositor]) {
        uniqueDepositors[depositor] = true;
        depositors[depositor].firstDepositTime = block.timestamp;
        uniqueDepositorsCount++;
        participants.push(depositor);
    }
    
    emit Deposited(depositor, amount);
}

    function setWinner(address _winner) external onlyAdmin {
        require(winner == address(0), "Winner already set");
        winner = _winner;
        
        depositors[winner].winner = true;

        // Transfer prize to the winner
        payable(winner).transfer(address(this).balance);
        
        uint256 amountToBurn = depositors[winner].totalDeposited;
        burnedPRIZE = amountToBurn;  // Update the burnedPRIZE variable
        prizeToken.transfer(0x000000000000000000000000000000000000dEaD, amountToBurn);

        emit WinnerSet(winner);
    }

    function claimRefund() external {
        require(winner != address(0), "Winner not yet set");
        require(msg.sender != winner, "Winner cannot claim refund");
        require(depositors[msg.sender].totalDeposited > 0, "No deposit found");
        require(!depositors[msg.sender].refunded, "Refund already claimed");
        
        uint256 refundAmount = depositors[msg.sender].totalDeposited;
        depositors[msg.sender].totalDeposited = 0;
        depositors[msg.sender].refunded = true;

        prizeToken.transfer(msg.sender, refundAmount);
    }

    function getAllParticipants() external view returns (address[] memory) {
        return participants;
    }

    function revealSecretAndVerify(bytes32 secret, string memory knownComponent) view  external onlyAdmin {
        require(keccak256(abi.encodePacked(secret, knownComponent)) == commitment, "Invalid reveal");
        // After this step, the secret is revealed and can be used for verification purposes.
    }

    // Allows the admin to deposit ETH as the prize
    function depositPrize() external payable onlyAdmin {}

    // Checks the balance of ETH in the contract
    function checkPrizeBalance() external view returns (uint256) {
        return address(this).balance;
    }
}