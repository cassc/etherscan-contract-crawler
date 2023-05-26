pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StringLibrary.sol";

contract IlluviumIDOCollection is ERC1155, Ownable {
    using StringLibrary for string;

    string public constant name = "Illuvium IDO Collection";
    string public constant symbol = "ILV-NFT";
    string private _uriPrefix;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public tokenSupply;

    constructor(string memory newURI) ERC1155(newURI) {
        _uriPrefix = newURI;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory newURI
    ) external onlyOwner {
        _mint(account, id, amount, data);
        _tokenURIs[id] = newURI;
        tokenSupply[id] += amount;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return _tokenURI(_id);
    }

    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function _tokenURI(uint256 id) private view returns (string memory) {
        return _uriPrefix.append(_tokenURIs[id]);
    }

    function setTokenURI(uint256 id, string memory newURI) external onlyOwner {
        _tokenURIs[id] = newURI;
    }

    function setURI(string memory newURI) external onlyOwner {
        _uriPrefix = newURI;
    }
}