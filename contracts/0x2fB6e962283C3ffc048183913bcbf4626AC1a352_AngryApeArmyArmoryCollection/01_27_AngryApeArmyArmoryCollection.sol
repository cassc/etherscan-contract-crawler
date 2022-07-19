// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

import "@massless.io/smart-contract-library/contracts/royalty/Royalty.sol";
import "@massless.io/smart-contract-library/contracts/interfaces/IContractURI.sol";
import "@massless.io/smart-contract-library/contracts/sale/SaleState.sol";
import "@massless.io/smart-contract-library/contracts/signature/Signature.sol";
import "@massless.io/smart-contract-library/contracts/utils/PreAuthorisable.sol";
import "@massless.io/smart-contract-library/contracts/utils/AdminPermissionable.sol";

error DeployerIsAdmin();
error NoTrailingSlash();
error ArrayLengthMismatch();
error BadArrayLength();
error NonExistTokenData(uint256 tokenId);
error MustMintMinimumOne(uint256 tokenId);
error SoldOut(uint256 tokenId);
error WalletMintLimit(uint256 tokenId, uint32 limit);
error NotEnoughEvoTokens();
error NotOwnerOfToken(uint256 tokenId);
error MaxSupplyMustBeMinimumOne();
error PriceMustBeMinimumOne();
error InvalidTokenId(uint256 tokenId);

