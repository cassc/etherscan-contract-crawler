// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MetaHouseMafia is ERC721A, Ownable {
    string private _name = "MetaHouseMafia";
    string private _symbol = "MHM";
    uint256 private _maxBatchSize = 10;

    uint public amountMinted = 0;

    string private _customBaseUri =
        "https://assets.metahousemafia.io/mafiosi/metadata/";
    string private _contractUri =
        "https://assets.metahousemafia.io/mafiosi/metadata/contract.json";

    uint256 public MAX_SUPPLY = 10000;
    bytes32 public ogMerkleRoot;
    bytes32 public gangMerkleRoot;

    uint public constant OGs = 1;
    uint public constant GANG_MEMBERS = 2;

    uint public maxPreMintForOG = 3;
    uint public maxPreMintForGang = 2;

    mapping(address => uint256) public numMintedByAddress;

    uint256 public publicPriceWei = 0.08 ether;
    uint256 public earlyPriceWei = 0.06 ether;

    // Sale state:
    // 0: Closed
    // 1: Early Mint 
    // 2: Open to Public
    uint256 public saleState = 0;

    constructor() ERC721A(_name, _symbol, _maxBatchSize) {}

    function mint(
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint whitelistType
    ) public payable {
        require(saleState > 0, "Sale is not open");
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "minting would exceed max supply"
        );

        if (saleState == 1) {
            verifyMerkle(msg.sender, merkleProof, whitelistType);
            checkEarlyPayment(amount);
            numMintedByAddress[msg.sender] =
                numMintedByAddress[msg.sender] +
                amount;
            if (whitelistType == OGs) {
                require(
                    numMintedByAddress[msg.sender] <= maxPreMintForOG,
                    "Trying to mint too many total"
                );
            } else {
                require(
                    numMintedByAddress[msg.sender] <= maxPreMintForGang,
                    "Trying to mint too many total"
                );
            }
        } else {
            checkPayment(amount);
        }

        _safeMint(msg.sender, amount);
        amountMinted = amountMinted + amount;
    }

    function checkPayment(uint256 numMinted) internal {
        uint256 amountRequired = publicPriceWei * numMinted;
        require(msg.value >= amountRequired, "Not enough funds sent");
    }

    function checkEarlyPayment(uint256 numMinted) internal {
        uint256 amountRequired = earlyPriceWei * numMinted;
        require(msg.value >= amountRequired, "Not enough funds sent");
    }

    function verifyMerkle(
        address addr, 
        bytes32[] calldata proof, 
        uint whitelistType
    ) internal view {
        require(
            isOnWhitelist(addr, proof, whitelistType), 
            "User is not on whitelist"
        );
    }

    function isOnWhitelist(
        address addr, 
        bytes32[] calldata proof, 
        uint whitelistType
    ) public view returns (bool) {
        bytes32 root;
        if (whitelistType == OGs) {
            root = ogMerkleRoot;
        } else if (whitelistType == GANG_MEMBERS) {
            root = gangMerkleRoot;
        } else {
            revert("Invalid whitelistType, must be 1 or 2");
        }
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, root, leaf);
    }

    function ownerMint(uint256 numToMint) public onlyOwner {
        require(
            totalSupply() + numToMint <= MAX_SUPPLY,
            "minting would exceed max supply"
        );
        _safeMint(msg.sender, numToMint);
        amountMinted = amountMinted + numToMint;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _customBaseUri;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }

    function setMerkleRoot(uint256 saleNum, bytes32 newMerkle)
        public
        onlyOwner
    {
        if (saleNum == OGs) {
            ogMerkleRoot = newMerkle;
        } else if (saleNum == GANG_MEMBERS) {
            gangMerkleRoot = newMerkle;
        }
    }

    function setSalePrice(uint256 newPriceWei) public onlyOwner {
        publicPriceWei = newPriceWei;
    }

    function setEarlyPrice(uint256 newPriceWei) public onlyOwner {
        earlyPriceWei = newPriceWei;
    }

    function setSaleState(uint256 newState) public onlyOwner {
        require(newState >= 0 && newState <= 2, "Invalid state");
        saleState = newState;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string calldata newURI) public onlyOwner {
        _customBaseUri = newURI;
    }

    function setContractUri(string calldata newUri) public onlyOwner {
        _contractUri = newUri;
    }
}

library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return
            address(registry) != address(0) &&
            address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}