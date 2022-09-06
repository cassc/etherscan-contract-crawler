pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";


contract KokoroClubNFT is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxSupply;
    address public immutable devAddress;

    struct SaleConfig {
        uint32 whitelistMintStartTime;
        uint32 publicSaleStartTime;
        uint64 whitelistPrice;
        uint64 publicPrice;
        uint64 maxPerAddressDuringMint;
        uint64 nowMaxSupply;
    }

    SaleConfig public saleConfig;
    mapping(address => uint64) public addressMintedCnt;
    mapping(address => uint64) public whitelistAddressMintedCnt;
    bytes32 public whitelistMerkleRoot;

    constructor(
        uint256 maxSupply_,
        address devAddress_
    ) ERC721A("Kokoro Club NFT", "KCN") {
        maxSupply = maxSupply_;
        devAddress = devAddress_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    function whitelistMint(bytes32[] calldata merkleProof, uint256 quantity) external payable callerIsUser 
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
    {
        SaleConfig memory config = saleConfig;
        uint256 whitelistPrice = uint256(config.whitelistPrice);
        uint256 whitelistMintStartTime = uint256(config.whitelistMintStartTime);
        uint256 maxPerAddressDuringMint = uint256(config.maxPerAddressDuringMint);
        uint256 nowMaxSupply = uint256(config.nowMaxSupply);
        require(
          isMintOn(whitelistPrice, whitelistMintStartTime),
          "whitelist mint has not begun yet"
        );
        if (maxPerAddressDuringMint > 0) {
            require(whitelistAddressMintedCnt[msg.sender] + quantity <= maxPerAddressDuringMint, "reached max mint cnt");
        }
        whitelistAddressMintedCnt[msg.sender] = whitelistAddressMintedCnt[msg.sender] + uint64(quantity);
        require(totalSupply() + quantity <= nowMaxSupply, "reached max supply");
        _safeMint(msg.sender, quantity);
        refundIfOver(whitelistPrice * quantity);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        uint256 maxPerAddressDuringMint = uint256(config.maxPerAddressDuringMint);
        uint256 nowMaxSupply = uint256(config.nowMaxSupply);
        require(
          isMintOn(publicPrice, publicSaleStartTime),
          "public sale has not begun yet"
        );
        if (maxPerAddressDuringMint > 0) {
            require(addressMintedCnt[msg.sender] + quantity <= maxPerAddressDuringMint, "reached max mint cnt");
        }
        addressMintedCnt[msg.sender] = addressMintedCnt[msg.sender] + uint64(quantity);
        require(totalSupply() + quantity <= nowMaxSupply, "reached max supply");
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }


    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function isMintOn(
        uint256 priceWei,
        uint256 mintStartTime
    ) public view returns (bool) {
        return
            priceWei != 0 &&
            block.timestamp >= mintStartTime;
    }

    function setSaleConfig(
        uint32 whitelistMintStartTime,
        uint32 publicSaleStartTime,
        uint64 whitelistPriceWei,
        uint64 publicPriceWei,
        uint64 maxPerAddressDuringMint,
        uint64 nowMaxSupply
    ) external onlyOwner {
        require(nowMaxSupply <= maxSupply, "Require nowMaxSupply <= maxSupply");
        saleConfig = SaleConfig(
          whitelistMintStartTime,
          publicSaleStartTime,
          whitelistPriceWei,
          publicPriceWei,
          maxPerAddressDuringMint,
          nowMaxSupply
        );
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    // metadata URI
    string private _baseTokenURI;
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        uint256 remainBalance = address(this).balance;
        uint256 devFee = remainBalance/5;
        remainBalance = remainBalance - devFee;
        (bool success, ) = devAddress.call{value: devFee}("");
        require(success, "Transfer to dev failed.");
        (success, ) = msg.sender.call{value: remainBalance}("");
        require(success, "Transfer to owner failed.");
    }
}