// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PartisanCats is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    uint256 public maxMintAmount = 20;
    uint256 public maxSupply = 9999;
    uint256 public mintRate = 0.25 ether; //0.25 ether;
    uint256 public whitelistMintrate = 0.125 ether; //price for whitelisted buyers
    uint256 public OwnerMintrate = 0 ether;
    uint256 public nftPerAddressLimit = 1;
    bool public paused = false;
    bool public revealed = false;
    address[] public whitelistedAddresses;
    string private baseURI;
    mapping(address => bool) public whitelisted;
    event logMint(address _from, address _to, uint256 quantity);

    constructor() ERC721A("Partisan Cats", "PCats") {}

    function contractURI() public pure returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmXqKgHqxMDa43ik1DvkKYEhDazVR3rzUzh79M2DmZE8dC";
    }

    function _mint_by_owner(uint256 quantity) public onlyOwner {
        require(
            totalSupply() + quantity <= maxSupply,
            "Not enough tokens left"
        );
        _safeMint(msg.sender, quantity);
    }

    function mint(address wallet, uint256 quantity) public payable {
        require(!paused, "Paused by Owner"); //Make sure the contract not stopped for minting
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "Not enough tokens left");
        require(
            quantity + _numberMinted(msg.sender) <= maxMintAmount,
            "Exceeded the limit"
        );

        if (msg.sender != owner()) {
            require(quantity <= maxMintAmount);
            if (isWhitelisted(msg.sender) != true) {
                require(
                    msg.value >= mintRate * quantity,
                    "Not enough ether sent"
                );
            } else {
                uint256 ownerTokenCount = balanceOf(msg.sender);
                require(
                    msg.sender == wallet,
                    "Whitelist wallet cannot mint for another wallet"
                );
                require(
                    ownerTokenCount < nftPerAddressLimit,
                    "Token limit per whitelist wallet exceeded."
                );
                require(
                    quantity <= nftPerAddressLimit,
                    "Quantity exceeded than allowed number of tokens"
                );
                require(
                    msg.value >= whitelistMintrate * quantity,
                    "Not enough ether sent"
                );
            }
        }
        _safeMint(wallet, quantity);
        emit logMint(msg.sender, wallet, quantity);
    }

    //Transfer tokens to another wallet using tokenIDs, ex: [1,3,6,7]
    function bulkTransfer(uint256[] memory tokenIds, address _to)
        external
        onlyOwner
        nonReentrant
    {
        for (uint256 i; i < tokenIds.length; ) {
            safeTransferFrom(msg.sender, _to, tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    //Pausing the contract
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    //Change the number of limited NFTs per wallet
    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _changeBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _reveal(bool _revealed) external onlyOwner {
        //bool _revealed
        revealed = _revealed;
    }

    //Set Mint Price
    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    //Set number of Mint can be done at once
    function setMaxMint(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    //WhiteList Functions

    function getArr() public view returns (address[] memory) {
        return whitelistedAddresses;
    }

    /*
    function del_Address_From_Whitelist(address[] memory _user) public view {
        arr = whitelistedAddresses.filter(function(_user) {
        return element != 3;
        });
        whitelistedAddresses = whitelistedAddresses.filter(_user);
        return whitelistedAddresses;
    }
*/

    //Whitelist array, ex: ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
        whitelistedAddresses.push(_user);
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function removeWhitelistUserAfterMint(address _user) internal {
        whitelisted[_user] = false;
    }

    function amIwhitelisted() external view returns (bool) {
        return isWhitelisted(tx.origin);
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    //Wraping whitelist functions

    //Get single toekn ownership and return tuple

    function getTokenOwnership(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    //Overrided Functions

    //Override start token ID to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //Returning token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();
        if (revealed) {
            return
                bytes(baseURI_).length != 0
                    ? string(
                        abi.encodePacked(baseURI, _toString(tokenId), ".json")
                    )
                    : "";
        } else {
            return
                string(
                    abi.encodePacked(
                        "https://ipfs.io/ipfs/QmfM1TksZ9XpLGyRbsFGQKqyXin6GEKJGF8nKWN4sVmTje/hidden.json"
                    )
                );
        }
    }
}