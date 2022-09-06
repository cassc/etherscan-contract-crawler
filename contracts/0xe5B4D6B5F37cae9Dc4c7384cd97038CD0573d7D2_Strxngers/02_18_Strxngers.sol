//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.0;

/*
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                                            $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$            
                                        $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$         
                                        $$$J/ft////////////////////////xkkkkkkbbd&$$$         
                                    $$$$ZQQt}}/cvvvvvvvvvvvvvvvvvvvvvvvXpppqqqo##%$$$         
                                    $$$$t[}{{}ckddddddddddddddddddddddddpppbkkB$$$            
                                    $$$$j}{{{}[email protected]$$$$$$            
                                    $$$$j}{{}[ckkC}{{{{{{{{{{{{{}(tttt/v88%$$$$               
                                    $$$$j}{fnxucc/l!!!!!!!!!!!!!l+}[[[]t$$$$                  
                                    $$$$j}}CbkjIl!iiiiiiiiiiiiii!_}}}}[f$$$$                  
                                    $$$$j}}Jbkjli!!!!!!!!!!!!!!i!+}[[[]t$$$$                  
                                $$$%nrx\|(xzzt}}(nxxxxxuuunnu([[/cccXzJhhkZOO0               
                                $$$8<ll1\|){{(//umZmbbdzccJLLcxxCbbZvccUUJ000O               
                                $$$8+!i]}}~!!]/\nZOq$$8;'`{/\UZOo$$O.':\\t0ZOO               
                                $$$8<Il]}{~!i]t/umZp$$8:.'{\|UmO*$$0 ',\\/Q00O               
                                $$$%JXY]~+>!i+]](zcUook\)(uzcccvOooO)(\ccc0ZZ0               
                                    $$$$/][~!iii!+\(fOOOwwwmmwcffXZO0QQ0qqpk                  
                                    [email protected]@flii!!~{}\dddddddddpppppbJ[[f$$$$                  
                                        $$$fIl+]?/QQz<<<<<<<<<[))|t/nLCZ$$$$                  
                                    $$$$kddn)(){{xbbO]]]]]]]]](//fxrXbph$$$$                  
                                [email protected]%%x(|YZZu{{jqmqbbbbbbbbbbbbddddddh$$$$                  
                                [email protected]////tt/\\|))[email protected]@@$$$$                  
                                $$$WCCJ/\\\\\\\\\//\((\cczmwwwwwmmmmmZh$$$                      
                                $$$M|||\//rxxt\\\\\////\\/UJJJJJQOOOO0b$$$                      
                                $$$M\\////LZZu\/////\\\\\\\\\\\\YZOOO0b$$$                      
                                $$$M//////QmmO0000Ou<<+{{1\////\YZOZZOk$$$                      
                                $$$#]]]]]]\tttff\))]!!>___)))\/\YZZYnxQ$$$                      
                                $$$o!!iiii!!!!!!lll!iii!!i[}}|/\YZZx[]v$$$                      
                                $$$o!!!!!!!!!!!lxooUl!!!!i[}}|/\YZZn[[c$$$                      
                                $$$*---????????_c#*L-?????/tt/\\YZZf<>r$$$                      
                                $$$MXYXrjjjjjjjjJbb0jjjjjjfff//\YZmt!lf$$$                      
                                $$$$wZZZZZZZZZOOOZZZZZOt\\//\YZmt!lf$$$                      
                                
:'######:::::'########::::'########:::::'##::::'##::::'##::: ##:::::'######::::::'########::::'########::::::'######::
'##... ##::::... ##..::::: ##.... ##::::. ##::'##::::: ###:: ##::::'##... ##::::: ##.....::::: ##.... ##::::'##... ##:
 ##:::..:::::::: ##::::::: ##:::: ##:::::. ##'##:::::: ####: ##:::: ##:::..:::::: ##:::::::::: ##:::: ##:::: ##:::..::
. ######:::::::: ##::::::: ########:::::::. ###::::::: ## ## ##:::: ##::'####:::: ######:::::: ########:::::. ######::
:..... ##::::::: ##::::::: ##.. ##:::::::: ## ##:::::: ##. ####:::: ##::: ##::::: ##...::::::: ##.. ##:::::::..... ##:
'##::: ##::::::: ##::::::: ##::. ##:::::: ##:. ##::::: ##:. ###:::: ##::: ##::::: ##:::::::::: ##::. ##:::::'##::: ##:
. ######:::::::: ##::::::: ##:::. ##:::: ##:::. ##:::: ##::. ##::::. ######:::::: ########:::: ##:::. ##::::. ######::
:......:::::::::..::::::::..:::::..:::::..:::::..:::::..::::..::::::......:::::::........:::::..:::::..::::::......:::

                                                                                                                                                                                        
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IStrxngersMetadata} from "./interfaces/IStrxngersMetadata.sol";

contract Strxngers is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string public STRXNGERS_PROVENANCE = "";

    string private baseURI;
    // openSeaProxyRegistryAddress
    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;

    // Max strxngers amount.
    uint256 public constant MAX_STRXNGERS = 6666;

    // Wallet max strxngers amount.
    uint256 public constant MAX_STRXNGERS_PER_WALLET_LIMIT = 5;

    // Max free minting amount.
    uint256 public constant MAX_FREE_MINTING_STRXNGERS = 433;

    // Max gifted amount.
    uint256 public constant MAX_GIFT_STRXNGERS = 400;

    bool public isPublicSaleActive;

    bool public isFreeMintActive;

    // RESERVED
    bool public useMetaDataContract = false;

    // RESERVED
    address public metaDataAddress;

    uint256 public numMintedStrxngers;

    uint256 public numGiftedStrxngers;

    uint256 public numFreeMintedStrxngers;

    mapping(address => bool) public freeMintedCounts;

    mapping(address => uint256) public numWalletMints;

    // ============ ACCESS CONTROL MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier freeMintActive() {
        require(isFreeMintActive, "Free Mint is not open");
        _;
    }

    modifier maxStrxngersPerWallet(uint256 numberOfTokens) {
        uint256 walletCurMints = numWalletMints[msg.sender];
        require(
            walletCurMints + numberOfTokens <= MAX_STRXNGERS_PER_WALLET_LIMIT,
            "Can only mint 5 strxngers pre wallet"
        );
        _;
    }

    modifier canMintStrxngers(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <= MAX_STRXNGERS,
            "Not enough strxngers remaining to mint"
        );
        _;
    }

    modifier canFreeMintStrxngers(uint256 numberOfTokens) {
        require(
            !freeMintedCounts[msg.sender],
            "Strxnger already free minted by this wallet"
        );
        require(
            numFreeMintedStrxngers + numberOfTokens <=
                MAX_FREE_MINTING_STRXNGERS,
            "Not enough strxngers remaining to free mint"
        );
        require(
            tokenCounter.current() + numberOfTokens <= MAX_STRXNGERS,
            "Not enough strxngers remaining to mint"
        );
        _;
    }

    modifier canGiftStrxngers(uint256 numberOfTokens) {
        require(
            numGiftedStrxngers + numberOfTokens <= MAX_GIFT_STRXNGERS,
            "Not enough strxngers remaining to gift"
        );
        require(
            tokenCounter.current() + numberOfTokens <= MAX_STRXNGERS,
            "Not enough strxngers remaining to gift"
        );
        _;
    }

    modifier isCorrectPayment(uint256 numberOfTokens) {
        uint256 price = 0.01 ether;

        if (numMintedStrxngers + numberOfTokens > 2500) {
            price = 0.02 ether;
        }

        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    constructor(address _openSeaProxyRegistryAddress)
        ERC721("Strxngers", "SXNR")
    {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        callerIsUser
        isCorrectPayment(numberOfTokens)
        publicSaleActive
        canMintStrxngers(numberOfTokens)
        maxStrxngersPerWallet(numberOfTokens)
    {
        uint256 walletCurMints = numWalletMints[msg.sender];
        numWalletMints[msg.sender] = (walletCurMints + numberOfTokens);

        for (uint256 i = 0; i < numberOfTokens; i++) {
            numMintedStrxngers += 1;
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function freeMint()
        external
        callerIsUser
        freeMintActive
        canFreeMintStrxngers(1)
    {
        freeMintedCounts[msg.sender] = true;
        numFreeMintedStrxngers += 1;

        _safeMint(msg.sender, nextTokenId());
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    function totalSupply() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        STRXNGERS_PROVENANCE = _provenanceHash;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsFreeMintActive(bool _isFreeMintActive) external onlyOwner {
        isFreeMintActive = _isFreeMintActive;
    }

    function setMetaDataAddress(address _metaDataAddress) external onlyOwner {
        metaDataAddress = _metaDataAddress;
    }

    function setUseMetaDataContract(bool _useMetaDataContract)
        external
        onlyOwner
    {
        useMetaDataContract = _useMetaDataContract;
    }

    function reserveForGifting(uint256 numToReserve)
        external
        nonReentrant
        onlyOwner
        canGiftStrxngers(numToReserve)
    {
        numGiftedStrxngers += numToReserve;

        for (uint256 i = 0; i < numToReserve; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function batchGiftStrxngers(address dropAddress, uint256 numToGift)
        external
        nonReentrant
        onlyOwner
        canGiftStrxngers(numToGift)
    {
        numGiftedStrxngers += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(dropAddress, nextTokenId());
        }
    }

    function giftStrxngers(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canGiftStrxngers(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGiftedStrxngers += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], nextTokenId());
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // ============ FUNCTION OVERRIDES ============

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            useMetaDataContract
                ? IStrxngersMetadata(metaDataAddress).tokenURI(tokenId)
                : string(
                    abi.encodePacked(baseURI, "/", tokenId.toString(), ".json")
                );
    }

}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}