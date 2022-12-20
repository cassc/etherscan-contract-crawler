// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./ERC721A.sol";

contract AlleyCatGang is Context, ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool public _isRevealed = false;
    bool public _isPreSaleActive = false;
    bool public _isPublicSaleActive = false;

    uint256 public PRICE = 0.05 ether;
    uint256 public MAX_SUPPLY = 7777;
    uint256 public MAX_BY_MINT = 10;
    uint256 public MAX_PER_ADDRESS = 10;

    string private _baseTokenURI;
    string private _preRevealURI;

    mapping(address => bool) private _whiteList;

    event TokenMinted(uint256 supply);

    constructor(string memory _uri) ERC721A("Alley Cat Gang", "ACG") {
        setPreRevealURI(_uri);
    }

    function onWhiteList(address addr) external view returns (bool) {
        return _whiteList[addr];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (_isRevealed == false) {
            return
                bytes(_preRevealURI).length > 0
                    ? string(
                        abi.encodePacked(
                            _preRevealURI,
                            Strings.toString(tokenId),
                            ".json"
                        )
                    )
                    : "";
        }

        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function create(uint256 qty) public payable {
        require(
            _isPreSaleActive || _isPublicSaleActive,
            "Sale isn't started yet"
        );
        require(qty > 0, "At least one should be minted");
        require(qty <= MAX_BY_MINT, "Exceeds mint quantity per transaction");
        require(totalSupply() + qty < MAX_SUPPLY, "Exceeding max supply");
        require(PRICE * qty <= msg.value, "Not enough ether sent");
        if (_isPreSaleActive) {
            require(_whiteList[msg.sender], "You are not in the WhiteList");
            require(
                balanceOf(msg.sender) + qty <= MAX_PER_ADDRESS,
                "Exceeds balance"
            );
            _whiteList[msg.sender] = false;
        }

        _safeMint(msg.sender, qty);
        emit TokenMinted(totalSupply());
    }

    function addToWhiteList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _whiteList[addresses[i]] = true;
        }
    }

    function removeFromWhiteList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            _whiteList[addresses[i]] = false;
        }
    }

    function enablePreSale() public onlyOwner {
        _isPreSaleActive = !_isPreSaleActive;
    }

    function enablePublicSale() public onlyOwner {
        _isPublicSaleActive = !_isPublicSaleActive;
    }

    function airdrop(address recipient, uint256 qty) public onlyOwner {
        require(totalSupply() + qty < MAX_SUPPLY, "Exceeding max supply");

        _safeMint(recipient, qty);
        emit TokenMinted(totalSupply());
    }

    function setReveal() public onlyOwner {
        _isRevealed = true;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function setMaxByMint(uint256 _amount) public onlyOwner {
        MAX_BY_MINT = _amount;
    }

    function setMaxPerAddress(uint256 _amount) public onlyOwner {
        MAX_PER_ADDRESS = _amount;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPreRevealURI(string memory preRevealURI) public onlyOwner {
        _preRevealURI = preRevealURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "The balance must be greater than Zero.");
        _withdraw(msg.sender, balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}