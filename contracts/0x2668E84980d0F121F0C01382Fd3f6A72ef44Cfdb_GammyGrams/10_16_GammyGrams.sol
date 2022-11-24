//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MultisigOwnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/*
╭━━┳━━┳╮╭┳╮╭┳╮╱╭╮╭━━┳━┳━━┳╮╭┳━━╮
┃╭╮┃╭╮┃╰╯┃╰╯┃┃╱┃┃┃╭╮┃╭┫╭╮┃╰╯┃━━┫
┃╰╯┃╭╮┃┃┃┃┃┃┃╰━╯┃┃╰╯┃┃┃╭╮┃┃┃┣━━┃
╰━╮┣╯╰┻┻┻┻┻┻┻━╮╭╯╰━╮┣╯╰╯╰┻┻┻┻━━╯
╭━╯┃╱╱╱╱╱╱╱╱╭━╯┃╱╭━╯┃
╰━━╯╱╱╱╱╱╱╱╱╰━━╯╱╰━━╯
*/

// IMPORTANT: _burn() must never be called
contract GammyGrams is ERC721A, MultisigOwnable, DefaultOperatorFilterer {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    uint constant public TOKEN_LIMIT = 1e3;
    uint public gammyPrice = 0.01 ether;
    uint constant public freeMint = 1;
    uint public startSaleTimestamp;
    bool public revealed = false;
    bool public finalized = false;
    bool public onIPFS = false;
    string public baseURI;
    string public unrevealedURI;
    mapping(address => uint) public tokenPrice;
    mapping(address => uint) public walletMint;

    /// @dev start with an unrevealed base URI, then web 2 during mint, then IPFS before locking
    constructor(string memory _baseURI, string memory _unrevealedURI)
        ERC721A("Gammy Grams", "GAMMY")
    {
        // todo set the correct timestamp
        startSaleTimestamp = block.timestamp + 2 days;
        baseURI = _baseURI;
        unrevealedURI = _unrevealedURI;
    }

    /// @dev use setParams to change the baseURI from web2 to IPFS
    function setParams(string memory _baseURI, bool _onIPFS, bool _revealed) external onlyRealOwner {
        require(finalized == false, "final");
        baseURI = _baseURI;
        onIPFS = _onIPFS;
        revealed = _revealed;
    }

    /// @dev use setFinalized to lock the contract from further changes
    function setFinalized(bool newFinal) external onlyRealOwner {
        require(finalized == false, "final");
        finalized = newFinal;
    }

    /// @dev use setStartSaleTimestamp adjust the starting timestamp
    function setStartSaleTimestamp(uint newTimestamp) external onlyRealOwner {
        require(finalized == false, "final");
        startSaleTimestamp = newTimestamp;
    }

    /// @dev use setFinalized to lock the contract from further changes
    function setUnrevealedURI(string calldata _unrevealedURI) external onlyRealOwner {
        require(finalized == false, "final");
        unrevealedURI = _unrevealedURI;
    }

    /// @dev use setFinalized to lock the contract from further changes
    function setGammyPrice(uint _newPrice) external onlyRealOwner {
        require(finalized == false, "final");
        gammyPrice = _newPrice;
    }

    function setTokenPrice(address _token, uint _price) external onlyRealOwner {
        require(finalized == false, "final");
        tokenPrice[_token] = _price;
    }

    function retrieveFunds(address payable _to) external onlyRealOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function retrieveToken(address _to, address _token) external onlyRealOwner {
        IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
    }

    function mintFromSale(uint gammiesToMint) public payable {
        require(totalSupply() < TOKEN_LIMIT, "limit reached");
        require(block.timestamp > startSaleTimestamp, "Public sale hasn't started yet");
        require(gammiesToMint <= 30, "Only up to 30 gammies can be minted at once");
        uint cost;
        if(walletMint[msg.sender] < freeMint) {
            if(gammiesToMint < freeMint) gammiesToMint = freeMint;
            unchecked {
                cost = (gammiesToMint - freeMint) * gammyPrice;
            }
            require(msg.value >= cost, "wrong payment");
            walletMint[msg.sender] += gammiesToMint;
        } else {
            unchecked {
                cost = gammiesToMint * gammyPrice;
            }
            require(msg.value >= cost, "wrong payment");
        }
        _mint(msg.sender, gammiesToMint);
    }

    function mintWithToken(uint gammiesToMint, address _token) public {
        require(totalSupply() < TOKEN_LIMIT, "limit reached");
        require(block.timestamp > startSaleTimestamp, "Public sale hasn't started yet");
        require(tokenPrice[_token] > 0, "token not acceptable");
        require(gammiesToMint <= 30, "Only up to 30 gammies can be minted at once");
        uint cost;
        if(walletMint[msg.sender] < freeMint) {
            if(gammiesToMint < freeMint) gammiesToMint = freeMint;
            unchecked {
                cost = (gammiesToMint - freeMint) * tokenPrice[_token];
            }
            walletMint[msg.sender] += gammiesToMint;
        } else {
            unchecked {
                cost = gammiesToMint * tokenPrice[_token];
            }
        }
        IERC20(_token).safeTransferFrom(msg.sender, address(this), cost);
        _mint(msg.sender, gammiesToMint);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (!revealed) {
            return unrevealedURI;
        }
        if (onIPFS) {
            return string(abi.encodePacked(baseURI, id.toString(), ".json"));
        } else {
            return string(abi.encodePacked(baseURI, id.toString()));
        }
    }

    // FOR OPERATOR FILTER REGISTRY: https://github.com/cygaar/OpenSea-NFT-Template
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}