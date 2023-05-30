// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./Jaguars.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract JaguarsPension is Ownable, Multicall
{
    IERC20Burnable public immutable gang;
    Jaguars        public immutable jaguars;

    uint256 public fusingCost    = 300 ether;
    uint256 public breedingCost  = 700 ether;
    uint256 public breedingDelay = 30 days;
    uint256 public viagraCost    = type(uint256).max;
    uint256 public fee           = 0.5 ether;

    mapping(uint256 => uint256) public lastBreed;
    mapping(uint256 => uint256) public countBreed;

    event Bred(uint256 indexed tokenId);
    event Reset(uint256 indexed tokenId);
    event FusingCostUpdated(uint256 newFusingCost);
    event BreedingCostUpdated(uint256 newBreedingCost);
    event BreedingDelayUpdated(uint256 newBreedingDelay);
    event ViagraCostUpdated(uint256 newViagraCost);
    event FeeUpdated(uint256 newFee);

    modifier onlySimple(uint256 tokenId) {
        require(tokenId < type(uint16).max, "restricted to simple jaguars");
        _;
    }

    modifier onlyLegendary(uint256 tokenId) {
        require(tokenId >= type(uint16).max && tokenId < type(uint32).max, "restricted to legendary jaguars");
        _;
    }

    modifier onlyBaby(uint256 tokenId) {
        require(tokenId >= type(uint32).max, "restricted to baby jaguars");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(jaguars.ownerOf(tokenId) == msg.sender, "caller must be owner");
        _;
    }

    modifier requirePayment(uint256 amount) {
        uint256 toOwner = amount * fee / 1 ether;
        gang.transferFrom(msg.sender, owner(), toOwner);
        gang.burnFrom(msg.sender, amount - toOwner);
        _;
    }

    constructor(IERC20Burnable _gang, Jaguars _jaguars)
    {
        gang    = _gang;
        jaguars = _jaguars;
    }

    /**
     * User functions
     */
    function fuse(uint256 tokenId1, uint256 tokenId2)
    external
        onlySimple(tokenId1)
        onlySimple(tokenId2)
        onlyTokenOwner(tokenId1)
        onlyTokenOwner(tokenId2)
        requirePayment(fusingCost)
    {
        jaguars.burn(tokenId1);
        jaguars.burn(tokenId2);
        jaguars.mint(
            msg.sender,
            tokenId1 << 16 | tokenId2
        );
    }

    function breed(uint256 tokenId1, uint256 tokenId2)
    external
        onlyLegendary(tokenId1)
        onlyLegendary(tokenId2)
        onlyTokenOwner(tokenId1)
        onlyTokenOwner(tokenId2)
        requirePayment(breedingCost)
    {
        uint256 breedCount1 = _updateBreed(tokenId1);
        uint256 breedCount2 = _updateBreed(tokenId2);

        jaguars.mint(
            msg.sender,
            breedCount1 << 72 | tokenId1 << 40 | breedCount2 << 32 | tokenId2
        );
    }

    function viagra(uint256 tokenId)
    external
        onlyLegendary(tokenId)
        requirePayment(viagraCost)
    {
        lastBreed[tokenId] = block.timestamp;
        emit Reset(tokenId);
    }

    /**
     * Admin functions
     */
    function updateFusingCost(uint256 newFusingCost)
    external onlyOwner()
    {
        fusingCost = newFusingCost;
        emit FusingCostUpdated(newFusingCost);
    }

    function updateBreedingCost(uint256 newBreedingCost)
    external onlyOwner()
    {
        breedingCost = newBreedingCost;
        emit BreedingCostUpdated(newBreedingCost);
    }

    function updateViagraCost(uint256 newViagraCost)
    external onlyOwner()
    {
        viagraCost = newViagraCost;
        emit ViagraCostUpdated(newViagraCost);
    }

    function updateFee(uint256 newFee)
    external onlyOwner()
    {
        require(newFee <= 1 ether, "invalid value");
        fee = newFee;
        emit FeeUpdated(newFee);
    }

    function updateBreedingDelay(uint256 newDelay)
    external onlyOwner()
    {
        breedingDelay = newDelay;
        emit BreedingDelayUpdated(newDelay);
    }

    /**
     * Private functions
     */
    function _updateBreed(uint256 tokenId) private returns (uint256) {
        require(lastBreed[tokenId] < block.timestamp, "not ready to bread");
        require(countBreed[tokenId] < 4, "cannot breed anymore");
        lastBreed[tokenId] = block.timestamp + breedingDelay;
        emit Bred(tokenId);
        return ++countBreed[tokenId];
    }
}