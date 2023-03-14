pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/// @author Monumental Team
/// @title Standard Contract
contract MNTContract  is Initializable, ERC721Upgradeable, ERC2981Upgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable, DefaultOperatorFiltererUpgradeable {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    CountersUpgradeable.Counter private _tokenBurntIds;

    event MNTMintDone(address _owner, uint256 _pinCode, uint256 _tokenId);
    event MNTBurnDone(address _owner, uint256 _pinCode, uint256 _tokenId);
    event MNTSendDone(address _owner, uint256 _pinCode, address to, uint256 _tokenId);
    event MNTBeforeTokenTransfer(address from, address to, uint amount);

    address internal  _creator;

    uint256 internal  _royalties;

    uint256 internal _maxSupply;

    string internal _baseUrl;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// Initialize
    /// @param creator creator address
    /// @param pinCode pinCode
    /// @param nftName nft name
    /// @param nftSymbol symbol
    /// @param baseUrl baseUrl
    /// @param royalties royalties
    /// @param maxSupply maxSupply
    /// @notice Standard constructor
    function initializeStandard(
        address creator,
        uint256 pinCode,
        string memory nftName,
        string memory nftSymbol,
        string memory baseUrl,
        uint256 royalties,
        uint256 maxSupply
    ) public virtual initializer returns (bool){
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init(nftName, nftSymbol);
        __Pausable_init();
        __ERC721Burnable_init();
        __DefaultOperatorFilterer_init();

        _creator = creator;
        _royalties = royalties;
        _maxSupply = maxSupply;
        _baseUrl = baseUrl;

        return true;
    }


    function initializeCommunity(
        string[] memory stringOptions,
        address creator,
        uint256 royalties,
        uint256 maxSupply,
        uint256[] memory communityOptions,
        bool onlyWhitelisted,
        address[] memory wlAddresses,
        address[] memory feeRcpts,
        uint32[] memory feePercs
    ) public virtual initializer returns (bool){
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init(stringOptions[0], stringOptions[1]);
        __Pausable_init();
        __ERC721Burnable_init();

        _creator = creator;
        _royalties = royalties;
        _maxSupply = maxSupply;
        _baseUrl = stringOptions[2];

        return true;
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// Burn a token
    /// @param _owner owner
    /// @param _tokenId tokenId
    /// @param _pinCode  pinCode
    /// @return the burned tokenId
    /// @notice Burn a token
    function mntBurn(address _owner, uint256 _tokenId, uint256 _pinCode)
    public
    returns (uint256)
    {
        super.burn(_tokenId);
        _maxSupply--;
        incrementTokenBurnId();
        emit MNTBurnDone(_owner, _pinCode, _tokenId);
        return _tokenId;
    }

    /// Get the current token counter index
    function getCurrentTokenId()
    internal
    returns (uint256){
        return _tokenIds.current();
    }

    /// Get the current burn token counter index
    function getTokenBurntId()
    internal
    returns (uint256){
        return _tokenBurntIds.current();
    }

    /// Increment the current token index
    function incrementTokenId()
    internal {
        _tokenIds.increment();
    }

    /// Increment the current token index
    function incrementTokenBurnId()
    internal {
        _tokenBurntIds.increment();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Return the total supply (current counter - burn counter)
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current() - _tokenBurntIds.current();
    }

    /// @notice Return the max supply
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /// Send a token `to`
    /// @param _owner owner
    /// @param _pinCode pincode
    /// @param _to to
    /// @param _tokenId tokenId
    /// @notice Send a token `to`
    function mntSend(address _owner, uint256 _pinCode, address _to, uint256 _tokenId)  public {
        safeTransferFrom(_msgSender(), _to, _tokenId);
        emit MNTSendDone(_owner, _pinCode, _to , _tokenId);
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC2981Upgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Get the receiver and royaltyAmount
    /// @param _tokenId a tokenId
    /// @param _salePrice a price
    /// @return receiver and royaltyAmount
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public override view
    returns (address receiver, uint256 royaltyAmount) {
        uint256 computed_royalties = (_salePrice * _royalties) / 100;
        return (_creator, computed_royalties);
    }

    // @notice Return a token URI. Target should provide a JSON Token level metadata
    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721Upgradeable)
    returns (string memory)
    {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_baseUrl, StringsUpgradeable.toString(tokenId)));
    }


    /**
   * @dev See {IERC721-setApprovalForAll}.
   *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
   */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


}