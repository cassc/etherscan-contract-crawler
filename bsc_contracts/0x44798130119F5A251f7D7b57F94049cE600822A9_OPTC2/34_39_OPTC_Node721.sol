// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract OPTCNode721 is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint public currentId = 1;
    address public superMinter;
    mapping(address => uint) public minters;
    mapping(uint => uint) public cid;
    uint public totalNode;
    uint public perCost = 100 ether;

    struct TokenInfo {
        uint weight;
        uint totalCost;
    }

    mapping(uint => TokenInfo) public tokenInfo;
    constructor() ERC721('TEST OPTC Node', 'TEST OPTCNode') {
        myBaseURI = "https://ipfs.io/ipfs";

    }

    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }


    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function mint(address player, uint cid_, uint cost) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        require(cid_ == 1 || cid_ == 2, 'wrong cid');
        cid[currentId] = cid_;

        uint nodeAdd = 0;
        if (cid_ == 2) {
            tokenInfo[currentId].totalCost = cost;
            nodeAdd = cost / perCost;
        } else if (cid_ == 1) {
            nodeAdd = 1;
        }
        tokenInfo[currentId].weight = nodeAdd;
        totalNode += nodeAdd;
        _mint(player, currentId);
        currentId ++;
    }

    function updateTokenCost(uint tokenId, uint cost) external {
        require(msg.sender == superMinter, 'not minter');
        require(cid[tokenId] == 2, 'wrong  cid');
        uint upgrade = cost / perCost;
        tokenInfo[tokenId].weight += upgrade;
        totalNode += upgrade;
    }

    function getCardWeight(uint tokenId) external view returns (uint){
        return tokenInfo[tokenId].weight;
    }

    function getCardTotalCost(uint tokenId) external view returns (uint){
        return tokenInfo[tokenId].totalCost;
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

    function checkUserCidList(address player, uint cid_) external view returns (uint[] memory){
        uint tempBalance = balanceOf(player);

        uint token;
        uint amount;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if (cid[token] == cid_) {
                amount ++;
            }
        }
        uint[] memory list = new uint[](amount);
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if (cid[token] == cid_) {
                amount --;
                list[amount] = token;
            }
        }
        return list;
    }

    function checkUserAllWeight(address player) public view returns (uint){
        uint tempBalance = balanceOf(player);
        uint token;
        uint res;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            res += tokenInfo[token].weight;
        }
        return res;
    }


    function setBaseUri(string memory uri) public onlyOwner {
        myBaseURI = uri;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        if (cid[tokenId_] == 1) {
            return string(abi.encodePacked(myBaseURI, '/', 'QmRqAHPigaZWcZNwJcqNWw8YLB1fji9p75NAwaxygFmV7P'));
        } else {
            return string(abi.encodePacked(myBaseURI, '/', 'QmTGojb1hnEhRb9M1Vx36LYWFqvPwgn44wDRMPVXEwXHX8'));
        }

    }

    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        return true;
    }

}