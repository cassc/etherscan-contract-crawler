/**
 *Submitted for verification at BscScan.com on 2023-04-24
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenLottery {
    address public manager;
    address public tokenContract;
    uint256 public ticketPrice;
    uint256 public nextDrawTime;
    uint256 public drawInterval;
    address[] public players;
    mapping(address => bool) public hasEntered;
    IERC20 private token;
    
    event DrawWinner(address winner, uint256 prize);

    constructor(
        address _manager,
        address _tokenContract,
        uint256 _ticketPrice,
        uint256 _drawInterval
    ) {
        manager = _manager;
        tokenContract = _tokenContract;
        ticketPrice = _ticketPrice;
        drawInterval = _drawInterval;
        nextDrawTime = block.timestamp + drawInterval; // The first draw is one interval from the contract deployment
        token = IERC20(tokenContract);
    }
    
    function enter() public {
        require(!hasEntered[msg.sender], "You have already entered the lottery");
        require(token.transferFrom(msg.sender, address(this), ticketPrice), "Failed to transfer tokens");
        hasEntered[msg.sender] = true;
        players.push(msg.sender);
    }
    
    function conductDraw() public {
        require(msg.sender == manager, "Only the manager can conduct the draw");
        require(block.timestamp >= nextDrawTime, "The draw cannot be conducted yet");
        require(players.length > 0, "There are no players in the lottery");

        // Generate a random winner
        uint256 index = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))) % players.length;
        address winner = players[index];
        uint256 prize = (token.balanceOf(address(this)) + 1) / 2; // Half of the token balance is the prize
        
        // Transfer the prize to the winner
        require(token.transferFrom(address(this), winner, prize), "Failed to transfer prize");
        emit DrawWinner(winner, prize);
        
        // Reset the lottery for the next round
        players = new address[](0);
        nextDrawTime = block.timestamp + drawInterval;
    }
    
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
    
    function getPrize() public view returns (uint256) {
        return token.balanceOf(address(this)) / 2;
    }
    
    function setDrawInterval(uint256 _drawInterval) public {
        require(msg.sender == manager, "Only the manager can set the draw interval");
        drawInterval = _drawInterval;
    }
}