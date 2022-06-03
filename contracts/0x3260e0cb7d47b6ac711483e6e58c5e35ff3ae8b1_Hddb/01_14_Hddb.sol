// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./OnlySender.sol";

struct AddressMint {
    address _address;
    uint256 _quantity;
}

contract Hddb is ERC721A, Ownable, Pausable, ReentrancyGuard, OnlySender {
    using Address for address;
    using Strings for uint256;

    uint256 public constant _maxSupply = 10000;
    uint256 public constant _mintPrice = 0.042069 ether;
    string public _tokenURIBase;
    string public _tokenURIExtension;

    uint256 public constant freeMintSupply = 200;
    uint256 public constant maxMintPerTxn = 20;

    address public constant xDao = 0xF14d484b29A8aC040FEb489aFADB4b972422B4E9;
    address public constant xCDB = 0x931bea6F8b81463dCb79c6274Bff8065514b4e70;
    address public constant xDev1 = 0xBDE93d2cb5E953Aeb8952162910b9BC7934DB2D0;
    address public constant xDev2 = 0xcB7F8E944D835f1D33C6573cDb11443C0AA02f9E;
    address public constant xProb = 0x852459D22dcd0aB2b6a9C802128Ac0c3E048b9F2;

    mapping(address => bool) public addressDidFreeMint;

    constructor(string memory _URIBase, string memory _URIExtension)
        ERC721A("Hddb", "HDDB")
    {
        _tokenURIBase = _URIBase;
        _tokenURIExtension = _URIExtension;
        _pause();
    }

    function freeMintCompliance(bool freeMintActive) private view {
        require(freeMintActive, "Free ended");
        require(!addressDidFreeMint[msg.sender], "Address free minted");
    }

    function mintCompliance(
        uint256 quantity,
        uint256 minted,
        bool freeMintActive
    ) private {
        require(!freeMintActive, "Free mint active");
        require(
            quantity > 0 && quantity <= maxMintPerTxn,
            "Max per txn exceeded"
        );
        require(msg.value == _mintPrice * quantity, "Incorrect payment");
        require(minted + quantity <= _maxSupply, "Maximum supply exceeded");
    }

    function freeMint() public onlySender whenNotPaused {
        bool freeMintActive = totalSupply() < freeMintSupply;
        freeMintCompliance(freeMintActive);
        addressDidFreeMint[msg.sender] = true;
        _mint(msg.sender, 1, "", false);
    }

    function mint(uint256 quantity) public payable onlySender whenNotPaused {
        uint256 minted = totalSupply();
        bool freeMintActive = minted < freeMintSupply;
        mintCompliance(quantity, minted, freeMintActive);
        _mint(msg.sender, quantity, "", false);
    }

    function setURIBase(string memory _URIBase) public onlyOwner {
        _tokenURIBase = _URIBase;
    }

    function setURIExtension(string memory _URIExtension) public onlyOwner {
        _tokenURIExtension = _URIExtension;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        uint256 daoCut = (balance * 20) / 100;
        uint256 cdbCut = (balance * 10) / 100;
        uint256 dev1Cut = (balance * 15) / 100;
        uint256 dev2Cut = (balance * 5) / 100;

        Address.sendValue(payable(xDao), daoCut);
        Address.sendValue(payable(xCDB), cdbCut);
        Address.sendValue(payable(xDev1), dev1Cut);
        Address.sendValue(payable(xDev2), dev2Cut);
        Address.sendValue(payable(xProb), address(this).balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent token");
        return
            string(
                abi.encodePacked(
                    _tokenURIBase,
                    _tokenId.toString(),
                    _tokenURIExtension
                )
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenURIBase;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function walletOfOwner(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_address);
        uint256[] memory tokens = new uint256[](balance);
        uint256 index;
        uint256 supply = totalSupply();
        for (uint256 i = 1; i < supply; i++) {
            if (_address == ownerOf(i)) {
                tokens[index] = i;
                index++;
                if (index >= balance) {
                    return tokens;
                }
            }
        }
        return tokens;
    }
}