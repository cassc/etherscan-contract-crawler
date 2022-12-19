// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import './interfaces/IMintable.sol';
import './Dividends.sol';

contract ERC1155DividendableUpgradeable is 
    IMintable,
    Dividends,
    ERC1155Upgradeable,
    OwnableUpgradeable 
{

    uint8 private constant _version = 3;

    mapping(uint256 => uint256) private _tokensSupply;

    string private _name;
    string private _symbol;

    function __ERC1155Dividendable_init(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address paymentToken
    ) external initializer {
        __Ownable_init_unchained();
        __ERC1155Dividendable_init_unchained(
            name_,
            symbol_,
            baseURI_,
            paymentToken
        );
    }

    function __ERC1155Dividendable_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address paymentToken
    ) public initializer {
        _name = name_;
        _symbol = symbol_;
        __ERC1155_init_unchained(baseURI_);
        _setPaymentToken(paymentToken);
    }

    function mint(
        address owner,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _mint(owner, id, amount);
    }

    function _mint(
        address owner,
        uint256 id,
        uint256 amount
    ) private {
        _beforeTokenMint(id, amount);
        _mint(owner, id, amount, '');
    }

    function mintBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _mintBatch(owner, ids, amounts);
    }

    function _mintBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) private {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length;) {
            _beforeTokenMint(ids[i], amounts[i]);
            unchecked {
                i++;
            }
        }
        _mintBatch(owner, ids, amounts, '');
    }

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    function setPaymentToken(address paymentToken) external onlyOwner {
        _setPaymentToken(paymentToken);
    }

    function _beforeTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) internal override(ERC1155Upgradeable){
        _beforeTokenTransfer(from, to, ids);
    } 

    function isExists(uint256 id) public override view returns (bool) {
        return _tokensSupply[id] != 0;
    }

    function supportsInterface(bytes4 interfaceId) public
    view override(ERC1155Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenSupply(uint256 id) public view override returns (uint256) {
        return _tokensSupply[id];
    }

    function balanceOf(
        address owner,
        uint256 id
    ) public view override(Dividends, ERC1155Upgradeable) returns (uint256) {
        return ERC1155Upgradeable.balanceOf(owner, id);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(
            abi.encodePacked(
                ERC1155Upgradeable.uri(0),
                StringsUpgradeable.toString(tokenId)
            )
        );
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function version() external pure returns (uint8) {
        return _version;
    }

    function withdrawByAdmin(address payable _destination) external onlyOwner {
        (bool success,) = _destination.call{value : address(this).balance}('');
        require(success, 'ERC1155Dividendable: failed to send money');
    }

    function _setTokenSupply(uint256 id, uint256 amount) private {
        _tokensSupply[id] = amount;
    }
    
    function _beforeTokenMint(
        uint256 id,
        uint256 amount
    ) private {
        require(isExists(id) == false, 'ERC1155Dividendable: you cannot add new parts');
        _setTokenSupply(id, amount);
    }
    
    uint256[200] private __gap;
}