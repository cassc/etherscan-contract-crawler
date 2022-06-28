// contracs/TroversePlanetsStaking.sol
// SPDX-License-Identifier: MIT

// ████████╗██████╗  ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗    
// ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    
//    ██║   ██████╔╝██║   ██║██║   ██║█████╗  ██████╔╝███████╗█████╗      
//    ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      
//    ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗    
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TroversePlanetsStaking is ERC721Holder, Ownable, ReentrancyGuard {
    mapping(address => uint256) private amountStaked;
    mapping(uint256 => address) public stakerAddress;

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    IERC721 public nftCollection;

    event NFTCollectionChanged(address _nftCollection);

    event Staked(uint256 id, address account);
    event Unstaked(uint256 id, address account);


    constructor() { }


    function setNFTCollection(address _nftCollection) external onlyOwner {
        require(_nftCollection != address(0), "Bad NFTCollection address");
        nftCollection = IERC721(_nftCollection);

        emit NFTCollectionChanged(_nftCollection);
    }

    function balanceOf(address owner) public view returns (uint256) {
        return amountStaked[owner];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        require(index < balanceOf(owner), "Owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    
    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        uint256 tokensLen = _tokenIds.length;
        for (uint256 i; i < tokensLen; ++i) {
            require(nftCollection.ownerOf(_tokenIds[i]) == _msgSender(), "Can't stake tokens you don't own!");

            nftCollection.transferFrom(_msgSender(), address(this), _tokenIds[i]);
            stakerAddress[_tokenIds[i]] = _msgSender();

            _addTokenToOwnerEnumeration(_msgSender(), _tokenIds[i]);
            amountStaked[_msgSender()] += 1;

            emit Staked(_tokenIds[i], _msgSender());
        }
    }

    function unstake(uint256[] calldata _tokenIds) external nonReentrant {
        require(amountStaked[_msgSender()] > 0, "You have no tokens staked");

        uint256 tokensLen = _tokenIds.length;
        for (uint256 i; i < tokensLen; ++i) {
            require(stakerAddress[_tokenIds[i]] == _msgSender(), "Can't unstake tokens you didn't stake!");

            stakerAddress[_tokenIds[i]] = address(0);
            nftCollection.transferFrom(address(this), _msgSender(), _tokenIds[i]);

            _removeTokenFromOwnerEnumeration(_msgSender(), _tokenIds[i]);
            amountStaked[_msgSender()] -= 1;

            emit Unstaked(_tokenIds[i], _msgSender());
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}