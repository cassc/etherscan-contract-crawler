// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Kubics__MintClosed();
error Kubics__MintLimitReached();
error Kubics__MintALimitReached();
error Kubics__NFTMinted();
error Kubics__NeedToPayUp();
error Kubics__NotMoneyInContract();

contract DragonKeeper is
    ERC721,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    //Declaring all tokens Counters
    uint256 private s_mainTokenCounter;
    uint256 private s_tokenCounter_Legendary;
    uint256 private s_tokenCounter_UltraRare;
    uint256 private s_tokenCounter_Rare;
    uint256 private s_tokenCounter_Uncommon;
    uint256 private s_tokenCounter_Common;

    //Declaring accounts
    address private immutable i_owner;
    address private immutable i_founderAccountA;
    address private immutable i_founderAccountB;
    address private immutable i_devAccount;
    address private immutable i_marketingAccountA;
    address private immutable i_marketingAccountB;
    address private immutable i_designAccount;
    address private immutable i_DragonKeeper;
    address private immutable i_Koniec;
    address private immutable i_Kubics;

    //Declaring price Collections
    uint256 private price_Legendary;
    uint256 private price_UltraRare;
    uint256 private price_Rare;
    uint256 private price_Uncommon;
    uint256 private price_Common;

    //Declaring status
    bool public mintStatus;

    // Declaring mapping: URIs to 1 or 0 (true or false)
    mapping(string => uint8) existingURIs;

    //Constructor
    constructor() ERC721("DragonKeeper", "DKP") {
        //Setting accounts
        i_owner = msg.sender;
        i_founderAccountA = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        i_founderAccountB = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        i_devAccount = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        i_marketingAccountA = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        i_marketingAccountB = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;
        i_designAccount = 0x17F6AD8Ef982297579C203069C1DbfFE4348c372;
        i_DragonKeeper = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678;
        i_Koniec = 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7;
        i_Kubics = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C;

        //Setting price for each collection Mint
        price_Legendary = 0.5 ether; //0,5
        price_UltraRare = 0.4 ether; //0,4
        price_Rare = 0.3 ether; //0,3
        price_Uncommon = 0.2 ether; //0,2
        price_Common = 0.18 ether; //0,18

        //Setting status: true= open & false = closed
        mintStatus = true;
    }

    modifier mintCompliance(string memory metadataURI) {
        if (mintStatus != true) {
            revert Kubics__MintClosed();
        }
        if (s_mainTokenCounter >= 10588) {
            revert Kubics__MintLimitReached();
        }
        if (existingURIs[metadataURI] == 1) {
            revert Kubics__NFTMinted();
        }
        _;
    }

    //Function to pause the whole contract. This will stop the whole contract and disable token transfers to all accounts
    function pause() public onlyOwner {
        _pause();
    }

    //Function to unpause the whole contract. This will restart the whole contract and enable token transfers to all accounts
    function unpause() public onlyOwner {
        _unpause();
    }

    // Standard safeMint function
    function safeMint(address to, string memory metadataURI) public onlyOwner {
        uint256 tokenId = s_mainTokenCounter;
        s_mainTokenCounter = s_mainTokenCounter + 1;
        existingURIs[metadataURI] = 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataURI);
    }

    //Custom payToMint_Legendary function. Receive metadataURI. Initiall status: false (closed)
    function payToMint_Legendary(string memory metadataURI)
        public
        payable
        nonReentrant
        mintCompliance(metadataURI)
        returns (uint256)
    {
        //Modifier checks three main conditionals before executing the Mint
        //Checking specific conditionals before executing the Mint
        if (s_tokenCounter_Legendary >= 40) {
            revert Kubics__MintALimitReached();
        }
        if (msg.value < price_Legendary) {
            revert Kubics__NeedToPayUp();
        }

        // Updating s_mainTokenCounter
        uint256 tokenId = s_mainTokenCounter;
        s_mainTokenCounter = s_mainTokenCounter + 1;
        // Updating s_tokenCounterA
        s_tokenCounter_Legendary = s_tokenCounter_Legendary + 1;
        // Updating existingURIs
        existingURIs[metadataURI] = 1;
        // Calling Mint Function. Sending address (msg.sender) and TokenID
        _mint(msg.sender, tokenId);
        //Setting TokeURI. Sending TokenID and MetadataURI
        _setTokenURI(tokenId, metadataURI);

        return s_mainTokenCounter;
    }

    //Custom payToMint_UltraRare function. Receive metadataURI. Initiall status: false (closed)
    function payToMint_UltraRare(string memory metadataURI)
        public
        payable
        nonReentrant
        mintCompliance(metadataURI)
        returns (uint256)
    {
        //Modifier checks three main conditionals before executing the Mint
        //Checking specific conditionals before executing the Mint
        if (s_tokenCounter_UltraRare >= 216) {
            revert Kubics__MintALimitReached();
        }
        if (msg.value < price_UltraRare) {
            revert Kubics__NeedToPayUp();
        }

        // Updating s_mainTokenCounter
        uint256 tokenId = s_mainTokenCounter;
        s_mainTokenCounter = s_mainTokenCounter + 1;
        // Updating s_tokenCounterB
        s_tokenCounter_UltraRare = s_tokenCounter_UltraRare + 1;
        // Updating existingURIs
        existingURIs[metadataURI] = 1;
        // Calling Mint Function. Sending address (msg.sender) and TokenID
        _mint(msg.sender, tokenId);
        //Setting TokeURI. Sending TokenID and MetadataURI
        _setTokenURI(tokenId, metadataURI);

        return s_mainTokenCounter;
    }

    //Custom payToMint_Rare function. Receive metadataURI. Initiall status: false (closed)
    function payToMint_Rare(string memory metadataURI)
        public
        payable
        nonReentrant
        mintCompliance(metadataURI)
        returns (uint256)
    {
        //Modifier checks three main conditionals before executing the Mint
        //Checking specific conditionals before executing the Mint
        if (s_tokenCounter_Rare >= 972) {
            revert Kubics__MintALimitReached();
        }
        if (msg.value < price_Rare) {
            revert Kubics__NeedToPayUp();
        }

        uint256 tokenId = s_mainTokenCounter;
        s_mainTokenCounter = s_mainTokenCounter + 1;
        s_tokenCounter_Rare = s_tokenCounter_Rare + 1;
        existingURIs[metadataURI] = 1;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataURI);

        return s_mainTokenCounter;
    }

    //Custom payToMint_Uncommon function. Receive metadataURI. Initiall status: false (closed)
    function payToMint_Uncommon(string memory metadataURI)
        public
        payable
        nonReentrant
        mintCompliance(metadataURI)
        returns (uint256)
    {
        //Modifier checks three main conditionals before executing the Mint
        //Checking specific conditionals before executing the Mint
        if (s_tokenCounter_Uncommon >= 2880) {
            revert Kubics__MintALimitReached();
        }
        if (msg.value < price_Uncommon) {
            revert Kubics__NeedToPayUp();
        }

        uint256 tokenId = s_mainTokenCounter;
        s_mainTokenCounter = s_mainTokenCounter + 1;
        s_tokenCounter_Uncommon = s_tokenCounter_Uncommon + 1;
        existingURIs[metadataURI] = 1;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataURI);

        return s_mainTokenCounter;
    }

    //Custom payToMint_Common function. Receive metadataURI. Initiall status: false (closed)
    function payToMint_Common(string memory metadataURI)
        public
        payable
        nonReentrant
        mintCompliance(metadataURI)
        returns (uint256)
    {
        //Modifier checks three main conditionals before executing the Mint
        //Checking specific conditionals before executing the Mint
        if (s_tokenCounter_Common >= 6480) {
            revert Kubics__MintALimitReached();
        }
        if (msg.value < price_Common) {
            revert Kubics__NeedToPayUp();
        }

        uint256 tokenId = s_mainTokenCounter;
        s_mainTokenCounter = s_mainTokenCounter + 1;
        s_tokenCounter_Common = s_tokenCounter_Common + 1;
        existingURIs[metadataURI] = 1;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataURI);

        return s_mainTokenCounter;
    }

    // Function to withdraw all funds
    function Withdraw() public payable nonReentrant onlyOwner {
        if (address(this).balance <= 0) {
            revert Kubics__NotMoneyInContract();
        }
        uint256 balance_i_founderAccountA = (address(this).balance * 4) / 100; //4%
        uint256 balance_i_founderAccountB = (address(this).balance * 2) / 100; //2%
        uint256 balance_i_devAccount = (address(this).balance * 1) / 100; //1%
        uint256 balance_i_marketingAccountA = (address(this).balance * 5) /
            1000; //0,5%
        uint256 balance_i_marketingAccountB = (address(this).balance * 5) /
            1000; //0,5%
        uint256 balance_i_designAccount = (address(this).balance * 2) / 100; //2%
        uint256 balance_i_Koniec = (address(this).balance * 10) / 100; //10%
        uint256 balance_i_Kubics = (address(this).balance * 10) / 100; //10%

        // This will pay to one account 4% of the total withdraw amount to devAccount
        // =============================================================================
        (bool ow, ) = payable(i_founderAccountA).call{
            value: balance_i_founderAccountA
        }("");
        require(ow);
        // This will pay to one account 2% of the total withdraw amount to i_marketingAccount
        // =============================================================================
        (bool fnd, ) = payable(i_founderAccountB).call{
            value: balance_i_founderAccountB
        }("");
        require(fnd);
        // This will pay to one account 1% of the total withdraw amount to i_designAccount
        // =============================================================================
        (bool dv, ) = payable(i_devAccount).call{value: balance_i_devAccount}(
            ""
        );
        require(dv);
        // This will pay to one account 0,5%% of the total withdraw amount to i_founderAccountA
        // =============================================================================
        (bool mktA, ) = payable(i_marketingAccountA).call{
            value: balance_i_marketingAccountA
        }("");
        require(mktA);
        // This will pay to one account 0,5%% of the total withdraw amount to i_founderAccountB
        // =============================================================================
        (bool mktB, ) = payable(i_marketingAccountB).call{
            value: balance_i_marketingAccountB
        }("");
        require(mktB);
        // This will pay to one account 2% of the total withdraw amount to devAccount
        // =============================================================================
        (bool ds, ) = payable(i_designAccount).call{
            value: balance_i_designAccount
        }("");
        require(ds);
        // This will pay to one account 10% of the total withdraw amount to devAccount
        // =============================================================================
        (bool kn, ) = payable(i_Koniec).call{value: balance_i_Koniec}("");
        require(kn);
        // This will pay to one account 10% of the total withdraw amount to devAccount
        // =============================================================================
        (bool kb, ) = payable(i_Kubics).call{value: balance_i_Kubics}("");
        require(kb);
        // =============================================================================
        // This will pay the rest of the total (70% approx) withdraw amount to the DragonKeeper account
        (bool success, ) = i_DragonKeeper.call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    //Setter for all price collections

    function setPrice_Legendary(uint256 newPriceA) public onlyOwner {
        //Set the new price in Wei!
        price_Legendary = newPriceA;
    }

    function setPrice_UltraRare(uint256 newPriceB) public onlyOwner {
        //Set the new price in Wei!
        price_UltraRare = newPriceB;
    }

    function setPrice_Rare(uint256 newPriceC) public onlyOwner {
        //Set the new price in Wei!
        price_Rare = newPriceC;
    }

    function setPriceCollectionD(uint256 newPriceD) public onlyOwner {
        //Set the new price in Wei!
        price_Uncommon = newPriceD;
    }

    function setPrice_Common(uint256 newPriceE) public onlyOwner {
        //Set the new price in Wei!
        price_Common = newPriceE;
    }

    //Update token counter in case safeMint is used
    function setTokenCounter_Legendary() public onlyOwner {
        s_tokenCounter_Legendary = s_tokenCounter_Legendary + 1;
    }

    //Update token counter in case safeMint is used
    function setTokenCounter_UltraRare() public onlyOwner {
        s_tokenCounter_UltraRare = s_tokenCounter_UltraRare + 1;
    }

    //Update token counter in case safeMint is used
    function setTokenCounter_Rare() public onlyOwner {
        s_tokenCounter_Rare = s_tokenCounter_Rare + 1;
    }

    //Update token counter in case safeMint is used
    function setTokenCounter_Uncommon() public onlyOwner {
        s_tokenCounter_Uncommon = s_tokenCounter_Uncommon + 1;
    }

    //Update token counter in case safeMint is used
    function setTokenCounter_Common() public onlyOwner {
        s_tokenCounter_Common = s_tokenCounter_Common + 1;
    }

    // Setters for the status
    function setMintStatus(bool status) public onlyOwner {
        mintStatus = status;
    }

    // Required function to check if the contract is paused or not
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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

    // Getters functions

    //Get contract balance
    function getContractBalance() public view returns (uint256) {
        return uint256(address(this).balance);
    }

    //Get mainTokenId
    function getTokenCounter() public view returns (uint256) {
        return s_mainTokenCounter;
    }

    //Get s_tokenCounter_Legendary
    function getTokenCounter_Legendary() public view returns (uint256) {
        return s_tokenCounter_Legendary;
    }

    //Get s_tokenCounter_UltraRare
    function getTokenCounter_UltraRare() public view returns (uint256) {
        return s_tokenCounter_UltraRare;
    }

    //Get s_tokenCounter_Rare
    function getTokenCounter_Rare() public view returns (uint256) {
        return s_tokenCounter_Rare;
    }

    //Get s_tokenCounter_Uncommon
    function getTokenCounter_Uncommon() public view returns (uint256) {
        return s_tokenCounter_Uncommon;
    }

    //Get s_tokenCounter_Common
    function getTokenCounter_Common() public view returns (uint256) {
        return s_tokenCounter_Common;
    }

    // Function to know if an URI is owned
    function isContentOwned(string memory uri) public view returns (bool) {
        return existingURIs[uri] == 1;
    }

    //Function to point the contract to a metadata
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmX51CpHKAzY2jeXHZT8rudwcgmFb5QExk4HUXRUzMPmEr";
    }

    //Function to set the base URI
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }
}