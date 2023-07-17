// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";

contract NFTLP is ERC721Burnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    struct NFTDetails {
        address erc20address; //Address of LP token contract
        uint256 amount; // amount lp tokens staked
        uint256 block; //block the nft was minted at
    }

    mapping(uint256 => NFTDetails) private nftDetails;

    // total staked per token address
    mapping(address => uint256) public totalStaked;

    constructor(string memory baseURI_) public ERC721("NFT20", "NFT20") {
        _setBaseURI(baseURI_);
    }

    function getNFTInfo(uint256 _nftId)
        public
        view
        returns (
            address _erc20address,
            uint256 _amount,
            uint256 _block
        )
    {
        NFTDetails storage nft = nftDetails[_nftId];
        _erc20address = nft.erc20address;
        _amount = nft.amount;
        _block = nft.block;
    }

    // deposit LP tokens and get NFT representation
    function deposit(address erc20address, uint256 amount) external {
        // deposit lp tokens into contract
        IERC20(erc20address).safeTransferFrom(
            address(msg.sender),
            address(this),
            amount
        );

        nftDetails[_tokenIdTracker.current()] = NFTDetails(
            erc20address,
            amount,
            block.number
        );

        totalStaked[erc20address] = totalStaked[erc20address].add(amount);

        // give minter role to this contract
        _mint(msg.sender, _tokenIdTracker.current());

        _tokenIdTracker.increment();
    }

    // instead of withdraw I am overriding the burn function from NFTs.
    // this is because if there was withdraw and someone executes burn, it would burn the token and
    // not delete the struct or make blance go down or send LP tokens back.
    // not sure about this let me know.
    function burn(uint256 tokenId) public override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );

        NFTDetails storage nft = nftDetails[tokenId];

        totalStaked[nft.erc20address] = totalStaked[nft.erc20address].sub(
            nft.amount
        );

        // Send lp tokens to user
        IERC20(nft.erc20address).transfer(msg.sender, nft.amount);

        // delete data
        delete nftDetails[tokenId];
        _burn(tokenId);
    }
}