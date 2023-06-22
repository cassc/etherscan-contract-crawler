// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC721A.sol";
import "./IERC20.sol";

contract AswangTribeSacrifice is Ownable {
    uint public ATReward;
    uint public RBReward;
    address public ATAddy;
    address public RBAddy;
    address public DugoAddy;
    address burnAddy;
    IERC721A public ATContract;
    IERC721A public RBContract;
    IERC20 public DugoContract;

    event ATSacrificed(uint[] tokenIds);
    event RBSacrificed(uint[] tokenIds); 

    constructor() {
        ATReward = 600 ether;
        RBReward = 10 ether;
        ATAddy = 0xb189789434a4728F45B88B009BeE5f4b339e3e88;
        RBAddy = 0xa462127735352B1F03dA8Ab92a87803d05cc6a7B;
        DugoAddy = 0xc6FDa51Da94bc7dDE0e8a5Ff3C45906AcD6ddC03;
        burnAddy = 0x000000000000000000000000000000000000dEaD;
        ATContract = IERC721A(ATAddy);
        RBContract = IERC721A(RBAddy);
        DugoContract = IERC20(DugoAddy);
    }

    function setATReward(uint newReward) external onlyOwner {
        ATReward = newReward;
    }

    function setRBReward(uint newReward) external onlyOwner {
        RBReward = newReward;
    }

    function burnCount() external view returns (uint) {
        return ATContract.balanceOf(burnAddy);
    }

    function dugoBalance() external view returns (uint) {
        return DugoContract.balanceOf(address(this));
    }
    
    /* SACRIFICE ASWANG TRIBE IN EXCHANGE FOR DUGO*/
    function sacrificeAT(uint256[] calldata tokenIds) external {
         uint256 balance = DugoContract.balanceOf(address(this));
        require(balance >= ATReward * tokenIds.length, "Insufficient Dugo Balance");
         for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            require(ATContract.ownerOf(tokenId) == msg.sender, "You don't own the token you are trying to burn");
            //BURN TOKEN
            (bool burnSuccess, ) = ATAddy.call(abi.encodeWithSelector(ATContract.transferFrom.selector, msg.sender, burnAddy, tokenId));
            require(burnSuccess, "Please approve contract to manage tokenId");
            
            //TRANSFER DUGO
            unchecked { ++i; }
        }
        // (bool transferSuccess, ) = DugoAddy.call(abi.encodeWithSelector(DugoContract.transferFrom.selector, address(this), msg.sender, ATReward * tokenIds.length));
        (bool transferSuccess, ) = DugoAddy.call(abi.encodeWithSelector(DugoContract.transfer.selector, msg.sender, ATReward * tokenIds.length));
        require(transferSuccess, "Reward transfer failed");
        emit ATSacrificed(tokenIds);
    }

    /* SACRIFICE RADIOACTIVE BALUT IN EXCHANGE FOR DUGO*/
    function sacrificeRB(uint256[] calldata tokenIds) external {
         uint256 balance = DugoContract.balanceOf(address(this));
        require(balance >= RBReward * tokenIds.length, "Insufficient Dugo Balance");
         for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            require(RBContract.ownerOf(tokenId) == msg.sender, "You don't own the token you are trying to burn");
            //BURN TOKEN
            (bool burnSuccess, ) = RBAddy.call(abi.encodeWithSelector(RBContract.transferFrom.selector, msg.sender, burnAddy, tokenId));
            require(burnSuccess, "Please approve contract to manage tokenId");
            
            //TRANSFER DUGO
            unchecked { ++i; }
        }
        // (bool transferSuccess, ) = DugoAddy.call(abi.encodeWithSelector(DugoContract.transferFrom.selector, address(this), msg.sender, ATReward * tokenIds.length));
        (bool transferSuccess, ) = DugoAddy.call(abi.encodeWithSelector(DugoContract.transfer.selector, msg.sender, RBReward * tokenIds.length));
        require(transferSuccess, "Reward transfer failed");
        emit RBSacrificed(tokenIds);
    }

    

}