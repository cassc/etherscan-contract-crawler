// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IDelotNFT.sol";

contract Divider is Ownable, KeeperCompatibleInterface {
    address public _tokenAddress;
    address public _nftAddress;   
    
    uint256 public _minimumTokensToProcess = 1000 * 10**18; 

    event Rewarded(address indexed receiver, uint256 amount);

    constructor(address tokenAddress, address nftAddress)
    {
        _tokenAddress = tokenAddress;
        _nftAddress = nftAddress;
    }

    function setMinimumTokensToProcess(uint256 amount) external onlyOwner {
        _minimumTokensToProcess = amount;
    }

    // KEEPER  
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = hasWork();
        performData = "";
    }

    function hasWork() private view returns (bool) {        
        IDelotNFT nftDELOT = IDelotNFT(_nftAddress);
        if (nftDELOT.totalSupply() > 0 && nftDELOT.numberOfHolders() > 0 &&
            IERC20(_tokenAddress).balanceOf(address(this)) >= _minimumTokensToProcess) 
        {
            return true;
        }        

        return false;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if (hasWork()==false) {
            return;
        }

        //
        IDelotNFT nftDELOT = IDelotNFT(_nftAddress);
        IERC721 nftDELOT721 = IERC721(_nftAddress);
        uint256 amountOfTokenPerNFT = IERC20(_tokenAddress).balanceOf(address(this)) / nftDELOT.totalSupply();

        //
        IERC20 token = IERC20(_tokenAddress);
        uint256 indexHolders = nftDELOT.numberOfHolders();
        
        address addr;
        uint256 amount;
        
        while (indexHolders > 0) {
            --indexHolders;

            addr = nftDELOT.getHolderAt(indexHolders);
            amount = nftDELOT721.balanceOf(addr) * amountOfTokenPerNFT;
            
            token.transfer(addr, amount);
            emit Rewarded(addr, amount);
        }
    }
}