// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IEnumerableContract.sol";

/*
I see you nerd! ⌐⊙_⊙
*/

contract GodsOfRock is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public maxTokenSupply;
    uint256 public constant MAX_MINTS_PER_TXN = 15;

    uint256 public mintPrice = 0.08 ether;
    uint256 public presaleTORPrice = 0.075 ether;
    uint256 public presaleVIPPrice = 0.07 ether;

    bool public preSaleVipIsActive = false;
    bool public preSaleTorIsActive = false;
    bool public saleIsActive = false;
    bool public demigodMintIsActive = false;

    string public baseURI;

    string public provenance;

    IEnumerableContract private _vipContractInstance;
    IEnumerableContract private _torContractInstance;

    // Mapping of whether this address has minted via TOR or not
    mapping (address => bool) private _presaleMints;

    // Mapping from VIP pass token ID to whether it has been claimed or not
    mapping(uint256 => bool) private _claimed;

    address[5] private _shareholders;
    uint[5] private _shares;

    event PaymentReleased(address to, uint256 amount);

    event DemigodMinted(uint256 demigodTokenId, uint256 torTokenId, uint256[3] gorTokenIds);

    constructor(string memory name, string memory symbol, uint256 maxGodsOfRockSupply, address vipContractAddress, address torContractAddress) ERC721(name, symbol) {
        maxTokenSupply = maxGodsOfRockSupply;

        _shareholders[0] = 0x804074b2a03CFc6c23F5f5bf0bf86832B3dDF51A; // JJ
        _shareholders[1] = 0xA7b612718840AE64735adC6d73B03b505a143A5D; // Jagger
        _shareholders[2] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[3] = 0x95270f71252AF1F92E54c777237091F9382Ca5D8; // Darko
        _shareholders[4] = 0x74a2acae9B92781Cbb1CCa3bc667c05313e14850; // Cam

        _shares[0] = 3150;
        _shares[1] = 3150;
        _shares[2] = 2500;
        _shares[3] = 1000;
        _shares[4] = 200;

        _vipContractInstance = IEnumerableContract(vipContractAddress);
        _torContractInstance = IEnumerableContract(torContractAddress);
    }

    function setMaxTokenSupply(uint256 maxGodsOfRockSupply) public onlyOwner {
        maxTokenSupply = maxGodsOfRockSupply;
    }

    function setPrices(uint256 newMintPrice, uint256 newPresaleTORPrice, uint256 newPresaleVIPPrice) public onlyOwner {
        mintPrice = newMintPrice;
        presaleTORPrice = newPresaleTORPrice;
        presaleVIPPrice = newPresaleVIPPrice;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 5; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        uint256 supply = _tokenIdCounter.current();
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _safeMint(mintAddress, supply + i);
            _tokenIdCounter.increment();
        }
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Set state switches for VIP and presale state + demigod minting.
    */
    function setStateSwitches(bool newPresaleVipState, bool newPresaleTorState, bool newDemigodMintIsActive) public onlyOwner {
        preSaleVipIsActive = newPresaleVipState;
        preSaleTorIsActive = newPresaleTorState;
        demigodMintIsActive = newDemigodMintIsActive;
    }

    /*
    * Mint Gods Of Rock NFTs, woot!
    */
    function mintGOR(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not live yet");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can mint a max of 15 GOR NFTs at a time");
        
        _mintMultiple(numberOfTokens, mintPrice);
    }

    /*
    * Mint Gods Of Rock NFTs for TOR owners during pre-sale
    */
    function presaleMintViaTOR() public payable {
        require(preSaleTorIsActive, "Pre-sale is not live yet");
        require(_torContractInstance.balanceOf(msg.sender) > 0, "This address does not own TOR NFTs");
        require(! _presaleMints[msg.sender], "This wallet has already minted GOR in the presale");

        _presaleMints[msg.sender] = true;

        _mintMultiple(1, presaleTORPrice);
    }

    /*
    * Mint Gods Of Rock NFTs for VIP pass owners during pre-sale
    * Tell JJ, I said hi!
    */
    function presaleMintViaVip(uint256 numberOfTokens, uint256[] calldata tokenIds) public payable {
        require(preSaleVipIsActive, "Pre-sale is not live yet");
        require(numberOfTokens <= (2 * tokenIds.length), "Insufficient VIP passes for the required mints");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_vipContractInstance.ownerOf(tokenIds[i]) == msg.sender && ! _claimed[tokenIds[i]], 'Caller is either not owner of the token ID or it has already been claimed');
            _claimed[tokenIds[i]] = true;
        }
        
        _mintMultiple(numberOfTokens, presaleVIPPrice);
    }

    function mintDemiGod(uint256 torTokenId, uint256[3] calldata gorTokenIds) public {
        require(demigodMintIsActive, "Demigod minting is not live yet");

        require(_torContractInstance.ownerOf(torTokenId) == msg.sender, 'Caller is not owner of the TOR Token ID');
        for (uint256 i = 0; i < 3; i++) {
            require(ownerOf(gorTokenIds[i]) == msg.sender, 'Caller is not owner of the GOR Token ID');
        }

        _torContractInstance.burn(torTokenId);
        for (uint256 i = 0; i < 3; i++) {
            _burn(gorTokenIds[i]);
        }

        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());

        emit DemigodMinted(_tokenIdCounter.current(), torTokenId, gorTokenIds);
    }

    /*
    * Check whether the given token ID can be claimed for VIP pass presale mints
    */
    function canClaim(uint256 tokenId) external view returns (bool) {
        return ! _claimed[tokenId];
    }

    /*
    * Check whether the given address can mint via TOR in presale
    */
    function canMintViaTOR(address owner) external view returns (bool) {
        return ! _presaleMints[owner];
    }

    /*
    * Mint Gods of Rock NFTs!
    */
    function _mintMultiple(uint256 numberOfTokens, uint256 mintingPrice) internal {
        require(_tokenIdCounter.current() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available NFTs");
        require(mintingPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}