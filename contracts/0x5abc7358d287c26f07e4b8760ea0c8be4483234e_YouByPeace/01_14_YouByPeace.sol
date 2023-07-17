//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IYouByPeaceRenderer.sol";

/*
YouByPeace.sol

Contract by @NftDoyler
*/

contract YouByPeace is Ownable, ERC721A {
    bytes32 public merkleRootFree = 0xddfc07e15cf29a03c4380032195f96ba84a17bc58c095ef656d94985de7eb5af;
    bytes32 public merkleRootAllowList = 0x4dc44a7fb4784d9c6186b83e07ea3865f125665f365b2c79b8cb6814732882ae;

    uint256 constant public MAX_SUPPLY = 8888;
    
    uint256 public freeListMax = 22;
    uint256 public allowListMax = 516;
    uint256 public publicMintMax = 8350;
    
    uint256 constant public ALLOW_LIST_PRICE = 0.018 ether;
    uint256 constant public PUBLIC_PRICE = 0.018 ether;

    uint256 public PUBLIC_MINT_LIMIT = 10;

    uint256 public totalSupplyPublic;

    // Remaining 15% goes to Treasury
    uint256 internal DEV_WITHDRAW_PERCENT = 850;
    // Gotta keep some for degen and some for the business!
    uint256 internal DEV_WITHDRAW_PERCENT_2 = 150;
    uint256 internal ARTIST_WITHDRAW_PERCENT = 4500;
    uint256 internal FOUNDER_WITHDRAW_PERCENT = 3000;

    // A block to use in the future to shift the tokenIDs
    uint256 public futureBlockToUse;

    // How far to shift the tokenID during the reveal
    uint256 public tokenIdShift;

    string public revealedURI;
    
    string public hiddenURI = "ipfs://QmVBqpDT1jSnXVR8bW4RaZeMa95QTVLQtrURp19rsjjpn4";

    // OpenSea CONTRACT_URI - https://docs.opensea.io/docs/contract-level-metadata
    string constant public CONTRACT_URI = "ipfs://QmVBqpDT1jSnXVR8bW4RaZeMa95QTVLQtrURp19rsjjpn4";

    // Provance hash of the un-shifted images
    string public provanceHash;

    bool public paused = true;
    bool public revealed;
    bool public customizationPaused;
    
    // Payment addresses
    address constant internal DEV_ADDRESS = 0x31f8933601497fD6Ade6EaEaA6a66b281d238E70;
    address constant internal DEV_ADDRESS_2 = 0xeD19c8970c7BE64f5AC3f4beBFDDFd571861c3b7;
    address constant internal ARTIST_ADDRESS = 0x5be0D3BE0C8A6E99A26fC8257d969d38a03c8306;
    address constant internal FOUNDER_ADDRESS = 0xD3E44Fd29Cc3BbeE78471275ABC56e9948F6482c;
    address constant internal TREASURY_ADDRESS = 0x92e089149Dc5dBd40F8B7b7949695E6d304Ed0dc;

    address public externalRenderer;
    
    mapping(address => bool) public userMintedFree;
    mapping(address => bool) public userMintedWL;
    mapping(address => uint256) public numUserMints;

    // This is how the token DNA will be stored on-chain while keeping the art off-chain
        // DNA of 0 will be a randomly generated asset.
    mapping(uint256 => uint256) public tokenIdToDNA;

    constructor() ERC721A("YouByPeace", "PEACE") { }

    /*
     *

    $$$$$$$\            $$\                      $$\                     $$$$$$$$\                              $$\     $$\                               
    $$  __$$\           \__|                     $$ |                    $$  _____|                             $$ |    \__|                              
    $$ |  $$ | $$$$$$\  $$\ $$\    $$\ $$$$$$\ $$$$$$\    $$$$$$\        $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$$$$$$  |$$  __$$\ $$ |\$$\  $$  |\____$$\\_$$  _|  $$  __$$\       $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$  ____/ $$ |  \__|$$ | \$$\$$  / $$$$$$$ | $$ |    $$$$$$$$ |      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |      $$ |      $$ |  \$$$  / $$  __$$ | $$ |$$\ $$   ____|      $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
    $$ |      $$ |      $$ |   \$  /  \$$$$$$$ | \$$$$  |\$$$$$$$\       $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
    \__|      \__|      \__|    \_/    \_______|  \____/  \_______|      \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 
                                                                                                                                                      
    *
    */

    // This function is if you want to override the first Token ID# for ERC721A
    // Note: Fun fact - by overloading this method you save a small amount of gas for minting (technically just the first mint)
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _verifyPublicAllowList(bytes32[] memory _proof, bytes32 _root) internal view returns (bool) {
        return MerkleProof.verify(_proof, _root, keccak256(abi.encodePacked(msg.sender)));
    }

    function refundOverpay(uint256 price) private {
        if (msg.value > price) {
            (bool succ, ) = payable(msg.sender).call{
                value: (msg.value - price)
            }("");
            require(succ, "Transfer failed");
        }
        else if (msg.value < price) {
            revert("Not enough ETH sent");
        }
    }

    /*
     *

    $$$$$$$\            $$\       $$\ $$\                 $$$$$$$$\                              $$\     $$\                               
    $$  __$$\           $$ |      $$ |\__|                $$  _____|                             $$ |    \__|                              
    $$ |  $$ |$$\   $$\ $$$$$$$\  $$ |$$\  $$$$$$$\       $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$$$$$$  |$$ |  $$ |$$  __$$\ $$ |$$ |$$  _____|      $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$  ____/ $$ |  $$ |$$ |  $$ |$$ |$$ |$$ /            $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |      $$ |  $$ |$$ |  $$ |$$ |$$ |$$ |            $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
    $$ |      \$$$$$$  |$$$$$$$  |$$ |$$ |\$$$$$$$\       $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
    \__|       \______/ \_______/ \__|\__| \_______|      \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    function freeMint(bytes32[] memory proof) external payable mintCompliance(1) {
        require(msg.value == 0, "This phase is free");
        require(!userMintedFree[msg.sender], "User already minted free");
        require(_verifyPublicAllowList(proof, merkleRootFree), "User not on free list");

        userMintedFree[msg.sender] = true;

        _mint(msg.sender, 1);
    }
    
    function allowListMint(bytes32[] memory proof) external payable mintCompliance(1) {
        require(_verifyPublicAllowList(proof, merkleRootAllowList), "User not on WL");

        uint256 price = ALLOW_LIST_PRICE;
        
        require(!userMintedWL[msg.sender], "User already minted WL");

        refundOverpay(price);
        
        userMintedWL[msg.sender] = true;

        _mint(msg.sender, 1);
    }
    
    // Note: By changing all 3 require statements from <= to <, some gas could be saved
        // That said, this is a savings of about 0.005% per publicMint for
        // a general loss in readability
    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(totalSupplyPublic + quantity <= publicMintMax, "Public supply out");

        uint256 price = PUBLIC_PRICE;
        uint256 currMints = numUserMints[msg.sender];
                
        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "User max mint limit");
        
        refundOverpay(price * quantity);

        numUserMints[msg.sender] = (currMints + quantity);
        totalSupplyPublic += quantity;

        _mint(msg.sender, quantity);
    }

    function setTokenDNA(uint256 _tokenId, uint256 _dna) external payable {
        require(!customizationPaused, "Customization paused");
        require(ownerOf(_tokenId) == msg.sender || owner() == msg.sender, "Not your token");

        tokenIdToDNA[_tokenId] = _dna;
    }

    /*
     *

    $$\    $$\ $$\                               $$$$$$$$\                              $$\     $$\                               
    $$ |   $$ |\__|                              $$  _____|                             $$ |    \__|                              
    $$ |   $$ |$$\  $$$$$$\  $$\  $$\  $$\       $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    \$$\  $$  |$$ |$$  __$$\ $$ | $$ | $$ |      $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
     \$$\$$  / $$ |$$$$$$$$ |$$ | $$ | $$ |      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
      \$$$  /  $$ |$$   ____|$$ | $$ | $$ |      $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
       \$  /   $$ |\$$$$$$$\ \$$$$$\$$$$  |      $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
        \_/    \__| \_______| \_____\____/       \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Note: You don't REALLY need this require statement since nothing should be querying for non-existing tokens after reveal.
            // That said, it's a public view method so gas efficiency shouldn't come into play.
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 shiftedTokenId = _tokenId + tokenIdShift;

        if (shiftedTokenId > MAX_SUPPLY) {
            shiftedTokenId = shiftedTokenId - MAX_SUPPLY;
        }

        if (revealed) {
            return IYouByPeaceRenderer(externalRenderer).tokenURI(shiftedTokenId); 
        }
        else {
            return hiddenURI;
        }
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function verifyPublicAllowList(address _address, bytes32[] memory _proof, bytes32 _root) public pure returns (bool) {
        return MerkleProof.verify(_proof, _root, keccak256(abi.encodePacked(_address)));
    }

    function getDnaByTokenId(uint256 _tokenId) public view returns (uint256) {
        return tokenIdToDNA[_tokenId];
    }
    
    // Not the most efficient function, but it's a view
        // This allows us to get the entire DNA mapping at once, for image generation
    function getTokenDNA() public view returns (uint256[] memory) {
        uint256[] memory fullDNA = new uint[](MAX_SUPPLY);

        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            fullDNA[i] = tokenIdToDNA[i+1];
        }

        return fullDNA;
    }

    /*
     *

     $$$$$$\                                                    $$$$$$$$\                              $$\     $$\                               
    $$  __$$\                                                   $$  _____|                             $$ |    \__|                              
    $$ /  $$ |$$\  $$\  $$\ $$$$$$$\   $$$$$$\   $$$$$$\        $$ |   $$\   $$\ $$$$$$$\   $$$$$$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\   $$$$$$$\ 
    $$ |  $$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\ $$  __$$\       $$$$$\ $$ |  $$ |$$  __$$\ $$  _____|\_$$  _|  $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$ |  $$ |$$ | $$ | $$ |$$ |  $$ |$$$$$$$$ |$$ |  \__|      $$  __|$$ |  $$ |$$ |  $$ |$$ /        $$ |    $$ |$$ /  $$ |$$ |  $$ |\$$$$$$\  
    $$ |  $$ |$$ | $$ | $$ |$$ |  $$ |$$   ____|$$ |            $$ |   $$ |  $$ |$$ |  $$ |$$ |        $$ |$$\ $$ |$$ |  $$ |$$ |  $$ | \____$$\ 
     $$$$$$  |\$$$$$\$$$$  |$$ |  $$ |\$$$$$$$\ $$ |            $$ |   \$$$$$$  |$$ |  $$ |\$$$$$$$\   \$$$$  |$$ |\$$$$$$  |$$ |  $$ |$$$$$$$  |
     \______/  \_____\____/ \__|  \__| \_______|\__|            \__|    \______/ \__|  \__| \_______|   \____/ \__| \______/ \__|  \__|\_______/ 

    *
    */

    function setFreeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRootFree = _merkleRoot;
    }

    function setAllowListMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRootAllowList = _merkleRoot;
    }

    function setFreeMintMax(uint256 _freeMintMax) public onlyOwner {
        freeListMax = _freeMintMax;
    }

    function setAllowListMax(uint256 _allowListMax) public onlyOwner {
        allowListMax = _allowListMax;
        publicMintMax = MAX_SUPPLY - freeListMax - _allowListMax;
    }    

    function setPublicLimitTotal(uint256 _publicLimitTotal) public onlyOwner {
        PUBLIC_MINT_LIMIT = _publicLimitTotal;
    }

    function setDevWithdrawCut(uint256 _devPercentage) public onlyOwner {
        DEV_WITHDRAW_PERCENT = _devPercentage;
    }

    function setArtistWithdrawCut(uint256 _artistPercentage) public onlyOwner {
        ARTIST_WITHDRAW_PERCENT = _artistPercentage;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        revealedURI = _baseUri;
    }

    // Note: This method can be hidden/removed if this is a constant.
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenURI = _hiddenMetadataUri;
    }

    function revealCollection(bool _revealed, string memory _baseUri) public onlyOwner {
        revealed = _revealed;
        revealedURI = _baseUri;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }
