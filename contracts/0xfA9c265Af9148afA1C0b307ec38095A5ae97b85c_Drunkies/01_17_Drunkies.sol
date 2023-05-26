// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Drunkies is ERC721URIStorage, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event Withdrawal(uint256 amount, uint256 when);
    event MintToken(uint tokenId, address userAddress);

    uint256 public freeMintLimit = 1;
    uint256 public _maxSupply = 2999;
    address public genesisNFTContractAddress =
        0x8A787dADB36fE6ABA8eD99dC135514e0e3019eb4;
    string public tokenURI =
        "https://ipfs.io/ipfs/QmU1NMragKxJrrbiD4vEo5e5CgcETgoiM4T3u4Ny5Yr4ag";

    mapping(address => uint256) public usedTokenCounts;
    mapping(address => bool) public whitelistedAddress;
    mapping(uint => address) public nftListed;

    constructor() ERC721("Drunkies Mint Pass", "DMP") {
        whitelistedAddress[msg.sender] = true;
    }

    function bulkMintNFT(
        uint256 numberOfTokens
    ) public payable returns (uint256) {
        require(
            _tokenIds.current().add(numberOfTokens) <= _maxSupply,
            "Max supply reached"
        );
        require(
            msg.value >= numberOfTokens.mul(0.025 ether),
            "Insufficient ether sent"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();

            _safeMint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, tokenURI);

            emit MintToken(newTokenId, msg.sender);
        }

        withdraw(payable(owner()));

        return _tokenIds.current();
    }

    function getNumberOfFreeTokens() public view returns (uint) {
        if (msg.sender != owner()) {
            return
                IERC721(genesisNFTContractAddress).balanceOf(msg.sender) -
                usedTokenCounts[msg.sender];
        } else {
            return _maxSupply;
        }
    }

    function bulkFreeMintNFT(
        uint256 numberOfTokens
    ) public payable returns (uint256) {
        require(
            whitelistedAddress[msg.sender] == true,
            "You are not eligibe for free mint"
        );

        require(
            numberOfTokens > 0,
            "Number of tokens must be greater than zero"
        );
        require(
            _tokenIds.current().add(numberOfTokens) <= _maxSupply,
            "Max supply reached"
        );

        uint256 numberOfFreeTokens;
        if (msg.sender == owner()) {
            numberOfFreeTokens = _maxSupply;
        } else {
            numberOfFreeTokens =
                IERC721(genesisNFTContractAddress).balanceOf(msg.sender) -
                usedTokenCounts[msg.sender];
        }

        if (numberOfTokens <= numberOfFreeTokens) {
            for (uint256 i = 0; i < numberOfTokens; i++) {
                _tokenIds.increment();
                uint256 newTokenId = _tokenIds.current();

                _safeMint(msg.sender, newTokenId);
                _setTokenURI(newTokenId, tokenURI);
                usedTokenCounts[msg.sender] += 1;

                emit MintToken(newTokenId, msg.sender);
            }
        } else {
            uint256 numberOfPaidTokens = uint256(
                numberOfTokens.sub(numberOfFreeTokens)
            );

            uint256 paidTokensCost = numberOfPaidTokens.mul(0.025 ether);

            require(msg.value >= paidTokensCost, "Insufficient ether sent");

            for (uint256 i = 0; i < numberOfTokens; i++) {
                _tokenIds.increment();
                uint256 newTokenId = _tokenIds.current();

                _safeMint(msg.sender, newTokenId);
                _setTokenURI(newTokenId, tokenURI);

                emit MintToken(newTokenId, msg.sender);
            }
            usedTokenCounts[msg.sender] += numberOfFreeTokens;

            withdraw(payable(owner()));
        }

        return _tokenIds.current();
    }

    function listNftForSale(uint _tokenId) public {
        address payable nftOwner = payable(ownerOf(_tokenId));
        require(nftOwner == msg.sender, "You are not Owner of this NFT!");
        nftListed[_tokenId] = msg.sender;
    }

    function buyNFT(uint256 tokenId) public payable {
        address payable nftOwner = payable(ownerOf(tokenId));
        require(nftOwner != address(0), "Invalid token ID");
        require(nftOwner != msg.sender, "You cannot buy your own token");
        require(
            nftListed[tokenId] == nftOwner,
            "This NFT is not listed for sale!"
        );
        require(msg.value == 0.025 ether, "Need to send 0.025 ether");

        // Calculate and transfer royalty to contract owner
        uint256 royaltyAmount = msg.value.mul(5).div(100);
        uint256 paymentAmount = msg.value.sub(royaltyAmount);

        payable(owner()).transfer(royaltyAmount);
        nftOwner.transfer(paymentAmount);

        _transfer(nftOwner, msg.sender, tokenId);
    }

    function whitelistWalletAddress(
        address[] memory walletAddresses
    ) public onlyOwner {
        for (uint256 i = 0; i < walletAddresses.length; i++) {
            if (whitelistedAddress[walletAddresses[i]] == false) {
                whitelistedAddress[walletAddresses[i]] = true;
            }
        }
    }

    function checkFreeMintAvailable() public view returns (bool) {
        if (whitelistedAddress[msg.sender] == true) {
            return true;
        } else {
            return false;
        }
    }

    function withdraw(address payable recipient) private {
        uint256 balance = address(this).balance;
        recipient.transfer(balance);

        emit Withdrawal(address(this).balance, block.timestamp);
    }

    function updateMaxSupply(uint256 supply) public onlyOwner {
        _maxSupply = supply;
    }

    function updateGenesisContractAddress(
        address _contractAddress
    ) public onlyOwner {
        genesisNFTContractAddress = _contractAddress;
    }

    function updateTokenURI(string memory _tokenURI) public onlyOwner {
        tokenURI = _tokenURI;
    }
}