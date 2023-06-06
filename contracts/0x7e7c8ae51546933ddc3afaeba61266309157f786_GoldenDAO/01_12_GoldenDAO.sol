// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract GoldenDAO is ERC1155, Ownable {
    string public name;
    string public symbol;

    uint256 public constant MAX_SUPPLY = 1_888;
    uint256 public constant RESERVE_COUNT = 112;

    uint256 public constant PRESALE_MAX_SUPPLY = RESERVE_COUNT + 888;
    uint256 public constant PRESALE_PRICE = 0.8 ether;
    uint256 public constant PRESALE_MAX_PER_TX = 2;
    uint256 public constant PRESALE_MAX_MINTS = 2;
    // Mon Mar 28 2022 14:00:00 GMT-0400 (Eastern Daylight Time)
    uint256 public presaleStart = 1_648_490_400;
    // Thu Mar 31 2022 14:00:00 GMT-0400 (Eastern Daylight Time)
    uint256 public presaleEnd = 1_648_749_600;

    uint256 public constant PUBLIC_MAX_PER_TX = 3;
    uint256 public constant PUBLIC_MAX_MINTS = 3;
    // Thu Mar 31 2022 14:00:00 GMT-0400 (Eastern Daylight Time)
    uint256 public publicStart = 1_648_749_600;

    uint256 public constant DUTCH_AUCTION_START_PRICE = 1.28 ether;
    uint256 public constant DUTCH_AUCTION_END_PRICE = 0.88 ether;
    uint256 public constant DUTCH_AUCTION_LENGTH = 2 hours;

    mapping(uint256 => uint256) public totalSupply;
    mapping(address => uint256) public mintsPerAddress;

    bytes32 public merkleRoot;
    address public multiSigWallet;

    constructor(string memory _uri, bytes32 _merkleRoot, address _multiSigWallet) ERC1155(_uri) {
        name = "GoldenDAO";
        symbol = "GD";

        merkleRoot = _merkleRoot;
        multiSigWallet = _multiSigWallet;

        _mint(_multiSigWallet, 0, RESERVE_COUNT, "");
        totalSupply[0] = RESERVE_COUNT;
    }

    function presaleMint(uint256 _count, bytes32[] calldata _merkleProof) external payable {
        require(block.timestamp >= presaleStart && block.timestamp <= presaleEnd, "Sale inactive.");
        require(_count <= PRESALE_MAX_PER_TX, "Max per tx.");

        unchecked {
            require(totalSupply[0] + _count <= PRESALE_MAX_SUPPLY, "Supply exceeded.");
            require(mintsPerAddress[msg.sender] + _count <= PRESALE_MAX_MINTS, "Max per person.");
            require(msg.value >= _count * PRESALE_PRICE, "Insufficient ETH.");
        }

        bytes32 merkleLeaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, merkleLeaf), "Invalid proof.");

        unchecked {
            mintsPerAddress[msg.sender] += _count;
            totalSupply[0] += _count;
        }

        _mint(msg.sender, 0, _count, "");
    }

    function publicMint(uint256 _count) external payable {
        require(block.timestamp >= publicStart, "Sale inactive.");
        require(_count <= PUBLIC_MAX_PER_TX, "Max per tx.");

        unchecked {
            require(totalSupply[0] + _count <= MAX_SUPPLY, "Supply exceeded.");
            require(mintsPerAddress[msg.sender] + _count <= PUBLIC_MAX_MINTS, "Max per person.");
            require(msg.value >= _count * currentPrice(), "Insufficient ETH.");

            mintsPerAddress[msg.sender] += _count;
            totalSupply[0] += _count;
        }

        _mint(msg.sender, 0, _count, "");
    }

    function currentPrice() internal view returns (uint256) {
        if (block.timestamp <= publicStart) return DUTCH_AUCTION_START_PRICE;

        unchecked {
            uint256 timeElapsed = block.timestamp - publicStart;
            if (timeElapsed >= DUTCH_AUCTION_LENGTH) return DUTCH_AUCTION_END_PRICE;

            return DUTCH_AUCTION_START_PRICE - (
                (timeElapsed * (DUTCH_AUCTION_START_PRICE - DUTCH_AUCTION_END_PRICE))
                    / DUTCH_AUCTION_LENGTH
            );
        }
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(totalSupply[_tokenId] > 0, "Nonexistent token");

        return string(abi.encodePacked(super.uri(_tokenId), Strings.toString(_tokenId)));
    }

    function setUri(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPresaleStart(uint256 _presaleStart) external onlyOwner {
        presaleStart = _presaleStart;
    }

    function setPresaleEnd(uint256 _presaleEnd) external onlyOwner {
        presaleEnd = _presaleEnd;
    }

    function setPublicStart(uint256 _publicStart) external onlyOwner {
        publicStart = _publicStart;
    }

    function setMultiSigWallet(address _multiSigWallet) external onlyOwner {
        multiSigWallet = _multiSigWallet;
    }

    function withdraw() external onlyOwner {
        (bool transfer, ) = payable(multiSigWallet).call{value: address(this).balance}("");
        require(transfer);
    }
}