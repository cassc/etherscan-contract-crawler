/*                                                                                                             
      # ###                                                       #####   ##    ##                ##            
    /  /###                                                    ######  /#### #####                 ##           
   /  /  ###                                                  /#   /  /  ##### #####               ##           
  /  ##   ###                                                /    /  /   # ##  # ##                ##           
 /  ###    ###                                                   /  /    #     #                   ##           
##   ##     ## ##   ####      /##       /##  ###  /###          ## ##    #     #      /###     ### ##    /##    
##   ##     ##  ##    ###  / / ###     / ###  ###/ #### /       ## ##    #     #     / ###  / ######### / ###   
##   ##     ##  ##     ###/ /   ###   /   ###  ##   ###/        ## ##    #     #    /   ###/ ##   #### /   ###  
##   ##     ##  ##      ## ##    ### ##    ### ##    ##         ## ##    #     #   ##    ##  ##    ## ##    ### 
##   ##     ##  ##      ## ########  ########  ##    ##         ## ##    #     ##  ##    ##  ##    ## ########  
 ##  ## ### ##  ##      ## #######   #######   ##    ##         #  ##    #     ##  ##    ##  ##    ## #######   
  ## #   ####   ##      ## ##        ##        ##    ##            /     #      ## ##    ##  ##    ## ##        
   ###     /##  ##      /# ####    / ####    / ##    ##        /##/      #      ## ##    ##  ##    /# ####    / 
    ######/ ##   ######/ ## ######/   ######/  ###   ###      /  #####           ## ######    ####/    ######/  
      ###   ##    #####   ## #####     #####    ###   ###    /     ##                ####      ###      #####   
            ##                                               #                                                  
            /                                                 ##                                                                                                                                                
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import { Stateable } from "./extensions/Stateable.sol";

import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error AlreadyRevealed();
error CannotBeZeroAddress();
error NotEnoughTokensAvailable();
error InvalidAmount(uint256 required);

contract HDGenerator is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    Stateable
{
    bool public isRevealed;
    uint96 public maxSupply;
    uint96 public mintPrice;
    string public contractURI;
    string public baseTokenURI;
    AggregatorV3Interface internal priceFeedContract;

    uint256 public deltaInWei;
    event Withdraw(uint256 amount);
    event MintPriceSet(uint96 priceInUSD);
    event UriPrefixSet(string baseTokenURI);
    event RoyaltyInfoSet(address receiver, uint256 royaltyFeesInBips);

    /*
     * To initialize upgradeable contract
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _contractURI,
        address _priceFeedContract,
        address _royaltyReceiver,
        uint96 _royaltyFeesInBips,
        uint96 _mintPrice, // in usd
        uint96 _maxSupply,
        bool _revealed
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __ERC721AQueryable_init();
        __ERC721ABurnable_init();
        __ERC2981_init();
        __Ownable_init();
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        mintPrice = _mintPrice;
        isRevealed = _revealed;
        contractURI = _contractURI;
        priceFeedContract = AggregatorV3Interface(_priceFeedContract);
        setRoyaltyInfo(_royaltyReceiver, _royaltyFeesInBips);
    }

    /**********************
     * External Functions *
     **********************/

    /*
     * To reveal collection's assets to public
     */
    function revealCollection(string calldata _newUri) external onlyOwner {
        if (isRevealed) revert AlreadyRevealed();
        baseTokenURI = _newUri;
        isRevealed = true;
        emit UriPrefixSet(_newUri);
    }

    /*
     * To withdraw funds from contract to owner's wallet
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit Withdraw(balance);
    }

    /*
     * To update mint price of queen nft
     */
    function setMintPrice(uint96 _newPriceInUSD) external onlyOwner {
        mintPrice = _newPriceInUSD;
        emit MintPriceSet(_newPriceInUSD);
    }

    /*
     * To update contract address of chainlink oracle
     */
    function setPriceFeed(address _priceFeedContract) external onlyOwner {
        priceFeedContract = AggregatorV3Interface(_priceFeedContract);
    }

    /*
     * To set the ContractURI for OpenSea royalty compliance on chain ID #1-5
     */
    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /*
     * To mint queens publicly
     */
    function mintForAddress(address _receiver, uint256 _mintQuantity)
        external
        payable
        notInState(State.Paused)
    {
        uint256 requiredAmount = _mintQuantity * getConversionRate(mintPrice);
        // delta is introduced to avoid an issue with USD/ETH fluctuations
        if (msg.value + deltaInWei < requiredAmount)
            revert InvalidAmount({ required: requiredAmount });
        mint(_receiver, _mintQuantity);
    }

    /*
     * To reserve some queens
     */
    function adminMint(address _receiver, uint256 _mintQuantity) external onlyOwner {
        mint(_receiver, _mintQuantity);
    }

    /*
     * To get burned tokens count in collection
     */
    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    /**********************
     * Public Functions *
     **********************/

    /*
     * To update royalty address and fees
     */
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
        emit RoyaltyInfoSet(_receiver, _royaltyFeesInBips);
    }

    /*
     * To set contract state
     */
    function updateState(State _state) public override onlyOwner {
        super.updateState(_state);
    }

    /*
     * To update update delta value
     */
    function setDeltaInWei(uint256 _newDeltaInWei) external onlyOwner {
        deltaInWei = _newDeltaInWei;
    }

    /*
     * To get minted tokens count in collection
     */
    function totalSupply()
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (uint256)
    {
        return _totalMinted();
    }

    /*
     * To get the complete URI of a specific token by its ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length == 0
                ? baseURI
                : string.concat(baseURI, _toString(tokenId));
    }

    /*
     * To check if this contract implements the interface defined by interfaceId
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
     * To get latest price of ether in wei to mint an NFT
     */
    function getConversionRate(uint96 valueInUsd) public view returns (uint256) {
        (, int256 price, , , ) = priceFeedContract.latestRoundData();
        uint256 ethAmountInWei = ((1 * 10**26) * valueInUsd) / uint256(price);
        return ethAmountInWei;
    }

    /**********************
     * Internal Functions *
     **********************/

    /*
     * To mint tokens of collection
     */
    function mint(address _receiver, uint256 _mintQuantity) internal {
        if (_totalMinted() + _mintQuantity > maxSupply) revert NotEnoughTokensAvailable();
        _safeMint(_receiver, _mintQuantity);
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}