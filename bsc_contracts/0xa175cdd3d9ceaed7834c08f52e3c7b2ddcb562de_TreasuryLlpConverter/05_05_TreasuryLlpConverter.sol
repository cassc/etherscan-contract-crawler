// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";

contract TreasuryLlpConverter is Ownable {
    ITreasury public treasury;

    address public controller;
    address public cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public llp = 0xB5C42F84Ab3f786bCA9761240546AA9cEC1f8821;
    address[] public assets;

    uint256 public llpSaved;
    uint256 public llpDeficit;

    constructor(address _treasury, address[] memory _assets) {
        require(_treasury != address(0), "invalid address");
        controller = msg.sender;
        treasury = ITreasury(_treasury);
        _setAssets(_assets);
    }

    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), "INVALID ADDRESS");
        controller = _controller;
    }

    function setAssets(address[] memory _assets) external onlyOwner {
        _setAssets(_assets);
    }

    function run(uint256 _minLlpAdded) external {
        require(msg.sender == controller || msg.sender == owner(), "NOT ALLOWED");

        // 1: swap CAKE to USDT
        uint256 _cakeBalance = IERC20(cake).balanceOf(address(treasury));
        if (_cakeBalance > 0) {
            treasury.swap(cake, usdt, _cakeBalance, 0); // optimistic
        }

        // 2: loop through all assest and convert to LLP
        uint256 _llpBalanceBefore = IERC20(llp).balanceOf(address(treasury));
        for (uint8 i = 0; i < assets.length; i++) {
            address _token = assets[i];
            uint256 _balance = IERC20(_token).balanceOf(address(treasury));
            if (_balance > 0) {
                treasury.convertToLLP(assets[i], _balance, 0); // optimistic
            }
        }
        uint256 _llpReceived = IERC20(llp).balanceOf(address(treasury)) - _llpBalanceBefore;
        require(_llpReceived >= _minLlpAdded, "Slippage");
        emit LlpAdded(_llpReceived);
    }

    function _setAssets(address[] memory _assets) internal {
        for (uint256 i = 0; i < _assets.length; ++i) {
            if (_assets[i] == address(0)) {
                revert("Invalid address");
            }
        }
        assets = _assets;
    }

    event LlpAdded(uint256 _amt);
}