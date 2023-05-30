// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HealingCodes is ERC721A, Ownable {
    string private _name = "HealingCodes";
    string private _symbol = "HCS";
    uint256 private _maxBatchSize = 5;

    uint public amountMinted = 0;

    string private _customBaseUri =
        "https://assets.healingcodes.io/healingcodes/metadata/";
    string private _contractUri =
        "https://assets.healingcodes.io/healingcodes/metadata/contract.json";

    uint256 public MAX_SUPPLY = 4850;
    bytes32 public clMerkleRoot;

    uint public maxPreMint = 1;

    mapping(address => uint256) public numMintedByAddress;

    uint256 public priceWei = 0.0888 ether;

    // Sale state:
    // 0: Closed
    // 1: Early Mint 
    // 2: Open to Public
    uint256 public saleState = 0;

    constructor() ERC721A(_name, _symbol, _maxBatchSize) {}

    function mint(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public payable {
        require(saleState > 0, "Sale is not open");
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "minting would exceed max supply"
        );

        if (saleState == 1) {
            verifyMerkle(msg.sender, merkleProof);
            checkPayment(amount);
            numMintedByAddress[msg.sender] =
                numMintedByAddress[msg.sender] +
                amount;
            require(
                numMintedByAddress[msg.sender] <= maxPreMint,
                "Trying to mint too many total"
            );
        } else {
            checkPayment(amount);
        }

        _safeMint(msg.sender, amount);
        amountMinted = amountMinted + amount;
    }

    function checkPayment(uint256 numMinted) internal {
        uint256 amountRequired = priceWei * numMinted;
        require(msg.value >= amountRequired, "Not enough funds sent");
    }

    function verifyMerkle(
        address addr, 
        bytes32[] calldata proof
    ) internal view {
        require(
            isOnWhitelist(addr, proof), 
            "User is not on whitelist"
        );
    }

    function isOnWhitelist(
        address addr, 
        bytes32[] calldata proof
    ) public view returns (bool) {
        bytes32 root;
        root = clMerkleRoot;
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

    function setMerkleRoot(bytes32 newMerkle)
        public
        onlyOwner
    {
        clMerkleRoot = newMerkle;
    }

    function setSalePrice(uint256 newPriceWei) public onlyOwner {
        priceWei = newPriceWei;
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