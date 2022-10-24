// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BLA is ERC20('BlaBlaGame.io GameFi token', 'BLA'), Ownable
{
    event HolderPaused(address holder);
    event HolderUnpaused(address holder);

    mapping (address => bool) public pausedHolders;

    constructor(address initialTokenHolder) {
        _mint(initialTokenHolder, 80000000e18);
    }

    function pauseHolder(address suspiciousHolder) external onlyOwner {
        pausedHolders[suspiciousHolder] = true;
        emit HolderPaused(suspiciousHolder);
    }

    function unpauseHolder(address holder) external onlyOwner {
        pausedHolders[holder] = false;
        emit HolderUnpaused(holder);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override view {
        require (pausedHolders[from] == false, "This sender could not transfer tokens now");
        require (pausedHolders[to] == false, "This receiver could not receive tokens now");
    }
}