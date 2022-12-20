// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MinterRole is Ownable {
    mapping(address => uint256) public _mintersMap;
    uint256 private minterLength;

    event SetMinterLimit(address indexed account, uint256 indexed mintNum);

    constructor() {
        setMinterLimit(_msgSender(), 1000000000);
    }

    modifier onlyMinter(uint256 num) {
        require(
            hasEnoughMint(_msgSender(), num),
            "MinterRole: caller mintLimit does not enough"
        );
        _;
    }

    function getMinterLength() public view returns (uint256) {
        return minterLength;
    }


    function hasEnoughMint(address account, uint num) public view returns (bool) {
        if (_mintersMap[account] >= num) {
            return true;
        }
        return false;
    }

    function setMinterLimit(address account, uint mintNumLimit) public onlyOwner {
        require(
            account != address(0),
            "setMinterLimit: account is the zero address"
        );
        if (mintNumLimit > 0 && _mintersMap[account] == 0) {
            minterLength++;
        } else if (mintNumLimit == 0 && _mintersMap[account] > 0) {
            minterLength--;
        }
        _mintersMap[account] = mintNumLimit;
        emit SetMinterLimit(account, mintNumLimit);
    }

    function _reduceMintNum(uint mintNumLimit) internal {
        _mintersMap[_msgSender()] -= mintNumLimit;
        if (_mintersMap[_msgSender()] == 0) {
            minterLength--;
        }
    }
}


//## SmartClubNFT721
contract SmartClubNFT721 is ERC721Enumerable, MinterRole {

    string private _baseTokenURI;
    uint256 public nextFreeTokenId = 1;

    mapping(address => uint256) public mintRecord;

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

    function freeMint() public {
        require(mintRecord[_msgSender()] == 0,"The address has already mint it");
        mintRecord[_msgSender()] = nextFreeTokenId;
        _mint(_msgSender(), nextFreeTokenId);
        nextFreeTokenId++;
    }



    function mint(address to, uint256 tokenId) public onlyMinter(1) {
        _mint(to, tokenId);
        _reduceMintNum(1);
    }

    function safeMint(address to, uint256 tokenId, bytes memory data) public onlyMinter(1) {
        _safeMint(to, tokenId, data);
        _reduceMintNum(1);
    }

    function safeMintBatch(
        address to,
        uint256[] memory tokenIds,
        bytes memory data
    ) public onlyMinter(tokenIds.length) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i], data);
        }
        _reduceMintNum(tokenIds.length);
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