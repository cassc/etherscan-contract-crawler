// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Opepepepen NFT Collection
/// @author Bitduke
/// @notice ERC721 NFT collection

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Opepepepen is ERC721A, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    string public contractURI;
    string public baseURI;

    uint256 public constant COST = 0.000777 ether;

    string private _defTokenURI = "https://ipfs.io/ipfs/QmcQsKhpdQX3RTmfSCe3cECaPqUKuPFm3tNemKoGnokM9b";
    string private _defTokenURI1 = "https://ipfs.io/ipfs/QmWvY2m4v15qo8ht7C8dJ96ZGn5iYR1ahzeA5FxaMtWaVE";
    string private _baseTokenURI = "";

    mapping(address => bool) private _hasMinted;

    event NewMint(address indexed msgSender, uint256 indexed mintQuantity);
    event ContractURIChanged(address sender, string newContractURI);

    constructor(
        string memory name, 
        string memory symbol
    ) ERC721A(name, symbol) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A)
    returns (bool) {
      return super.supportsInterface(interfaceId);
    }

    function transferOut(address _to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function changeDefURI(string calldata _tokenURI) external onlyOwner {
        _defTokenURI = _tokenURI;
    }

    function changeURI(string calldata _tokenURI) external onlyOwner {
        _baseTokenURI = _tokenURI;
    }

    /// @notice Update contractURI/NFT metadata
    /// @param _newContractURI New collection metadata
    function setContractURI(string calldata _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
        emit ContractURIChanged(msg.sender, _newContractURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function _defURI() internal view virtual returns (string memory) {
        return _defTokenURI;
    }

    function preudoBinaryRandom() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.prevrandao,  
        msg.sender))) % 2;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 _flag = preudoBinaryRandom();
        if (_flag == 0) {
            return _defTokenURI;
        } else {
            return _defTokenURI1;
        }
    }


    function mint(uint256 quantity) public payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "ERC721: Exceeds maximum supply");
        require(quantity <= 13, "ERC721: Maximum is 13 per mint");

        _safeMint(msg.sender, quantity);
        emit NewMint(msg.sender, quantity);
    }

}