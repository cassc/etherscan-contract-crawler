// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract WhoGonWinNft is ERC721A, Ownable, ReentrancyGuard {

    uint public immutable maxSupply = 3200;

    bool public buyBackEnabled = false;
    string public baseURI = 'https://arweave.net/3aoWGe7ys-6K3iAJaz_faclKaB6LfKpLu4IrBtg6W6E/';
    bytes32 public merkleRoot;

    uint public preSaleFreeMintCount = 0;
    uint public preSaleMintCost = 0 ether;
    uint public preSaleMintLimit = 1;
    uint public preSaleOpenTimestamp = 1669813200;

    uint public publicSaleFreeMintCount = 0;
    uint public publicSaleMintCost = 0.01 ether;
    uint public publicSaleMintLimit = 1;
    uint public publicSaleOpenTimestamp = 1668952800;
    uint public publicSaleCloseTimestamp = 1669816800;

    mapping(address => uint) public preSaleMintCountMap;
    mapping(address => uint) public publicSaleMintCountMap;

    constructor() ERC721A('WhoGonWinNft', 'WhoGonWinNft') {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function updateBuyBackEnabled(bool buyBackEnabled_) public onlyOwner {
        buyBackEnabled = buyBackEnabled_;
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function configPublicSale(uint publicSaleFreeMintCount_, uint publicSaleMintCost_, uint publicSaleMintLimit_, uint publicSaleOpenTimestamp_, uint publicSaleCloseTimestamp_) public onlyOwner {
        require(publicSaleOpenTimestamp_ >= preSaleOpenTimestamp, 'Invalid publicSaleOpenTimestamp_ input');
        publicSaleFreeMintCount = publicSaleFreeMintCount_;
        publicSaleMintCost = publicSaleMintCost_;
        publicSaleMintLimit = publicSaleMintLimit_;
        publicSaleOpenTimestamp = publicSaleOpenTimestamp_;
        publicSaleCloseTimestamp = publicSaleCloseTimestamp_;
    }

    function configPreSale(uint preSaleFreeMintCount_, uint preSaleMintCost_, uint preSaleMintLimit_, uint preSaleOpenTimestamp_) public onlyOwner {
        require(publicSaleOpenTimestamp >= preSaleOpenTimestamp_, 'Invalid preSaleOpenTimestamp_ input');
        preSaleFreeMintCount = preSaleFreeMintCount_;
        preSaleMintCost = preSaleMintCost_;
        preSaleMintLimit = preSaleMintLimit_;
        preSaleOpenTimestamp = preSaleOpenTimestamp_;
    }

    function getHoldingTokenIds(address msgSender) public view returns (uint[] memory _tokenIds) {
        uint j = 0;
        _tokenIds = new uint[](balanceOf(msgSender));
        for (uint i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == msgSender) {
                _tokenIds[j++] = i;
            }
        }
    }

    function currentMintLimit() public view returns (uint) {
        uint blockTimestamp = block.timestamp;
        if (blockTimestamp >= publicSaleOpenTimestamp) {
            return publicSaleMintLimit;
        } else {
            return preSaleMintLimit;
        }
    }

    function calculateRemainMintLimit(address addr, bytes32[] calldata merkleProof) public view returns (uint) {
        uint blockTimestamp = block.timestamp;
        if (blockTimestamp >= publicSaleOpenTimestamp) {
            return publicSaleMintLimit - publicSaleMintCountMap[addr];
        } else {
            return preSaleMintLimit - preSaleMintCountMap[addr];
        }
    }

    function isInPreSaleList(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    function calculateCost(address addr, uint mintCount) public view returns (uint) {
        uint blockTimestamp = block.timestamp;
        if (blockTimestamp >= publicSaleOpenTimestamp) {
            if (publicSaleFreeMintCount > publicSaleMintCountMap[addr]) {
                uint remainFreeMintCount = publicSaleFreeMintCount - publicSaleMintCountMap[addr];
                if (remainFreeMintCount >= mintCount) {
                    return 0;
                } else {
                    return (mintCount - remainFreeMintCount) * publicSaleMintCost;
                }
            } else {
                return mintCount * publicSaleMintCost;
            }
        } else {
            if (preSaleFreeMintCount > preSaleMintCountMap[addr]) {
                uint remainFreeMintCount = preSaleFreeMintCount - preSaleMintCountMap[addr];
                if (remainFreeMintCount >= mintCount) {
                    return 0;
                } else {
                    return (mintCount - remainFreeMintCount) * preSaleMintCost;
                }
            } else {
                return mintCount * preSaleMintCost;
            }
        }
    }

    function checkCanMint(address addr, bytes32[] calldata merkleProof, uint mintCount) public view {
        uint blockTimestamp = block.timestamp;
        require(blockTimestamp >= preSaleOpenTimestamp, 'Public-Sale/Pre-Sale is not open yet');
        require(publicSaleCloseTimestamp >= blockTimestamp, 'All-Sale is closed now');
        require(maxSupply >= totalSupply() + mintCount, 'Max supply for mint met');

        if (blockTimestamp >= publicSaleOpenTimestamp) {
            require(publicSaleMintLimit >= publicSaleMintCountMap[addr] + mintCount, 'Max mints per wallet met');
        } else {
            require(isInPreSaleList(addr, merkleProof), 'Address is not in white list');
            require(preSaleMintLimit >= preSaleMintCountMap[addr] + mintCount, 'Max mints per wallet met');
        }
        require(address(addr).balance > calculateCost(addr, mintCount), 'Address balance not enough');
    }

    function mint(bytes32[] calldata merkleProof, uint mintCount) external payable {
        address msgSender = _msgSender();
        uint expectedCost = calculateCost(msgSender, mintCount);

        checkCanMint(msgSender, merkleProof, mintCount);
        require(tx.origin == msgSender, 'Only EOA');
        require(msg.value >= expectedCost, 'Insufficient funds');

        bool isPublicSale = block.timestamp >= publicSaleOpenTimestamp;
        _doMint(msgSender, mintCount);

        if (isPublicSale) {
            publicSaleMintCountMap[msgSender] += mintCount;
        } else {
            preSaleMintCountMap[msgSender] += mintCount;
        }
    }

    function airdrop(address[] memory toAddresses, uint[] memory mintCounts) public onlyOwner {
        for (uint i = 0; i < toAddresses.length; i++) {
            _doMint(toAddresses[i], mintCounts[i]);
        }
    }

    function _doMint(address to, uint mintCount) private {
        require(maxSupply > totalSupply() + mintCount, 'Max supply exceeded');
        require(to != address(0), 'Cannot have a non-address as reserve');
        _safeMint(to, mintCount);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}('');
        require(os);
    }
}