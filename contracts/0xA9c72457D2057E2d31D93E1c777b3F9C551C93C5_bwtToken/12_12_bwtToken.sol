// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract bwtToken is ERC1155, Ownable, ERC1155Burnable {
    uint public consentTokenCount;
    address public master;

    constructor() ERC1155("BWT") {
        consentTokenCount = 0;
        master = 0x92d7e0cA1147800321A5949DC1617cc936714E12;
        //debi-Enterprise Account
    }

    mapping(uint256 => uint) public consentTokenIndex; //  public
    mapping(address => consentToken[]) public consentTokensList;

    //mapping(uint => Token) public tokens;

    struct consentToken {
        address account;
        uint256 id; // auto increment
        bytes data;
    }

    function mintConsentToken(
        address account,
        bytes memory data,
        string memory newuri
    ) public onlyOwner {
        require(account != address(0), "mint to zero address");
        uint256 id = consentTokenCount++;
        consentTokensList[account].push(consentToken(account, id, data));
        uint index = consentTokensList[account].length - 1;
        consentTokenIndex[id] = index;
        _mint(account, id, 1, data);
        _setURI(newuri);
    }

    function consentTokens(
        address account
    ) public view returns (consentToken[] memory) {
        return consentTokensList[account];
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override onlyOwner {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override onlyOwner {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal view override {
        require(
                from == address(0) ||
                to == address(0) ||
                from == master ||
                to == master,
                "BioWallet Token (BWT) is not transferable"
        );
    }
}

//  npx hardhat run scripts/deploy.js --network sepolia
//  npx hardhat compile   
//  npx hardhat run scripts/deploy.js --network sepolia
//  npm install dovenv