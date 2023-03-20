// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

contract MiraOnChain is ERC721A, Ownable {
    using Strings for uint256;

    bytes32 public merkleRoot;

    enum MintStatus {
        PAUSED,
        LIVE
    }
    MintStatus public mintStatus;

    struct Block {
        string name;
        string description;
        string bar1Hue;
        string bar2Hue;
        string bar3Hue;
    }

    uint256 public price = 0.003 ether;
    uint256 public maxSupply = 5000;
    uint256 public maxPerWallet = 5;
    uint256 public maxFreeMint = 1100;
    uint256 public totalFreeMinted;

    mapping(uint256 => Block) public blocks;
    mapping(address => bool) public hasClaimedWhitelist;


    constructor() ERC721A("Mira On Chain", "MOC"){
        mintStatus = MintStatus.PAUSED;
    }

    modifier canMint(uint256 _quantity) {
        require(
            _quantity > 0 &&
            _quantity + totalSupply() <= maxSupply &&
            _quantity + _numberMinted(msg.sender) <= maxPerWallet,
            "Invalid input amount, Sold out or Mint limit exceeded!"
        );
        _;
    }

    function mint(uint256 _quantity, bytes32[] calldata proof) external payable canMint(_quantity) {
        require(mintStatus == MintStatus.LIVE, "Whitelist mint is not live");
        uint256 _price = price;
        uint256 _totalFreeMinted = totalFreeMinted;
        uint256 _maxFreeMint = maxFreeMint;
        uint256 _maxSupply = maxSupply;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if(MerkleProof.verify(proof, merkleRoot, leaf)) {
            if(!hasClaimedWhitelist[msg.sender]) {
                require(1 + _totalFreeMinted <= _maxFreeMint, "Miralist mint is over");
                require(msg.value >= (_quantity - 1) * _price, "Incorrect ETH amount");
                hasClaimedWhitelist[msg.sender] = true;
                totalFreeMinted += 1;
                createNewBlock(_quantity);
            } else {
                require((totalSupply() - _totalFreeMinted) + _quantity <= (_maxSupply - _maxFreeMint), "Sold Out");
                require(msg.value >= (_quantity * _price), "Incorrect ETH amount");
                createNewBlock(_quantity);
            }
        } else {
            require((totalSupply() - _totalFreeMinted) + _quantity <= (_maxSupply - _maxFreeMint), "Sold Out");
            require(msg.value >= (_quantity * _price), "Incorrect ETH amount");
            createNewBlock(_quantity);
        }
    }

    function teamMint(uint256 _quantity) external onlyOwner {
        require(_quantity + _numberMinted(owner()) <= 10, "Max limit exceeded");

        createNewBlock(_quantity);
    }

    function setMintStatus(uint256 _index) external onlyOwner {
        if(_index == 1) {
            mintStatus = MintStatus.LIVE;
        }else {
            mintStatus = MintStatus.PAUSED;
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxFreeMint(uint256 _maxFreeMint) external onlyOwner {
        maxFreeMint = _maxFreeMint;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function _startTokenId() internal view virtual override returns(uint256) {
        return 1;
    }

    function getRandomNumber(uint256 _mod, uint256 _seed, uint256 _salt) private view returns(uint256) {
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
        return num;
    }

    function createNewBlock(uint256 _quantity) private {
        for(uint256 i = 0; i < _quantity; i++) {
            uint256 _tokenId = totalSupply() + 1;
            Block memory newBlock = Block(
                string(abi.encodePacked('MOC#', _tokenId.toString())),
                "Colorful Mira bars, 100% uniquely generated on chain. Live on the Ethereum Blockchain!",
                getRandomNumber(361, block.gaslimit, _tokenId).toString(),
                getRandomNumber(361, block.timestamp, _tokenId).toString(),
                getRandomNumber(361, block.number, _tokenId).toString()
            );
            blocks[_tokenId] = newBlock;
            _safeMint(msg.sender, 1);
        }
    }

    function getHeight() private view returns(string memory, string memory, string memory) {
        uint256 bar1;
        uint256 bar2;
        uint256 bar3;

        uint256 value = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, totalSupply()))) % 6;

        if(value == 0) {
            bar1 = 100;
            bar2 = 150;
            bar3 = 200;
        } else if(value == 1) {
            bar1 = 100;
            bar2 = 200;
            bar3 = 150;
        } else if(value == 2) {
            bar1 = 200;
            bar2 = 150;
            bar3 = 100;
        } else if(value == 3) {
            bar1 = 200;
            bar2 = 100;
            bar3 = 150;
        } else if(value == 4) {
            bar1 = 150;
            bar2 = 100;
            bar3 = 200;
        } else {
            bar1 = 150;
            bar2 = 200;
            bar3 = 100;
        }
        return (bar1.toString(), bar2.toString(), bar3.toString());
    }

    function buildImage(uint256 _tokenId) private view returns(string memory) {
        (string memory bar1, string memory bar2, string memory bar3) = getHeight();
        Block memory currentBlock = blocks[_tokenId];
        uint256 blockStyle = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, totalSupply()))) % 2;
        string memory base64String;

        if(blockStyle == 0) {
            base64String = Base64.encode(bytes(
                abi.encodePacked(
                    '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
                        '<rect x="0" y="0" height="500" width="500" fill="#000000"/>',
                        '<rect height="',bar1,'" width="70" y="200" x="130" fill="hsl(',currentBlock.bar1Hue,', 80%, 50%)"/>',
                        '<rect height="',bar2,'" width="70" y="175" x="215.25" fill="hsl(',currentBlock.bar2Hue,', 70%, 60%)"/>',
                        '<rect height="',bar3,'" width="70" y="150" x="300" fill="hsl(',currentBlock.bar3Hue,', 75%, 75%)"/>',
                    '</svg>'
                )
            ));
        } else {
            base64String = Base64.encode(bytes(
                abi.encodePacked(
                    '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg">',
                        '<rect height="500" width="500" y="0" x="0" fill="#000000"/>',
                        '<rect fill="hsl(',currentBlock.bar1Hue,', 80%, 50%)" x="200" y="300" width="',bar1,'" height="70"/>',
                        '<rect fill="hsl(',currentBlock.bar2Hue,', 70%, 60%)" x="175" y="215.25" width="',bar2,'" height="70"/>',
                        '<rect fill="hsl(',currentBlock.bar3Hue,', 75%, 75%)" x="150" y="130" width="',bar3,'" height="70"/>',
                    '</svg>'
                )
            ));
        }
        return base64String;
    }

    function buildMetadata(uint256 _tokenId) private view returns(string memory) {
        Block memory currentBlock = blocks[_tokenId];
        return string(abi.encodePacked(
            'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                '{"name":"',
                currentBlock.name,
                '", "description":"',
                currentBlock.description,
                '", "image":"',
                'data:image/svg+xml;base64,',
                buildImage(_tokenId),
                '"}'
            )))
        ));
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for non-existent token");
        return buildMetadata(_tokenId);
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Withdrawal failed");
    }

    receive() external payable {}
}