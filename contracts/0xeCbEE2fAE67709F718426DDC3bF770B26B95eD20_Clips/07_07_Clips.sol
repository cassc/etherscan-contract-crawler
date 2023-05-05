// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract Clips is ERC20Capped, Ownable {
    uint256 public constant maxSupply = 220000000000 * 10 ** 18; // 220b
		uint256 public prizePool = 50000000000 * 10 ** 18; // 50b
		uint256 public teamSupply = 20000000000 * 10 ** 18; // 20b
    uint256 public initialMintAmount = 5000000 * 10 ** 18; // 5m
    uint256 public clipCost = 250000 * 10 ** 18; // 250k
    uint256 public lastClipUpdate;
    address public clipOwner;
    string public clip = "FUCK JANNIES";
    mapping(address => uint256) public lastMintValue;
    mapping(address => uint256) public lastMintTime;

    event ClipUpdated(address indexed user, string message, uint256 newClipCost);
    event PrizePoolClaimed(address indexed clipOwner, uint256 amount);
		event Log(string func, uint gas);

    modifier maxLength(string memory message) {
        require(bytes(message).length <= 26, "Message must be 26 characters or less");
        _;
    }

    constructor() ERC20("CLIPS", "CLIPS") ERC20Capped(maxSupply) {
        _mint(address(this), maxSupply); 
				_transfer(address(this), msg.sender, teamSupply); 
        clipOwner = msg.sender; 
    }

    function mintClips() external {
        require(block.timestamp >= lastMintTime[msg.sender] + 1 days, "You can only mint once every 24 hours");
        uint256 mintAmount;
        if (lastMintValue[msg.sender] == 0) {
            mintAmount = initialMintAmount;
        } else {
						mintAmount = lastMintValue[msg.sender] / 2;
        }
        require(mintAmount > 0, "Mint amount is too small");
				require(balanceOf(address(this)) - prizePool >= mintAmount, "Not enough CLIPS left to mint");
        lastMintValue[msg.sender] = mintAmount;
				lastMintTime[msg.sender] = block.timestamp;
				_transfer(address(this), msg.sender, mintAmount);
    }

    function setClip(string memory message) external maxLength(message) {
				require(bytes(message).length > 0, "Message cannot be empty");
        if (msg.sender != clipOwner) {
            require(balanceOf(msg.sender) >= clipCost, "Insufficient CLIPS to set CLIP");
            IERC20(address(this)).transferFrom(msg.sender, address(this), clipCost);
						_burn(address(this), clipCost);
						clipCost = clipCost + (clipCost * 5000) / 10000;
        }
        clip = message;
        clipOwner = msg.sender;
        lastClipUpdate = block.timestamp;
        emit ClipUpdated(msg.sender, message, clipCost);
    }

    function claimPrizePool() external {
        require(block.timestamp >= lastClipUpdate + 7 days, "Prizepool can be claimed if 7 days have passed without a CLIP update");
        require(msg.sender == clipOwner, "Only the current clipOwner can claim the prizepool");
				uint256 claimAmount = prizePool;
        prizePool = 0;
				_transfer(address(this), msg.sender, claimAmount);
        emit PrizePoolClaimed(msg.sender, prizePool);
    }

    fallback() external payable {
        emit Log("fallback", gasleft());
    }

    receive() external payable {
        emit Log("receive", gasleft());
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

		function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

}