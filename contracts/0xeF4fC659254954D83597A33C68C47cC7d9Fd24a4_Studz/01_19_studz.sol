// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";



pragma solidity ^0.8.0;


contract Studz is ERC721Enumerable, AccessControl, ERC721URIStorage, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    // KOD Treasury address to disperse all funds.
    address private constant TREASURY_ADDRESS = 0xbfCF42Ef3102DE2C90dBf3d04a0cCe90eddA6e3F;

    // Maximum Minting Constants
    uint256 private constant MAX_SUPPLY = 4444;
    uint256 private constant MAX_PUBLIC_MINT_PER_ADDRESS = 5; 

    // Default: Steedz are sold in public mint at 0.1444 eth.
    // Setter allows this to be modified.
    uint256 private mintPrice = 144400000000000000; // 0.1444 eth

    // Flags for whether the relevant sales are open or not.
    bool private presaleOpen = false;
    bool private publicSaleOpen = false;

    // Maps to track how much has been minted by certain addresses
    mapping(address => uint256) private maxMintAmountPresaleByAddress;
    mapping(address => uint256) private presaleMintedByAddress;
    mapping(address => uint256) private publicMintedByAddress;

    // Maps for limits on claiming in presale
    mapping(address => uint256) private numClaimedAmountInPresaleByAddress;

    // Base token URI
    string private _baseTokenURI;
    
    // Address which will sign the transactions
    address private signerAddress;

    // Safe counter for tracking mints
    Counters.Counter private totalMinted;

    // For when the contract is ready to freeze metadata uri forever
    bool private metadataIsFrozen = false;

    constructor(
        address _signerAddress
    ) ERC721("Steedz", "STEEDZ") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        signerAddress = _signerAddress;
    }

    // Set the signer address should we need to change this.
    function setSignerAddress(address _signerAddress) external nonReentrant onlyOwner {
        signerAddress = _signerAddress;
    }

    // Compare what was signed by the signer against what was received from the caller.
    function isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool isValid) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == signerAddress;
    }

    // Allow someone on the presale allowlist to purchase their Steedz
    function presalePurchase(
        uint256 _maxMintable,
        uint256 _maxClaimable,
        uint256 _numMinting,
        uint256 _numClaiming,
        bytes memory signature
    ) external payable nonReentrant {
        require(presaleOpen, "Presale Minting must be open");
        require(publicSaleOpen == false, "Public sale must not have started");
        require(totalSupply() < MAX_SUPPLY, "Can not mint more than the max supply");

        // check claimable data
        require(numClaimedAmountInPresaleByAddress[msg.sender] + _numClaiming <= _maxClaimable, "You may only claim your specified amounts");
        
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, _maxMintable, _maxClaimable, _numMinting, _numClaiming, msg.value));
        require(isValidSignature(msgHash, signature), "Signature must be valid");

        // Set the maximum amount that this sender can purchase in the presale based on what was obtained from the signature.
        maxMintAmountPresaleByAddress[msg.sender] = _maxMintable;
        require(presaleMintedByAddress[msg.sender] + _numMinting <= _maxMintable, "You can not exceed your max mintable amount");
        require(totalMinted.current() + _numMinting <= MAX_SUPPLY, "You can not mint more than the max supply");

        for(uint256 i = 0; i < _numMinting; i ++) {
            uint256 nextTokenId = totalMinted.current() + 1;
            _safeMint(msg.sender, nextTokenId);
            totalMinted.increment();
        }

        // Increment the counter
        presaleMintedByAddress[msg.sender] = presaleMintedByAddress[msg.sender] + _numMinting;
        // Increment claimable data
        numClaimedAmountInPresaleByAddress[msg.sender] = numClaimedAmountInPresaleByAddress[msg.sender] + _numClaiming;
    }

    // Public method to purchase steedz during the public sale
    function publicPurchase(
        uint256 _numPurchasing
    ) external payable nonReentrant {
        require(publicSaleOpen, "Public sale must be open");
        require(totalSupply() < MAX_SUPPLY, "Can not mint more than the max supply");
        require(totalSupply() + _numPurchasing <= MAX_SUPPLY, "You may not go over the max supply");

        require(msg.value >= _numPurchasing * mintPrice, "Must supply proper amount to pay for purchase");
        require(_numPurchasing > 0, "Safety check");
        require(_numPurchasing <= MAX_PUBLIC_MINT_PER_ADDRESS, "You are limited in the public mint");
        require(publicMintedByAddress[msg.sender] + _numPurchasing <= MAX_PUBLIC_MINT_PER_ADDRESS, "You may not mint more than the max allowed in the public sale");

        for(uint256 i = 0; i < _numPurchasing; i ++) {
            uint256 nextTokenId = totalMinted.current() + 1;
            _safeMint(msg.sender, nextTokenId);
            totalMinted.increment();
        }

        publicMintedByAddress[msg.sender] = publicMintedByAddress[msg.sender] + _numPurchasing;
    }

    // Getters and setters for the presale open flag
    function setPresaleOpen(bool _isOpen) external onlyOwner {
        presaleOpen = _isOpen;
    }
    function getPresaleOpen() public view returns (bool) {
        return presaleOpen;
    }

    // Getters and setters for the public sale open flag
    function setPublicSaleOpen(bool _isOpen) external onlyOwner {
        publicSaleOpen = _isOpen;
    }
    function getPublicSaleOpen() public view returns (bool) {
        return publicSaleOpen;
    }

    function setPublicSalePrice(uint256 _psp) external onlyOwner {
        mintPrice = _psp;
    }
    function getPublicSalePrice() public view returns (uint256) {
        return mintPrice;
    }

    function getNumClaimedByAddress(address _a) public view returns (uint256) {
        return numClaimedAmountInPresaleByAddress[_a];
    }
    function getNumPublicMintByAddress(address _a) public view returns (uint256) {
        return publicMintedByAddress[_a];
    }

    // Toggle the base URI
    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set the base URI");
        require(metadataIsFrozen == false, "Can no longer set the base URI after frozen");
        _baseTokenURI = baseURI;
    }

    // Getter for the value of the base token uri
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Set that we have revealed the final base token URI, and lock the reveal so that the token URI is permanent
    function freezeMetadata() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only an admin can finalize the metadata");
        require(metadataIsFrozen != true, "Can no longer set the metadata once it has been frozen");
        metadataIsFrozen = true;
    }

    // Getter for frozen metadata flag
    function isFrozenMetadata() public view returns (bool) {
        return metadataIsFrozen;
    }

    // Return the total mint count
    function getTotalMintCount() public view returns (uint256) {
        return totalMinted.current();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

     function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getTreasuryAddress() public pure returns (address) {
        return TREASURY_ADDRESS;
    }

    function withdrawAll() public payable {
        require(payable(getTreasuryAddress()).send(address(this).balance));
    }
}