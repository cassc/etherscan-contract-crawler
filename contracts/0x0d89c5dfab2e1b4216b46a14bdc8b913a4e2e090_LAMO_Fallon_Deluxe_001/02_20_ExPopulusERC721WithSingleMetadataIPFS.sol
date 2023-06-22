// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "rarible-protocol-contracts/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "rarible-protocol-contracts/royalties/contracts/LibRoyaltiesV2.sol";


/**
 *  /$$$$$$$$                 /$$$$$$$                               /$$
 * | $$_____/                | $$__  $$                             | $$
 * | $$       /$$   /$$      | $$  \ $$ /$$$$$$   /$$$$$$  /$$   /$$| $$ /$$   /$$  /$$$$$$$
 * | $$$$$   |  $$ /$$/      | $$$$$$$//$$__  $$ /$$__  $$| $$  | $$| $$| $$  | $$ /$$_____/
 * | $$__/    \  $$$$/       | $$____/| $$  \ $$| $$  \ $$| $$  | $$| $$| $$  | $$|  $$$$$$
 * | $$        >$$  $$       | $$     | $$  | $$| $$  | $$| $$  | $$| $$| $$  | $$ \____  $$
 * | $$$$$$$$ /$$/\  $$      | $$     |  $$$$$$/| $$$$$$$/|  $$$$$$/| $$|  $$$$$$/ /$$$$$$$/
 * |________/|__/  \__/      |__/      \______/ | $$____/  \______/ |__/ \______/ |_______/
 *                                              | $$
 *                                              | $$
 *                                              |__/
 */
