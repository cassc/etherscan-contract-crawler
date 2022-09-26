// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/*
  _  _     _           _               ___              
 | \| |___| |_ ___ _ _(_)___ _  _ ___ | _ \_  _ __ _ ___
 | .` / _ \  _/ _ \ '_| / _ \ || (_-< |   / || / _` (_-<
 |_|\_\___/\__\___/_| |_\___/\_,_/__/ |_|_\\_,_\__, /__/
                                               |___/    
*/
// Mikey Valet and Sal420

contract NotoriousRugs is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = '';
    string public uriSuffix = '.json';
    string public hiddenMetadataUri;

    // cost is set twice. 1st on 'yarn public-sale-open --network truffle' and if hasFreeMint and maxFreeMintSupplay is reached the cost is set to  paidMintCost
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

    //
    uint256 public maxFreeMintSupply;
    uint256 public maxFreeMintAmountPerTx;
    uint256 public paidMintCost;
    //

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    //
    bool public hasFreeMint = false;

    //

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri,
        //
        bool _hasFreeMint,
        uint256 _maxFreeMintSupply,
        uint256 _maxFreeMintAmountPerTx
    )
        //
        ERC721A(_tokenName, _tokenSymbol)
    {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
        //
        setHasFreeMint(_hasFreeMint);
        setMaxFreeMintSupply(_maxFreeMintSupply);
        setMaxFreeMintAmountPerTx(_maxFreeMintAmountPerTx);
        //
    }

    modifier mintCompliance(uint256 _mintAmount) {
        //
        require(
            hasFreeMintSupplyAvailable() == false,
            'Mint is unavailable while free mint supply exist!'
        );
        require(_mintAmount > 0, 'Mint amount must be greater than 0!');
        //
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            'Invalid mint amount. Mint amount can not be greater than mint amount max per transaction!'
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            'Mint amount exceeds max supply!'
        );
        require(tx.origin == msg.sender, 'Contracts cannot mint');
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            'Invalid proof!'
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, 'The contract is paused!');

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : '';
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
        paidMintCost = cost; // FreeMint
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        require(
            address(this).balance > 0,
            'Cannot withdraw funds, balance is 0'
        );
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os, 'Failed to withdraw funds');
        // =============================================================================
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // FreeMint functions
    function setHasFreeMint(bool _state) public onlyOwner {
        hasFreeMint = _state;
        paidMintCost = cost;
        cost = 0;
    }

    function setMaxFreeMintSupply(uint256 _maxFreeMintSupply) public onlyOwner {
        maxFreeMintSupply = _maxFreeMintSupply;
    }

    function setMaxFreeMintAmountPerTx(uint256 _maxFreeMintAmountPerTx)
        public
        onlyOwner
    {
        maxFreeMintAmountPerTx = _maxFreeMintAmountPerTx;
    }

    function freeMint(uint256 _mintAmount)
        public
        payable
        freeMintCompliance(_mintAmount)
    {
        _safeMint(_msgSender(), _mintAmount);
        if (totalSupply() >= maxFreeMintSupply) {
            // Reset cost
            cost = paidMintCost;
        }
    }

    modifier freeMintCompliance(uint256 _mintAmount) {
        require(!paused, 'The contract is paused!');
        require(hasFreeMint, 'Free mint is not available!');
        require(_mintAmount > 0, 'Free mint amount must be 1 or more!');
        require(
            _mintAmount <= maxFreeMintAmountPerTx,
            'Free mint amount execeeds max free mint per transaction!'
        );
        require(
            totalSupply() + _mintAmount <= maxFreeMintSupply,
            'Free mint amount will exceed max free mint supply'
        );

        require(
            (balanceOfNFtTokenAmountInWallet(msg.sender) + _mintAmount) <=
                maxFreeMintAmountPerTx,
            'The requested free mint amount will exceed your eligible free mint amount. Your eligible free mint amount is the same as as the free mint per tranasction amount'
        );

        require(
            totalSupply() + _mintAmount <= maxSupply,
            'Free mint amount will exceed max mint supply!'
        );
        require(
            maxFreeMintAmountPerTx >
                balanceOfNFtTokenAmountInWallet(msg.sender),
            'You have reached your eligible free mint amount. Your eligible free mint amount is the same as as the free mint per tranasction amount'
        );
        require(
            balanceOfNFtTokenAmountInWallet(msg.sender) + _mintAmount <=
                maxFreeMintAmountPerTx,
            'The requested free mint amount will exceed your eligible free mint amount. Your eligible free mint amount is the same as as the free mint per tranasction amount'
        );
        require(tx.origin == msg.sender, 'Contracts cannot free mint');
        _;
    }

    function hasFreeMintSupplyAvailable() private view returns (bool) {
        if (hasFreeMint == true && totalSupply() < maxFreeMintSupply)
            return true;
        return false;
    }

    function availableFreeMintSupplyAmount() public view returns (uint256) {
        if (hasFreeMintSupplyAvailable() == false) return 0;
        return maxFreeMintSupply - totalSupply();
    }

    function allowedFreeMintAmountPerTxn() public view returns (uint256) {
        return maxFreeMintAmountPerTx;
    }

    function balanceOfNFtTokenAmountInWallet(address _sender)
        public
        view
        returns (uint256)
    {
        return balanceOf(_sender);
    }

    //
}