function commit(string memory _provanceHash) external payable onlyOwner {
        // Can only commit once
            // Note: A reveal has to happen within 256 blocks or this will break
        require(futureBlockToUse == 0, "Committed already");

        provanceHash = _provanceHash;
        futureBlockToUse = block.number + 5;
    }

    function reveal() external payable onlyOwner {
        require(futureBlockToUse != 0, "Commit first");

        require(block.number >= futureBlockToUse, "Wait for the future block");

        require(tokenIdShift == 0, "Revealed already");

        // Note: This is technically insufficient randomness, as a miner can
            // just throw away blocks with hashes they don't want.
            // That said, I don't expect this free mint during goblin town
            // to have > 3 ETH incentives.
        // https://soliditydeveloper.com/2019-06-23-randomness-blockchain
        // Note: We add one to this just in case the casted hash is
            // cleanly divisibly by MAX_SUPPLY
            // Trust me, this doesn't break randomness
        tokenIdShift = (uint256(blockhash(futureBlockToUse)) % MAX_SUPPLY) + 1;

        revealed = true;
    }

    function setCustomizationPaused(bool _state) public onlyOwner {
        customizationPaused = _state;
    }

    function setRendererAddress(address _renderer) public onlyOwner {
        externalRenderer = _renderer;
    }

    function withdraw() external payable onlyOwner {
        // Get the current funds to calculate initial percentages
        uint256 currBalance = address(this).balance;

        (bool succ, ) = payable(DEV_ADDRESS).call{
            value: (currBalance * DEV_WITHDRAW_PERCENT) / 10000
        }("");
        require(succ, "Dev transfer failed");

        (succ, ) = payable(DEV_ADDRESS_2).call{
            value: (currBalance * DEV_WITHDRAW_PERCENT_2) / 10000
        }("");
        require(succ, "Dev transfer2 failed");

        (succ, ) = payable(ARTIST_ADDRESS).call{
            value: (currBalance * ARTIST_WITHDRAW_PERCENT) / 10000
        }("");
        require(succ, "Artist transfer failed");

        (succ, ) = payable(FOUNDER_ADDRESS).call{
            value: (currBalance * FOUNDER_WITHDRAW_PERCENT) / 10000
        }("");
        require(succ, "Founder transfer failed");

        // Withdraw the ENTIRE remaining balance to the treasury wallet
        (succ, ) = payable(TREASURY_ADDRESS).call{
            value: address(this).balance
        }("");
        require(succ, "Treasury (remaining) transfer failed");
    }

    // Owner-only mint functionality to "Airdrop" mints to specific users
        // Note: These will likely end up hidden on OpenSea
    function mintToUser(uint256 quantity, address receiver) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "toUser MAX_SUPPLY");

        _mint(receiver, quantity);
    }

    /*
     *

    $$\      $$\                 $$\ $$\  $$$$$$\  $$\                               
    $$$\    $$$ |                $$ |\__|$$  __$$\ \__|                              
    $$$$\  $$$$ | $$$$$$\   $$$$$$$ |$$\ $$ /  \__|$$\  $$$$$$\   $$$$$$\   $$$$$$$\ 
    $$\$$\$$ $$ |$$  __$$\ $$  __$$ |$$ |$$$$\     $$ |$$  __$$\ $$  __$$\ $$  _____|
    $$ \$$$  $$ |$$ /  $$ |$$ /  $$ |$$ |$$  _|    $$ |$$$$$$$$ |$$ |  \__|\$$$$$$\  
    $$ |\$  /$$ |$$ |  $$ |$$ |  $$ |$$ |$$ |      $$ |$$   ____|$$ |       \____$$\ 
    $$ | \_/ $$ |\$$$$$$  |\$$$$$$$ |$$ |$$ |      $$ |\$$$$$$$\ $$ |      $$$$$$$  |
    \__|     \__| \______/  \_______|\__|\__|      \__| \_______|\__|      \_______/ 

    *
    */

    modifier mintCompliance(uint256 quantity) {
        require(!paused, "Contract is paused");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough mints left");
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}