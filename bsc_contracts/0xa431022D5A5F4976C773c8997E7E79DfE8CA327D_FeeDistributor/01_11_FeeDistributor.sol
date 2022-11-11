// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeDistributor is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;


    mapping(address => bool) public stopDividend;


    address public usdt;
    address public blueDogNft;
    address public redDogNft;
    mapping(address => uint) public userToTotalDividendUSDT;
    constructor(address usdt_, address blueDogNft_, address redDogNft_){
        usdt = usdt_;
        blueDogNft = blueDogNft_;
        redDogNft = redDogNft_;

    }

    event DividendForBlueDogHolders(uint totalSupplyBlueDogNFT,uint amountForBuleDogNft);
    event DividendForRedDogHolders(uint totalSupplyBlueDogNFT,uint amountForBuleDogNft);

    function setStopDividend(address addr_,bool stop) external onlyOwner{
            stopDividend[addr_] = stop;
    }

    function distribute() external nonReentrant {
        uint usdtBlanceHalf = IERC20(usdt).balanceOf(address(this)) / 2;
        if(usdtBlanceHalf == 0){
            return;
        }
        _dividendForBlueDogHolders(usdtBlanceHalf);
        _dividendForRedDogHolders(usdtBlanceHalf);
    }



    function _dividendForBlueDogHolders(uint usdtBlanceHalf) private {

        uint totalSupplyBlueDogNFT = IERC721Enumerable(blueDogNft).totalSupply();
        uint amountForBuleDogNft = usdtBlanceHalf / totalSupplyBlueDogNFT;

        emit DividendForBlueDogHolders(totalSupplyBlueDogNFT,amountForBuleDogNft);


        for (uint i; i < totalSupplyBlueDogNFT; i++) {
            uint buleDogNftId = IERC721Enumerable(blueDogNft).tokenByIndex(i);
            address buleDogNftHolder = IERC721Enumerable(blueDogNft).ownerOf(buleDogNftId);


            if(!stopDividend[buleDogNftHolder]){
                if (i == totalSupplyBlueDogNFT - 1) {

                    uint laseBodyToDividend = usdtBlanceHalf - ((totalSupplyBlueDogNFT - 1) * amountForBuleDogNft);
                    IERC20(usdt).safeTransfer(buleDogNftHolder, laseBodyToDividend);
                    userToTotalDividendUSDT[buleDogNftHolder] += laseBodyToDividend;
                } else {
                    IERC20(usdt).safeTransfer(buleDogNftHolder, amountForBuleDogNft);
                    userToTotalDividendUSDT[buleDogNftHolder] += amountForBuleDogNft;
                }
            }


        }

    }


    function _dividendForRedDogHolders(uint usdtBlanceHalf) private {

        uint totalSupplyRedDogNFT = IERC721Enumerable(redDogNft).totalSupply();

        uint amountForRedDogNft = usdtBlanceHalf / totalSupplyRedDogNFT;

        emit DividendForRedDogHolders(totalSupplyRedDogNFT,amountForRedDogNft);

        for (uint i; i < totalSupplyRedDogNFT; i++) {
            uint redDogNftId = IERC721Enumerable(redDogNft).tokenByIndex(i);
            address redDogNftHolder = IERC721Enumerable(redDogNft).ownerOf(redDogNftId);

            if(!stopDividend[redDogNftHolder]){
                if (i == totalSupplyRedDogNFT - 1) {
                    uint laseBodyToDividend = usdtBlanceHalf - ((totalSupplyRedDogNFT - 1) * amountForRedDogNft);
                    IERC20(usdt).safeTransfer(redDogNftHolder, laseBodyToDividend);
                    userToTotalDividendUSDT[redDogNftHolder] += laseBodyToDividend;
                } else {
                    IERC20(usdt).safeTransfer(redDogNftHolder, amountForRedDogNft);
                    userToTotalDividendUSDT[redDogNftHolder] += amountForRedDogNft;
                }
            }

        }
    }

    function claim(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        if(address(this).balance >0){
            payable(msg.sender).transfer(address(this).balance);
        }
    }


}