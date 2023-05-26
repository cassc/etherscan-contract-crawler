// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ISpiral } from "../interfaces/ISpiral.sol";
import { IERC20, SafeERC20, SafeERC20Burn } from "../libraries/SafeERC20Burn.sol";

contract SpiralStaking {
    using SafeERC20 for IERC20;
    using SafeERC20 for ISpiral;
    using SafeERC20Burn for IERC20;
    using SafeERC20Burn for ISpiral;
    mapping (address => uint256) public lastStake;
    struct Epoch {
        uint length;
        uint number;
        uint endBlock;
        uint apr;
    }
    modifier onlyGuard() {
        require(guard == msg.sender, "not a guard");
        _;
    }

    Epoch public epoch;
    uint256 public index = 10**18;
    uint256 constant initialIndex = 10**18;
    uint256 constant blocksPerYear = 2628000;
    //apr 50% - 5000
    uint256 constant aprBase = 10000;
    ISpiral public immutable Coil;
    ISpiral public immutable Spiral;
    address public guard;
    constructor(address coil, address spiral)  {
        Coil = ISpiral(coil);
        Spiral = ISpiral(spiral);
        epoch.number = 1;
        epoch.length = 2400;
        epoch.endBlock = block.number;
        guard = msg.sender;
    }


    function stake(uint256 amount_) external {
        rebase();
        Coil.safeTransferFrom(msg.sender, address(this), amount_);
        Spiral.mint( msg.sender, (amount_*initialIndex) / index );
        lastStake[msg.sender] = epoch.number;
    }

    function unstake(uint256 amount_) external {
        rebase();
        Spiral.safeBurnFrom(msg.sender, amount_);
        Coil.safeTransfer( msg.sender, (amount_ * index) / initialIndex );
    }

    function rebase() public {
        while( epoch.endBlock <= block.number ) { // #FX: SGN-01M
            index = index + ((epoch.apr*index*epoch.length) / blocksPerYear / aprBase);
            uint256 totalSpiral = Spiral.totalSupply();
            epoch.endBlock = epoch.endBlock + epoch.length;
            epoch.number++;
            if (totalSpiral > 0 && Coil.balanceOf(address(this)) > 0 && epoch.apr > 0){
                Coil.mint(address(this), (totalSpiral * index / initialIndex) - Coil.balanceOf(address(this)));
            }
        }
    }

    function changeLength(uint256 length) external onlyGuard {
        require(length < 50000, "Too long");
        epoch.length = length;
    }

    function changeAPR(uint256 apr) external onlyGuard {
        require(apr < 1000000, "Too Big");
        epoch.apr = apr;
    }

    function changeGuard(address newGuard) external onlyGuard {
        require(newGuard != address(0));
        guard = newGuard;
    }
}