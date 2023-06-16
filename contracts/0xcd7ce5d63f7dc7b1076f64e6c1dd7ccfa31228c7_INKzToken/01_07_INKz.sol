pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

interface iOctoHedz {
    function balanceOf(address owner) external view returns(uint256);
}

contract INKzToken is ERC20, ERC20Burnable, Ownable {

    iOctoHedz public OctoHedz;
    uint256 constant public INKZ_RATE = 8 ether;
    uint256 public START;
    uint256 constant public END = 1892199600;
    bool inkzPaused = false;
    
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    constructor(address octohedzAddress) ERC20("INKzToken", "INKz") {
        OctoHedz = iOctoHedz(octohedzAddress);
        START = block.timestamp - (38 days);
    }

    function toggleReward() public onlyOwner {
        inkzPaused = !inkzPaused;
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(OctoHedz));
        if(from != address(0)){
            rewards[from] += getPendingReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if(to != address(0)){
            rewards[to] += getPendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function claimReward() external {
        require(!inkzPaused, "Claiming INKz must be active");
        require(block.timestamp <= END, "Date exceeds the max limit");
        _mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

   
    function claimINKzRewards(address _address, uint256 _amount) external {
        require(!inkzPaused, "Claiming reward has been paused");
        require(allowedAddresses[msg.sender], "Address does not have permission to distrubute tokens");
        _mint(_address, _amount);
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(OctoHedz), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }



    function getPendingReward(address user) internal view returns(uint256) {
        return OctoHedz.balanceOf(user) * INKZ_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }
  

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }
}