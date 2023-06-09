// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Abstractars is ERC721A, Ownable {
    string private _name = "Abstractars";
    string private _symbol = "ABS";
    uint256 private _maxBatchSize = 10;

    string private _customBaseUri =
        "https://assets.chromaworld.io/abstractars/metadata/";
    string private _contractUri =
        "https://assets.chromaworld.io/abstractars/metadata/contract.json";

    uint256 public maxSupply = 9001;
    bytes32 public earlySale1MerkleRoot;
    bytes32 public earlySale2MerkleRoot;

    mapping(uint256 => uint256) public mintablePerAddressPerSale;

    mapping(address => uint256) public sale1NumMinted;
    mapping(address => uint256) public sale2NumMinted;
    mapping(address => uint256) public publicNumMinted;

    uint256 public sale1PriceWei;
    uint256 public sale2PriceWei;
    uint256 public publicPriceWei;

    // Sale state:
    // 0: Closed
    // 1: Early Sale 1
    // 2: Early Sale 2
    // 3: Open to Public
    uint256 public saleState = 0;

    constructor() public ERC721A(_name, _symbol, _maxBatchSize) {
        mintablePerAddressPerSale[1] = 1;
        mintablePerAddressPerSale[2] = 1;
        mintablePerAddressPerSale[3] = maxSupply;
    }

    function mint(uint256 amount, bytes32[] calldata merkleProof)
        public
        payable
    {
        require(saleState > 0, "Sale is not open");
        require(
            totalSupply() + amount <= maxSupply,
            "minting would exceed max supply"
        );

        uint256 priceWei;
        if (saleState == 1) {
            /**
             * Early Sale 1
             */
            sale1NumMinted[msg.sender] = sale1NumMinted[msg.sender] + amount;
            require(
                sale1NumMinted[msg.sender] <= mintablePerAddressPerSale[1],
                "Trying to mint too many for this sale phase"
            );
            verifyMerkle(msg.sender, merkleProof, 1);
            priceWei = sale1PriceWei;
        } else if (saleState == 2) {
            /**
             * Early Sale 2
             */
            sale2NumMinted[msg.sender] = sale2NumMinted[msg.sender] + amount;
            require(
                sale2NumMinted[msg.sender] <= mintablePerAddressPerSale[2],
                "Trying to mint too many for this sale phase"
            );
            verifyMerkle(msg.sender, merkleProof, 2);
            priceWei = sale2PriceWei;
        } else {
            /**
             * Public
             */
            publicNumMinted[msg.sender] = publicNumMinted[msg.sender] + amount;
            require(
                publicNumMinted[msg.sender] <= mintablePerAddressPerSale[3],
                "Trying to mint too many for this sale phase"
            );
            priceWei = publicPriceWei;
        }

        checkPayment(priceWei, amount);
        _safeMint(msg.sender, amount);
    }

    function checkPayment(uint256 priceWei, uint256 numMinted) internal {
        uint256 amountRequired = priceWei * numMinted;
        require(msg.value >= amountRequired, "Not enough funds sent");
    }

    function verifyMerkle(
        address addr,
        bytes32[] calldata proof,
        uint256 saleNum
    ) internal view {
        require(
            isOnWhitelist(addr, proof, saleNum),
            "User is not on whitelist for this sale"
        );
    }

    function isOnWhitelist(
        address addr,
        bytes32[] calldata proof,
        uint256 saleNum
    ) public view returns (bool) {
        bytes32 root;
        if (saleNum == 1) {
            root = earlySale1MerkleRoot;
        } else if (saleNum == 2) {
            root = earlySale2MerkleRoot;
        } else {
            revert("Invalid whitelistType, must be 1 or 2");
        }
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, root, leaf);
    }

    function ownerMint(uint256 numToMint) public onlyOwner {
        require(
            totalSupply() + numToMint <= maxSupply,
            "minting would exceed max supply"
        );
        _safeMint(msg.sender, numToMint);
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
        if (saleNum == 1) {
            earlySale1MerkleRoot = newMerkle;
        } else if (saleNum == 2) {
            earlySale2MerkleRoot = newMerkle;
        }
    }

    function setSalePrice(uint256 saleNum, uint256 newPriceWei)
        public
        onlyOwner
    {
        if (saleNum == 0) {
            // saleNum 0 sets same price for all.
            sale1PriceWei = newPriceWei;
            sale2PriceWei = newPriceWei;
            publicPriceWei = newPriceWei;
        } else if (saleNum == 1) {
            sale1PriceWei = newPriceWei;
        } else if (saleNum == 2) {
            sale2PriceWei = newPriceWei;
        } else if (saleNum == 3) {
            publicPriceWei = newPriceWei;
        }
    }

    function setMintablePerAddress(uint256 saleNum, uint256 numMintable)
        public
        onlyOwner
    {
        mintablePerAddressPerSale[saleNum] = numMintable;
    }

    function setSaleState(uint256 newState) public onlyOwner {
        require(newState >= 0 && newState <= 3, "Invalid state");
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

    function decreaseMaxSupply(uint256 newMax) public onlyOwner {
        // Owner can decrease max supply only (not increase). This cannot affect already-minted NFTs.
        require(newMax < maxSupply, "Can only decrease max supply");
        maxSupply = newMax;
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