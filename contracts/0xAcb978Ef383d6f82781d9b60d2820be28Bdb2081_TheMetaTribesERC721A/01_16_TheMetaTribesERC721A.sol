// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @author Ben BK https://twitter.com/BenBKTech
/// @title the MetaTribes by Anthrometa-v1

// @@@@@@@@@@@@@@@@@P?:..::!??Y5GGJ?Y&&&&&&&B#&&&&&&&&&##GPPBBP5YJY5PGP55GB&@@@@@@@
// @@@@@@@@@@@@@@@@#?....:~7?JYGPJ?!J&&&&&&&&&#&&&&&&###[email protected]@@@@@@
// @@@@@@@@@@@@@@@@G:  ..^~77YG5?J!^7&&&&@@@@@&&#&&&&&&###GGPJ^^[email protected]@@@@@
// @@@@@@@@@@@@@@@@5. ..:^!?PPJJ7?~~7&&&&@@@@&&&&######BBBGGP~::.:^[email protected]@@@@@
// @@@@@@@@@@@@@@@@5: .:^!5P5?J???!~J&&&&@@@&&&&&&&&#BBBGGGGY^::::^~?JY5GBB##@@@@@@
// @@@@@@@@@@@@@@@@#^ .^7JYJ??Y77?!~5&&&&&@@&&&&&&&&&&#BBBBGJ^::.:^^7?YPBBB##&@@@@@
// @@@@@@@@@@@@@@@@@!:~!~~?JJYYJ777!5&&&&&&&&&&&&####BBB###GJ^::::!7JYPB##&&&#&@@@@
// @@@@@@@@@@@@@@@@@?..^^^!?YPP5??7!5&&&&&&&&&&&&##BB#B##BPY?777!!?YPPG#&&&&&&&@@@@
// @@@@@@@@@@@@@@@@@P::::^~75GGGY?7~5&&&&&&&&&&&&&##G##&BGP?~^^^!?YPGB##&##&&&@@@@@
// @@@@@@@@@@@@@@@@@&B&#P7?55GBBBY!~P&&&&&&&&&&&&&&&BB&&BBBB5!~~~75GB####B#&&&@@@@@
// @@@@@@@@@@@@@@@@@@&@@@&BY5G##&G!^Y&&#&&&@@@@&&&####BGG&&&@P77?YG#&&&&&P&&&&@@@@@
// @@@@@@@@@@@@@@@@@@&@@@@&!^Y5YPGJ~Y###&@@@&#BBBBB&&#GPB&@@@@B5Y5##&&&&BG&&#&@@@@@
// @@@@@@@@@@@@@@@@@@&&@@@@&5JBBGP5!Y###B&&BBBB#&&&&&PJ5P#@@@@@B5P##&&&&5##&&@@@@@@
// @@@@@@@@@@@@@@@@@@&Y#@@@&G5B#GP7!YBBBG&B7J5P&&G&#B??#B5&@@@&GPGB#&&#GP&#&&@@@@@@
// @@@@@@@@@@@@@@@@@@@Y^5&@@#5PPG#G~JBBB#[email protected]&&#&&&#&&#GP##&&#G55PGB####BY#&&&&&&@@@@
// @@@@@@@@@@@@@@@@@@@5~.:J#@@@#B#P:JGPG&#@@&&@&&@@@&&#BG5YJYYPPG#BB##YG&&&&&@&@@@@
// @@@@@@@@@@@@@@@@@@@Y?:..^#@@@&@?.YBYG#&@@&#&@@@&&GP5JJJJY5PPPPGGGGP5&&&&@@@@@@@@
// @@@@@@@@@@@@@@@@@@@Y75!^[email protected]@BGB:.5BGGG#&&&BB&@@BB5YYJYY5Y55YY55555Y##&&&@&@@@@@@
// @@@@@@@@@@@@@@@@@@B^^GG7!P&@&G~..P##PPBBYYGB&@&GBP5PPGGP555YJJJYYJ##&&&&@@#&@@@@
// @@@@@@@@@@@@@@@@@@5!55GJ~J#@@&G7.5B##BGG5P#&&@&B#B5P&BGYJ?5PJJJYJB#&&##&&@@GP&&5
// @@@@@@@@@@@@@@@@@@5Y&#BY:[email protected]@@&&YYG#@#B#B#&#&@&BP5P#&##BP5PGYJJ?5B#&&&&#B#@@YJPJ
// @@@@@@@@@@@@@@@@@@@@PPG^ [email protected]@@@&BG###&#G#&&&@@#GY77G##&#B5P5J?7JYGB###BPBPG&&?JP
// @@@@@@@@@@@@@@@@@@&GY~!  [email protected]@&&G7B&BGG#P#PG&@@#Y?7!7PGGBP5J!7!7?JP###GGGGPPP&!Y#
// @@@@@&&&@@@@@@@@@B7?Y:.  [email protected]@@&5J#&##&&&&BG#@@B7~~!!!7J?777!!!~!?PGP5GBGGGGGG ^B
// !~!?JYYPB#BGGBGPP?PBY:.. [email protected]@@@B5B#####&&##&@@G!!!77!!!!!7!!!^^~?55Y#&&BBGB&B:.J
// !?7~^~~~:.  :[email protected]&&#Y~::[email protected]@@&&&&###BGB&&&&@&P!!!7777?7!!~~^^^7J?7P&@&&#B#@@#~.
// YYY5Y7^!P5^~YG#&B5YBB!~::[email protected]@&&@@&&#B##&##&@@&P~^~!!!77?7~~~!7??YP?^^?G&&#B&@@@#
// 555PPGP~:?YY5PY^.~B&@P7?^[email protected]@&&&@@&&#&&@#&@@@&P?7!77777?7!7?77YP&&&&GJ~~75BB#@@@
// BBGGG#&&BB#PY7:^?#@@@@Y?~?GG&&&@@@@&&&&@@@@@@&Y~!!~~~!7JYY?J5G#&@@@@@&&&#B##BB#&
// B&&&&&&&&@@P~:7#&@@@@@&7~?Y~#@@@@&@@&&&@@@@@@&?^^^~~!???JP#&#GG&@@@@@@@@@@@@&&##
// &&&&@&&&@@#GYG&&@@@@@#BG7YJ^#@@@@@@@@@@@@@@@@B7^~7JJ!7YB&@@&[email protected]@@@@@&&&@@@@@&#B
// &&@@&&@@#?~P#&@@@@@@@&&&PP?^#@@@@@@@@@@@@@@@@P77!!7JP&@@@@@&J7&@@@@@@@&&#&@@@&~.
// &&&&&@#Y^5BY&@@@@@@&&@@@&BJJ&@@@@@@@@@@@@@@@@5?7?5#@@@@@@@@&[email protected]@@@@@@@@@@&&@@@J:
// &&&&&575P&@&&&@@@@&&#B#&@@&&@&@@@@@@@@@@@@@@&GB&@@@@@@@@@@@&5#@@@@@@@@@@@@@@@@@#
// &@@B!~P&@@@@@@@@@&G5#P7?P#@@@&@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@#@@@@@@@@@@@@@@@@@@?
// #BG!^7PGG#&@@@@&&P?G#5~: :#@&#&@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@@@@@@@@@@@&&&&@&&&
//  .  .:^~!7Y&@@@@&GBBJ^~^:~#B#&&@@@@@@@@@@@@@@@@@@@@@&#B&@@@@@@@@@@&&&@&&&&&@&&&&
//  ...^[email protected]@@@@@@BJ7::7&&@@@@@@@@@@@@@@@@@@@@@@@@B7P&&&&&&&&&&&&&&&@@@@@@@@@&
// .^!~GPYYPB#&#B&@@@@@@@G^^[email protected]@@@@@@@&&@@@@@@@&@@@@@@@@&&&&&&#&&&@@@@@@@@@@@&&#BBB#
// :!7~!PBGGBB##&##&@@@@@@#[email protected]@@@@@@@&&@@@@@@@@&@@@@@@@@@&&&&##&&@@@@@@@@@&#GY~:....
// ^7JJ7!7PB##B##&&&###&&@@@@@@&#B&&&@@@@@@@@@&&@@@@@@@@&#GB#&@@@@@@@@@&&&&&&&BPJ!^
// ~?JJY5YJY5PB##&&&&&&##BGGBG5775B&@@@@@@@@@&&@@@&@@@@@@&@@@@@@@@@@&&&&&&&&&&&&&&#
// :!YB##BP5YJ55B#&&#&&&&&&&#G5YJJ5B&@@@@&&#&&@@@@&@@@@@@&&&&@@&&&&&&&&&&&&&&&&&#&&
// .!B&&BJ?7^~J5PGB##&&&##&&&&&&&&&&#&@@&###BB###&&&&&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&
// !B&#P?!~^:755GGGGB&&&&&&&&&&&&&&&&@@@&&&&&&&&&&&&#####&##&&&&&&&&&&&&&&&&&&&&&&&
// ##PY7~^~?5GPPGGGB#&&&&&&&&&&&&&&&@@@@@&&&&&&&&&&&&&&&&&&&&&@&&&&&&&&&&&&&&&&&&&&
// P?77~:^7Y5GGBBGG##&&BB&&&&&&&&&&&@@@&@&&&&&&&&&&&&&&&&&&&&&&&&&&B#&&&&&&&&&&&&#G

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract TheMetaTribesERC721A is Ownable, ERC721A, PaymentSplitter {
    //To concatenate the URL of an NFT
    using Strings for uint;

    //The different steps of the sale by Anthrometa-v1
    enum Step {
        Before,
        Presale,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    Step public sellingStep;

    //The total number of NFTs
    uint private constant MAX_SUPPLY = 8888;
    //The amount for gift 
    uint private constant MAX_GIFT = 100;
    //The amount for the presale (dutch auction)
    uint private constant MAX_PRESALE = 6788;
    //The amount for the whitelist sale
    uint private constant MAX_WHITELIST = 2000;
    //The amount for the presale AND for the whitelist 
    uint private constant MAX_PRESALE_AND_WHITELIST = MAX_PRESALE + MAX_WHITELIST;
    //The total number of NFTs minus gift 
    uint private constant MAX_SUPPLY_MINUS_GIFT = MAX_SUPPLY - MAX_GIFT;

    //The price for the whitelist sale & public sale
    uint public wlSalePrice;
    uint public publicSalePrice;

    //When the presale (dutch auction) starts
    uint public saleStartTime = 1646413200;

    //The Merkle Root
    bytes32 public merkleRoot;

    //base URI of the NFTs
    string public baseURI;

    //Number of NFTs/Wallet Whitelist 
    mapping(address => uint) public amountNFTsperWalletWhitelistSale;
    
    //Amount of NFTs per Wallet for presale and whitelist sale Mint
    uint private constant maxPerAddressDuringPresaleMint = 5;
    uint private constant maxPerAddressDuringWhitelistMint = 1;

    //Managing the price by Anthrometa-v1
    uint private constant DUTCH_AUCTION_PRICE_START = 1 ether;
    uint private constant DUTCH_AUCTION_PRICE_END = 0.15 ether;
    uint private constant DUTCH_AUCTION_DURATION = 340 minutes;
    uint private constant DUTCH_AUCTION_DROP_INTERVAL = 20 minutes;
    uint private constant DUTCH_AUCTION_DROP_PER_STEP = (DUTCH_AUCTION_PRICE_START - DUTCH_AUCTION_PRICE_END) /
    (DUTCH_AUCTION_DURATION / DUTCH_AUCTION_DROP_INTERVAL);

    //Is the contract paused ?
    bool public isPaused;

    //Number of addresses in the paymentSplitter
    uint private teamLength;

    //How Anthrometa-v1 is creating the MetaTribes to save the planet
    constructor(
        address[] memory _team, 
        uint[] memory _teamShares, 
        bytes32 _merkleRoot, 
        string memory _baseURI) 
    ERC721A("The MetaTribes", "TMT") 
    PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        teamLength = _team.length;
    }
    

    /**
    * @notice Get the price of 1 NFT during the Presale (dutch auction)
    *
    * @return the price of 1 NFT in Wei during the Presale (dutch auction)
    **/
    function getPresalePrice() public view returns(uint) {
        if (currentTime() < saleStartTime) {
            return DUTCH_AUCTION_PRICE_START;
        }

        if (currentTime() - saleStartTime >= DUTCH_AUCTION_DURATION) {
            return DUTCH_AUCTION_PRICE_END;
        } else {
            uint256 intervalCount = (currentTime() - saleStartTime) /DUTCH_AUCTION_DROP_INTERVAL;
            return DUTCH_AUCTION_PRICE_START - (intervalCount * DUTCH_AUCTION_DROP_PER_STEP);
        }
    }

    /**
    * @notice Anthrometa-v1 does not want his contract to be called by other AIs
    **/
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    * @notice Mint function for the Presale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFTs the user wants to mint
    **/
    function presaleMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is paused");
        uint price = getPresalePrice();
        require(currentTime() >= saleStartTime, "Presale has not started yet");
        require(currentTime() < saleStartTime + DUTCH_AUCTION_DURATION, "Presale Mint is finished");
        require(sellingStep == Step.Presale, "Presale has not started yet");
        require(
        totalSupply() + _quantity <= MAX_PRESALE, "Not enough remaining reserved for presale to support desired mint amount");
        require(_numberMinted(msg.sender) + _quantity <= maxPerAddressDuringPresaleMint, "You can't mint so much");
        require(msg.value >= price * _quantity, "Not enought funds");
        _safeMint(_account, _quantity);
    }

    /**
    * @notice Mint function for the Whitelist Sale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFTs the user wants to mint
    * @param _proof The Merkle Proof
    **/
    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(!isPaused, "Contract is paused");
        uint price = wlSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= maxPerAddressDuringWhitelistMint, 
        "You can only get 1 NFT on the Whitelist Sale");
        require(totalSupply() + _quantity <= MAX_PRESALE_AND_WHITELIST, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    /**
    * @notice Mint function for the Public Sale
    *
    * @param _account Account which will receive the NFT
    * @param _quantity Amount of NFTs the user wants to mint
    **/
    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is paused");
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(totalSupply() + _quantity <= MAX_SUPPLY_MINUS_GIFT, "Max supply exceeded");
        require(msg.value >= price * _quantity, "Not enought funds");
        _safeMint(_account, _quantity);
    }

    /**
    * @notice Allows the owner to gift NFTs
    *
    * @param _to The address of the receiver
    * @param _quantity Amount of NFTs the owner wants to gift
    **/
    function gift(address _to, uint _quantity) external onlyOwner {
        require(sellingStep > Step.PublicSale, "Gift is after the public sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(_to, _quantity);
    }

    /**
    * @notice Allows to set the whitelist sale price
    */
    function setWlSalePrice(uint _wlSalePrice) external onlyOwner {
        wlSalePrice = _wlSalePrice;
    }

    /**
    * @notice Allows to set the public sale price
    */
    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }
    
    /**
    * @notice Change the starting time (timestamp) of the Presale (dutch auction)
    *
    * @param _saleStartTime The starting timestamp of the Presale (dutch auction)
    **/
    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    /**
    * @notice Get the current timestamp
    *
    * @return the current timestamp
    **/
    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

    /**
    * @notice Get the token URI of an NFT by his ID
    *
    * @param _tokenId The ID of the NFT you want to have the URI
    **/
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
    * @notice Change the step of the sale
    *
    * @param _step The new step of the sale
    **/
    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    /**
    * @notice Pause or unpause the smart contract
    *
    * @param _isPaused true or false if we want to pause or unpause the contract
    **/
    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    /**
    * @notice Change the base URI of the NFTs
    *
    * @param _baseURI The new base URI of the NFTs
    **/
    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
 
    /**
    * @notice Change the Merkle Root
    *
    * @param _merkleRoot The new Merkle Root
    **/
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    * @notice Check if an address is whitelisted
    *
    * @param _account The address checked
    * @param _proof The Merkle proof
    * 
    * @return bool return true if the address is whitelisted, false otherwise
    **/
    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account), _proof);
    }

    /**
    * @notice Hash an address
    *
    * @param _account The address to be hashed
    * 
    * @return bytes32 The hashed address
    **/
    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    /** 
    * @notice Returns true if a leaf can be proved to be a part of a Merkle tree defined by root
    *
    * @param _leaf The leaf
    * @param _proof The Merkle Proof
    *
    * @return True if a leaf can be provded to be a part of a Merkle tree defined by root
    **/
    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    /** 
    * @notice Release the gains on every accounts
    **/
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    /**
    * Not allowing receiving ether outside minting functions
    */
    receive() override external payable {
        revert('Only if you mint');
    }
}