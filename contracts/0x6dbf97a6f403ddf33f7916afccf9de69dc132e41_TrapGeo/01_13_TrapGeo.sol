// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TrapGeo is ReentrancyGuard, ERC721, Ownable {

    uint256 public totalSupply;
    uint256 public maxMintsPerTransaction;
    uint256 public totalNumberOfPacksMinted;

    uint256 public publicMintPrice;

    uint256 public maxSupply;
    uint256 public maxNumberOfPacksAvailable;

    bool public isMintingEnabled;

    address public catWallet;
    address public orionWallet;

    bool public isRevealed;
    string public GEO_PROVENANCE;

    string internal baseTokenUri;
    string public hiddenMetadataUri;    

    mapping(address => uint256) public WalletMints;
    mapping(uint256 => address) public MintedPacks;
    

    constructor() payable ERC721('Trap Geo', 'GEO') {

        totalSupply = 0;
        maxMintsPerTransaction = 3;
        totalNumberOfPacksMinted = 0;

        publicMintPrice = 0.2 ether;

        maxSupply = 160;
        maxNumberOfPacksAvailable = 53;

        isMintingEnabled = false;

        catWallet = 0xd42D52b709829926531c64a32f2713B4Dc8eA6F6;
        orionWallet = 0x0F574D45D73F5c8F4189CCf4D98Cd22eaDFA9532;

        setHiddenMetadataUri("ipfs://Qmei8uhBUN5U5znagU6TRDVJZ5KkcarrXwybETVDWu8ai3/"); 

        isRevealed = false;
        GEO_PROVENANCE = "2aef1de1eb520872b43ed41f5fe10efc2bae66277b58251b92b9221d0e4c7720";

    }

    modifier callerIsAWallet() {
        require(tx.origin ==msg.sender, "Another contract detected");
        _;
    }

    function setIsMintingEnabled() external onlyOwner {
        isMintingEnabled = !isMintingEnabled;
    }

    // Orion Solidified allocation claim (1 Token)

    function claimForOrion() external nonReentrant callerIsAWallet {

        uint256 newTokenId = 0;

        require(WalletMints[orionWallet] < 1, 'Already minted');
        require(msg.sender == orionWallet, 'Wrong Wallet Called');
        
        WalletMints[orionWallet]++;
        totalSupply++;

        _safeMint(orionWallet, newTokenId);
    }

    //minting Packs

    function mintPacks(uint256 quantity_) public payable callerIsAWallet {
        uint256 numberOfMintsPerPack = 3;

        require(isMintingEnabled, 'minting not enabled'); 
        require(msg.value >= quantity_ * publicMintPrice, 'wrong mint value');
        require(quantity_ <= maxMintsPerTransaction, 'Asking too many packs');
        require(totalNumberOfPacksMinted + quantity_ <= maxNumberOfPacksAvailable, 'sold out');

        for(uint256 i = 0; i < quantity_; i++) {

            uint256 newPackId = totalNumberOfPacksMinted + 1;

            MintedPacks[newPackId] = msg.sender;

            for(uint256 j = 0; j < numberOfMintsPerPack; j++) { 

                uint256 newTokenId = (totalNumberOfPacksMinted * numberOfMintsPerPack) + (j + 1);

                WalletMints[msg.sender]++;
                totalSupply++;
                _safeMint(msg.sender, newTokenId);

            }

            totalNumberOfPacksMinted++;

        }
    }

    function reveal() external onlyOwner {
        isRevealed = true;
    }

    function setHiddenMetadataUri(string memory hiddenMetadataUri_) public onlyOwner {
        hiddenMetadataUri = hiddenMetadataUri_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {

        if (isRevealed == false) {
            return hiddenMetadataUri;
            }

        require(_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    string private customContractURI = "ipfs://QmWtgf7cjePszXY6gjrsyLMhnKpTdVNRC6jN8n2kKVLeuu/";

    function setContractURI(string memory customContractURI_) external onlyOwner {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = catWallet.call{ value: address(this).balance }('');
        require(success, 'withdraw failed');
    }

}