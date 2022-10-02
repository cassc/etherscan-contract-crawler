//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract EicoNft is ERC1155, Ownable, ERC1155Burnable {
    uint256 private s_tokenCounter;
    uint public constant EICO_CONTRIBUTOR_ID = 1;
    string private _name = "EICO Contributor NFT";
    string private _symbol = "EICO";

    //event
    event BatchNftAirDrop(uint amount);

    constructor()
        ERC1155(
            "ipfs://bafkreia4kwaao3xxvo43lwvmjru6f7larb3kxns72l6nh4x4tcif6cp2rq"
        )
    {}

    //mint
    function mint(address to, uint256 amount) public onlyOwner {
        s_tokenCounter = s_tokenCounter + amount;
        _mint(to, EICO_CONTRIBUTOR_ID, amount, "");
    }

    //burn nft
    function burnNFT(address from, uint256 amount) public onlyOwner {
        s_tokenCounter = s_tokenCounter - amount;
        _burn(from, EICO_CONTRIBUTOR_ID, amount);
    }

    //batch airdrop

    function batchAirDrop(address[] memory _recipients) external onlyOwner {
        for (uint i = 0; i < _recipients.length; i++) {
            //this NFT is meant to 1 per holder

            if (
                _recipients[i] != address(0) &&
                balanceOf(_recipients[i], EICO_CONTRIBUTOR_ID) == 0
            ) {
                mint(_recipients[i], 1);
            }
        }
        emit BatchNftAirDrop(_recipients.length);
    }

    //update URI
    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    //get counter
    function getTotalSupply() public view returns (uint256) {
        return s_tokenCounter;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setNameAndSymbol(
        string calldata _newName,
        string calldata _newSymbol
    ) external onlyOwner {
        _name = _newName;
        _symbol = _newSymbol;
    }
}