//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//// @title Airdrop
/// @dev A smart contract for distributing ERC20 tokens to multiple addresses
contract Airdrop is Ownable {
    using SafeERC20 for IERC20;

    address public DEV;

    IERC20 public HORNY = IERC20(0x3d939F3aAB9aF971a9eDA1bC63A768D0DF386f66);

    IERC721 public hornyPixel = IERC721(0xE6C2b125FC1481C2C59CDe72Ab9f2F9f1394111b);
    IERC721 public pixieBumz = IERC721(0x705C59D470cB86D55784090596C1831B903daFc7);

    uint256 public hornyPixelAirdrop = 3378378 * (10 ** 18);
    uint256 public pixieBumzAirdrop = 1036269 * (10 ** 18);
    
    mapping(uint16 => bool) public isHornyPixelClaimed;
    mapping(uint16 => bool) public isPixieBumzClaimed;

    uint256 public startClaimTime = 1684252800;

    constructor() {
        DEV = msg.sender;
    }

    /// @dev Allows a recipient to claim their airdropped tokens
    function claim(uint16[] calldata _hornyPixelIds, uint16[] calldata _pixieBumzIds) public {
        uint256 amountHornyPixel = 0;
        uint256 amountPixieBumz = 0;

        for (uint256 i = 0; i < _hornyPixelIds.length; i++) {
            if (hornyPixel.ownerOf(_hornyPixelIds[i]) == msg.sender && !isHornyPixelClaimed[_hornyPixelIds[i]]) {
                amountHornyPixel += hornyPixelAirdrop;
                isHornyPixelClaimed[_hornyPixelIds[i]] = true;
            }
        }

        for (uint256 i = 0; i < _pixieBumzIds.length; i++) {
            if (pixieBumz.ownerOf(_pixieBumzIds[i]) == msg.sender && !isPixieBumzClaimed[_pixieBumzIds[i]]) {
                amountPixieBumz += pixieBumzAirdrop;
                isPixieBumzClaimed[_pixieBumzIds[i]] = true;
            }
        }

        uint256 amount = amountHornyPixel + amountPixieBumz;

        require(amount > 0, "Not eligible to claim");

        HORNY.safeTransfer(msg.sender, amount);
    }

    function checkClaimableAmount(address _address, uint16[] calldata _hornyPixelIds, uint16[] calldata _pixieBumzIds) public view returns (uint256) {
        uint256 amountHornyPixel = 0;
        uint256 amountPixieBumz = 0;

        for (uint256 i = 0; i < _hornyPixelIds.length; i++) {
            if (hornyPixel.ownerOf(_hornyPixelIds[i]) == _address && !isHornyPixelClaimed[_hornyPixelIds[i]]) {
                amountHornyPixel += hornyPixelAirdrop;
            }
        }

        for (uint256 i = 0; i < _pixieBumzIds.length; i++) {
            if (pixieBumz.ownerOf(_pixieBumzIds[i]) == _address && !isPixieBumzClaimed[_pixieBumzIds[i]]) {
                amountPixieBumz += pixieBumzAirdrop;
            }
        }

        uint256 amount = amountHornyPixel + amountPixieBumz;
        return amount;
    }

    /// @dev in case of emergency
    function withdrawHORNY() external onlyOwner {
        require(HORNY.balanceOf(address(this)) > 0, "Contract has no HORNY");
        HORNY.transfer(owner(), HORNY.balanceOf(address(this)));
    }

    /// @dev in case of emergency
    function withdrawETH() external onlyOwner {
        require(address(this).balance > 0, "Contract has no ETH");
        payable(DEV).transfer(address(this).balance);
    }

    /// @dev token balance
    function tokensAvailable() public view returns (uint256) {
        return HORNY.balanceOf(address(this));
    }
}