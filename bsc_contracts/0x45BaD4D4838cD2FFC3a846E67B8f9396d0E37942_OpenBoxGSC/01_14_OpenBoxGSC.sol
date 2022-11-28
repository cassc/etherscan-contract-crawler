// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IERC721 {
    function totalSupply() external returns(uint256);
    function currentTokenId() external view returns(uint256);
    function mint(address _to, uint256 _tokenId, string memory _hashs) external;
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint _tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract OpenBoxGSC is Ownable {
    ERC1155Burnable public immutable box;
    address public immutable items721;
    mapping(uint => bool) public nonces;
    mapping(address => mapping(uint => bool)) public isOpen; // user => tokenid

    mapping(uint => string[]) public itemsFlag; // group => flags

    constructor(ERC1155Burnable _box, address _items721) {
        box = _box;
        items721 = _items721;
    }
    function setItemsFlag(uint index, string[] memory itemHash) external onlyOwner {
        itemsFlag[index] = itemHash;
    }
    function random(uint nonce, uint percentDecimal) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce)))%percentDecimal;
    }
    function randomHash(uint group, uint nonce, uint tokenId) internal {
        uint resultNumber = random(++nonce, 100);
        IERC721(items721).mint(_msgSender(), tokenId, itemsFlag[group][resultNumber]);
    }
    function handleOpen(uint nonce, uint tokenId, uint boxId) internal {
        uint resultNumber = random(nonce, 100);
        nonces[nonce] = true;
        if(boxId == 2) {
            if(resultNumber < 8) randomHash(4, nonce, tokenId);
            else if(resultNumber >= 8 && resultNumber < 47) randomHash(5, nonce, tokenId);
            else if(resultNumber >= 47 && resultNumber < 81) randomHash(6, nonce, tokenId);
            else randomHash(7, nonce, tokenId);
        }
        else if(boxId == 3) {
            if(resultNumber < 3) randomHash(4, nonce, tokenId);
            else if(resultNumber >= 3 && resultNumber < 23) randomHash(5, nonce, tokenId);
            else if(resultNumber >= 23 && resultNumber < 60) randomHash(6, nonce, tokenId);
            else randomHash(7, nonce, tokenId);
        }
        else {
            if(resultNumber < 5) randomHash(5, nonce, tokenId);
            else if(resultNumber >= 5 && resultNumber < 18) randomHash(6, nonce, tokenId);
            else randomHash(7, nonce, tokenId);
        }

    }
    function handleOpen1(uint nonce, uint tokenId, uint boxId) internal {
        uint resultNumber = random(nonce, 100);
        nonces[nonce] = true;
        if(boxId == 2) {
            if(resultNumber < 8) randomHash(0, nonce, tokenId);
            else if(resultNumber >= 8 && resultNumber < 47) randomHash(1, nonce, tokenId);
            else if(resultNumber >= 47 && resultNumber < 81) randomHash(2, nonce, tokenId);
            else randomHash(3, nonce, tokenId);
        }
        else if(boxId == 3) {
            if(resultNumber < 3) randomHash(0, nonce, tokenId);
            else if(resultNumber >= 3 && resultNumber < 23) randomHash(1, nonce, tokenId);
            else if(resultNumber >= 23 && resultNumber < 60) randomHash(2, nonce, tokenId);
            else randomHash(3, nonce, tokenId);
        }
        else {
            if(resultNumber < 5) randomHash(1, nonce, tokenId);
            else if(resultNumber >= 5 && resultNumber < 18) randomHash(2, nonce, tokenId);
            else randomHash(3, nonce, tokenId);
        }
        isOpen[_msgSender()][boxId] = true;
    }
    function open(uint nonce, uint[] memory tokenIds, uint[] memory amounts) public {
        require(!nonces[nonce], "OpenBox::open: nonce used");
        require(tokenIds.length == 1 && amounts.length == 1 && (tokenIds[0] == 2 || tokenIds[0] == 3 || tokenIds[0] == 4), "OpenBox::open: invalid token ids");
        uint balanceOf = box.balanceOf(_msgSender(), tokenIds[0]);
        require(amounts[0] > 0 && amounts[0] <= 100 && amounts[0] <= balanceOf, "OpenBox::open: amount invalid");
        box.burnBatch(_msgSender(), tokenIds, amounts);
        uint tokenId = IERC721(items721).currentTokenId();
        for(uint i = 0; i < amounts[0]; i++) {
            if(!isOpen[_msgSender()][tokenIds[0]]) handleOpen1(nonce+i, tokenId+1+i, tokenIds[0]);
            else {
                uint resultNumber = random(nonce+i+500, 100);
                if(resultNumber < 50) handleOpen1(nonce+i, tokenId+1+i, tokenIds[0]);
                else handleOpen(nonce+i, tokenId+1+i, tokenIds[0]);
            }
        }

    }

    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}