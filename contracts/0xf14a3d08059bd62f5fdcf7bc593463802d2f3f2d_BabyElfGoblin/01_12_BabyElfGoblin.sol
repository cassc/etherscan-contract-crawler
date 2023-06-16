// SPDX-License-Identifier: MIT
/*
Ⲃⲁⲃⲩ Ⲉ𝓵𝓯 𝓖ⲟⲃ𝓵ⲓⲛ
Web: babyelfgoblin.wtf
Twitter: @babyelfgoblin
*/
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract BabyElfGoblin is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public uriPrefix = "";
    string public uriExt = ".json";

    uint256 public constant mint_price = 0.003 ether;
    uint256 public free_max_supply = 3333;
    uint256 public free_max_per_wallet = 1;
    uint256 public max_supply = 6666;
    uint256 public max_mint_per_wallet = 5;

    mapping(address => uint256) public free_wallet_minted;
    mapping(address => uint256) public wallet_minted;

    bool public isLive = false;

    constructor (
        string memory _uriPrefix
    ) ERC721A("BabyElfGoblin", "BEGT") {
        setUriPrefix(_uriPrefix);
    }

    function setLive(bool _state) public onlyOwner {
        isLive = _state;
    }

    function mint(uint256 _mintAmount) public payable {
        require(isLive, "Mint is not live");
        require(totalSupply() + _mintAmount <= max_supply, "No supply left");
        require(_mintAmount > 0, "Must mint atleast 1");

        if (free_max_supply > totalSupply()) {
            require(_mintAmount <= free_max_per_wallet, "Allocated max per TX reached");
            require(free_wallet_minted[msg.sender] + _mintAmount <= free_max_per_wallet, "Transaction limit reached");
            require(totalSupply() + _mintAmount <= free_max_supply, "No more free mint supply");
            free_wallet_minted[msg.sender] += _mintAmount;
        } else {
            require(_mintAmount <= max_mint_per_wallet, "Allocated max per TX reached");
            require(wallet_minted[msg.sender] + _mintAmount <= max_mint_per_wallet, "Transaction limit reached");
            require(msg.value == mint_price * _mintAmount, "Invalid amount");
            wallet_minted[msg.sender] += _mintAmount;
        }

        _safeMint(_msgSender(), _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokensOwned = new uint256[](ownerTokenCount);
        uint256 thisTokenId = _startTokenId();
        uint256 tokensOwnedIndex = 0;
        address latestOwnerAddress;

        while (tokensOwnedIndex < ownerTokenCount && thisTokenId <= max_supply) {
            TokenOwnership memory ownership = _ownerships[thisTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                tokensOwned[tokensOwnedIndex] = thisTokenId;

                tokensOwnedIndex++;
            }
            thisTokenId++;
        }
        return tokensOwned;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string memory _newUriPrefix) public onlyOwner {
        uriPrefix = _newUriPrefix;
    }

    function setUriExt(string memory _newUriExt) public onlyOwner {
        uriExt = _newUriExt;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token unavailable.");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriExt))
            : '';
    }

    function setFreeMaxPerWallet (uint256 _free_max_per_wallet) public onlyOwner {
        free_max_per_wallet = _free_max_per_wallet;
    }

    function setMaxSupply (uint256 _max_supply) public onlyOwner {
        max_supply = _max_supply;
    }

    function setMaxPerWallet (uint256 _max_mint_per_wallet) public onlyOwner {
        max_mint_per_wallet = _max_mint_per_wallet;
    }

    function setFreeMaxSupply (uint256 _free_max_supply) public onlyOwner {
        free_max_supply = _free_max_supply;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, "Withdrawal failed.");
    }
}