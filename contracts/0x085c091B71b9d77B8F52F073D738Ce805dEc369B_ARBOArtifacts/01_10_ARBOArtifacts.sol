pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ARBOArtifacts is ERC1155, Ownable { 
    string public name;
    string public symbol;

    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) public ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }


    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(to, id, amount, data);
    }

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _burn(from, id, amount);
    }

    function batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner {
        _burnBatch(from, ids, amounts);
    }
}