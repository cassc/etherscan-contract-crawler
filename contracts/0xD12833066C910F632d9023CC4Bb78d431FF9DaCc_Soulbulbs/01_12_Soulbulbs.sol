// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import './ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract Soulbulbs is ERC721A, Ownable, ReentrancyGuard {
    // Immutable Values
    uint256 public immutable MAX_SUPPLY = 2000;
    uint256 public OWNER_MINT_MAX_SUPPLY = 10;
    uint256 public AIRDROP_MAX_SUPPLY = 100;
    uint256 public WHITELIST_MAX_SUPPLY = 1000;

    string internal baseUri;
    uint256 public mintRate;
    uint256 public maxMintLimit = 3;
    bool public publicMintPaused = true;
    bool public ownerSupplyWentPublic;

    // Whitelist Variables
    using MerkleProof for bytes32[];
    bool public whitelistMintPaused = true;
    uint256 public whitelistMintRate;
    bytes32 public whitelistMerkleRoot;
    uint256 public maxItemsPerWhiteListedWallet = 1;
    mapping(address => uint256) public whitelistMintedAmount;

    mapping(address => uint256) public paymentTokens;

    // Reveal NFT Variables
    bool public revealed;
    string public hiddenBaseUri;

    struct BatchMint {
        address to;
        uint256 amount;
    }

    modifier isValidERC20PaymentTokenAddress(address _tokenAddress) {
        require(paymentTokens[_tokenAddress] > 0, "Can't make payment with this token, please contact support team");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _hiddenBaseUri,
        uint256 _mintRate,
        uint256 _whitelistMintRate,
        bytes32 _whitelistMerkleRoot
    ) ERC721A(_name, _symbol) {
        mintRate = _mintRate;
        hiddenBaseUri = _hiddenBaseUri;
        whitelistMintRate = _whitelistMintRate;
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    // ===== Owner mint in batches =====
    function ownerMintInBatch(BatchMint[] memory batchMint) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < batchMint.length; i++) {
            require(batchMint[i].amount <= OWNER_MINT_MAX_SUPPLY, 'Minting amount exceeds reserved owner supply');
            require((totalSupply() + batchMint[i].amount) <= MAX_SUPPLY, 'Sold out!');
            _safeMint(batchMint[i].to, batchMint[i].amount);
            OWNER_MINT_MAX_SUPPLY = OWNER_MINT_MAX_SUPPLY - batchMint[i].amount;
        }
    }

    // ===== Owner mint in batches =====
    function airdropInBatch(BatchMint[] memory batchMint) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < batchMint.length; i++) {
            require(batchMint[i].amount <= AIRDROP_MAX_SUPPLY, 'Minting amount exceeds reserved airdrop supply');
            require((totalSupply() + batchMint[i].amount) <= MAX_SUPPLY, 'Sold out!');
            _safeMint(batchMint[i].to, batchMint[i].amount);
            AIRDROP_MAX_SUPPLY = AIRDROP_MAX_SUPPLY - batchMint[i].amount;
        }
    }

    function _getMintQuantity(uint256 value, bool _publicMint) internal view returns (uint256) {
        uint256 tempRate = _publicMint == true ? mintRate : whitelistMintRate;
        uint256 remainder = value % tempRate;
        require(remainder == 0, 'Send a divisible amount of eth');
        uint256 quantity = value / tempRate;
        require(quantity > 0, 'quantity to mint is 0');
        if (!ownerSupplyWentPublic) {
            require(
                (totalSupply() + quantity) <=
                    (MAX_SUPPLY - (OWNER_MINT_MAX_SUPPLY + AIRDROP_MAX_SUPPLY + WHITELIST_MAX_SUPPLY)),
                'Not enough NFTs left!'
            );
        } else {
            require(
                (totalSupply() + quantity) <= (MAX_SUPPLY - (AIRDROP_MAX_SUPPLY + WHITELIST_MAX_SUPPLY)),
                'Not enough NFTs left!'
            );
        }
        return quantity;
    }

    // ===== Public mint =====
    function mintWithETH() external payable nonReentrant {
        require(!publicMintPaused, 'Public mint is paused');
        uint256 quantity = _getMintQuantity(msg.value, true);
        require(
            balanceOf(msg.sender) + quantity <= maxMintLimit,
            'Your wallet can hold upto 3 NFTs only.'
        );
        _safeMint(msg.sender, quantity);
    }

    // ===== Public mint with ERC20 =====
    function mintWithERC20(uint256 amount, address tokenAddress)
        external
        isValidERC20PaymentTokenAddress(tokenAddress)
        nonReentrant
    {
        require(!publicMintPaused, 'Public mint is paused');
        require(balanceOf(msg.sender) + amount <= maxMintLimit, 'Your wallet can hold upto 3 NFTs only.');
        uint256 calculatedAmount = amount * paymentTokens[tokenAddress];
        require(
            calculatedAmount <= IERC20(tokenAddress).allowance(msg.sender, address(this)),
            'Allowance amount approved to this contract by user is insufficient'
        );
        if (!ownerSupplyWentPublic) {
            require(
                (totalSupply() + amount) <=
                    (MAX_SUPPLY - (OWNER_MINT_MAX_SUPPLY + AIRDROP_MAX_SUPPLY + WHITELIST_MAX_SUPPLY)),
                'Not enough NFTs left!'
            );
        } else {
            require(
                (totalSupply() + amount) <= (MAX_SUPPLY - (AIRDROP_MAX_SUPPLY + WHITELIST_MAX_SUPPLY)),
                'Not enough NFTs left!'
            );
        }
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), calculatedAmount);
        _safeMint(msg.sender, amount);
    }

    // ===== Public mint with ERC20 using SafeTransfer =====
    function safeMintWithERC20(uint256 amount, address tokenAddress)
        external
        isValidERC20PaymentTokenAddress(tokenAddress)
        nonReentrant
    {
        require(!publicMintPaused, 'Public mint is paused');
        require(balanceOf(msg.sender) + amount <= maxMintLimit, 'Your wallet can hold upto 3 NFTs only.');
        uint256 calculatedAmount = amount * paymentTokens[tokenAddress];
        require(
            calculatedAmount <= IERC20(tokenAddress).allowance(msg.sender, address(this)),
            'Allowance amount approved to this contract by user is insufficient'
        );
        if (!ownerSupplyWentPublic) {
            require(
                (totalSupply() + amount) <=
                    (MAX_SUPPLY - (OWNER_MINT_MAX_SUPPLY + AIRDROP_MAX_SUPPLY + WHITELIST_MAX_SUPPLY)),
                'Not enough NFTs left!'
            );
        } else {
            require(
                (totalSupply() + amount) <= (MAX_SUPPLY - (AIRDROP_MAX_SUPPLY + WHITELIST_MAX_SUPPLY)),
                'Not enough NFTs left!'
            );
        }
        SafeERC20.safeTransferFrom(IERC20(tokenAddress), msg.sender, address(this), calculatedAmount);
        _safeMint(msg.sender, amount);
    }

    // ===== Whitelist mint =====
    function whitelistMint(bytes32[] memory proof) external payable nonReentrant {
        require(!whitelistMintPaused, 'Whitelist mint is paused');
        require(isAddressWhitelisted(proof, msg.sender), 'You are not eligible for a whitelist mint');

        uint256 amount = _getMintQuantity(msg.value, false);
        require(balanceOf(msg.sender) + amount <= maxMintLimit, 'Your wallet can hold upto 3 NFTs only.');

        require(WHITELIST_MAX_SUPPLY >= amount, 'Whitelist mint is sold out');

        require(
            whitelistMintedAmount[msg.sender] + amount <= maxItemsPerWhiteListedWallet,
            'Minting amount exceeds allowance per wallet'
        );
        _safeMint(msg.sender, amount);

        whitelistMintedAmount[msg.sender] += amount;

        WHITELIST_MAX_SUPPLY = WHITELIST_MAX_SUPPLY - amount;
    }

    function isAddressWhitelisted(bytes32[] memory proof, address _address) public view returns (bool) {
        return isAddressInMerkleRoot(whitelistMerkleRoot, proof, _address);
    }

    function isAddressInMerkleRoot(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        address _address
    ) internal pure returns (bool) {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     * @dev Used to get the maximum supply of tokens.
     * @return uint256 for max supply of tokens.
     */
    function getMaxSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    // Only Owner Functions
    function addPaymentTokenAddressAndMintPrice(uint256 _amount, address _tokenAddress) external onlyOwner {
        paymentTokens[_tokenAddress] = _amount;
    }

    function removePaymentTokenAddressAndMintPrice(address _tokenAddress) external onlyOwner {
        delete paymentTokens[_tokenAddress];
    }

    function updateMintRate(uint256 _mintRate) external onlyOwner {
        require(_mintRate > 0, 'Invalid mint rate value.');
        mintRate = _mintRate;
    }

    function updateWhitelistMintRate(uint256 _whitelistMintRate) public onlyOwner {
        whitelistMintRate = _whitelistMintRate;
    }

    function updateMaxMintLimit(uint256 _maxMintLimit) external onlyOwner {
        require(_maxMintLimit > 0, 'Invalid max mint limit.');
        maxMintLimit = _maxMintLimit;
    }

    function updatePublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function updateWhitelistMintPaused(bool _whitelistMintPaused) external onlyOwner {
        whitelistMintPaused = _whitelistMintPaused;
    }

    function setWhitelistMintMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function updatemaxItemsPerWhiteListedWallet(uint256 _maxItemsPerWhiteListedWallet) external onlyOwner {
        maxItemsPerWhiteListedWallet = _maxItemsPerWhiteListedWallet;
    }

    function updateBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseUri = _baseTokenURI;
    }

    function updateOwnerSupplyWentPublic() external onlyOwner {
        ownerSupplyWentPublic = !ownerSupplyWentPublic;
        OWNER_MINT_MAX_SUPPLY = 0;
    }

    function updateRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function updateHiddenBaseTokenURI(string memory _hiddenBaseTokenURI) external onlyOwner {
        hiddenBaseUri = _hiddenBaseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (revealed == false) {
            baseURI = hiddenBaseUri;
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : '.json';
    }

    /**
     * @dev withdraw all eth from contract and transfer to owner.
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool aa, ) = payable(owner()).call{value: address(this).balance}('');
        require(aa);
    }

    /// @dev To withdraw all erc20 token from the contract
    /// @param token - address of the erc20 token
    function withdrawERC20(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, 'Amount Insufficient');
        IERC20(token).transfer(msg.sender, amount);
    }

    /// @dev To withdraw all erc20 token from the contract
    /// @param token - address of the erc20 token
    function withdrawERC20UsingSafeTransfer(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, 'Amount Insufficient');
        SafeERC20.safeTransfer(IERC20(token), msg.sender, amount);
    }
}