contract ExPopulusERC721WithSingleMetadataIPFS is ERC721Enumerable, Ownable, RoyaltiesV2Impl {

    // use the counters to guarantee unique IDs
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Base URI
    string private _baseURIExtended;

    // Contract Base URI
    string private _contractBaseURI;

    // Contract URI
    string private _contractURI;

    // Global base URI, all NFTs share the same TokenURI
    string private _tokenURI;

    // the total balance
    uint256 private _totalMint = 0;

    // madding of token URIs based on the tokenID
    mapping(uint256 => string) private _tokenURIs;

    // the price
    uint256 _price = 0;

    // the rarible percentage for royalties
    uint96 private _raribleRoyaltyPercentage = 0;

    // the beneficiary is who gets the eth paid during the mint
    address payable _beneficiary = payable(address(0));

    // the beneficiary is who gets the eth paid for rarible royalties
    address payable _raribleBeneficiary = payable(address(0));

    // events for all the different changes
    event BeneficiaryChanged(address payable indexed previousBeneficiary, address payable indexed newBeneficiary);
    event RaribleBeneficiaryChanged(address payable indexed previousBeneficiary, address payable indexed newBeneficiary);
    event BeneficiaryPaid(address payable beneficiary, uint256 amount);
    event PriceChange(uint256 previousPrice, uint256 newPrice);
    event RaribleRoyaltyPercentageChange(uint96 previousPercentage, uint96 newPercentage);
    event BaseURIChanged(string previousBaseURI, string newBaseURI);
    event ContractBaseURIChanged(string previousBaseURI, string newBaseURI);
    event ContractURIChanged(string previousURI, string newURI);
    event PermanentURI(string _value, uint256 indexed _id); //https://docs.opensea.io/docs/metadata-standards

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory defaultTokenURI,
        string memory contractBaseURI,
        string memory contractMetadataURI,
        uint256 totalMint,
        uint256 price,
        uint96 raribleRoyaltyPercentage,
        address payable beneficiary,
        address payable raribleRoyaltyBeneficiary
    ) ERC721(name, symbol) Ownable() {
        setBaseURI(baseURI);
        setPrice(price);
        setBeneficiary(beneficiary);
        setRaribleBeneficiary(raribleRoyaltyBeneficiary);
        setContractBaseURI(contractBaseURI);
        setContractURI(contractMetadataURI);
        setRaribleRoyaltyPercentage(raribleRoyaltyPercentage);
        _totalMint = totalMint;
        _tokenURI = defaultTokenURI;
    }

    /**
     * @dev create a new token with the currently set _contractBaseURI
     */
    function mintToken(address owner) public payable returns (uint256) {

        require(msg.value == getPrice(), "The wrong price was sent, please call getPrice() to get the amount of Ether to send.");

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        require(id <= _totalMint, "You cannot mint anymore of this token");

        _safeMint(owner, id);
        _setTokenURI(id, _tokenURI);

        _setRoyalties(id, _raribleBeneficiary, _raribleRoyaltyPercentage);

        emit PermanentURI(tokenURI(id), id);

        if (getPrice() > 0) {
            (bool sent, ) = _beneficiary.call{value : msg.value}("");
            require(sent, "Failed to send Ether");
            emit BeneficiaryPaid(_beneficiary, msg.value);
        }

        return id;
    }

    /**
     * @dev gets the current beneficiary that is set
     */
    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
    * @dev the owner can call this to set a new beneficiary
    */
    function setBeneficiary(address payable newBeneficiary) public onlyOwner {
        require(newBeneficiary != address(0), "Beneficiary: new beneficiary is the zero address");
        address payable _oldBeneficiary = _beneficiary;
        _beneficiary = newBeneficiary;
        emit BeneficiaryChanged(_oldBeneficiary, _beneficiary);
    }

    /**
     * @dev the owner can call this to set a new beneficiary for any royalties on rarible
     */
    function setRaribleBeneficiary(address payable newBeneficiary) public onlyOwner {
        require(newBeneficiary != address(0), "Beneficiary: new rarible beneficiary is the zero address");
        address payable _oldRaribleBeneficiary = _raribleBeneficiary;
        _raribleBeneficiary = newBeneficiary;
        emit RaribleBeneficiaryChanged(_oldRaribleBeneficiary, _raribleBeneficiary);
    }

    /**
     * @dev public function to get the current price of a mint.
     */
    function getPrice() public view virtual returns (uint256)  {
        return _price;
    }

    /**
     * @dev the total amount to be minted
     */
    function getTotalAmountAllowedToBeMinted() public view virtual returns (uint256)  {
        return _totalMint;
    }

    /**
     * @dev get the current tokenID, which should be equal to the amount minted
     */
    function getTotalMinted() public view virtual returns (uint256)  {
        return _tokenIds.current();
    }

    /**
    * @dev public function for the owner to change the price.
    */
    function setPrice(uint256 price) public onlyOwner {
        uint256 oldPrice = _price;
        _price = price;
        emit PriceChange(oldPrice, _price);
    }

    /**
    * @dev public function for the owner to change the the rarible royalty percentage.
    */
    function setRaribleRoyaltyPercentage(uint96 percentage) public onlyOwner {
        uint96 oldPercentage = _raribleRoyaltyPercentage;
        _raribleRoyaltyPercentage = percentage;
        emit RaribleRoyaltyPercentageChange(oldPercentage, _raribleRoyaltyPercentage);
    }

    /**
     * @dev public function for the owner to change the baseURI.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        string memory oldBase = _baseURIExtended;
        _baseURIExtended = baseURI_;
        emit BaseURIChanged(oldBase, _baseURIExtended);
    }

    /**
     * @dev public function for the owner to change the baseURI of the contractURI.
     */
    function setContractBaseURI(string memory baseURI_) public onlyOwner {
        string memory oldBase = _contractBaseURI;
        _contractBaseURI = baseURI_;
        emit ContractBaseURIChanged(oldBase, _contractBaseURI);
    }

    /**
     * @dev function for the owner to change the metadata of the smart contract for opensea.
     */
    function setContractURI(string memory contractURI_) public onlyOwner {
        string memory oldURI = _contractURI;
        _contractURI = contractURI_;
        emit ContractURIChanged(oldURI, _contractURI);
    }

    /**
     * @dev public function to get contract level metadata
     * https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_contractBaseURI, _contractURI));
    }

    /**
    * @dev get the current BaseURI
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    /**
    * @dev get the current tokenURI given a tokenID
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory tokenURI_ = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return tokenURI_;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(tokenURI_).length > 0) {
            return string(abi.encodePacked(base, tokenURI_));
        }

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    /**
    * @dev since this application only returns a singular tokenURI, this function allows getting that before a token
    * is minted
    */
    function getStaticTokenURI() public view virtual returns (string memory) {
        string memory base = _baseURI();
        return string(abi.encodePacked(base, _tokenURI));
    }

    /**
     * @dev internal function to save the tokenURI for a given tokenId
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = tokenURI_;
    }

    /**
     * @dev function for setting the royalty data on rarible
     * https://docs.rarible.org/asset/royalties-schema
     * https://medium.com/rarible-dao/rarible-nft-royalties-in-your-custom-smart-contract-b07550e89ef4
     */
    function _setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal virtual {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        _setRoyalties(_tokenId, _royaltiesReceipientAddress, _percentageBasisPoints);
    }

    /**
     * @dev function to verify this contract is compatible with rarible royalty interface
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}