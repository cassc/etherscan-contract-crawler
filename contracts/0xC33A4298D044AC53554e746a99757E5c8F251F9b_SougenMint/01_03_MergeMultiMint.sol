// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMergeMint {
    function publicMint(uint256 _mintAmount) payable external;
    function totalSupply() external view returns (uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract SougenMint is Ownable {
    address constant sougen = address(0x08549931C9766c7d7ae59d98Cc08EE133Fe3DB12); // mainnet
    
    function batchMint(uint256 times) external payable{
        require(times * 0.15 ether <= msg.value, "ETH isn't enough");
        for(uint i = 0; i < times; ++i){
            (new Minter){value: 0.15 ether }(sougen);
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address token, uint256 id) external onlyOwner {
        IERC721(token).transferFrom(address(this), msg.sender, id);
    }
}

contract Minter{
    constructor(address sougen) payable{
        IMergeMint(sougen).publicMint{value: 0.15 ether}(5);
        uint256 supply = IMergeMint(sougen).totalSupply();
        IERC721(sougen).transferFrom(address(this), tx.origin, supply-4);
        IERC721(sougen).transferFrom(address(this), tx.origin, supply-3);
        IERC721(sougen).transferFrom(address(this), tx.origin, supply-2);
        IERC721(sougen).transferFrom(address(this), tx.origin, supply-1);
        IERC721(sougen).transferFrom(address(this), tx.origin, supply);
        selfdestruct(payable(address(tx.origin)));
    }
}