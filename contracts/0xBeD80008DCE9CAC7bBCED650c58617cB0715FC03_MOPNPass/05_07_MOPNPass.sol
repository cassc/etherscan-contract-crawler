// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "./IMOPNPassMetaDataRender.sol";

contract MOPNPass is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 10981;

    address public constant ADDR_TREASURY =
        0x7B7049388A1deDDD43B4184f42b346917141e367;

    bytes32 public whitelistMerkleRoot;

    string public whitelistCID;

    address public mopnPassMetaDataRenderAddress;

    uint256[MAX_SUPPLY] internal indices;

    uint256 internal randomNonce;

    enum PassType {
        REGULAR,
        SILVER,
        GOLD
    }

    struct SaleConfig {
        uint256 preSalePrice;
        uint256 preSaleStartTime;
        uint256 secondSalePrice;
        uint256 secondSaleStartTime;
        uint256 thirdSalePrice;
        uint256 thirdSaleStartTime;
    }

    SaleConfig public saleConfig;

    mapping(uint256 => uint256) public tokenIdToIndex;
    mapping(address => uint256) public whitelistMintedCount;

    event NewWhiteList(bytes32 whitelistMerkleRoot, string whitelistCID);
    event Minted(address indexed sender, uint256 amount, uint256 quantity);

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        _;
    }

    constructor(uint256 preSaleStartTime, uint256 preSalePrice)
        ERC721A("MOPN", "MOPN")
    {
        saleConfig.preSaleStartTime = preSaleStartTime;
        saleConfig.preSalePrice = preSalePrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot, string memory _whitelistCID)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _merkleRoot;
        whitelistCID = _whitelistCID;
        emit NewWhiteList(_merkleRoot, whitelistCID);
    }

    function setPublicSaleConfig(
        uint256 secondSalePrice,
        uint256 secondSaleStartTime,
        uint256 thirdSalePrice,
        uint256 thirdSaleStartTime
    ) external onlyOwner {
        saleConfig.secondSalePrice = secondSalePrice;
        saleConfig.secondSaleStartTime = secondSaleStartTime;
        saleConfig.thirdSalePrice = thirdSalePrice;
        saleConfig.thirdSaleStartTime = thirdSaleStartTime;
    }

    function setRender(address mopnPassMetaDataRenderAddress_)
        external
        onlyOwner
    {
        require(_isContract(mopnPassMetaDataRenderAddress_), "Invalid address");
        mopnPassMetaDataRenderAddress = mopnPassMetaDataRenderAddress_;
    }

    // @dev Returns the starting token ID.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function preSale(
        uint256 quantity,
        uint256 maxQuantity,
        bytes32[] calldata proof
    ) external payable notContract {
        require(
            saleConfig.preSaleStartTime > 0 &&
                block.timestamp >= saleConfig.preSaleStartTime,
            "Presale has not started yet"
        );
        require(totalSupply() + quantity <= 2000, "Reached max supply");
        require(
            whitelistMintedCount[msg.sender] + quantity <= maxQuantity,
            "Reached max quantity"
        );
        require(
            isWhitelisted(msg.sender, maxQuantity, proof),
            "Not a whitelisted address"
        );
        require(
            msg.value == saleConfig.preSalePrice * quantity,
            "Invalid price"
        );
        _mintPass(msg.sender, quantity);
        whitelistMintedCount[msg.sender] += quantity;

        emit Minted(msg.sender, msg.value, quantity);
    }

    function secondSale(uint256 quantity) external payable notContract {
        require(
            saleConfig.secondSaleStartTime > 0 &&
                block.timestamp >= saleConfig.secondSaleStartTime &&
                totalSupply() >= 2000,
            "Second-Sale has not started yet"
        );
        require(totalSupply() + quantity <= 5000, "Reached max supply");
        require(
            msg.value == saleConfig.secondSalePrice * quantity,
            "Invalid price"
        );
        _mintPass(msg.sender, quantity);

        emit Minted(msg.sender, msg.value, quantity);
    }

    function thirdSale(uint256 quantity) external payable notContract {
        require(
            saleConfig.thirdSaleStartTime > 0 &&
                block.timestamp >= saleConfig.thirdSaleStartTime &&
                totalSupply() >= 5000,
            "Third-Sale has not started yet"
        );
        require(
            msg.value == saleConfig.thirdSalePrice * quantity,
            "Invalid price"
        );
        _mintPass(msg.sender, quantity);

        emit Minted(msg.sender, msg.value, quantity);
    }

    function _mintPass(address to, uint256 quantity) internal {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Reached max supply");

        uint256 tokenId = _nextTokenId();

        for (uint256 i = 0; i < quantity; i++) {
            _setTokenIndex(tokenId);
            tokenId++;
        }
        _safeMint(to, quantity);
    }

    function _setTokenIndex(uint256 id) internal {
        require(tokenIdToIndex[id] == 0, "Cannot be set");
        uint256 _index = _randomIndex();
        tokenIdToIndex[id] = _index;
    }

    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory tokenuri)
    {
        require(_exists(id), "not exist");

        if (mopnPassMetaDataRenderAddress != address(0)) {
            IMOPNPassMetaDataRender metaDataRender = IMOPNPassMetaDataRender(
                mopnPassMetaDataRenderAddress
            );
            tokenuri = metaDataRender.constructTokenURI(
                address(this),
                tokenIdToIndex[id]
            );
        }
    }

    function isWhitelisted(
        address account,
        uint256 maxQuantity,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return _verify(_leaf(account, maxQuantity), proof);
    }

    function _leaf(address account, uint256 maxQuantity)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, maxQuantity));
    }

    // Merkle proof
    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function _randomIndex() internal returns (uint256) {
        uint256 totalSize = MAX_SUPPLY - randomNonce;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    randomNonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        randomNonce++;
        // Don't allow a zero index, start counting at 1
        return value + 1;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(ADDR_TREASURY).transfer(amount);
    }
}