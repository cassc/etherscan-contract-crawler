// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingView is Ownable {
    IERC1155 public genOneStaked;
    IERC1155 public genTwoStaked;

    uint256 public genOneStakedSupply;
    uint256 public genTwoStakedSupply;

    constructor(
        IERC1155 genOneStaked_,
        IERC1155 genTwoStaked_
    ) {
        genOneStaked = genOneStaked_;
        genTwoStaked = genTwoStaked_;
    }

    function _isStaked(address owner_, IERC1155 implementation, uint256 totalSupply_) internal view returns (bool) {
        bool isStaked = false;
        for(uint256 i = 0; i < totalSupply_; i++) {   
            if (implementation.balanceOf(owner_, i) == 1) {                
                isStaked = true;
                break;
            }
        }
        return isStaked;
    }

    function isStakedGenOne(address owner_) public view returns (bool) {
        return _isStaked(owner_, genOneStaked, genOneStakedSupply);
    }

    function isStakedGenTwo(address owner_) public view returns (bool) {
        return _isStaked(owner_, genTwoStaked, genTwoStakedSupply);
    }

    function setGenOneStakedSupply(uint256 totalSupply_) external onlyOwner {
        genOneStakedSupply = totalSupply_;
    }

    function setGenTwoStakedSupply(uint256 totalSupply_) external onlyOwner {
        genTwoStakedSupply = totalSupply_;
    }

    function setGenOneStaked(IERC1155 genOneStaked_) external onlyOwner {
        genOneStaked = genOneStaked_;
    }

    function setGenTwoStaked(IERC1155 genTwoStaked_) external onlyOwner {
        genTwoStaked = genTwoStaked_;
    }
}