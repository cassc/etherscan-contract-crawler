// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface STCStaking {
    function diamondStaker(address _user) external view returns (bool);
}

contract ETHASKID is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    STCStaking stakingContract;
    address devWallet = 0xB8684538b07d6c1C11Fa04223D4f94DE84429792;

    struct Coins {
        uint256 price;
        uint256 discountedPrice;
        bool isValid;
        bool burnenabled;
    }

    mapping(address => Coins) public coinReq;

    address[] public coins;

    constructor() ERC721("ShitCoin", "STC") {
        coinReq[0x28D82C4D7315C02D19562dB1080a713eb5cc2639].price = 620 * (1e8);
        coinReq[0x28D82C4D7315C02D19562dB1080a713eb5cc2639].discountedPrice = 600 * (1e8);
        coinReq[0x28D82C4D7315C02D19562dB1080a713eb5cc2639].isValid = true;
        coinReq[0x28D82C4D7315C02D19562dB1080a713eb5cc2639].burnenabled = true;
        coins.push(0x28D82C4D7315C02D19562dB1080a713eb5cc2639);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setPrice(
        uint256 _price,
        uint256 _discountedPrice,
        bool burnenabled,
        address token
    ) public onlyOwner {
        require(coinReq[token].isValid, "Coin not added");
        coinReq[token].price = _price;
        coinReq[token].discountedPrice = _discountedPrice;
        coinReq[token].burnenabled = burnenabled;
    }

    function addCoin(
        uint256 _price,
        uint256 _discountedPrice,
        bool burnenabled,
        address token
    ) public onlyOwner {
        require(!coinReq[token].isValid, "Coin already added");
        coinReq[token].price = _price;
        coinReq[token].discountedPrice = _discountedPrice;
        coinReq[token].burnenabled = burnenabled;
        coinReq[token].isValid = true;
        coins.push(token);
    }

    function removeCoin(address token) public onlyOwner {
        require(coinReq[token].isValid, "Coin not added");
        delete coinReq[token];
        for (uint256 i = 0; i < coins.length; i++) {
            if (coins[i] == token) {
                coins[i] = coins[coins.length - 1];
                coins.pop();
                break;
            }
        }
    }

    function getCoins() public view returns (address[] memory) {
        return coins;
    }

    function setStakingContract(address _stakingContract) public onlyOwner {
        stakingContract = STCStaking(_stakingContract);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(IERC20 token, uint256 balance) public onlyOwner {
        token.transfer(msg.sender, balance);
    }

    function mint(string memory uri, IERC20 token) public {
        require(coinReq[address(token)].isValid, "Coin not added");
        uint256 price;
        if (address(stakingContract) != address(0)) {
            if (stakingContract.diamondStaker(msg.sender)) {
                price = coinReq[address(token)].discountedPrice;
            } else {
                price = coinReq[address(token)].price;
            }
        } else {
            price = coinReq[address(token)].price;
        }
        token.transferFrom(msg.sender, address(this), price);
        token.transfer(devWallet, (price * 10) / 100);
        if (coinReq[address(token)].burnenabled) {
            token.transfer(address(0xdead), (price * 20) / 100);
            token.transfer(owner(), (price * 70) / 100);
        } else {
            token.transfer(owner(), (price * 90) / 100);
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function Burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}