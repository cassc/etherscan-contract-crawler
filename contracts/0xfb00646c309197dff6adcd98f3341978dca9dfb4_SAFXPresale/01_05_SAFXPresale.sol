// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SAFXPresale is Ownable, ReentrancyGuard {
    uint256 public raised;
    uint256 public cap = 15 * (10 ** 18);
    uint256 public max = 2 * (10 ** 18);
    bool public live;
    uint256 public ends;
    mapping (address => bool) private _participated;

    constructor() {}

    receive() external payable {}

    function contribute() external payable nonReentrant {
        require(live, "Not open");
        require(block.timestamp < ends, "Closed");
        require(msg.value + raised <= cap, "Hard cap hit");
        require(msg.value >= 0, "Amount too low");
        require(msg.value <= max, "Amount too high");
        require(!_participated[msg.sender], "Already contributed");
        _participated[msg.sender] = true;
        raised += msg.value;
    }

    function viewRaised() external view returns (uint256) {
        return raised;
    }

    function viewParticipated(address _wallet) external view returns (bool) {
        return _participated[_wallet];
    }

    function viewLive() external view returns (bool) {
        return live;
    }

    function goLive() external onlyOwner {
        live = true;
        ends = block.timestamp + 86400;
    }

    function extend(uint256 _seconds) external onlyOwner {
        ends = block.timestamp + _seconds;
    }

    function collect() external onlyOwner {
        payable(msg.sender).call{value: address(this).balance}("");
    }

    function collectToken(address _address) external onlyOwner {
        IERC20 _token = IERC20(_address);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
}