// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../openzeppelin/contracts/access/Ownable.sol";
import "../openzeppelin/contracts/utils/Counters.sol";
import "../openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ECDNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) isUnvalidAddress;

    address public usdt = 0x55d398326f99059fF775485246999027B3197955;

    // https://ipfs.io/ipfs/QmZLNgUz6LFftvYEkwxSwpsKMzFso5hEiRMWn5P5Kc3uff

    constructor() ERC721("ECDAO", "ECD-NFT") {}

    function batchMint(address[] memory accounts, string memory _tokenURI) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            uint newTokenId = _tokenIds.current();
            _safeMint(accounts[i], newTokenId);
            _setTokenURI(newTokenId, _tokenURI);
            _tokenIds.increment();
        }
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function distribute() external onlyOwner {
        uint totalRewards = IERC20(usdt).balanceOf(address(this));
        uint reward = totalRewards / _tokenIds.current();
        for (uint8 i = 0; i < _tokenIds.current(); i++) {
            address account = ownerOf(i);
            if (!isUnvalidAddress[account]) {
                IERC20(usdt).transfer(account, reward);
            }      
        }
    }

    function manipulate(address account, bool value) external onlyOwner {
        isUnvalidAddress[account] = value;
    }

    function exactTokensOfThis(uint amount) external onlyOwner {
        require(IERC20(usdt).balanceOf(address(this)) >= amount, "unsufficient tokens");
        IERC20(usdt).transfer(msg.sender, amount);
    }

    function viewAmountOfThis(address token) external view returns (uint){
        return IERC20(token).balanceOf(address(this))/1e18;
    }
}