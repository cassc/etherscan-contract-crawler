// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract NFIV is ERC1155, ERC1155Supply, Ownable {
    using Strings for uint256;

    address safe = 0xdD768c3fE658c5949107E7E047e14467EEca745B;

    constructor() ERC1155("") {
        _mint(address(this), 0, 70, "");
        _mint(safe, 0, 5, "");
        _mint(safe, 1, 175, "");
    }

    string public name = "NFIV";
    string baseURI = "https://bafybeibtqhkunzygzv6cnhq3ii64c5w4blmfndllrubxkmfmsuvxoywede.ipfs.nftstorage.link/";
    string baseExtension = ".json";

    mapping(address=>uint256) public totalPurchased;
    mapping(address=>bool) public whitelisted;
    uint256 public totalSold;

    function uri(uint256 id) override public view returns (string memory) {
        return string(
            abi.encodePacked(baseURI, id.toString(), baseExtension)
        );
    }

    function whitelist(address _user, bool _whitelisted) public onlyOwner {
        whitelisted[_user] = _whitelisted;
    }

    function whitelistBatch(address[] memory _users, bool _whitelisted) public onlyOwner {
        for (uint i=0; i < _users.length; i++) {
            whitelisted[_users[i]] = _whitelisted;
        }
    }

    function buy(uint256 _total) public payable {
        require(whitelisted[msg.sender], "Not whitelisted");
        require(totalSold + _total <= 70, "Max cap reached");
        require(msg.value == 3.5 ether * _total, "Invalid value");

        totalPurchased[msg.sender] += _total;
        totalSold += _total;

        (bool sent,) = safe.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _safeTransferFrom(address(this), msg.sender, 0, _total, "");
    }

    function recoverTokens(uint256 _amount, uint256 _tokenID, address _to) public onlyOwner {
        _safeTransferFrom(address(this), _to, _tokenID, _amount, "");
    }

    function recoverETH(uint256 _amount, address _to) public onlyOwner {
        payable(_to).transfer(_amount);
    }

    function recoverETHToContract(uint256 _amount, address _to) public onlyOwner {
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function updateUri(string memory _baseURI, string memory _baseExtension) public onlyOwner {
        baseURI = _baseURI;
        baseExtension = _baseExtension;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}