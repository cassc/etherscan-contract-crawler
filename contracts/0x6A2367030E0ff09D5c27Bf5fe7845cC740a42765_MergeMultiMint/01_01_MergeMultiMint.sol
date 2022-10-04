// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMergeMint {
    function publicMint(uint256 _mintAmount) payable external;
    function totalSupply() external view returns (uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract MergeMultiMint {
    address constant sougen = address(0x08549931C9766c7d7ae59d98Cc08EE133Fe3DB12);
    function batchMint(uint256 times) public payable{
        require(times * 0.15 ether == msg.value, "ETH value error");
        for(uint i = 0; i < times; ++i){
            (new Minter){value: 0.15 ether }(sougen);
        }
    }
}

contract Minter{
    constructor(address sougen) payable{
        IMergeMint(sougen).publicMint{value: 0.15 ether}(5);
        uint256 supply = IMergeMint(sougen).totalSupply();
        IERC721(sougen).transferFrom(address(this), msg.sender, supply-4);
        IERC721(sougen).transferFrom(address(this), msg.sender, supply-3);
        IERC721(sougen).transferFrom(address(this), msg.sender, supply-2);
        IERC721(sougen).transferFrom(address(this), msg.sender, supply-1);
        IERC721(sougen).transferFrom(address(this), msg.sender, supply);
        selfdestruct(payable(address(msg.sender)));
    }
}