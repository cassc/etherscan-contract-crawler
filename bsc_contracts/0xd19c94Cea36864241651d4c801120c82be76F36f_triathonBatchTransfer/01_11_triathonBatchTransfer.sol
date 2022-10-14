// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract triathonBatchTransfer{
    address public geon;
    address public trias;
    address public part;
    address public hull;
    address public ship;

    constructor(address geonAddress,address triasAddress,address partAddress,address hullAddress,address shipAddress){
        geon = geonAddress;
        trias = triasAddress;
        part = partAddress;
        hull = hullAddress;
        ship  = shipAddress;
    }

    function triasBatchTransfer(address[] memory to,uint256[] memory amounts) external {
        require(to.length == amounts.length,"different length");
        for(uint256 i=0;i<to.length;i++){
            IERC20(trias).transferFrom(msg.sender, to[i], amounts[i] * 1 ether);
        }
    }

    function geonBatchTransfer(address[] memory to,uint256[] memory amounts) external {
        require(to.length == amounts.length,"different length");
        for(uint256 i=0;i<to.length;i++){
            IERC20(geon).transferFrom(msg.sender, to[i], amounts[i] * 1 ether);
        }
    }

    function partsTransfer(address[] memory to,uint256[] memory ids,uint256[] memory amounts) external {
        require(to.length == amounts.length && ids.length == amounts.length,"different length");

        for(uint256 i=0;i<to.length;i++){
            IERC1155(part).safeTransferFrom(msg.sender,to[i],ids[i],amounts[i], "0x");
        }
    }

    function partsBatchTransfer(address[] memory to,uint256[] memory amounts) external {
        require(to.length == amounts.length,"different length");
        uint[] memory ids = new uint[](5);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        ids[3] = 3;
        ids[4] = 4;

        for(uint256 i=0;i<to.length;i++){
            uint[] memory amount = new uint[](5);
            amount[0] = amounts[i];
            amount[1] = amounts[i];
            amount[2] = amounts[i];
            amount[3] = amounts[i];
            amount[4] = amounts[i];
            IERC1155(part).safeBatchTransferFrom(msg.sender,to[i],ids,amount, "0x");
        }
    }

    function partsBatchTransferPro(address[] memory to,uint256[][] memory ids,uint256[][] memory amounts) external {
        require(to.length == amounts.length && amounts.length == ids.length ,"different length");
        for(uint256 i=0;i<to.length;i++){
            require(ids[i].length == amounts[i].length,"length not match");
            IERC1155(part).safeBatchTransferFrom(msg.sender,to[i],ids[i],amounts[i], "0x");
        }
    }

    function hullBatchTransfer(address to,uint256[] memory tokenIds) external {
        for(uint256 i=0;i<tokenIds.length;i++){
            IERC721(hull).safeTransferFrom(msg.sender, to, tokenIds[i]);
        }
    }

    function hullBatchTransferPro(address[] memory to,uint256[][] memory tokenIds) external {
        require(to.length == tokenIds.length,"length not equal");
        for(uint256 i=0;i<to.length;i++){
            for(uint256 j=0;j<tokenIds[i].length;j++){
                IERC721(hull).safeTransferFrom(msg.sender, to[i], tokenIds[i][j]);
            }
        }
    }

    function withDrowHull(address toAddress,uint amount) external {
        uint balance = IERC721(hull).balanceOf(msg.sender);
        require(balance>=amount,"not enough");
        uint tokenId = IERC721Enumerable(hull).tokenOfOwnerByIndex(msg.sender, 0);
        for(uint256 i=0;i<amount;i++){
            IERC721(hull).safeTransferFrom(msg.sender, toAddress, tokenId);
        }
    }

    function shipBatchTransfer(address to,uint256[] memory tokenIds) external {
        for(uint256 i=0;i<tokenIds.length;i++){
            IERC721(ship).safeTransferFrom(msg.sender, to, tokenIds[i]);
        }
    }

    function shipBatchTransferPro(address[] memory to,uint256[][] memory tokenIds) external {
        require(to.length == tokenIds.length,"length not equal");
        for(uint256 i=0;i<to.length;i++){
            for(uint256 j=0;j<tokenIds[i].length;j++){
                IERC721(ship).safeTransferFrom(msg.sender, to[i], tokenIds[i][j]);
            }
           
        }
    }

    function withDrowShip(address toAddress,uint amount) external {
        uint balance = IERC721(ship).balanceOf(msg.sender);
        require(balance>=amount,"not enough");
        uint tokenId = IERC721Enumerable(ship).tokenOfOwnerByIndex(msg.sender, 0);
        for(uint256 i=0;i<amount;i++){
            IERC721(ship).safeTransferFrom(msg.sender, toAddress, tokenId);
        }
    }    

    function withDrow(address tokenAddress, address toAddress,uint amount) external {
        uint balance = IERC721(tokenAddress).balanceOf(msg.sender);
        require(balance>=amount,"not enough");
        uint tokenId = IERC721Enumerable(tokenAddress).tokenOfOwnerByIndex(msg.sender, 0);
        for(uint256 i=0;i<amount;i++){
            IERC721(tokenAddress).safeTransferFrom(msg.sender, toAddress, tokenId);
        }
    }    
}