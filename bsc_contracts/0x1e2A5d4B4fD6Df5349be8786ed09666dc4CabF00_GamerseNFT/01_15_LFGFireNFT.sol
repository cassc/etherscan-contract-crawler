//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILFGFireNFT.sol";

contract GamerseNFT is ILFGFireNFT, ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Base Token URI
    string public baseURI;

    // MAX supply of collection
    uint256 public constant MAX_SUPPLY = 10000;

    // minters
    mapping(address => bool) public minters;

    modifier onlyMinter() {
        require(minters[msg.sender], "NFT: Invalid minter");
        _;
    }

    constructor(address _owner) ERC721("GamerseNFT", "GamerseNFT") {
        require(_owner != address(0), "Invalid owner address");
        _transferOwnership(_owner);
    }

    /**************************
     ***** MINT FUNCTIONS *****
     *************************/
    function mint(uint256 _qty, address _to) external override onlyMinter {
        require(totalSupply() + _qty <= MAX_SUPPLY, "NFT: out of stock");
        require(_to != address(0), "NFT: invalid address");

        for (uint256 i = 0; i < _qty; i++) {
            _safeMint(_to, totalSupply() + 1);
        }
    }

    function multiMint(address[] calldata _wallets) external onlyOwner {
        require(_wallets.length > 0, "Input address list is empty");
        require(totalSupply() + _wallets.length <= MAX_SUPPLY, "NFT: max supply reached");

        for (uint256 i = 0; i < _wallets.length; i++) {
            require(_wallets[i] != address(0), "NFT: invalid address");
            _safeMint(_wallets[i], totalSupply() + 1);
        }
    }

    function adminMint(uint256 _qty, address _to) external onlyOwner {
        require(_qty != 0, "NFT: minitum 1 nft");
        require(_to != address(0), "NFT: invalid address");
        require(totalSupply() + _qty <= MAX_SUPPLY, "NFT: max supply reached");

        for (uint256 i = 0; i < _qty; i++) {
            _safeMint(_to, totalSupply() + 1);
        }
    }

    /**************************
     ***** VIEW FUNCTIONS *****
     *************************/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        require(_exists(_id), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _id.toString()))
                : "";
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(_owner);
        uint256[] memory ids = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            ids[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return ids;
    }

    function exists(uint256 _id) external view returns (bool) {
        return _exists(_id);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMinter(address _account, bool _isMinter) external onlyOwner {
        require(_account != address(0), "NFT: invalid address");

        minters[_account] = _isMinter;
    }

    function clearStuckTokens(IERC20 erc20) external onlyOwner {
        uint256 balance = erc20.balanceOf(address(this));
        erc20.transfer(msg.sender, balance);
    }
}