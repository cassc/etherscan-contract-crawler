// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract OPTCMining721 is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint public currentId = 1;
    address public superMinter;
    mapping(address => uint) public minters;

    struct MiningInfo {
        uint times;
        uint value;
        uint power;
    }

    mapping(uint => MiningInfo) public tokenInfo;
    constructor() ERC721('TEST OPTC Mining', 'TEST OPTCMining') {
        myBaseURI = "https://ipfs.io/ipfs/QmWAk4o4hy7cT1VAWScdGXrTnFbh9tPosd6Pc6UMZVpxxM";

    }



    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }


    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function mint(address player, uint times, uint value) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        tokenInfo[currentId].value = value;
        tokenInfo[currentId].times = times;
        tokenInfo[currentId].power = value * times;
        _mint(player, currentId);
        currentId ++;
    }

    function changePower(uint tokenId, uint power) external {
        require(msg.sender == superMinter, 'not minter');
        require(tokenInfo[tokenId].power >= power, 'wrong power');
        tokenInfo[tokenId].power = power;
    }

    function checkUserTokenList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = token;
        }
        return list;
    }

    function checkCardPower(uint tokenId) public view returns(uint){
        return tokenInfo[tokenId].power;
    }


    function setBaseUri(string memory uri) public onlyOwner {
        myBaseURI = uri;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI));
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        return true;
    }

}