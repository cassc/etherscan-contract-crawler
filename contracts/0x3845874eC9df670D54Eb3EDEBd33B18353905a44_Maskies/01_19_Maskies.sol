// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma abicoder v2;

import 'erc721psi/contracts/ERC721Psi.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

// Using relative paths because hardhat doesn't know about the
// libs folder defined in foundry.toml
import '../lib/Whitelisting/src/Whitelist.sol';

// Date of creation: 2022-06-03T13:02:06.207Z

contract Maskies is ERC721Psi, Pausable, Ownable, ReentrancyGuard, WhiteList {
    //--------------------------------------------------
    // Constants
    //--------------------------------------------------
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant MAX_TOKENS_PER_WALLET = 50;
    uint256 public constant RESERVED_AMOUNT = 500;
    uint256 public constant MAX_FREE_MINTS = 5000;

    //--------------------------------------------------
    // Variables
    //--------------------------------------------------
    uint256 public maxTotalMintsThisStage = 10000;
    uint256 public maxMintBatchAmount = 50;
    uint256 public pricePerToken = 0.009 ether;
    uint256 public reservedTokensMinted = 0;
    uint256 public freeMints = 1;
    uint256 public totalFreeMintsMinted = 0;

    mapping(address => uint256) public addressMinted;

    // URI
    string public baseTokenURI = '';
    string public unrevealedURI = '';
    bool public revealed = false;

    //--------------------------------------------------
    // Events
    //--------------------------------------------------
    event Mint(address minter, uint256 amount, bytes32[] proof);
    event MintReserved(uint256 amount, address to);
    event SetMaxTotalMintsThisStage(uint256 newMax);
    event SetMaxMintBatchAmount(uint256 newLimit);
    event SetPricePerToken(uint256 newPricePerToken);
    event SetFreeMints(uint256 newFreeMints);
    event SetBaseURI();
    event SetUnrevealedURI(string newUnrevealedURI);
    event FlipReleaved(bool newState);
    event WithdrawAmount(uint256 amount);
    event WithdrawAll(uint256 amount);
    event ChangeOwner(address newOwner);

    //--------------------------------------------------
    // Constructor
    //--------------------------------------------------
    constructor() ERC721Psi('Maskies', 'MSK') {}

    //--------------------------------------------------
    // Minting
    //--------------------------------------------------
    function mint(
        address minter,
        uint256 maxMints,
        uint256 amount,
        bytes32[] memory proof
    ) external payable whenNotPaused nonReentrant {
        require(amount > 0, 'Mint amount cannot be 0');
        require(
            totalSupply() + amount <= maxTotalMintsThisStage,
            'Mint would reach max mints in this stage'
        );
        require(amount <= maxMintBatchAmount, 'Maximum batch size reached');
        require(
            totalSupply() + amount <=
                MAX_TOKENS - (RESERVED_AMOUNT - reservedTokensMinted),
            'Mint would reach maximum supply'
        );
        require(
            addressMinted[minter] + amount <= MAX_TOKENS_PER_WALLET,
            'Address would exceed balance limit'
        );

        uint256 freeMintsRemaining = 0;

        if (totalFreeMintsMinted < MAX_FREE_MINTS) {
            // Every wallet can mint {freeMints} amount of tokens
            freeMintsRemaining =
                freeMints -
                (
                    addressMinted[minter] > freeMints
                        ? freeMints
                        : addressMinted[minter]
                );

            freeMintsRemaining = amount >= freeMintsRemaining
                ? freeMintsRemaining
                : amount;

            if (totalFreeMintsMinted + freeMintsRemaining > MAX_FREE_MINTS) {
                freeMintsRemaining = MAX_FREE_MINTS - totalFreeMintsMinted;
            }

            if (freeMintsRemaining > 0) {
                totalFreeMintsMinted += amount >= freeMintsRemaining
                    ? freeMintsRemaining
                    : amount;
            }
        }

        require(
            msg.value >= pricePerToken * (amount - freeMintsRemaining),
            'Not enough ETH for transaction'
        );

        // Whitelist related
        bytes32 leaf = keccak256(abi.encode(minter, maxMints));
        require(
            !whitelistIsActive || addressMinted[minter] + amount <= maxMints,
            'Address would exceed mint limit'
        );
        require(
            !whitelistIsActive || verifyMerkleProof(proof, leaf),
            'Address not whitelisted'
        );

        // The actual mint
        addressMinted[minter] += amount;
        _safeMint(minter, amount);
        emit Mint(minter, amount, proof);
    }

    function mintReserved(uint256 amount, address to)
        external
        onlyOwner
        nonReentrant
    {
        // Amount > 0 and addres(0) checks are already done in the ERC721Psi._mint() function
        require(
            reservedTokensMinted + amount <= RESERVED_AMOUNT,
            'Would be more than reserved amount'
        );

        reservedTokensMinted += amount;
        _safeMint(to, amount);

        emit MintReserved(amount, to);
    }

    //--------------------------------------------------
    // Sale related
    //--------------------------------------------------
    function setMaxTotalMintsThisStage(uint256 newMax) external onlyOwner {
        require(newMax <= MAX_TOKENS, 'Stage max cannot exceed MAX_TOKENS');

        maxTotalMintsThisStage = newMax;
        emit SetMaxTotalMintsThisStage(maxTotalMintsThisStage);
    }

    function flipWhitelistState() external override onlyOwner {
        _flipWhitelistState();
    }

    function setMaxMintBatchAmount(uint256 newMax) external onlyOwner {
        require(newMax <= MAX_TOKENS, 'Batch max cannot exceed MAX_TOKENS');

        maxMintBatchAmount = newMax;
        emit SetMaxMintBatchAmount(maxMintBatchAmount);
    }

    function setPricePerToken(uint256 newPricePerToken) external onlyOwner {
        pricePerToken = newPricePerToken;
        emit SetPricePerToken(pricePerToken);
    }

    function setFreeMints(uint256 newFreeMints) external onlyOwner {
        freeMints = newFreeMints;
        emit SetFreeMints(newFreeMints);
    }

    //--------------------------------------------------
    // Merkle proof related
    //--------------------------------------------------
    function setMerkleRoot(bytes32 newMerkleRoot) external override onlyOwner {
        _setMerkleRoot(newMerkleRoot);
    }

    //--------------------------------------------------
    // URI related
    //--------------------------------------------------
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        require(bytes(newBaseURI).length > 0, 'URI cannot be empty');
        baseTokenURI = newBaseURI;
        emit SetBaseURI();
    }

    function setUnrevealedURI(string calldata newUnrevealedURI)
        external
        onlyOwner
    {
        require(bytes(newUnrevealedURI).length > 0, 'URI cannot be empty');
        unrevealedURI = newUnrevealedURI;
        emit SetUnrevealedURI(unrevealedURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // To avoid an overflow when adding 1
        require(tokenId < type(uint256).max);
        require(_exists(tokenId), 'URI query for nonexistent token');

        if (!revealed) {
            return unrevealedURI;
        }

        uint256 internalTokenId = tokenId + 1;

        string memory baseURI = _baseURI();
        string memory _tokenURI = bytes(baseURI).length > 0
            ? string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(internalTokenId),
                    '.json'
                )
            )
            : '';

        return _tokenURI;
    }

    function flipReleaved() external onlyOwner {
        revealed = !revealed;
        emit FlipReleaved(revealed);
    }

    //--------------------------------------------------
    // Withdrawel related
    //--------------------------------------------------
    function withdrawAmount(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, 'Amount should be greater than 0');
        uint256 contractBalance = address(this).balance;
        require(amount <= contractBalance, 'Not enough balance in contract');

        (bool success, ) = payable(owner()).call{value: amount}('');
        require(success, 'Transfer failed');

        emit WithdrawAmount(amount);
    }

    function withdrawAll() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, 'Contract balance is 0');

        (bool success, ) = payable(owner()).call{value: contractBalance}('');
        require(success, 'Transfer failed');

        emit WithdrawAll(contractBalance);
    }

    //--------------------------------------------------
    // Owner related
    //--------------------------------------------------
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), 'newOwner cannot be address(0)');
        require(newOwner != owner(), 'newowner cannot be current owner');
        transferOwnership(newOwner);

        emit ChangeOwner(newOwner);
    }

    //--------------------------------------------------
    // Pause related
    //--------------------------------------------------
    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }
}