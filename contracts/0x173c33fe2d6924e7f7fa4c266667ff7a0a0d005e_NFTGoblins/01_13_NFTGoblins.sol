//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IGoblinRenderer.sol";

/*
NFTGoblins.sol

Contract by @NftDoyler
*/

// Setup OpenSea for gas-free listings
// Example from - https://github.com/nftchance/nft-marketapproved/blob/master/contracts/MockToken.sol
contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NFTGoblins is Ownable, ERC721A {
    uint256 constant public MAX_SUPPLY = 2222;

    uint256 constant public TEAM_MINT_MAX = 222;
    
    uint256 constant public PUBLIC_MINT_LIMIT_TXN = 5;
    uint256 constant public PUBLIC_MINT_LIMIT = 10;

    uint256 public TOTAL_SUPPLY_TEAM;

    // A block to use in the future to shift the tokenIDs
    uint256 public futureBlockToUse;

    // How far to shift the tokenID during the reveal
    uint256 public tokenIdShift;

    string constant public HIDDEN_URI = "ipfs://Qmbjwrtn89oiWHWfbG1SV8ff56nz6b7XxF1HizWtgcdoB2";

    // OpenSea CONTRACT_URI - https://docs.opensea.io/docs/contract-level-metadata
    string public contractMetadataUri = "ipfs://Qmbjwrtn89oiWHWfbG1SV8ff56nz6b7XxF1HizWtgcdoB2";

    // Provance hash of the un-shifted images
    string public provanceHash;

    bool public paused = true;
    bool public revealed = false;

    // Where the renderer is located - now you degens can have it on-chain later as well
    address public goblinRenderer;
    
    address public teamWalletAddress = 0x1dCA02DbbA7Da8767dB485624E718243013126A3;

    // Proxy to register, this will be OS
    address public proxyRegistryAddress;

    // Whether or not a user has enabled/disabled the auto-OS access
    mapping(address => bool) public addressToRegistryStatus;

    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("GoblinsNFT", "GOBS") {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    }

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

    function teamMint(uint256 quantity) external payable mintCompliance(quantity) {
        // Note: Remove if the owner will be minting
        require(msg.sender == teamWalletAddress, "Team minting only");
        require(TOTAL_SUPPLY_TEAM + quantity <= TEAM_MINT_MAX, "No team mints left");

        TOTAL_SUPPLY_TEAM += quantity;

        _safeMint(msg.sender, quantity);
    }
    
    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        uint256 currMints = numUserMints[msg.sender];
                
        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "User max mint limit");
        
        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
    }

    // Allow individual users to enable/disable their auto-OS approval
    function flipProxyState() external payable onlyOwner {
        addressToRegistryStatus[msg.sender] = !addressToRegistryStatus[msg.sender];
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

    // Note: walletOfOwner is only really necessary for enumerability when staking/using on websites etc.
        // That said, it's a public view so we can keep it in.
        // This could also be optimized if someone REALLY wanted, but it's just a public view.
        // Check the pinned tweets of 0xInuarashi for more ideas on this method!
        // For now, this is just the version that existed in v1.
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
            return IGoblinRenderer(goblinRenderer).tokenURI(shiftedTokenId); 
        }
        else {
            return HIDDEN_URI;
        }
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    // https://ethereum.stackexchange.com/questions/110924/how-to-properly-implement-a-contracturi-for-on-chain-nfts
    function contractURI() public view returns (string memory) {
        return contractMetadataUri;
    }

    function isApprovedForAll(address _owner, address _spender) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);

        if(address(proxyRegistry.proxies(_owner)) == _spender && addressToRegistryStatus[_owner]) {
            return true;
        }

        return super.isApprovedForAll(_owner, _spender);
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

    // As always, setting external methods to be payable saves a hilariously
        // small amount of gas. Only use if you are the only caller OR
        // you explain what's going on.
    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory _contractURI) public onlyOwner {
        contractMetadataUri = _contractURI;
    }

    function setRendererAddress(address _renderer) external payable onlyOwner {
        goblinRenderer = _renderer;
    }

    function setTeamWalletAddress(address _teamWallet) external payable onlyOwner {
        teamWalletAddress = _teamWallet;        
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external payable onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
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

    // Note: Another option is to inherit Pausable without implementing the logic yourself.
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
    function setPaused(bool _state) external payable onlyOwner {
        paused = _state;
    }

    function withdraw() external payable onlyOwner {
        (bool succ, ) = payable(owner()).call{
        //(succ, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(succ, "Owner transfer failed");
    }

    // Owner-only mint functionality to "Airdrop" mints to specific users
        // Note: These will likely end up hidden on OpenSea
    function mintToUser(uint256 quantity, address receiver) external payable onlyOwner mintCompliance(quantity) {
        _safeMint(receiver, quantity);
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
        require(msg.value == 0, "Free mints only");
        _;
    }
}