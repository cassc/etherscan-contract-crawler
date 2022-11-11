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

contract OpenBoxHallowen is Ownable {
    ERC1155Burnable public immutable box;
    address public immutable items721;
    mapping(uint => bool) public nonces;
    mapping(uint => bool) public importRequestId;
    mapping(uint => string[]) public importInfos; // importRequestId => ipfs

    mapping(uint => string[]) public itemsFlag; // group => flags

    constructor(ERC1155Burnable _box, address _items721) {
        box = _box;
        items721 = _items721;
    }
    function getImportInfos(uint _importRequestId) external view returns (string[] memory) {
        return importInfos[_importRequestId];
    }
    function setItemsFlag(uint index, string[] memory itemHash) external onlyOwner {
        itemsFlag[index] = itemHash;
    }
    function random(uint nonce, uint percentDecimal) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce)))%percentDecimal;
    }
    function randomHash(uint group, uint nonce, uint tokenId, bool isImport, uint _importRequestId) internal {
        uint resultNumber = random(++nonce, 100);
        if(!isImport) IERC721(items721).mint(_msgSender(), tokenId, itemsFlag[group][resultNumber]);
        else importInfos[_importRequestId].push(itemsFlag[group][resultNumber]);
    }
    function handleOpen(uint nonce, uint tokenId, bool isImport, uint _importRequestId) internal {
        uint resultNumber = random(nonce, 100);
        nonces[nonce] = true;
        if(resultNumber < 2) randomHash(0, nonce, tokenId, isImport, _importRequestId);
        else if(resultNumber >= 2 && resultNumber < 5) randomHash(1, nonce, tokenId, isImport, _importRequestId);
        else if(resultNumber >= 5 && resultNumber < 30) randomHash(2, nonce, tokenId, isImport, _importRequestId);
        else if(resultNumber >= 30 && resultNumber < 66) randomHash(3, nonce, tokenId, isImport, _importRequestId);
        else randomHash(4, nonce, tokenId, isImport, _importRequestId);

    }
    function open(uint nonce, uint[] memory tokenIds, uint[] memory amounts) public {
        require(!nonces[nonce], "OpenBox::open: nonce used");
        require(tokenIds.length == 1 && amounts.length == 1 && tokenIds[0] == 5, "OpenBox::open: invalid token ids");
        uint balanceOf = box.balanceOf(_msgSender(), tokenIds[0]);
        require(amounts[0] > 0 && amounts[0] <= 100 && amounts[0] <= balanceOf, "OpenBox::open: amount invalid");
        box.burnBatch(_msgSender(), tokenIds, amounts);
        uint tokenId = IERC721(items721).currentTokenId();
        for(uint i = 0; i < amounts[0]; i++) {
            handleOpen(nonce+i, tokenId+1+i, false, 0);
        }

    }

    function openImport(uint nonce, uint[] memory tokenIds, uint[] memory amounts, uint _importRequestId) public {
        require(!nonces[nonce], "OpenBox::open: nonce used");
        require(!importRequestId[_importRequestId], "OpenBox::openImport: importRequestId used");
        uint balanceOf = box.balanceOf(_msgSender(), 1);
        require(amounts[0] > 0 && amounts[0] <= 100 && amounts[0] <= balanceOf, "OpenBox::open: amount invalid");
        box.burnBatch(_msgSender(), tokenIds, amounts);
        uint tokenId = IERC721(items721).currentTokenId();
        for(uint i = 0; i < amounts.length; i++) {
            handleOpen(nonce+random(i, 1000), tokenId+1+i, true, _importRequestId);
        }
        importRequestId[_importRequestId] = true;
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
}