// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

//                   .        .           -     _
//               .       .  ~   . ~  -  ~  . = .  ~
//           ~        ~  __.---~~_~~_~~_~~_~ ~ ~~_~~~
//         .    .     .-'  ` . ~_ = ~ _ =  . ~ .    ~
//                  .'  `. ~  -   =      ~  -  _ ~ `
//         ~    .  }` =  - _ ~  -  . ~  ` =  ~  _ . ~
//               }`   . ~   =    ~  =  ~   -  ~    - _
//     .        }   ~ .__,_O     ` ~ _   ~  ^  ~  -
//            `}` - =    /#/`-'     -   ~   =   ~  _ ~
//       ~ .   }   ~ -   |^\   _ ~ _  - ~ -_  =  _
//            }`  _____ /_  /____ - ~ _   ~ _
//          }`   `~~~~~~~~~~~~~~~`_ = _ ~ -
//  _ _ _ }` `. ~ . - _ = ~. ~ = .   -   =
//   _     ___   ___  _
//  | | __/ _ \ / _ \| | _____
//  | |/ / | | | | | | |/ / __|
//  |   <| |_| | |_| |   <\__ \
//  |_|\_\\___/ \___/|_|\_\___/

contract k00ks is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public baseTokenURI;
    bytes32 public partywaveRoot;

    uint256 public collectionSize = 5555;
    uint256 public maxPerAddress_wave1 = 3;
    uint256 public maxPerAddress = 6;
    uint public wave = 0;
    uint public price = 0.075 ether;

    mapping(address => bool) private freeMintClaimed;
    mapping(address => bool) private freeMints;
    mapping(address => uint256) private mintCount;

    constructor(string memory baseURI) ERC721("k00ks", "k00ks") {
        setBaseURI(baseURI);
    }

    function freeMint(bytes32[] calldata _proof) public {
        uint256 freeMintQuantity = 1;
        uint totalMinted = _tokenIds.current();

        require(MerkleProof.verify(_proof, partywaveRoot, keccak256(abi.encodePacked(msg.sender, wave))) == true, "Invalid merkle proof");

        require(verifyFreeMintStatus(msg.sender), "Not entitled to free mint");
        require(wave == 1, "Free mints only allowed in Wave 1");

        require(!freeMintClaimed[msg.sender], "Free mint claimed");
        require(totalMinted + freeMintQuantity <= collectionSize, "Not enough remaining!");

        freeMintClaimed[msg.sender] = true;

        _mintNFT();
    }

    function mint(uint _quantity, bytes32[] calldata _proof) public payable {

        uint totalMinted = _tokenIds.current();

        if (wave < 3) {
            require(MerkleProof.verify(_proof, partywaveRoot, keccak256(abi.encodePacked(msg.sender, wave))) == true, "Invalid merkle proof");

            if (wave == 1) {
                uint256 freeMintQuantity = verifyFreeMintStatus(msg.sender) ? 1 : 0;
                require(mintCount[msg.sender] + _quantity <= maxPerAddress_wave1 + freeMintQuantity, "Exceeds max mint count");
            }
        }

        require(mintCount[msg.sender] + _quantity <= maxPerAddress, "Exceeds max mint count");
        require(_quantity <= maxPerAddress, "Cannot mint more than max");
        require(totalMinted + _quantity <= collectionSize, "Not enough remaining!");
        require(_quantity > 0, "Cannot mint zero");

        require(msg.value == price * _quantity,"Insufficient funds to redeem");

        for (uint i = 0; i < _quantity; i++) {
            _mintNFT();
            // uint id = _mintNFT();
            // tokensExist[id] = true;
        }
    }

    // function _mintNFT() private returns (uint id) {
    //     require(wave > 0, "Minting not yet started");
    //     require(!_paused, "Sale paused");

    //     uint newTokenID = _tokenIds.current();
    //     _safeMint(msg.sender, newTokenID);

    //     mintCount[msg.sender] += 1;

    //     id = newTokenID;
    //     _tokenIds.increment();

    //     return id;
    // }

    function _mintNFT() private {
        require(wave > 0, "Minting not live");

        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);

        mintCount[msg.sender] += 1;

        _tokenIds.increment();
    }

    function hasToken() private view returns (uint balance) {
        balance = balanceOf(msg.sender);
    }

    function getTokens() public view returns (uint[] memory) {
        uint balance = hasToken();
        uint[] memory tokens = new uint[](balance);

        for (uint i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(msg.sender, i);
        }

        return tokens;
    }

    function verifyFreeMintStatus(address _address) public view returns (bool) {
        return freeMints[_address];
    }

    function verifyFreeMintClaimed(address _address) public view returns (bool) {
        return freeMintClaimed[_address];
    }

    function getPrice(uint _quantity)
        public
        view
        returns (uint totalPrice)
    {
        totalPrice = price * _quantity;

        return totalPrice;
    }

    function getCollectionSize() public view returns (uint256 _collectionSize) {
        _collectionSize = collectionSize;

        return _collectionSize;
    }

    function addFreeMints(address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            freeMints[_addresses[i]] = true;
        }
    }

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setWave(uint _wave) public onlyOwner {
        wave = _wave;
    }

    function setMaxPerAddress(uint256 _max) public onlyOwner {
        maxPerAddress = _max;
    }

    function setCollectionSize(uint256 _collectionSize) public onlyOwner {
        collectionSize = _collectionSize;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPartyWaveRoot(bytes32 _root) external onlyOwner {
        partywaveRoot = _root;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAmount(uint amount) public onlyOwner {
        require(amount < address(this).balance, "Balance too low for amount");
        payable(owner()).transfer(amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}