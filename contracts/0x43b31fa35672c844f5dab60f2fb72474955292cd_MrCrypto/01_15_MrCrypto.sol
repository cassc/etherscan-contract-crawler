// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MrCrypto is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 20;

    uint256 public mintPrice = 0.08 ether;

    uint256 public presalePrice = 0.06 ether;

    uint256 public maxPresaleMintsPerWallet = 10;

    bool public preSaleIsActive = false;

    bool public saleIsActive = false;

    string public baseURI;

    string public provenance;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    mapping (address => uint256) private _presaleMints;

    address[11] private _shareholders;

    uint[11] private _shares;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxMrCryptoSupply) ERC721(name, symbol) {
        maxTokenSupply = maxMrCryptoSupply;

        _shareholders[0] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[1] = 0xF45D5a7a7E14e94D7c3091600E6EEab58648f0F1; // Kama
        _shareholders[2] = 0x6c183EE7AE606b69Ba71A940c0B827BbF1DE3589; // Revobit
        _shareholders[3] = 0x36ED2D75A82e180e0871456b15c239b73B4EE9F4; // Dikasso
        _shareholders[4] = 0x5Acb6713375793DEB82634B013Ed86767Ee46BCE; // Melionka
        _shareholders[5] = 0x45394FF3c6C3442240bE68aAf5a852f07e745AfD; // Basil Mountian
        _shareholders[6] = 0x0c88f0F125c59cad35c704B8044107F2E51D28Fe; // Asithos
        _shareholders[7] = 0xC40dF87e16339f21fBB2E59FB38bF2A957A16FfD; // TappySF
        _shareholders[8] = 0x478B1B25fF9859eEF3609f67AD66b18890c779E8; // ShilliamShakespeare
        _shareholders[9] = 0xc591674216324dc6f5496Be098DfB52b674cbAca; // georginacastens
        _shareholders[10] = 0xF4A12bC4596E1c3e19D512F76325B52D72D375CF; // Reylasrdams

        _shares[0] = 3000;
        _shares[1] = 3000;
        _shares[2] = 3000;
        _shares[3] = 125;
        _shares[4] = 125;
        _shares[5] = 125;
        _shares[6] = 125;
        _shares[7] = 125;
        _shares[8] = 125;
        _shares[9] = 125;
        _shares[10] = 125;
    }

    function setMaxTokenSupply(uint256 maxMrCryptoSupply) public onlyOwner {
        maxTokenSupply = maxMrCryptoSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setPresalePrice(uint256 newPrice) public onlyOwner {
        presalePrice = newPrice;
    }

    function setMaxPresaleMintsPerWallet(uint256 newLimit) public onlyOwner {
        maxPresaleMintsPerWallet = newLimit;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 11; i++) {
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
    * Pause pre-sale if active, make active if paused.
    */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /*
    * Mint Mr Crypto NFTs, woot!
    */
    function mintMrcryptos(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not live yet");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can mint a max of 20 NFTs at a time");
        require(totalSupply() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available NFTs");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    /*
    * Mint Mr Crypto NFTs during pre-sale
    */
    function presaleMint(uint256 numberOfTokens) public payable {
        require(preSaleIsActive, "Pre-sale is not live yet");
        require(_presaleMints[msg.sender] + numberOfTokens <= maxPresaleMintsPerWallet, "Max mints per wallet limit exceeded");
        require(totalSupply() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available NFTs");
        require(presalePrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _presaleMints[msg.sender] += numberOfTokens;

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index, set the starting index block.
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Set the starting index for the collection.
     */
    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % maxTokenSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % maxTokenSupply;
        }
        // Prevent default sequence.
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    /**
     * Set the starting index block for the collection. Usually, this will be set after the first sale mint.
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
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