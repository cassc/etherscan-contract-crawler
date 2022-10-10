// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';

contract LZ_DIAMOND_1 is ERC1155, Ownable, Pausable, ERC1155Supply, ERC1155Burnable, ReentrancyGuard {
    struct Special {
        string name;
        uint256 num;
    }

    uint256 public constant DIA = 0;
    uint256 public maxSupply;
    string private _name;
    string private _symbol;
    uint256 private _publicPrice;

    // Mapping for the combination if used
    mapping(string => bool) private _merged;
    mapping(uint256 => bool) private _t_merged;

    // Mapping for the special objects's nums
    mapping(string => uint256) private _special;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 publicPrice_,
        Special[] memory special,
        string memory uri_
    ) ERC1155(uri_) {
        _name = name_;
        _symbol = symbol_;
        maxSupply = maxSupply_;
        _publicPrice = publicPrice_;
        initSpecial(special);
    }

    function initSpecial(Special[] memory special) private {
        for (uint256 i = 0; i < special.length; i++) {
            _special[special[i].name] = special[i].num;
        }
    }

    function merge(
        string memory curStr,
        uint256 tnum,
        string[] memory specials
    ) external whenNotPaused {
        require(balanceOf(msg.sender, DIA) > 0, 'balance must bigger than 0');
        require(!_merged[curStr], 'images you choosed was merged');
        require(!_t_merged[tnum], 'your the three gates image was merged');
        for (uint256 i = 0; i < specials.length; i++) {
            require(_special[specials[i]] > 0, 'one of images is out of use');
        }
        _merged[curStr] = true;
        _t_merged[tnum] = true;
        for (uint256 i = 0; i < specials.length; i++) {
            _special[specials[i]] -= 1;
        }
        burn(msg.sender, DIA, 1);
    }

    function getNums(string[] memory specials) external view whenNotPaused returns (Special[] memory) {
        Special[] memory list = new Special[](specials.length);
        for (uint256 i = 0; i < specials.length; i++) {
            list[i] = Special(specials[i], _special[specials[i]]);
        }
        return list;
    }

    function airDrop(address[] memory addrs, uint256 amount) external onlyOwner {
        require(totalSupply(DIA) + addrs.length * amount <= maxSupply, 'exceeded max supply');
        for (uint256 i = 0; i < addrs.length; i++) {
            _mint(addrs[i], DIA, amount, '');
        }
    }

    function mint(address to) external payable whenNotPaused {
        require(balanceOf(to, DIA) < 1, 'address can not mint more than 1 times');
        require(totalSupply(DIA) <= maxSupply, 'exceeded max supply');
        require(msg.value == _publicPrice, 'cost incorrect');
        _mint(to, DIA, 1, '');
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setPublicPrice(uint256 price) public onlyOwner {
        _publicPrice = price;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function check(uint256 tnum) public view returns (bool) {
        return _t_merged[tnum];
    }

    function checkMerged(string memory curStr) public view returns (bool) {
        return _merged[curStr];
    }

    function selfMint(
        address account,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, DIA, amount, data);
    }

    function selfMintBatch(
        address to,
        uint256 _amounts,
        bytes memory data
    ) public onlyOwner {
        uint256[] memory ids;
        uint256[] memory amounts;
        ids[0] = DIA;
        amounts[0] = _amounts;
        _mintBatch(to, ids, amounts, data);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}