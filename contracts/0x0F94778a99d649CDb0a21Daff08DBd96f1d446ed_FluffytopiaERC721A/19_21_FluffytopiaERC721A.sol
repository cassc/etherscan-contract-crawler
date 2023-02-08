// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Fluffytopia ERC721A

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC721A.sol";

contract FluffytopiaERC721A is
    ERC721A,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer,
    PaymentSplitter
{
    using Strings for uint;

    enum Step {
        Before,
        ClaimSale,
        WhitelistSale,
        WhitelistDutchSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    uint private constant MAX_SUPPLY = 5000;
    uint private constant maxPerAddressWl = 1;
    uint private constant maxPerAddressPublic = 2;

    uint public saleStartTime = 1675882800; // Feb 08 2023 19:00:00
    uint private DUTCH_AUCTION_PRICE_START = 1 ether;
    uint private DUTCH_AUCTION_PRICE_END = 0.15 ether;
    uint private DUTCH_AUCTION_DURATION = 60 minutes;
    uint private DUTCH_AUCTION_DROP_INTERVAL = 10 minutes;
    uint private DUTCH_AUCTION_DROP_PER_STEP =
        (DUTCH_AUCTION_PRICE_START - DUTCH_AUCTION_PRICE_END) /
            (DUTCH_AUCTION_DURATION / DUTCH_AUCTION_DROP_INTERVAL);

    uint public wlSalePrice = 50000000000000000; // 0.05 ETH
    uint public publicSalePrice = 80000000000000000; // 0.08 ETH

    IERC721 public fluffContract;

    mapping(uint256 => bool) public claimInfo;
    mapping(uint256 => address) public claimInfoAddress;
    mapping(address => uint) public amountNFTsperWalletWl;
    mapping(address => uint) public amountNFTsperWalletPublic;

    Step public sellingStep;
    bytes32 public merkleRoot;
    string public baseURI;
    string public baseCollectionURI;
    uint private teamLength;

    constructor(
        address[] memory _team,
        uint[] memory _teamShares,
        bytes32 _merkleRoot,
        string memory _baseURI,
        string memory _baseCollectionURI,
        address _fluffContract
    ) ERC721A("Fluffytopia", "TOPIA") PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        baseCollectionURI = _baseCollectionURI;
        teamLength = _team.length;
        fluffContract = IERC721(_fluffContract);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setWlSalePrice(uint _wlSalePrice) external onlyOwner {
        wlSalePrice = _wlSalePrice;
    }

    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setDutchAuctionPriceStart(
        uint _dutchAuctionPriceStart
    ) external onlyOwner {
        DUTCH_AUCTION_PRICE_START = _dutchAuctionPriceStart;
    }

    function setDutchAuctionPriceEnd(
        uint _dutchAuctionPriceEnd
    ) external onlyOwner {
        DUTCH_AUCTION_PRICE_END = _dutchAuctionPriceEnd;
    }

    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function giftMany(address[] calldata _to) external onlyOwner {
        require(totalSupply() + _to.length <= MAX_SUPPLY, "Reached max supply");
        for (uint i = 0; i < _to.length; i++) {
            _safeMint(_to[i], 1);
        }
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(_to, _quantity);
    }

    function claimLand(
        uint256[] calldata _fluffToken
    ) external payable callerIsUser {
        require(sellingStep == Step.ClaimSale, "Claim sale is not activated");
        require(
            _fluffToken.length >= 3,
            "Need to add min 3 Fluff to claim free land"
        );
        require(
            totalSupply() + uint256(_fluffToken.length) / 3 <= MAX_SUPPLY,
            "Max supply exceeded"
        );
        require(
            fluffContract.balanceOf(msg.sender) >= 3,
            "Need to hold 3 Fluff to claim free land"
        );
        for (uint i = 0; i < _fluffToken.length; i++) {
            require(
                msg.sender == fluffContract.ownerOf(_fluffToken[i]),
                "Message sender must be the Fluff owner."
            );
            require(!claimInfo[_fluffToken[i]], "Token already claimed");
            claimInfo[_fluffToken[i]] = true;
            claimInfoAddress[_fluffToken[i]] = msg.sender;
        }

        _safeMint(msg.sender, uint256(_fluffToken.length) / 3);
    }

    function whitelistMint(
        address _account,
        uint _quantity,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        require(
            sellingStep == Step.WhitelistSale,
            "Whitelist sale is not activated"
        );
        uint price = wlSalePrice;
        require(price != 0, "Price is 0");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(msg.value >= price * _quantity, "Not enought funds");
        require(
            amountNFTsperWalletWl[msg.sender] + _quantity <= maxPerAddressWl,
            "You can only get 1 NFT on the Whitelist Sale"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        amountNFTsperWalletWl[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function whitelistMintDutch(
        address _account,
        uint _quantity,
        bytes32[] calldata _proof
    ) external payable callerIsUser {
        require(
            sellingStep == Step.WhitelistDutchSale,
            "Whitelist dutch sale is not activated"
        );
        uint price = getPresalePrice();
        require(
            currentTime() >= saleStartTime,
            "Whitelist dutch sale has not started yet"
        );
        require(
            currentTime() < saleStartTime + DUTCH_AUCTION_DURATION,
            "Whitelist dutch sale is finished"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(
            amountNFTsperWalletWl[msg.sender] + _quantity <= maxPerAddressWl,
            "You can only get 1 NFT on the Whitelist Sale"
        );
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletWl[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function currentTime() internal view returns (uint) {
        return block.timestamp;
    }

    function getPresalePrice() public view returns (uint) {
        if (currentTime() < saleStartTime) {
            return DUTCH_AUCTION_PRICE_START;
        }

        if (currentTime() - saleStartTime >= DUTCH_AUCTION_DURATION) {
            return DUTCH_AUCTION_PRICE_END;
        } else {
            uint256 intervalCount = (currentTime() - saleStartTime) /
                DUTCH_AUCTION_DROP_INTERVAL;
            return
                DUTCH_AUCTION_PRICE_START -
                (intervalCount * DUTCH_AUCTION_DROP_PER_STEP);
        }
    }

    function publicSaleMint(
        address _account,
        uint _quantity
    ) external payable callerIsUser {
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(
            amountNFTsperWalletPublic[msg.sender] + _quantity <=
                maxPerAddressPublic,
            "You can only get 1 NFT on the Public Sale"
        );
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletPublic[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function tokenURI(
        uint _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setCollectionBaseUri(
        string memory _baseCollectionURI
    ) external onlyOwner {
        baseCollectionURI = _baseCollectionURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhiteListed(
        address _account,
        bytes32[] calldata _proof
    ) internal view returns (bool) {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(
        bytes32 _leaf,
        bytes32[] memory _proof
    ) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function releaseAll() external onlyOwner {
        for (uint i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return baseCollectionURI;
    }

    function fluffIsClaim(
        uint256 tokenId
    ) external view returns (bool isClaim, address claimerAddress) {
        isClaim = claimInfo[tokenId];
        claimerAddress = claimInfoAddress[tokenId];
    }

    receive() external payable override {
        revert("Only if you mint");
    }
}