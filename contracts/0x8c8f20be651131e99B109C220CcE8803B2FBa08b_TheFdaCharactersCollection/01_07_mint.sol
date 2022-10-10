// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract TheFdaCharactersCollection is ERC721A, Ownable, ReentrancyGuard {

    uint public immutable maxSupply = 6000;
    uint public immutable reserveForBurn = 800;
    IERC721A public immutable fdaFoodCollection;
    address public immutable deadAddr = 0x000000000000000000000000000000000000dEaD;

    string public baseURI = 'https://arweave.net/7eM10uiSluNS-apjwEjyK-ls7MfIqn4RuCLh-et5XlA/';
    bytes32 public merkleRoot;

    uint public whiteListSaleFreeMintCount = 1;
    uint public whiteListSaleMintCost = 0.005 ether;
    uint public whiteListSaleMintLimit = 3;
    uint public whiteListSaleOpenTimestamp = 1665320400;

    uint public publicSaleFreeMintCount = 1;
    uint public publicSaleMintCost = 0.008 ether;
    uint public publicSaleMintLimit = 3;
    uint public publicSaleOpenTimestamp = 1665322200;
    uint public publicSaleCloseTimestamp = 1665329400;

    uint public burnFactor = 10;

    mapping(address => uint) public whiteListSaleMintCountMap;
    mapping(address => uint) public publicSaleMintCountMap;

    constructor() ERC721A('TheFdaCharactersCollection', 'TheFdaCharactersCollection') {
        fdaFoodCollection = IERC721A(0xd82c9290A240eB90d26bc7facb5518cfCdAacb6b);
    }

    function updateBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function updateMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function configPublicSale(uint publicSaleFreeMintCount_, uint publicSaleMintCost_, uint publicSaleMintLimit_, uint publicSaleOpenTimestamp_, uint publicSaleCloseTimestamp_) public onlyOwner {
        require(publicSaleOpenTimestamp_ >= whiteListSaleOpenTimestamp, 'Invalid publicSaleOpenTimestamp_ input');
        publicSaleFreeMintCount = publicSaleFreeMintCount_;
        publicSaleMintCost = publicSaleMintCost_;
        publicSaleMintLimit = publicSaleMintLimit_;
        publicSaleOpenTimestamp = publicSaleOpenTimestamp_;
        publicSaleCloseTimestamp = publicSaleCloseTimestamp_;
    }

    function configWhiteListSale(uint whiteListSaleFreeMintCount_, uint whiteListSaleMintCost_, uint whiteListSaleMintLimit_, uint whiteListSaleOpenTimestamp_) public onlyOwner {
        require(publicSaleOpenTimestamp >= whiteListSaleOpenTimestamp_, 'Invalid whiteListSaleOpenTimestamp_ input');
        whiteListSaleFreeMintCount = whiteListSaleFreeMintCount_;
        whiteListSaleMintCost = whiteListSaleMintCost_;
        whiteListSaleMintLimit = whiteListSaleMintLimit_;
        whiteListSaleOpenTimestamp = whiteListSaleOpenTimestamp_;
    }

    function configBurnFactor(uint burnFactor_) public onlyOwner {
        burnFactor = burnFactor_;
    }

    function currentMintLimit() public view returns (uint) {
        uint blockTimestamp = block.timestamp;
        if (blockTimestamp >= publicSaleOpenTimestamp) {
            return publicSaleMintLimit;
        } else {
            return whiteListSaleMintLimit;
        }
    }

    function calculateRemainMintLimit(address addr, bytes32[] calldata merkleProof) public view returns (uint) {
        uint blockTimestamp = block.timestamp;
        if (blockTimestamp >= publicSaleOpenTimestamp) {
            return publicSaleMintLimit - publicSaleMintCountMap[addr];
        } else {
            return whiteListSaleMintLimit - whiteListSaleMintCountMap[addr];
        }
    }

    function isInWhiteList(address addr, bytes32[] calldata merkleProof) public view returns (bool) {
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
            if (whiteListSaleFreeMintCount > whiteListSaleMintCountMap[addr]) {
                uint remainFreeMintCount = whiteListSaleFreeMintCount - whiteListSaleMintCountMap[addr];
                if (remainFreeMintCount >= mintCount) {
                    return 0;
                } else {
                    return (mintCount - remainFreeMintCount) * whiteListSaleMintCost;
                }
            } else {
                return mintCount * whiteListSaleMintCost;
            }
        }
    }

    function checkCanMint(address addr, bytes32[] calldata merkleProof, uint mintCount) public view {
        uint blockTimestamp = block.timestamp;
        require(blockTimestamp >= whiteListSaleOpenTimestamp, 'Public-Sale/WhiteList-Sale is not open yet');
        require(publicSaleCloseTimestamp >= blockTimestamp, 'All-Sale is closed now');
        require((maxSupply - reserveForBurn) >= totalSupply() + mintCount, 'Max supply for mint met');

        if (blockTimestamp >= publicSaleOpenTimestamp) {
            require(publicSaleMintLimit > publicSaleMintCountMap[addr] + mintCount, 'Max mints per wallet met');
        } else {
            require(isInWhiteList(addr, merkleProof), 'Address is not in white list');
            require(whiteListSaleMintLimit > whiteListSaleMintCountMap[addr] + mintCount, 'Max mints per wallet met');
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
            whiteListSaleMintCountMap[msgSender] += mintCount;
        }
    }

    function checkCanBurn(address addr) public view {
        require(burnFactor > 0, 'Action-Burn is closed now');
        require(block.timestamp >= publicSaleCloseTimestamp, 'Action-Burn is not open yet');
        require(maxSupply >= totalSupply() + 1, 'Max supply for burn met');

        uint foodCollectionBalance = fdaFoodCollection.balanceOf(addr);
        require(foodCollectionBalance >= burnFactor, 'FdaFoodCollection balance not enough');
    }

    function burnFdaFoodCollections() external {
        address msgSender = _msgSender();
        checkCanBurn(msgSender);

        uint j = 0;
        uint[] memory tokenIds = new uint[](burnFactor);
        for (uint i = 0; i < fdaFoodCollection.totalSupply(); i++) {
            if (fdaFoodCollection.ownerOf(i) == msgSender) {
                tokenIds[j++] = i;
            }
        }

        for (uint i = 0; i < tokenIds.length;) {
            fdaFoodCollection.transferFrom(msgSender, deadAddr, tokenIds[i]);
            unchecked {
                i++;
            }
        }
        _doMint(msgSender, 1);
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}