contract AngryApeArmyArmoryCollection is
    AdminPermissionable,
    PreAuthorisable,
    ERC1155Supply,
    ERC1155Burnable,
    Royalty,
    Signature,
    SaleState
{
    struct TokenData {
        uint32 maxSupply;
        uint32 price;
    }

    string private _name;
    string private _symbol;

    uint32 public constant MAX_MINT = 2;

    // token id to token data
    mapping(uint256 => TokenData) public tokenData;

    // token id to use when new token is added. Whenever new token is added, this value is increased by 1
    uint256 public newTokenId = 9;

    // Evo contract
    ERC721ABurnable private _evoContract;

    // Events
    event MintBegins();
    event MintEnds();
    event URIUpdated(string uri_);
    event TokenDataSet(uint256 tokenId);

    constructor(
        address signer_,
        address admin_,
        address royaltyReceiver_,
        ERC721ABurnable evoContract_,
        address[] memory _preAuthorized
    )
        ERC1155("https://massless-ipfs-public-gateway.mypinata.cloud/ipfs/")
        Signature(signer_)
        PreAuthorisable(_preAuthorized)
    {
        if (_msgSender() == admin_) revert DeployerIsAdmin();
        _name = "Angry Ape Army Armory Collection";
        _symbol = "AAAARM";

        tokenData[1] = TokenData(400, 4); // 1. Golem
        tokenData[2] = TokenData(400, 4); // 2. Goliath
        tokenData[3] = TokenData(400, 2); // 3. Virus Horse
        tokenData[4] = TokenData(400, 2); // 4. Nano Horse
        tokenData[5] = TokenData(400, 1); // 5. Virus Weapon
        tokenData[6] = TokenData(400, 1); // 6. Nano Weapon
        tokenData[7] = TokenData(400, 1); // 7. Virus Wings
        tokenData[8] = TokenData(400, 1); // 8. Nano Backpack

        _evoContract = evoContract_;

        setRoyaltyReceiver(royaltyReceiver_);
        setRoyaltyBasisPoints(750);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    modifier maxGiveawayLimit(
        uint256[] calldata tokenIds_,
        uint256[] calldata quantities_
    ) {
        uint256 tokenIdsLength = tokenIds_.length;
        if (tokenIdsLength != quantities_.length) revert ArrayLengthMismatch();
        if (tokenIdsLength == 0) revert BadArrayLength();

        uint256[] memory tokenIdToQuantity = new uint256[](newTokenId);
        for (uint256 i; i < tokenIdsLength; i++) {
            uint256 tokenId = tokenIds_[i];
            TokenData memory token = tokenData[tokenId];

            // if token exists
            if (token.maxSupply > 0) {
                uint256 supplyLimit = token.maxSupply - totalSupply(tokenId);
                uint256 quantity = quantities_[i];

                if (quantity == 0) revert MustMintMinimumOne(tokenId);

                tokenIdToQuantity[tokenId] =
                    tokenIdToQuantity[tokenId] +
                    quantity;
                if (tokenIdToQuantity[tokenId] > supplyLimit)
                    revert SoldOut(tokenId);
            } else {
                revert NonExistTokenData(tokenId);
            }
        }
        _;
    }

    modifier validTokenData(uint32 maxSupply_, uint32 price_) {
        if (maxSupply_ == 0) revert MaxSupplyMustBeMinimumOne();
        if (price_ == 0) revert PriceMustBeMinimumOne();
        _;
    }

    // mint
    function mint(
        bytes calldata signature_,
        bytes32 salt_,
        uint256[] calldata tokenIds_,
        uint256[] calldata quantities_,
        uint256[] calldata evoTokenIds_
    )
        external
        whenSaleIsActive("Mint")
        onlySignedTx(
            keccak256(
                abi.encodePacked(
                    _msgSender(),
                    salt_,
                    tokenIds_,
                    quantities_,
                    evoTokenIds_
                )
            ),
            signature_
        )
    {
        _checkMintLimitAndPrice(tokenIds_, quantities_, evoTokenIds_.length);

        for (uint256 i; i < evoTokenIds_.length; i++) {
            if (_evoContract.ownerOf(evoTokenIds_[i]) != _msgSender())
                revert NotOwnerOfToken(evoTokenIds_[i]);
            _evoContract.burn(evoTokenIds_[i]);
        }

        _mintBatch(_msgSender(), tokenIds_, quantities_, "");
    }

    function giveaway(
        address[] calldata to_,
        uint256[] calldata tokenIds_,
        uint256[] calldata quantities_
    ) public onlyAdmin maxGiveawayLimit(tokenIds_, quantities_) {
        if (to_.length != tokenIds_.length) revert ArrayLengthMismatch();
        if (to_.length == 0) revert BadArrayLength();

        for (uint256 i; i < to_.length; i++) {
            _mint(to_[i], tokenIds_[i], quantities_[i], "");
        }
    }

    function startMint() external onlyAdminOrModerator {
        _setSaleType("Mint");
        _setSaleState(State.ACTIVE);

        emit MintBegins();
    }

    function unpauseMint() external onlyAdminOrModerator {
        _unpause();
    }

    function pauseMint() external onlyAdminOrModerator {
        _pause();
    }

    function endMint() external onlyAdmin {
        if (getSaleState() != State.ACTIVE) revert NoActiveSale();
        _setSaleState(State.FINISHED);

        emit MintEnds();
    }

    function _checkMintLimitAndPrice(
        uint256[] calldata tokenIds_,
        uint256[] calldata quantities_,
        uint256 totalPrice
    ) private view {
        if (tokenIds_.length != quantities_.length)
            revert ArrayLengthMismatch();
        if (tokenIds_.length == 0) revert BadArrayLength();

        uint256 sumPrice;
        for (uint256 i; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            TokenData memory token = tokenData[tokenId];

            // if token exists
            if (token.maxSupply > 0) {
                uint256 supplyLimit = token.maxSupply - totalSupply(tokenId);
                uint256 quantity = quantities_[i];

                if (quantity == 0) revert MustMintMinimumOne(tokenId);
                if (quantity > supplyLimit) revert SoldOut(tokenId);
                if (balanceOf(_msgSender(), tokenId) + quantity > MAX_MINT)
                    revert WalletMintLimit(tokenId, MAX_MINT);

                sumPrice = sumPrice + (token.price * quantity);
            } else {
                revert NonExistTokenData(tokenId);
            }
        }
        if (sumPrice != totalPrice) revert NotEnoughEvoTokens();
    }

    // Metadata
    function setURI(string memory uri_) public onlyAdminOrModerator {
        if (bytes(uri_)[bytes(uri_).length - 1] != bytes1("/"))
            revert NoTrailingSlash();
        _setURI(uri_);

        emit URIUpdated(uri_);
    }

    function uri(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(ERC1155.uri(tokenId_), "token/{id}.json"));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(ERC1155.uri(0), "contract.json"));
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    // Administration
    function setSignerAddress(address signerAddress_)
        public
        onlyAdminOrModerator
    {
        _setSignerAddress(signerAddress_);
    }

    function setRoyaltyReceiver(address royaltyReceiver_) public onlyAdmin {
        _setRoyaltyReceiver(royaltyReceiver_);
    }

    function setRoyaltyBasisPoints(uint32 royaltyBasisPoints_)
        public
        onlyAdmin
    {
        _setRoyaltyBasisPoints(royaltyBasisPoints_);
    }

    function setAuthorizedAddress(address authorizedAddress_, bool authorized_)
        public
        onlyAdmin
    {
        _setAuthorizedAddress(authorizedAddress_, authorized_);
    }

    function setTokenData(
        uint256 tokenId_,
        uint32 maxSupply_,
        uint32 price_
    ) public onlyAdmin validTokenData(maxSupply_, price_) {
        // if new token data
        if (tokenData[tokenId_].maxSupply == 0) {
            if (tokenId_ == newTokenId) {
                newTokenId++;
            } else {
                revert InvalidTokenId(tokenId_);
            }
        }

        tokenData[tokenId_].maxSupply = maxSupply_;
        tokenData[tokenId_].price = price_;

        emit TokenDataSet(tokenId_);
    }

    // Overrides
    /**
     * @dev Override supportsInterface to ensure interfaces are reports as supported.
     */
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

    /**
     * @dev Override supportsInterface to ensure interfaces are reports as supported.
     */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, Royalty, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IContractURI).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to whitelist the trusted accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        if (_isAuthorizedAddress(_operator)) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        ERC1155Supply._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }
}