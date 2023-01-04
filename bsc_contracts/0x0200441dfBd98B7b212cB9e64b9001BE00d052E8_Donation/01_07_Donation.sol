// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "ERC20.sol";
import "Ownable.sol";

import "ReentrancyGuard.sol";

contract Token is ERC20 {
    constructor(
        string memory _name,
        string memory _ticker,
        uint256 _supply
    ) ERC20(_name, _ticker) {
        _mint(msg.sender, _supply);
    }

    function mint(address _from, uint256 _supply) public {
        _mint(_from, _supply);
    }
}

contract Donation is Ownable, ReentrancyGuard {
    address[] public tokens;
    uint256 public tokenCount;
    event TokenDeployed(address tokenAddress);

    function deployToken(
        string calldata _name,
        string calldata _ticker,
        uint256 _supply
    ) public returns (address) {
        require(tokenCount == 0, "can be used only one time");
        Token token = new Token(_name, _ticker, _supply);
        token.transfer(msg.sender, _supply);
        tokens.push(address(token));
        tokenCount += 1;
        emit TokenDeployed(address(token));
        return address(token);
    }

    //sil
    mapping(address => uint256) public donationAmount;

    //AggregatorV3Interface internal ethUsdPriceFeed;

    /*enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;*/

    // 0
    // 1
    // 2

    function donateHere() public payable nonReentrant {
        require(msg.value > 0, "Cannot donate 0");
        calculateTransferAmount();
    }

    function calculateTransferAmount() internal {
        uint256 calculatedTransferAmount = 0;
        uint256 beforeAmount = donationAmount[msg.sender];
        uint256 issueAmount = 0;
        uint256 transferAmount = findIssued(beforeAmount, msg.value);
        donationAmount[msg.sender] += msg.value;
        require(address(0) != tokens[0], "token is not deployed");
        Token myToken = Token(tokens[0]);

        myToken.mint(msg.sender, transferAmount);
        myToken.mint(owner(), transferAmount / 10);
        //myToken.transfer(msg.sender, transferAmount);
    }

    function findIssued(uint256 _beforeAmount, uint256 _afterAmount)
        public
        pure
        returns (uint256)
    {
        uint256 totalPrizeAmount;
        uint256 totalAmount = _beforeAmount + _afterAmount;
        if (_beforeAmount == 0) {
            totalPrizeAmount = 1 * 10**18;
        }
        //kactane verildiği
        return
            totalPrizeAmount +
            (((totalAmount * 1 * 10**18) - (_beforeAmount * 1 * 10**18)) /
                (10**17));
    }

    /*function transferOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }*/

    function recoverEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //event cantSendEthOwner(address indexed to, uint256 value);

    //sil sonu

    constructor() public {}

    /*nonReentrant*/
}