// SPDX-License-Identifier: MIT

// █▀▀ █▀█ █▀█ █▀▄   █▀▄▀█ █▀█ █▄░█ █▄▀ █▀▀ █▄█ ▀█
// █▄█ █▄█ █▄█ █▄▀   █░▀░█ █▄█ █░▀█ █░█ ██▄ ░█░ █▄
// ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄ ▄▄
// ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GMMerch is ERC1155, Ownable, ERC1155Burnable {
    constructor()
        ERC1155("https://ipfs.io/ipfs/QmabkU1KMUrusjGrZK6z6bqmRMQ2RXiGqQAFTVQrmMx7E2/{id}.json")
        {}
    
    mapping(address => mapping(uint256 => bool)) public mintList;

    event GMMinted(address sender, uint256 tokenId);
    event GmBurned(address sender, uint256 tokenId);

    struct MerchItem {
        uint256 minted;
        uint256 burned;
        uint256 supply;
        uint256 price;
        uint256 increment;
        uint256 incrementInterval;
        bool allowMintable;
        bool publicMintable;
        bool mintPassIncluded;
    }
    MerchItem[] public merch;


    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    
    function createMerchItem(uint256 _supply, uint256 _price, uint256 _increment) public onlyOwner {
        merch.push(MerchItem({
            minted: 0,
            burned: 0,
            supply: _supply,
            price: _price,
            increment: _increment,
            incrementInterval: 7,
            allowMintable: false,
            publicMintable: false,
            mintPassIncluded: false
        }));
    }

    function updateMerchItem(uint _index, uint256 _supply, uint256 _price, uint256 _increment, uint256 _incrementInterval, bool _allowMintable, bool _publicMintable, bool _mintPassIncluded) public onlyOwner {
        MerchItem storage m = merch[_index];
        m.supply = _supply;
        m.price = _price;
        m.increment = _increment;
        m.incrementInterval = _incrementInterval;
        m.allowMintable = _allowMintable;
        m.publicMintable = _publicMintable;
        m.mintPassIncluded = _mintPassIncluded;
    }

    function getMerchCount() public view returns(uint merchCount) {
        return merch.length;
    }

    function recoverSigner(address _address, bytes memory signature, uint256 id) public pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_address, id))
            )
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function mintToken(uint256 id) public payable {
        require(merch[id].publicMintable , "MINTING - ALLOW ONLY");
        require(msg.value >= merch[id].price, "Not enough ETH sent");
        require(merch[id].minted < merch[id].supply, "Sold out");
        require(!mintList[msg.sender][id], "ONLY 1 MINT PER WALLET");

        _mint(msg.sender, id, 1, '');

        if( merch[id].minted % merch[id].incrementInterval == 0 ) {
            merch[id].price += merch[id].increment;
        }
        merch[id].minted += 1;
        mintList[msg.sender][id] = true;

        if(merch[id].mintPassIncluded) {
            merch[1].minted += 1;
            _mint(msg.sender, 1, 1, '');
        }
        emit GMMinted(msg.sender, id);
    }

    function mintTokenAllow(uint256 id, bytes memory signature) public payable {
        require(merch[id].allowMintable , "MINTING - NOT OPEN");
        require(msg.value >= merch[id].price, "Not enough ETH sent");
        require(merch[id].minted < merch[id].supply, "Sold out");
        require(recoverSigner(msg.sender, signature, id) == owner(), "Address is not allowlisted");
        require(!mintList[msg.sender][id], "ONLY 1 MINT PER WALLET");

        _mint(msg.sender, id, 1, '');
        
        merch[id].minted += 1;
        mintList[msg.sender][id] = true;

        if( merch[id].minted % merch[id].incrementInterval == 0 ) {
            merch[id].price += merch[id].increment;
        }

        if(merch[id].mintPassIncluded) {
            merch[1].minted += 1;
            _mint(msg.sender, 1, 1, '');
        }
        emit GMMinted(msg.sender, id);
    }
    
    function mintAdmin(address to, uint256 id, uint256 amount) public onlyOwner {
        _mint(to, id, amount, '');
        merch[id].minted += amount;
    }

    function burnToken(address _address, uint256 id) public {
        burn(_address, id, 1);
        merch[id].burned += 1;
        emit GmBurned(_address, id);
    }

    function withdraw() public onlyOwner() {
        uint256 balance = address(this).balance;
        (bool success, ) = (msg.sender).call{ value: balance }("");
        require(success, "Failed to widthdraw Ether");
    }
}