//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.17;

contract WToken is ERC20, Ownable {
    address public StakingContract;

    constructor() ERC20("$W", "$W") {}

    modifier onlyOwnerOrStaking() {
        require(msg.sender == StakingContract || msg.sender == owner(), "Only Owner Or Staking Contract");
        _;
    }

    function mint(address receiver, uint tokens) external onlyOwnerOrStaking {
        _mint(receiver, tokens);
    }

    function burn(address burner, uint tokens) external onlyOwnerOrStaking {
        _burn(burner, tokens);
    }

    function setStakingContract(address _newContract) external onlyOwner {
        StakingContract = _newContract;
    }
}