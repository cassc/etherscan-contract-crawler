pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title InvertedApeClub contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract InvertedApeClub is ERC721, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Emitted when `tokenId` token is sold from `from` to `to`.
     */
    event Sold(address indexed from, address indexed to, uint256 indexed tokenId, uint256 price);

    string public INVERTED_PROVENANCE = "";

    uint public constant MAX_APES = 10000;

    address public BAYC_ADDRESS;

    // Mapping from tokenId to sale price.
    mapping(uint256 => uint256) public tokenPrices;

    // Mapping from tokenId to token owner that set the sale price.
    mapping(uint256 => address) public priceSetters;

    constructor(string memory name, string memory symbol, address ogAddress) ERC721(name, symbol) {
        BAYC_ADDRESS = ogAddress;
        _setBaseURI('ipfs://Qme9cSSVAnf6c8VnN3YCWb183Vodrkc2XU7XLcDttbY7qN/');
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        INVERTED_PROVENANCE = provenanceHash;
    }

    /**
    * Mints Inverted Apes
    */
    function mintApe(uint256[] memory tokenIds) public payable {
        require(totalSupply().add(tokenIds.length) <= MAX_APES, "would exceed max supply of Apes");

        ERC721 bayc = ERC721(BAYC_ADDRESS);

        for (uint i=0; i < tokenIds.length; i++) {
            bool mintingBurnedApe = (tokenIds[i] == 4885 || tokenIds[i] == 8860);

            require(
                (!mintingBurnedApe || msg.sender == owner()),
                "only contract owner can mint for the burned apes"
            );

            require(
              (mintingBurnedApe || bayc.ownerOf(tokenIds[i]) == msg.sender),
              "must own the BAYC ape rights"
            );

            if (totalSupply() < MAX_APES) {
                _safeMint(msg.sender, tokenIds[i]);
            }
        }
    }

    /*
    * @dev Checks that the token owner or the token ID is approved for the Market
    * @param _tokenId uint256 ID of the token
    */
    modifier ownerMustHaveMarketplaceApproved(uint256 _tokenId) {
        address owner = ownerOf(_tokenId);
        address marketplace = address(this);
        require(
            isApprovedForAll(owner, marketplace) ||
            getApproved(_tokenId) == marketplace,
            "owner must have approved marketplace"
        );
        _;
    }

    /*
    * @dev Checks that the token is owned by the sender
    * @param _tokenId uint256 ID of the token
    */
    modifier senderMustBeTokenOwner(uint256 _tokenId) {
        address tokenOwner = ownerOf(_tokenId);
        require(
            tokenOwner == msg.sender,
            "sender must be the token owner"
        );
        _;
    }

    /*
    * @dev Checks that the token is owned by the same person who set the sale price.
    * @param _tokenId address of the contract storing the token.
    */
    function _priceSetterStillOwnsTheApe(uint256 _tokenId)
        internal view returns (bool)
    {
        return ownerOf(_tokenId) == priceSetters[_tokenId];
    }

    /*
    * @dev Set the token for sale
    * @param _tokenId uint256 ID of the token
    * @param _amount uint256 wei value that the item is for sale
    */
    function setWeiSalePrice(uint256 _tokenId, uint256 _amount)
        public
        ownerMustHaveMarketplaceApproved(_tokenId)
        senderMustBeTokenOwner(_tokenId)
    {
        tokenPrices[_tokenId] = _amount;
        priceSetters[_tokenId] = msg.sender;
    }

    /*
    * @dev Purchases the token if it is for sale.
    * @param _tokenId uint256 ID of the token.
    */
    function buy(uint256 _tokenId)
        public payable
        ownerMustHaveMarketplaceApproved(_tokenId)
    {
        // Check that the person who set the price still owns the ape.
        require(
            _priceSetterStillOwnsTheApe(_tokenId),
            "Current token owner must be the person to have the latest price."
        );

        // Check that token is for sale.
        uint256 tokenPrice = tokenPrices[_tokenId];
        require(tokenPrice > 0, "Tokens priced at 0 are not for sale.");

        // Check that the correct ether was sent.
        require(
            tokenPrice == msg.value,
            "Must purchase the token for the correct price"
        );

        address tokenOwner = ownerOf(_tokenId);

        // Payout all parties.
        _payout(tokenPrice, payable(tokenOwner), _tokenId);

        // Transfer token.
        _transfer(tokenOwner, msg.sender, _tokenId);

        // Wipe the token price.
        _resetTokenPrice(_tokenId);

        emit Sold(msg.sender, tokenOwner, tokenPrice, _tokenId);
    }

    /* @dev Internal function to set token price to 0 for a give contract.
    * @param _tokenId uint256 id of the token.
    */
    function _resetTokenPrice(uint256 _tokenId)
        internal
    {
        tokenPrices[_tokenId] = 0;
        priceSetters[_tokenId] = address(0);
    }

    /* @dev Internal function to pay the seller and yacht ape owner.
    * @param _amount uint256 value to be split.
    * @param _seller address seller of the token.
    * @param _tokenId uint256 ID of the token.
    */
    function _payout(uint256 _amount, address payable _seller, uint256 _tokenId) 
        private
    {
        ERC721 bayc = ERC721(BAYC_ADDRESS);
        address payable yachtApeOwner = payable(bayc.ownerOf(_tokenId));

        uint256 yachtApeOwnerPayment = _calcProportion(1, _amount); // 1%
        uint256 sellerPayment = _amount - yachtApeOwnerPayment;

        if (yachtApeOwnerPayment > 0) {
            yachtApeOwner.transfer(yachtApeOwnerPayment);
        }
        if (sellerPayment > 0) {
            _seller.transfer(sellerPayment);
        }
    }

    /*
    * @dev Internal function calculate proportion of a fee for a given amount.
    *      _amount * fee / 100
    * @param _amount uint256 value to be split.
    */
    function _calcProportion(uint256 fee, uint256 _amount)
        internal pure returns (uint256)
    {
        return _amount.mul(fee).div(100);
    }
}