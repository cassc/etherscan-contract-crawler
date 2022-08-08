// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract PrayersNFT is ERC721A, Ownable, ReentrancyGuard {

    uint public immutable maxSupply = 4009;
    string public baseURI = 'https://static-resource.buddhanft.xyz/metadata/';

    bytes32 public merkleRoot;

    uint private offset = 0;
    uint public whiteListSaleOpenTimestamp = 1659873600 - offset;
    uint public publicSaleOpenTimestamp = 1659916800 - offset;

    uint public freeMintQuantity = 1;
    uint public mintLimit = 2;
    uint public cost = 5000000000000000; // 0.005

    mapping(address => uint[]) public mintTokenIdsMap;

    constructor() ERC721A('PrayersNFT', 'PrayersNFT') {
    }

    function updateSaleOpenTimestamp(uint whiteListSaleOpenTimestamp_, uint publicSaleOpenTimestamp_) public onlyOwner {
        whiteListSaleOpenTimestamp = whiteListSaleOpenTimestamp_;
        publicSaleOpenTimestamp = publicSaleOpenTimestamp_;
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateFreeMintQuantity(uint freeMintQuantity_) public onlyOwner {
        freeMintQuantity = freeMintQuantity_;
    }

    function updateMintLimit(uint mintLimit_) public onlyOwner {
        mintLimit = mintLimit_;
    }

    function updateCost(uint cost_) public onlyOwner {
        cost = cost_;
    }

    function updateMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function calculateCost(address addr, uint quantity) public view returns (uint) {
        if (freeMintQuantity > mintTokenIdsMap[addr].length) {
            uint remainFreeMintQuantity = freeMintQuantity - mintTokenIdsMap[addr].length;
            if (remainFreeMintQuantity >= quantity) {
                return 0;
            } else {
                return (quantity - remainFreeMintQuantity) * cost;
            }
        } else {
            return quantity * cost;
        }
    }

    function getMintTokenIds(address addr) public view returns (uint[] memory _tokenIds) {
        _tokenIds = mintTokenIdsMap[addr];
    }

    function isInWhiteList(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function checkCanMint(address addr, bytes32[] calldata merkleProof) public view {
        uint blockTimestamp = block.timestamp;
        if (isInWhiteList(addr, merkleProof)) {
            require(blockTimestamp >= whiteListSaleOpenTimestamp && blockTimestamp < publicSaleOpenTimestamp, 'WhiteList-Sale is not open!');
        } else {
            require(blockTimestamp > publicSaleOpenTimestamp, 'Public-Sale is not open!');
        }
    }

    function mint(uint quantity, bytes32[] calldata merkleProof) external payable {
        address msgSender = _msgSender();

        checkCanMint(msgSender, merkleProof);
        require(quantity > 0, 'Invalid quantity');
        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= calculateCost(msgSender, quantity), 'Insufficient funds');
        require(mintTokenIdsMap[msgSender].length + quantity <= mintLimit, 'Max mints per wallet met');

        _doMint(msgSender, quantity);
        for (uint i = 0; i < quantity; i++) {
            mintTokenIdsMap[msgSender].push(totalSupply() - quantity + i);
        }
    }

    function airdrop(address[] memory toAddrs, uint[] memory mintCounts) public onlyOwner {
        for (uint i = 0; i < toAddrs.length; i++) {
            _doMint(toAddrs[i], mintCounts[i]);
        }
    }

    function _doMint(address to, uint quantity) private {
        require(totalSupply() + quantity <= maxSupply, 'Max supply exceeded');
        require(to != address(0), 'Cannot have a non-address as reserve');
        _safeMint(to, quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        uint balance = address(this).balance;
        uint toDev = balance * 3 / 10;
        uint toOwner = balance - toDev;
        address dev = 0x865885e3eDA815fbf75874C8BCe533C41E6D826d;

        (bool os1,) = payable(dev).call{value : toDev}('');
        require(os1);
        (bool os2,) = payable(owner()).call{value : toOwner}('');
        require(os2);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}