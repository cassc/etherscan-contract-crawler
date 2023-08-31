// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;


import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function mint(address user, uint256 amount) external returns(bool);
    function burn(address user, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TokenHelper is Ownable {
    IERC20 public immutable esLBR;
    IERC20 public immutable LBR;
    IERC20 public immutable oldLBR;
    uint256 public deadline;
   
    event BatchEsLBRForUsers(address indexed caller, string desc, uint256 total);
    event BatchLBRForUsers(address indexed caller, string desc, uint256 total);

    constructor(address _esLBR, address _LBR, address _oldLBR, uint256 _deadline) {
        esLBR = IERC20(_esLBR);
        LBR = IERC20(_LBR);
        oldLBR = IERC20(_oldLBR);
        deadline = _deadline;
    }

    function airdropEsLBR(address[] calldata to, uint256[] calldata value, string memory desc) external onlyOwner {
        require(block.timestamp <= deadline);
        uint256 total = 0;
        for(uint256 i = 0; i < to.length; i++){
            esLBR.mint(to[i], value[i]);
            total += value[i];
        }
        emit BatchEsLBRForUsers(msg.sender, desc, total);
    }

    function airdropLBR(address[] calldata to, uint256[] calldata value, string memory desc) external onlyOwner {
        require(block.timestamp <= deadline);
        uint256 total = 0;
        for(uint256 i = 0; i < to.length; i++){
            LBR.mint(to[i], value[i]);
            total += value[i];
        }
        emit BatchLBRForUsers(msg.sender, desc, total);
    }

    function migrate(uint256 amount) external {
        require(block.timestamp <= deadline);
        oldLBR.transferFrom(msg.sender, address(this), amount);
        LBR.mint(msg.sender, amount);
    }
}