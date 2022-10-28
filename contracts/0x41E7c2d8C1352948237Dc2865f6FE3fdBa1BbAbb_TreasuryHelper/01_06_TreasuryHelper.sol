// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";
import "./libs/Ownable.sol";
import "./interfaces/ITreasury.sol";

contract TreasuryHelper is Ownable {

    ITreasury private treasury;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private psi;

    constructor (address _treasury, address _psi) {
        require(_treasury != address(0));
        psi = _psi;
        treasury = ITreasury(_treasury);
    }

    function setPsiAddress(address _psiAddress) external onlyManager() {
        psi = _psiAddress;
    }

    function setTreasury(address _treasury) external onlyManager() {
        require(_treasury != address(0));
        treasury = ITreasury(_treasury);
    }

    function depositTreasury(uint _amount, uint _profit) public onlyManager() {
        uint256 balance = IERC20(DAI).balanceOf(address(this));
        require(_amount <= balance);

        IERC20(DAI).approve(address(treasury), _amount);
        treasury.deposit(_amount, DAI, _profit);
    }

    function depositTreasury() external {
        require(msg.sender == psi);
        uint balance = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).approve(address(treasury), balance);
        IERC20(DAI).approve(address(ROUTER), balance);
        treasury.deposit(balance, DAI, balance);
    }

    function withdraw() external onlyManager {
        uint256 balance = IERC20(DAI).balanceOf(address(this));
        IERC20(DAI).transfer(msg.sender, balance);
    }

    function withdrawEth() public payable onlyManager {
        (bool success,) = payable(msg.sender).call{value : address(this).balance}("");
    }

}