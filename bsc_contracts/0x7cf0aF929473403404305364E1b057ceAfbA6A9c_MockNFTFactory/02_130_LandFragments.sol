// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import '../core/SafeOwnable.sol';

contract LandFragments is ERC721, SafeOwnable {
    using SafeMath for uint;

    event SupportNFTChanged(IERC721 nft, bool available);
    event MinterChanged(address minter, bool available);
    event NewRequiredNum(uint oldNum, uint newNum);
    event Convert(address user, IERC721[] nfts, uint256[] ids, uint256[] newIds);

    address constant public HOLE = 0x000000000000000000000000000000000000dEaD;
    uint constant MAX_SUPPLY = 120000;

    mapping(IERC721 => bool) public supportNFTs;
    mapping(address => bool) public minters;
    uint public requiredNum;

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721(_name, _symbol) {
        requiredNum = 5;
        emit NewRequiredNum(0, 5);
        _setBaseURI(_uri);
        addMinter(address(this));
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _setBaseURI(_uri);
    }

    function addSupportNFT(IERC721 _nft) external onlyOwner {
        require(!supportNFTs[_nft] && address(_nft) != address(0), "already supported");
        supportNFTs[_nft] = true;
        emit SupportNFTChanged(_nft, true);
    }

    function delSupportNFT(IERC721 _nft) external onlyOwner {
        require(supportNFTs[_nft], "not supported");
        supportNFTs[_nft] = false;
        emit SupportNFTChanged(_nft, false);
    }

    function addMinter(address _minter) public onlyOwner {
        require(!minters[_minter] && _minter != address(0), "already minter");
        minters[_minter] = true;
        emit MinterChanged(_minter, true);
    }

    function delMinter(address _minter) public onlyOwner {
        require(minters[_minter], "not minter");
        minters[_minter] = false;
        emit MinterChanged(_minter, false);
    }

    function setRequiredNum(uint _newNum) external onlyOwner {
        require(_newNum > 0, "illegal num");
        emit NewRequiredNum(requiredNum, _newNum);
        requiredNum = _newNum;
    }

    modifier onlyMinter {
        require(minters[msg.sender], "only minter can do this");
        _;
        require(totalSupply() <= MAX_SUPPLY, "out of supply");
    }

    function mint(address _recipient, uint _num) public onlyMinter returns(uint[] memory _ids) {
        uint currentSupply = totalSupply();    
        _ids = new uint[](_num);
        for (uint i = 1; i <= _num; i ++) {
            uint id = currentSupply.add(i);
            _mint(_recipient, id);
            _ids[i - 1] = id;
        }
    }

    function convert(IERC721[] memory _nfts, uint[] memory _ids) external {
        require(_nfts.length == _ids.length && _nfts.length >= requiredNum && _nfts.length % requiredNum == 0, "illegal length");
        for (uint i = 0; i < _nfts.length; i ++) {
            require(supportNFTs[_nfts[i]], "nft not support");
            _nfts[i].transferFrom(msg.sender, HOLE, _ids[i]);
        }
        uint num = _nfts.length / requiredNum;
        uint[] memory nftIds = this.mint(msg.sender, num);
        emit Convert(msg.sender, _nfts, _ids, nftIds);
    }

}