pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMINT {
    function mint(address receiver, uint amount) external;
}

contract Faith is ERC20("Faith", "FAITH"), Ownable {
    IERC20 public love;

    uint public lovePerBlock;
    uint public lastMintBlock;
    uint public faithFeePercent;

    address public feeReceiver;

    bool public active;

    constructor(IERC20 _love) Ownable() {
        love = _love;
        active = true;
        lovePerBlock = 200 * 10 ** 18;
        faithFeePercent = 10;
        lastMintBlock = block.number;
        feeReceiver = msg.sender;
    }

    modifier onlyActive() {
        require(active, "Faith: Not active");
        _;
    }

    function enter(uint256 _amount) public onlyActive {
        snap();
        uint256 totalLove = love.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalLove == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = (_amount * totalShares) / totalLove;
            uint256 faithToMint = what * (100 - faithFeePercent) / 100;
            uint256 faithFeeToMint = what - faithToMint;
            _mint(msg.sender, what);
            _mint(feeReceiver, faithFeeToMint);
        }
        love.transferFrom(msg.sender, address(this), _amount);
    }

    function leave(uint256 _share) public onlyActive {
        snap();
        uint256 totalShares = totalSupply();
        uint256 what = (_share * love.balanceOf(address(this))) / totalShares;
        _burn(msg.sender, _share);
        love.transfer(msg.sender, what);
    }

    function snap() internal {
        if(block.number == lastMintBlock) {
            return;
        }
        IMINT(address(love)).mint(address(this), lovePerBlock * (block.number - lastMintBlock));
        lastMintBlock = block.number;
    }

    function flipActive() external onlyOwner {
        active = !active;
    }

    function updateLovePerBlock(uint _lovePerBlock) external onlyOwner {
        snap();
        lovePerBlock = _lovePerBlock;
    }

    function updateFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function updateFaithFeePercent(uint _faithFeePercent) external onlyOwner {
        require (_faithFeePercent <= 100, "Faith: Fee percent must be less than or equal to 100");
        faithFeePercent = _faithFeePercent;
    }
}