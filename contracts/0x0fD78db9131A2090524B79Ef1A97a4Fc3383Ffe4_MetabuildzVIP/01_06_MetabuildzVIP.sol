// SPDX-License-Identifier: MIT

/*
 /$$      /$$             /$$               /$$                 /$$ /$$       /$$                 /$$    /$$ /$$$$$$ /$$$$$$$        /$$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$ 
| $$$    /$$$            | $$              | $$                |__/| $$      | $$                | $$   | $$|_  $$_/| $$__  $$      | $$__  $$ /$$__  $$ /$$__  $$ /$$__  $$
| $$$$  /$$$$  /$$$$$$  /$$$$$$    /$$$$$$ | $$$$$$$  /$$   /$$ /$$| $$  /$$$$$$$ /$$$$$$$$      | $$   | $$  | $$  | $$  \ $$      | $$  \ $$| $$  \ $$| $$  \__/| $$  \__/
| $$ $$/$$ $$ /$$__  $$|_  $$_/   |____  $$| $$__  $$| $$  | $$| $$| $$ /$$__  $$|____ /$$/      |  $$ / $$/  | $$  | $$$$$$$/      | $$$$$$$/| $$$$$$$$|  $$$$$$ |  $$$$$$ 
| $$  $$$| $$| $$$$$$$$  | $$      /$$$$$$$| $$  \ $$| $$  | $$| $$| $$| $$  | $$   /$$$$/        \  $$ $$/   | $$  | $$____/       | $$____/ | $$__  $$ \____  $$ \____  $$
| $$\  $ | $$| $$_____/  | $$ /$$ /$$__  $$| $$  | $$| $$  | $$| $$| $$| $$  | $$  /$$__/          \  $$$/    | $$  | $$            | $$      | $$  | $$ /$$  \ $$ /$$  \ $$
| $$ \/  | $$|  $$$$$$$  |  $$$$/|  $$$$$$$| $$$$$$$/|  $$$$$$/| $$| $$|  $$$$$$$ /$$$$$$$$         \  $/    /$$$$$$| $$            | $$      | $$  | $$|  $$$$$$/|  $$$$$$/
|__/     |__/ \_______/   \___/   \_______/|_______/  \______/ |__/|__/ \_______/|________/          \_/    |______/|__/            |__/      |__/  |__/ \______/  \______/ 

POWERED BY https://metabuildz.io | https://metabuildz.com
*/   

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract MetabuildzVIP is ERC721A, Ownable {
    // ======== SUPPLY ========
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant TEAM_RESERVED = 1000;

    // ======== ROYALTY ========
    address private royaltyAddress;
    uint96 private royaltyBasisPoints = 1000; //10 * 100 = 10%
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // ======== SALE STATUS ========
    bool public paused = true;
    uint256 public mintLimit = 1;
    uint256 public supplyLimit = 1000;
    uint256 public publicSalePrice = 0.05 ether;

    // ======== METADATA ========
    bool public isRevealed = false;
    string private baseTokenURI;
    string private unrevealedTokenURI;

    // ======== CONTRACT LEVEL METADATA ========
    string public contractURI;

    uint8 public currentMintBatch;

    // ======== MERKLE ROOT ========
    bytes32 public merkleRoot;

    // ======== CONSTRUCTOR ========
    constructor() ERC721A("Metabuildz VIP PASS", "MVP") {
        setRoyaltyAddress(0x6d46377d64436816159d2A624dB4b907233260Cf);
    }

    modifier mintCompliance {
        require(!paused, "Sale has not started");
        require(_msgSender() == tx.origin, "Minting from contract not allowed");
        require(totalSupply() < MAX_SUPPLY, "Exceeds supply");
        _;
    }

    // ======== MINTING ========
    function whitelistMint(bytes32[] calldata _proof)
    external
    mintCompliance {
        require(currentMintBatch == 1, "Whitelist is not active yet.");
        require(_numberMinted(_msgSender()) < mintLimit, "Can't mint anymore, mint limit reached.");
        require(totalSupply() < supplyLimit, "Can't mint anymore as it exceeds mint supply limit");
        require(
            MerkleProof.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Signer address mismatch"
        );
        _mint(_msgSender(), mintLimit);
    }

    // ======== SETTERS ========
    function setCurrentMintBatch(uint8 _batch) external onlyOwner {
        currentMintBatch = _batch;
    }

    function setMintLImit(uint8 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    function setSupplyLimit(uint8 _supplyLimit) external onlyOwner {
        supplyLimit = _supplyLimit;
    }

    function publicMint(uint256 _quantity)
    external
    payable
    mintCompliance {
        require(currentMintBatch == 2, "Public Sale has not started");
        require(msg.value == publicSalePrice * _quantity, "Incorrect ether sent");
        require(_numberMinted(_msgSender()) < mintLimit, "Can't mint anymore, mint limit reached.");
        require(totalSupply() < supplyLimit, "Can't mint anymore as it exceeds mint supply limit");
        _mint(_msgSender(), _quantity);
    }

    function setPublicSalePrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }

    function numberMinted(address _minter) view external returns(uint256) {
        return _numberMinted(_minter);
    }
    
    // ======== AIRDROP ========
    function airdrop(uint256 _quantity, address _receiver) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds supply");
        _mint(_receiver, _quantity);
    }

    // ======== SETTERS ========
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setUnrevealedTokenURI(string memory _unrevealedTokenURI)
    public
    onlyOwner {
        unrevealedTokenURI = _unrevealedTokenURI;
    }

    function setIsRevealed(bool _reveal) external onlyOwner {
        isRevealed = _reveal;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    // ========= GETTERS ===========
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns(string memory) {
        require(
            _exists(tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );

        if (!isRevealed) {
            return unrevealedTokenURI;
        }

        return string(
            abi.encodePacked(
                baseTokenURI,
                _toString(tokenId)
            )
        );
    }

    function _startTokenId()
    internal
    view
    virtual
    override(ERC721A)
    returns(uint256) {
        return 1;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            TokenOwnership memory ownership = _ownershipAt(currentTokenId);

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    // ========= EIP-2981 ===========
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns(address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A)
    returns(bool) {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    // ======== WITHDRAW ========
    function withdraw(uint256 amount_) external onlyOwner {
        require(address(this).balance >= amount_, "Address: insufficient balance");

        // This will payout the owner 100% of the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: amount_}("");
        require(os);
        // =============================================================================
    }
}