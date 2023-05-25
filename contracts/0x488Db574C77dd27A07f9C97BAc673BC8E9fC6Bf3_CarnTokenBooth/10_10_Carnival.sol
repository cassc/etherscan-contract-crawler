// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CarnTokenBooth is ERC20, ERC20Burnable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_SUPPLY = 2 * 3141592 * 1e12;
    uint256 public currentRate; // How many token units a buyer gets per USDCBits
    uint256 public nextHike; // timestamp for the next hike
    uint256 week = 1;

    address public immutable pulseBitcoinLockNFTRewardPoolAddress;
    address public immutable carnivalBenevolentAddress;
    address public immutable waatcaAddress;
    address public immutable USDC;

    constructor(
        address _pulseBitcoinLockNFTRewardPoolAddress,
        address _carnivalBenevolentAddress,
        address _waatcaAddress,
        address _USDC
    ) ERC20("The PulseDogecoin Staking Carnival Token", "CARN") {
        pulseBitcoinLockNFTRewardPoolAddress = _pulseBitcoinLockNFTRewardPoolAddress;
        carnivalBenevolentAddress = _carnivalBenevolentAddress;
        waatcaAddress = _waatcaAddress;
        USDC = _USDC;
        _mint(pulseBitcoinLockNFTRewardPoolAddress, 1000000 * 1e12);
        _mint(carnivalBenevolentAddress, 2 * 141592 * 1e12);
        currentRate = 1e12 / 1e6; // Initially 1 USDC =  1 CARN
        nextHike = block.timestamp + 2 weeks;
    }

    function buyCARN(uint256 _usdcValue) public nonReentrant {
        require(block.chainid == 1, "This function can only be called on Ethereum mainnet");
        if (block.timestamp >= nextHike) {
            currentRate = 1e12 / (1e6 + 50000 * week);
            nextHike = block.timestamp + 1 weeks;
            week++;
        }

        IERC20(USDC).safeTransferFrom(msg.sender, carnivalBenevolentAddress, _usdcValue / 2);
        IERC20(USDC).safeTransferFrom(msg.sender, waatcaAddress, _usdcValue / 2);

        uint256 amount = _usdcValue * currentRate;
        require(totalSupply() + amount <= MAX_SUPPLY, "CARN supply exhausted");
        _mint(msg.sender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 12;
    }
}