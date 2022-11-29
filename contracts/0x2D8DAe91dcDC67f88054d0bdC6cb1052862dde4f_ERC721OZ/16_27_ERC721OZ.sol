// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {DefaultOperatorFilterer} from "./openSea/DefaultOperatorFilterer.sol";
import {BasisPoints} from "./libraries/BasisPoints.sol";
import "./rarible/impl/RoyaltiesV2Impl.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./libraries/Sender.sol";
import "./RoyaltySender.sol";

//Contract errors
error MaxSupplyOvercome(address buyerAddress);
error ValueIsNotEqualPrice();

/// @author Polemix team
/// @title Contract to mint nfts
contract ERC721OZ is
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard,
    Pausable,
    RoyaltiesV2Impl,
    DefaultOperatorFilterer
{
    using Counters for Counters.Counter;
    uint96 private royaltyFeesInBips;
    address private royaltyAddress;
    string public contractURI;

    
    // Contract events
    
    /**
     * @notice IsMinted event fired when a mint is executed with success
     * @param contentCreator contains the content creator address
     * @param buyerAddress contains the buyer address
     * @param tokenId contains the token ID
     * @param price contains the token's price
    */
    event IsMinted(
        address indexed contentCreator,
        address indexed buyerAddress,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @notice ValueSendedToContentCreator event fired when when funds are sent to the content creator
     * @param contentCreator contains the content creator address
     * @param buyerAddress contains the buyer address
     * @param tokenId contains the token ID
     * @param price contains the token's price
    */
    event ValueSendedToContentCreator(
        address indexed contentCreator,
        address indexed buyerAddress,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @notice WithdrawEvent event fired when withdraw is executed
     * @param withdrawAddress contains the address to do withdraw
     * @param amount contains the amount withdrawed
    */
    event WithdrawEvent(
        address indexed withdrawAddress,
        uint256 amount
    );

    string public baseURI = "";
    uint256 public maxSupply;
    uint256 private tokenPrice;
    address payable private creatorAddress;
    uint16 private creatorBasisPoint;
    address payable private royaltySenderContract;
    uint16 private royaltyResellBasisPoints;

    Counters.Counter private _tokenIds;


    /**
     * @notice ERC721OZ constructor
     * @param name contains collection name
     * @param symbol contains collection symbol
     * @param maxTokensSupply contains the max number of tokens that can be supplied
     * @param metadataURI contains the metadata token's URI
     * @param price contains token's price
     * @param contentCreator contains the address of content creator
     * @param creatorBasisPoint_ contains the percentage of royalties in basis points for the content creator
     * @param royaltySenderContract_ contains the address of royalty proxy contract
     * @param royaltyResellBasisPoints_ contains the percentage of royalties in basis points to be transferred in secondary sales
    */
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxTokensSupply,
        string memory metadataURI,
        uint256 price,
        address payable contentCreator,
        uint16 creatorBasisPoint_,
        address payable royaltySenderContract_,
        uint16 royaltyResellBasisPoints_
    ) Pausable() ERC721(name, symbol) checkBasisPoint(creatorBasisPoint_) checkBasisPoint(royaltyResellBasisPoints_) {
        require(price > 0, "Price must be > 0");
        require(maxTokensSupply > 0, "MaxTokensupply must be > 0");
        maxSupply = maxTokensSupply;
        baseURI = metadataURI;
        tokenPrice = price;
        creatorAddress = contentCreator;
        creatorBasisPoint = creatorBasisPoint_;
        royaltySenderContract = royaltySenderContract_;
        royaltyResellBasisPoints = royaltyResellBasisPoints_;
    }

    /**
     * @notice checkBasisPoint modifier function to validate that basis points are between 1 and 10000
     * @param basisPoint to validate
    */
    modifier checkBasisPoint(uint16 basisPoint) {
        require(
            BasisPoints.check(basisPoint),
            "Basis point beetween 1 and 10000"
        );
        _;
    }

    /**
     * @notice validateMaxSupply modifier function to validate max supply
     * @param sender contains the address which is requesting the mint process
    */
    modifier validateMaxSupply(address sender) {
        if (_tokenIds.current() >= maxSupply) {
            revert MaxSupplyOvercome(sender);
        }
        _;
    }


    /**
     * @notice mintNft function executes the minting process
     * @param buyer contains the address to safeMint function
    */
    function mintNft(address buyer)
        external
        payable
        validateMaxSupply(buyer)
        nonReentrant
        whenNotPaused
    {
        if (msg.value != tokenPrice) {
            revert ValueIsNotEqualPrice();
        }
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        bool creatorSendSuccess = Sender.sendBalancePercentage(
            creatorAddress,
            creatorBasisPoint,
            msg.value
        );
        require(creatorSendSuccess, "Send percentage to creator fails");
        uint256 royaltyBips = 10000 - creatorBasisPoint;
        RoyaltySender(royaltySenderContract).receiveRoyalties{
            value: BasisPoints.calculeAmount(uint16(royaltyBips), msg.value)
        }();
        emit ValueSendedToContentCreator(
            creatorAddress,
            buyer,
            newItemId,
            tokenPrice
        );
        setExternalRoyalties(
            newItemId,
            uint96(royaltyResellBasisPoints),
            royaltySenderContract
        );
        _safeMint(buyer, newItemId);
        _setTokenURI(newItemId, baseURI);
        emit IsMinted(creatorAddress, buyer, newItemId, tokenPrice);
    }

    /**
     * @notice pauseContract function to pause or unpause contract's functions. Only contract owner can use this function to pause/unpause this contract. This is an emergency stop mechanism.
     * @param pauseState contains a bool with the state of pause. true for pause, false for unpause
    */
    function pauseContract(bool pauseState) external onlyOwner {
        if (pauseState) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice setMaxSupply function to set max supply, only called by contract owner
     * @param newSupply contains the number of new supply
    */
    function setMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    /**
     * @notice setBaseUri function to set new base uri, only called by contract owner
     * @param newBaseUri contains a string with new base uri
    */
    function setBaseUri(string memory newBaseUri) external onlyOwner {
        baseURI = newBaseUri;
    }

    /**
     * @notice setTokenPrice function to set a new token price, only called by contract owner
     * @param newPrice contains the new token's price
    */
    function setTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    /**
     * @notice setRoyaltySenderContract function to set a new royalty proxy contract address, only called by contract owner
     * @param newRoyaltySenderContract contains the address of a new royalty proxy contract
    */
    function setRoyaltySenderContract(address payable newRoyaltySenderContract) external onlyOwner {
        royaltySenderContract = newRoyaltySenderContract;
    }

    /**
     * @notice getRoyaltySenderContract function to get the address of royalty proxy contract
     * @return address royalty proxy contract
    */
    function getRoyaltySenderContract() external view returns(address payable){
        return royaltySenderContract;
    }

    /**
     * @notice getMaxSupply function to get max supply value
     * @return uint256 with max supply
    */
    function getMaxSupply() external view returns (uint256) {
        return maxSupply;
    }

    /**
     * @notice getBaseUri function to get base uri
     * @return string base uri 
    */
    function getBaseUri() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @notice getTokenPrice function to get the token's price
     * @return uint256 token price
    */
    function getTokenPrice() external view returns (uint256) {
        return tokenPrice;
    }

    /**
     * @notice supportsInterface function to get the supported (bool) of an interfaceId
     * @param interfaceId contains the ID interface to get the supported
     * @return bool true if interface is supported or false if interface is not supported
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /**
    * @notice transferFrom function of ERC721 is overrided to add onlyAllowedOperator modifier (open sea operator-filter-registry)
    */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
    * @notice safeTransferFrom function of ERC721 is overrided to add onlyAllowedOperator modifier (open sea operator-filter-registry)
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
    * @notice safeTransferFrom function of ERC721 is overrided to add onlyAllowedOperator modifier (open sea operator-filter-registry)
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    /**
     * @notice royaltyInfo function to get royalty proxy contract address and percentage of royalties
     * @param _salePrice contains the token's price
     * @return obejct (address, uint256) with royalty address and amount to send
    */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view virtual returns (address, uint256) {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    /**
     * @notice setRoyaltyInfo function to set royalty address and percentage of royalties in bips, only called by contract owner
     * @param _receiver contains the address to send royalties
     * @param _royaltyFeesInBips contains the royalty percentage in bips
    */
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        external
        onlyOwner
    {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    /**
     * @notice calculateRoyalty function to calculate the royalties with specific sale price
     * @param _salePrice contains the token's price
     * @return uint256 amount of royalty
    */
    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice * royaltyFeesInBips) / 10000;
    }

    /**
     * @notice setRoyalties function to set royalties for Rarible marketplace
     * @param _tokenId contains the token ID
     * @param _royaltiesReceipientAddress contains the address to send royalties
     * @param _percentageBasisPoints contains the percentage of royalty in basis points
    */
    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesReceipientAddress,
        uint96 _percentageBasisPoints
    ) private {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    /**
     * @notice setExternalRoyalties function to set royalties for Rarible and all marketplaces which uses EIP-2981 protocol
     * @param tokenId contains the token ID
     * @param basisPoints contains the percentage of royalty in basis points
     * @param royaltiesContract contains the address to send royalties
    */
    function setExternalRoyalties(
        uint256 tokenId,
        uint96 basisPoints,
        address payable royaltiesContract
    ) private {
        // set royalties for rarible
        setRoyalties(tokenId, royaltiesContract, basisPoints);
        // END set royalties for rarible

        // set royalty for EIP-2981 protocol
        royaltyFeesInBips = basisPoints;
        royaltyAddress = royaltiesContract;
        contractURI = baseURI;
        // END set royalty for EIP-2981 protocol
    }

    /**
     * @notice getCurrentSupply function to get the number of minted tokens
     * @return uint256 supplied quantity
     */
    function getCurrentSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @notice Withdraw function
     * @param withdrawAddress to do balance withdraw
     */
     function withdrawBalance(address payable withdrawAddress) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(withdrawAddress).transfer(balance);
        emit WithdrawEvent(withdrawAddress, balance);
     }
}