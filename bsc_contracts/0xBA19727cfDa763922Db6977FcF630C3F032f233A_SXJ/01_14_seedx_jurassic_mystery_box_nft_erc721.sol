// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MinterRole is Ownable {
    EnumerableSet.AddressSet private _minters;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    constructor() {
        addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(
            isMinter(_msgSender()),
            "MinterRole: caller does not have the Minter role"
        );
        _;
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function getMinter(uint256 _index) public view returns (address) {
        require(
            _index <= getMinterLength() - 1,
            "getMinter: index out of bounds"
        );
        return EnumerableSet.at(_minters, _index);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function addMinter(address account) public onlyOwner returns (bool) {
        require(
            account != address(0),
            "addMinter: account is the zero address"
        );
        emit MinterAdded(account);
        return EnumerableSet.add(_minters, account);
    }

    function removeMinter(address account) public onlyOwner returns (bool) {
        require(isMinter(account), "removeMinter: account not be listed");
        emit MinterRemoved(account);
        return EnumerableSet.remove(_minters, account);
    }
}


//## SeedX_Jurassic_Mystery_Box_NFT_ERC721
contract SXJ is ERC721Enumerable, MinterRole {

    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function transferFromBatch(address from, address to, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            transferFrom(from, to, tokenIds[i]);
        }
    }

    function transferFromBatchMulti(address from, address[] memory tos, uint256[] memory tokenIds) public {
        require(tos.length > 0 && tos.length == tokenIds.length, "param error");
        for (uint256 i = 0; i < tos.length; i++) {
            transferFrom(from, tos[i], tokenIds[i]);
        }
    }

    function safeTransferFromBatch(address from, address to, uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(from, to, tokenIds[i]);
        }
    }

    function safeTransferFromBatchMulti(address from, address[] memory tos, uint256[] memory tokenIds) public {
        require(tos.length > 0 && tos.length == tokenIds.length, "param error");
        for (uint256 i = 0; i < tos.length; i++) {
            safeTransferFrom(from, tos[i], tokenIds[i]);
        }
    }

    function mint(address to, uint256 tokenId) public onlyMinter {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId, bytes memory data) public onlyMinter {
        _safeMint(to, tokenId, data);
    }

    function safeMintBatch(
        address to,
        uint256[] memory tokenIds,
        bytes memory data
    ) public onlyMinter {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i], data);
        }
    }

    function burn(address to, uint256 tokenId) public {
        require(
            to == _msgSender() || isApprovedForAll(to, _msgSender()) || getApproved(tokenId) == _msgSender(),
            "ERC721: caller is not token owner nor approved"
        );
        _burn(tokenId);
    }


    function burnBatch(
        address to,
        uint256[] memory tokenIds
    ) public {
        require(
            to == _msgSender() || isApprovedForAll(to, _msgSender()),
            "ERC721: caller is not token owner nor approved"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(getApproved(tokenIds[i]) == _msgSender());
            _burn(tokenIds[i]);
        }
    }


    function setURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

}