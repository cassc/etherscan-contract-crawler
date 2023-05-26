// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@massless.io/smart-contract-library/contracts/royalty/Royalty.sol";
import "@massless.io/smart-contract-library/contracts/interfaces/IContractURI.sol";
import "@massless.io/smart-contract-library/contracts/sale/SaleState.sol";
import "@massless.io/smart-contract-library/contracts/utils/AdminPermissionable.sol";
import "@massless.io/smart-contract-library/contracts/utils/PreAuthorisable.sol";

error MustMintMinimumOne();
error WalletMintLimit(uint256 limit);
error NotOwnerOfToken(uint256 tokenId);
error SoldOut();

error BadArrayLength();
error ArrayLengthMismatch();

error NoTrailingSlash();

contract AngryApeArmyValkyrieCollection is
    AdminPermissionable,
    PreAuthorisable,
    ERC721ABurnable,
    Royalty,
    SaleState
{
    // Constants
    uint32 public constant MAX_SUPPLY = 4444;
    uint32 public constant MINT_SUPPLY = 1111;
    uint32 public constant MAX_MINT = 4;

    // ERC721 Metadata
    string private __baseURI = "https://api.massless.io/";

    // Evo contract
    ERC721ABurnable private _evoContract;

    // Events
    event SetBaseURI(string _baseURI_);
    event MintBegins();
    event MintEnds();

    constructor(
        address admin_,
        address royaltyReceiver_,
        ERC721ABurnable evoContract_,
        address[] memory preAuthorised_
    )
        ERC721A("Angry Ape Army Valkyrie Collection", "VALK")
        PreAuthorisable(preAuthorised_)
    {
        _evoContract = evoContract_;

        _setRoyaltyReceiver(royaltyReceiver_);
        _setRoyaltyBasisPoints(500);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    modifier maxLimit(uint256 quantity_, uint256 supply_) {
        uint256 supplyLimit = supply_ - _totalMinted();

        if (quantity_ == 0) revert MustMintMinimumOne();
        if (quantity_ > supplyLimit) revert SoldOut();
        _;
    }

    function mint(uint256[] calldata tokenIds_)
        external
        whenSaleIsActive("Mint")
        maxLimit(tokenIds_.length / 2, MINT_SUPPLY)
    {
        if (tokenIds_.length % 2 != 0 || tokenIds_.length == 0)
            revert BadArrayLength();
        uint256 quantity = tokenIds_.length / 2;

        if (_numberMinted(_msgSender()) + quantity > MAX_MINT)
            revert WalletMintLimit(MAX_MINT);

        for (uint256 i; i < tokenIds_.length; i++) {
            if (_evoContract.ownerOf(tokenIds_[i]) != _msgSender())
                revert NotOwnerOfToken(tokenIds_[i]);
            _evoContract.burn(tokenIds_[i]);
        }

        _safeMint(_msgSender(), quantity);
    }

    function airdrop(address[] calldata to_, uint32[] calldata quantity_)
        public
        onlyAdmin
        maxLimit(_sumArray(quantity_), MAX_SUPPLY)
    {
        if (to_.length != quantity_.length) revert ArrayLengthMismatch();
        if (to_.length == 0) revert BadArrayLength();

        for (uint256 i; i < to_.length; i++) {
            _safeMint(to_[i], quantity_[i]);
        }
    }

    function startMint() external onlyAdminOrModerator {
        _setSaleType("Mint");
        _setSaleState(State.ACTIVE);

        emit MintBegins();
    }

    function pauseMint() external onlyAdminOrModerator {
        _pause();
    }

    function unpauseMint() external onlyAdminOrModerator {
        _unpause();
    }

    function endMint() external onlyAdmin {
        if (getSaleState() != State.ACTIVE) revert NoActiveSale();
        _setSaleState(State.FINISHED);

        emit MintEnds();
    }

    // Contract & token metadata
    function setBaseURI(string memory baseURI_) public onlyAdminOrModerator {
        if (bytes(baseURI_)[bytes(baseURI_).length - 1] != bytes1("/"))
            revert NoTrailingSlash();

        __baseURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(__baseURI, "contract.json"));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            string(
                abi.encodePacked(
                    __baseURI,
                    "token/",
                    _toString(tokenId),
                    ".json"
                )
            );
    }

    // Royalty details
    function setRoyaltyReceiver(address royaltyReceiver_) public onlyAdmin {
        _setRoyaltyReceiver(royaltyReceiver_);
    }

    function setRoyaltyBasisPoints(uint32 royaltyBasisPoints_)
        public
        onlyAdmin
    {
        _setRoyaltyBasisPoints(royaltyBasisPoints_);
    }

    // Access and Ownership
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, owner());
        _transferOwnership(newOwner);
    }

    function setAuthorizedAddress(address authorizedAddress_, bool authorized_)
        public
        onlyAdmin
    {
        _setAuthorizedAddress(authorizedAddress_, authorized_);
    }

    // Compulsory overrides
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, Royalty, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IContractURI).interfaceId ||
            ERC721A.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        if (_isAuthorizedAddress(_operator)) {
            return true;
        }

        return ERC721A.isApprovedForAll(_owner, _operator);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Utils
    function _sumArray(uint32[] calldata array_)
        private
        pure
        returns (uint256 result)
    {
        for (uint256 i; i < array_.length; i++) {
            result += array_[i];
        }
    }
}