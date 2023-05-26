//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
GoblinGrlz.sol

Contract by @NftDoyler
*/

contract GoblinGrlz is Ownable, ERC721A {
    uint256 constant public MAX_SUPPLY = 5000;
    uint256 public TEAM_MINT_MAX = 30;

    uint256 public publicPrice = 0.005 ether;

    uint256 constant public PUBLIC_MINT_LIMIT_TXN = 10;
    uint256 constant public PUBLIC_MINT_LIMIT = 20;

    uint256 public TOTAL_SUPPLY_TEAM;

    string public revealedURI;
    
    string public hiddenURI = "ipfs://QmRDWZrGtJqeX29JbZUFtvZ2Wey4p8HNa2uMqdmfb6oHwd";

    // OpenSea CONTRACT_URI - https://docs.opensea.io/docs/contract-level-metadata
    string public CONTRACT_URI = "ipfs://QmRDWZrGtJqeX29JbZUFtvZ2Wey4p8HNa2uMqdmfb6oHwd";

    bool public paused = true;
    bool public revealed = false;

    bool public freeSale = true;
    bool public publicSale = false;

    address constant internal CHARITY_ADDRESS = 0x2bda8cE2c8Bad94C02d9890447aD3dF57fd3a4e3;
    address constant internal DEV_ADDRESS = 0x31f8933601497fD6Ade6EaEaA6a66b281d238E70;
    address constant internal WEB_ADDRESS = 0x2a6C2fb70703ef1901Dd61b8Dce90B7ACAd87700;
    address public teamWallet = 0x5AA0c01d481546c388Ef28f495dD1e898399A4E9;

    mapping(address => bool) public userMintedFree;
    mapping(address => uint256) public numUserMints;

    constructor() ERC721A("GOBLIN GRLZ", "GOBGRZ") { }

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

    function teamMint(uint256 quantity) public payable mintCompliance(quantity) {
        require(msg.sender == teamWallet, "Team minting only");
        require(TOTAL_SUPPLY_TEAM + quantity <= TEAM_MINT_MAX, "No team mints left");
        require(totalSupply() >= 1000, "Team mints after free");

        TOTAL_SUPPLY_TEAM += quantity;

        _safeMint(msg.sender, quantity);
    }
    
    function freeMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(freeSale, "Free sale inactive");
        require(msg.value == 0, "This phase is free");
        require(quantity == 1, "Only 1 free");

        uint256 newSupply = totalSupply() + quantity;
        
        require(newSupply <= 1000, "Not enough free supply");

        require(!userMintedFree[msg.sender], "User max free limit");
        
        userMintedFree[msg.sender] = true;

        if(newSupply == 1000) {
            freeSale = false;
            publicSale = true;
        }

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        require(publicSale, "Public sale inactive");
        require(quantity <= PUBLIC_MINT_LIMIT_TXN, "Quantity too high");

        uint256 price = publicPrice;
        uint256 currMints = numUserMints[msg.sender];
                
        require(currMints + quantity <= PUBLIC_MINT_LIMIT, "User max mint limit");
        
        refundOverpay(price * quantity);

        numUserMints[msg.sender] = (currMints + quantity);

        _safeMint(msg.sender, quantity);
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
        
        if (revealed) {
            return string(abi.encodePacked(revealedURI, Strings.toString(_tokenId), ".json"));
        }
        else {
            return hiddenURI;
        }
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    // https://ethereum.stackexchange.com/questions/110924/how-to-properly-implement-a-contracturi-for-on-chain-nfts
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
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

    function setTeamMintMax(uint256 _teamMintMax) public onlyOwner {
        TEAM_MINT_MAX = _teamMintMax;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
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

    // https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    // Note: Another option is to inherit Pausable without implementing the logic yourself.
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setPublicEnabled(bool _state) public onlyOwner {
        publicSale = _state;
        freeSale = !_state;
    }
    function setFreeEnabled(bool _state) public onlyOwner {
        freeSale = _state;
        publicSale = !_state;
    }

    function setTeamWalletAddress(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function withdraw() external payable onlyOwner {
        // Get the current funds to calculate initial percentages
        uint256 currBalance = address(this).balance;

        (bool succ, ) = payable(DEV_ADDRESS).call{
            value: (currBalance * 2833) / 10000
        }("");
        require(succ, "Dev transfer failed");

        (succ, ) = payable(WEB_ADDRESS).call{
            value: (currBalance * 2833) / 10000
        }("");
        require(succ, "Web transfer failed");

        (succ, ) = payable(CHARITY_ADDRESS).call{
            value: (currBalance * 1500) / 10000
        }("");
        require(succ, "Charity transfer failed");

        // Withdraw the ENTIRE remaining balance to the team wallet
        (succ, ) = payable(teamWallet).call{
            value: address(this).balance
        }("");
        require(succ, "Team (remaining) transfer failed");
    }

    // Owner-only mint functionality to "Airdrop" mints to specific users
        // Note: These will likely end up hidden on OpenSea
    function mintToUser(uint256 quantity, address receiver) public onlyOwner mintCompliance(quantity) {
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
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}