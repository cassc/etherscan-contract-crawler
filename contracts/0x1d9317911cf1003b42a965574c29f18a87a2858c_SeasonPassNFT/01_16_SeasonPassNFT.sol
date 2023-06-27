// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SeasonPassNFT is ERC721URIStorage, ERC721Royalty, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    Counters.Counter private _seasonPassTokenCount;
    Counters.Counter private _referralIds;

    mapping (uint256 => string) private _tokenURIs;

    uint256 public constant MAX_SEASONPASS = 10000;

    uint256 public constant MAX_TX_MINT_SEASONPASS = 10;

    // Set to 10000 so commission percentage are expressed in basis points
    uint256 public constant COMMISSION_DENOMINATOR = 10000;
    
    uint256 public COMMISSION_PERCENTAGE = 1000; // 10 %

    uint256 public PRICE_SEASONPASS = 20 * 10**15; // .020 eth

    address payable target = payable(0x30A7bC1AB0765223a221BDDD2394d9eDE74a7d69);

    mapping (uint256 => address) private _referrers;

    struct Referee {
        address referee;
        uint256 count;
    }

    event CreateSeasonPassNFT(uint256 indexed id);
    event RegisterAsReferrer(address indexed referrerAddress, uint256 indexed referralId);
    event MintByReferral(uint256 indexed referralId, address indexed referee, uint256 count, uint256 commissionAmount);

    constructor() ERC721("LaLigaLand Season Pass", "LLL") {}

    // Base URI
    string private _baseURIext;

    function _totalSupply() internal view returns (uint) {
        return _tokenIds.current();
    }
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIext = baseURI_;
    }

    function updateTargetAddress(address _newtarget) public onlyOwner {
        target = payable(_newtarget);
    }

    function getTargetAddress() public view returns(address) {
        return target;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIext;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
        require(_exists(tokenId), "Cannot set tokenURI for nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage, ERC721) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return super.tokenURI(tokenId);
    }

    function registerAsReferrer() public {
        _referralIds.increment();
        uint256 referralId = _referralIds.current();
        address referrerAddress = msg.sender;
        _referrers[referralId] = referrerAddress;
        emit RegisterAsReferrer(referrerAddress, referralId);
    }

    // CALLED FROM PUBLIC SITE
    function mintSeasonPassNFTByReferral(address recipient, uint256 _count, uint256 _referralId)
    public virtual payable
    {
        require(_referralId > 0, "SeasonPassNFT: Invalid Referral Id");
        require(_referralId <= _referralIds.current(), "SeasonPassNFT: Referral Id Not Registered");

        require(msg.value >= priceSeasonPass(_count), "SeasonPassNFT: Not enough ETH sent");
        _mintSeasonPassNFT(recipient, _count);

        uint256 commissionAmount = (priceSeasonPass(_count) * COMMISSION_PERCENTAGE) / COMMISSION_DENOMINATOR ;
        payable(_referrers[_referralId]).transfer(commissionAmount);
        target.transfer(msg.value - commissionAmount);

        emit MintByReferral(_referralId, recipient, _count, commissionAmount);
    }

    // CALLED FROM PUBLIC SITE
    function mintSeasonPassNFT(address recipient, uint256 _count)
    public virtual payable
        //   returns (uint256)
    {
        // TODO: restrict non allow list users to after the pre-sale period
        require(msg.value >= priceSeasonPass(_count), "SeasonPassNFT: Not enough ETH sent");

        _mintSeasonPassNFT(recipient, _count);

        target.transfer(msg.value);
    }

    function _mintSeasonPassNFT(address recipient, uint256 _count) internal {
        require(_count > 0, "SeasonPassNFT: Must mint 1 or more per transaction");
        require(_count <= MAX_TX_MINT_SEASONPASS, "SeasonPassNFT: Exceeds max mint number per transaction");
        require(_seasonPassTokenCount.current() <= MAX_SEASONPASS, "SeasonPassNFT: Member tokens sold out");
        require(_seasonPassTokenCount.current() + _count <= MAX_SEASONPASS, "SeasonPassNFT: Exceeds the number remaining. Try again, requesting a smaller number.");
        for (uint256 i = 0; i < _count; i++) {
            _seasonPassTokenCount.increment();
            _tokenIds.increment();

            uint256 newItemId = _tokenIds.current();
            _mint(recipient, newItemId);

            emit CreateSeasonPassNFT(newItemId);
        }


    }

    function setSeasonPassPrice(uint256 _price) public onlyOwner {
        PRICE_SEASONPASS = _price;
    }

    function setSeasonPassCommission(uint256 _commissionRate) public onlyOwner {
        COMMISSION_PERCENTAGE = _commissionRate;
    }

    function priceSeasonPass(uint256 _count) public view returns (uint256) {
        return PRICE_SEASONPASS * _count;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner{
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner{
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}