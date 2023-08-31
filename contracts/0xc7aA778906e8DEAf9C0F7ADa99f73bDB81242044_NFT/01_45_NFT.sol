// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

//  ==========  External imports    ==========

import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "./erc721a/ERC721AUpgradeable.sol";


//  ==========  Internal imports    ==========

import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "./lib/CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "./extension/ContractMetadata.sol";
import "./extension/PlatformFee.sol";
import "./extension/Royalty.sol";
import "./extension/PrimarySale.sol";
import "./extension/Ownable.sol";
import "./extension/PermissionsEnumerable.sol";
import "./extension/DropSinglePhase.sol";
import "./extension/SignatureMint.sol";

contract NFT is
    Initializable,
    ContractMetadata,
    PlatformFee,
    Royalty,
    PrimarySale,
    Ownable,
    PermissionsEnumerable,
    DropSinglePhase,
    
    SignatureMint,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    ERC721AUpgradeable
{
    using StringsUpgradeable for uint256;

    /*///////////////////////////////////////////////////////////////
                            State variables
    //////////////////////////////////////////////////////////////*/

    bytes32 private transferRole;
    bytes32 private minterRole;

    uint256 private constant MAX_BPS = 10_000;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,                          // 默认管理员
        string memory _name,                            // 名称
        string memory _symbol,                          // 符号
        string memory _contractURI,                     // 合约URI
        address _saleRecipient,                         // 销售接收者
        uint128 _platformFeeBps,                        // 平台费用BPS
        address _platformFeeRecipient                   // 平台费用接收者
    ) external initializer {

        bytes32 _transferRole = keccak256("TRANSFER_ROLE");
        bytes32 _minterRole = keccak256("MINTER_ROLE");

        
        __ERC721A_init(_name, _symbol);                                     // ERC721AUpgradeable
        __SignatureMintERC721_init();                                       // SignatureMintERC721Upgradeable

        _setupContractURI(_contractURI);                                    // 设置合约URI
        _setupOwner(_defaultAdmin);                                         // 设置默认管理员

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(_minterRole, _defaultAdmin);                             // 
        _setupRole(_transferRole, _defaultAdmin);                           // transfer role is not required
        _setupRole(_transferRole, address(0));                              // transfer role is not required

        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);      // 设置平台费用信息
        _setupPrimarySaleRecipient(_saleRecipient);                         // 设置主要销售接收者

        transferRole = _transferRole;
        minterRole = _minterRole;
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 2981 logic
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {

        string memory baseURI = contractURI;
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    function contractType() external pure returns (bytes32) {
        return bytes32("SignatureDrop");
    }

    function contractVersion() external pure returns (uint8) {
        return uint8(5);
    }

 
    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        returns (address signer)
    {
        uint256 tokenIdToMint = _currentIndex;

        signer = _processRequest(_req, _signature);

        address receiver = _req.userAddress;

        require(_req.mintNumber + this.totalMinted() <= _req.totalSupply, "Req MintNumber should be lower than the totalSupply!");

        _collectPriceOnClaim(address(0), _req.mintNumber, _req.paymentToken, _req.nftPrice);

        _safeMint(receiver, _req.mintNumber);

        emit TokensMintedWithSignature(signer, receiver, tokenIdToMint, _req);
    }

     // admin mint directly
    function mint(address receiver, uint256 quantity) external {
        require(quantity > 0, "!Quantity");
        require(_isAuthorizedSigner(_msgSender()), "!Signer");
    
        _safeMint(receiver, quantity);
    }
 

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Runs before every `claim` function call.
    function _beforeClaim(
        address,
        uint256 _quantity,
        address,
        uint256,
        AllowlistProof calldata,
        bytes memory
    ) internal view override {
        require(_currentIndex + _quantity <= this.totalSupply(), "!Tokens");
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function _collectPriceOnClaim(
        address _primarySaleRecipient,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal override {
        if (_pricePerToken == 0) {
            return;
        }
       

        (address platformFeeRecipient, uint16 platformFeeBps) = getPlatformFeeInfo();

        address saleRecipient = _primarySaleRecipient == address(0) ? primarySaleRecipient() : _primarySaleRecipient;
        

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert("!Price");
            }
        }

        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, _msgSender(), saleRecipient, totalPrice - platformFees);
    }

    function _transferTokensOnClaim(address _to, uint256 _quantityBeingClaimed)
        internal
        override
        returns (uint256 startTokenId)
    {
        startTokenId = _currentIndex;
        _safeMint(_to, _quantityBeingClaimed);
    }

    /// @dev Returns whether a given address is authorized to sign mint requests.
    function _isAuthorizedSigner(address _signer) internal view override returns (bool) {
        return hasRole(minterRole, _signer);
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether primary sale recipient can be set in the given execution context.
    function _canSetPrimarySaleRecipient() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether owner can be set in the given execution context.
    function _canSetOwner() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _canSetContractURI() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetClaimConditions() internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() external view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function burn(uint256 tokenId) external virtual {
        _burn(tokenId, true);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (!hasRole(transferRole, address(0)) && from != address(0) && to != address(0)) {
            if (!hasRole(transferRole, from) && !hasRole(transferRole, to)) {
                revert("!Transfer-Role");
            }
        }
    }

    function _dropMsgSender() internal view virtual override returns (address) {
        return _msgSender();
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}