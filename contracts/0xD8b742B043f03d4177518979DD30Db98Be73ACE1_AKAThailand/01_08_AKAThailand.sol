//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AKAThailand is ERC721A, Ownable, ReentrancyGuard {
    event SaleStateChange(uint256 _saleState);
    event PriceChange(uint256 _price, uint256 _presalePrice);

    using Strings for uint256;

    bytes32 public merkleRoot;
    uint256 constant public maxTokens = 555;
    uint256 public maxTokensPerWallet = 5;
    uint256 public presalePrice = 0.55 ether;
    uint256 public price = 0.79 ether;

    string private baseURI;
    string public notRevealedJson = "ipfs://bafybeiaeku3gwigcflnlji3w33etdh64cwocfoz2jyxuwqjkfkwuusul5q/";

    bool public rarityRevealed = false;
    bool public revealed = false;

    enum SaleState {
        NOT_ACTIVE,
        PRESALE,
        PUBLIC
    }

    SaleState public saleState = SaleState.NOT_ACTIVE;

    mapping(address => uint256) public mintedPerWallet;

    constructor() ERC721A("AKA Thailand", "AKA") {}

    modifier isValidMerkleProof(
        bytes32[] calldata merkleProof,
        bytes32 root,
        uint256 _maxAmount
    ) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender, _maxAmount.toString()))
            ),
            "Not whitelisted or incorrect amount"
        );
        _;
    }

    modifier isWithinLimits(uint256 _amount) {
        require(maxTokens >= _amount + totalSupply(), "Not enough tokens left");
        require(
            _amount > 0 &&
                _amount + mintedPerWallet[msg.sender] <= maxTokensPerWallet,
            "Too many tokens per wallet"
        );
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (rarityRevealed || revealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                );
        }
        return string(
                    abi.encodePacked(notRevealedJson, tokenId.toString(), ".json")
                );
    }

    function whitelistMint(
        uint256 _amount,
        uint256 _maxAmount,
        bytes32[] calldata _merkleProof
    )
        external
        payable
        nonReentrant
        isValidMerkleProof(_merkleProof, merkleRoot, _maxAmount)
        isWithinLimits(_amount)
    {
        require(saleState == SaleState.PRESALE, "Presale is not active");
        require(msg.value >= presalePrice * _amount, "Not enough ETH");
        require(
            _amount <= _maxAmount &&
                mintedPerWallet[msg.sender] + _amount <= _maxAmount,
            "Amount exceeds WL spots bought!"
        );
        mintedPerWallet[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function mint(uint256 _amount)
        external
        payable
        nonReentrant
        isWithinLimits(_amount)
    {
        require(saleState == SaleState.PUBLIC, "Public sale is not active");
        require(msg.value >= price * _amount, "Not enough ETH");
        mintedPerWallet[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    // Owner functions
    function airdrop(uint256 _amount, address _recipent) external onlyOwner {
        require(maxTokens >= _amount + totalSupply(), "Not enough tokens left");
        _safeMint(_recipent, _amount);
    }

    function startPresale() external onlyOwner {
        saleState = SaleState.PRESALE;
        emit SaleStateChange(1);
    }

    function startPublicSale() external onlyOwner {
        saleState = SaleState.PUBLIC;
        emit SaleStateChange(2);
    }

    function stopSale() external onlyOwner {
        saleState = SaleState.NOT_ACTIVE;
        emit SaleStateChange(0);
    }

    function setPrice(uint256 _price, uint256 _presalePrice)
        external
        onlyOwner
    {
        price = _price;
        presalePrice = _presalePrice;
        emit PriceChange(_price, _presalePrice);
    }

    function setMaxTokensPerWallet(uint256 _maxTokensPerWallet)
        external
        onlyOwner
    {
        maxTokensPerWallet = _maxTokensPerWallet;
    }

    function setUnrevealedTokenCID(string calldata _ipfsCID)
        external
        onlyOwner
    {
        notRevealedJson = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
    }

    function rarityReveal(string calldata _ipfsCID) external onlyOwner {
        require(!revealed, "Tokens already revealed");
        baseURI = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
        rarityRevealed = true;
    }

    function reveal(string calldata _ipfsCID) external onlyOwner {
        require(!revealed, "Tokens already revealed");
        require(rarityRevealed, "Rarity is not revealed yet!");
        baseURI = string(abi.encodePacked("ipfs://", _ipfsCID, "/"));
        revealed = true;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawBalance() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdrawal failed");
    }

    receive() external payable {}
}