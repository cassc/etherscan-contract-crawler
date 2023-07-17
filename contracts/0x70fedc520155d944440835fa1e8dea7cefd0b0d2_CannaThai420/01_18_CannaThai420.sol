// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract CannaThai420 is ERC721Tradable {
    uint256 private _price = 0.42 ether;

    uint256 maxTokens = 120;
    uint256 private TEAM_TOKENS = 21;
    bool public canMint = false;

    address b1 = 0xf556Fb45d16A53c1F2Aa504849e3356Bdafb499A; 

    function userMint(uint256 num) public payable {
        uint256 supply = totalSupply();
        
        require( supply + num <= maxTokens, "Exceed total tokens" );
        require( msg.value >= _price * num, "Not enough Ether" );
        require( canMint, "Not ready" );

        for(uint256 i = 0; i < num; i++){
            _userMint(msg.sender);
        }
        require(payable(b1).send(address(this).balance));
    }

    function setCanMint(bool _canMint) public onlyOwner {
        canMint = _canMint;
    }    

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("CannaThai420", "420TH", _proxyRegistryAddress) {

        for(uint256 i = 0; i < TEAM_TOKENS; i++) 
            mintTo(b1);
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://api.cannathai420.com/api/seed/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.cannathai420.com/contract/seed";
    }
}