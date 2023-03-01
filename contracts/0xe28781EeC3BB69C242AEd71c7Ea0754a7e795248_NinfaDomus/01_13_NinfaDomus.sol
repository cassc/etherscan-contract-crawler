/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../extensions/ERC721Enumerable.sol";
import "../extensions/ERC721URIStorage.sol";
import "../extensions/ERC721Burnable.sol";
import "../extensions/ERC721LazyMintableCommunal.sol";
import "../extensions/ERC721Royalty.sol";
import "../../../access/AccessControl.sol";

/*************************************************************
 * @title ERC721Communal                                     *
 *                                                           *
 * @notice Communal/shared ERC-721 minter preset             *
 *                                                           *
 * @dev {ERC721} token                                       *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract NinfaDomus is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721URIStorage,
    ERC721LazyMintableCommunal,
    ERC721Royalty,
    AccessControl
{
    /*----------------------------------------------------------*|
    |*  # ACCESS CONTROL                                        *|
    |*----------------------------------------------------------*/

    bytes32 internal constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE"); one or more smart contracts allowed to call the mint function, eg. the Marketplace contract
    bytes32 internal constant CURATOR_ROLE =
        0x850d585eb7f024ccee5e68e55f2c26cc72e1e6ee456acf62135757a5eb9d4a10; // keccak256("CURATOR_ROLE")

    /*----------------------------------------------------------*|
    |*  # PRIMARY MARKET FEES                                   *|
    |*----------------------------------------------------------*/
    /// @dev optional market fees for lazy minting (primary sales) on communal/shared collections

    uint24 private _feeBps;
    address private _feeRecipient;

    /*----------------------------------------------------------*|
    |*  # MINTING                                               *|
    |*----------------------------------------------------------*/

    function lazyMint(
        Voucher calldata _voucher,
        bytes calldata _signature,
        bytes calldata _data,
        address _to
    ) external payable {
        uint256 sellerAmount = _voucher.price;

        require(msg.value == sellerAmount);

        uint256 tokenId = _owners.length;

        /*----------------------------------------------------------*|
        |*  # PAY PRIMARY MARKET FEES                               *|
        |*----------------------------------------------------------*/
        /**
         * @dev primary market fees MUST be paid before calling lazyMint
         *       in order to subtract the fee amount from the seller amount first
         * @dev it is assumed that there is always a market fee higher than 0, therefore an `if` check has been omitted
         */
        uint256 feeAmount = (msg.value * _feeBps) / 10000;
        sellerAmount -= feeAmount;
        _sendValue(_feeRecipient, feeAmount);

        /*----------------------------------------------------------*|
        |*  # LAZY MINTING                                          *|
        |*----------------------------------------------------------*/

        address signer = _lazyMint(
            _voucher,
            _signature,
            _data,
            _to,
            tokenId,
            sellerAmount
        );

        require(hasRole(MINTER_ROLE, signer));

        /*----------------------------------------------------------*|
        |*  # ERC-721 EXTENSIONS                                    *|
        |*----------------------------------------------------------*/

        _setTokenURI(tokenId, _voucher.tokenURI);

        _setRoyaltyRecipient(signer, tokenId);

    }

    /*----------------------------------------------------------*|
    |*  # BURN OVERRIDE                                         *|
    |*----------------------------------------------------------*/

    /**
     * @dev required override by Solidity
     */
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721Royalty, ERC721URIStorage) {
        
        super._burn(tokenId);
    }

    /*----------------------------------------------------------*|
    |*  # ADMIN FUNCTIONS                                       *|
    |*----------------------------------------------------------*/

    function setFeeBps(
        uint24 feeBps_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _feeBps = feeBps_;
    }

    function setFeeRecipient(
        address feeRecipient_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _feeRecipient = feeRecipient_;
    }

    /*----------------------------------------------------------*|
    |*  # VIEW FUNCTIONS                                        *|
    |*----------------------------------------------------------*/

    /**
     * @dev same function interface as erc1155, so that external contracts, i.e. the marketplace, can check either erc without requiring an if/else statement
     */
    function exists(uint256 _id) external view returns (bool) {
        return _owners[_id] != address(0);
    }

    /*----------------------------------------------------------*|
    |*  # ERC-165                                               *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC165-supportsInterface}.
     * @dev hardcoded interface IDs in order to save gas to callers.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return
            interfaceId == 0x80ac58cd || // type(IERC721).interfaceId
            interfaceId == 0x780e9d63 || // type(IERC721Enumerable).interfaceId
            interfaceId == 0x01ffc9a7 || // type(IERC165).interfaceId
            interfaceId == 0x2a55205a || // type(IERC2981).interfaceId
            interfaceId == 0x7965db0b; // type(IAccessControl).interfaceId;
    }

    /*----------------------------------------------------------*|
    |*  # INITIALIZATION                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice creates `DOMAIN_SEPARATOR`,
     *      Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract,
     *      assigns `CURATOR_ROLE` as the admin role for `MINTER_ROLE`,
     *      sets fee account address and fee BPS to 15% on primary market sales.
     * @param feeRecipient_ admin multisig contract for receiving market fees on sales.
     */
    constructor(
        string memory _eip712DomainName,
        string memory _symbol,
        address feeRecipient_,
        uint24 feeBps_
    ) ERC721LazyMintableCommunal(_eip712DomainName) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, CURATOR_ROLE);

        name = _eip712DomainName; // "Ninfa Domus"
        symbol = _symbol;

        _feeBps = feeBps_;
        _feeRecipient = feeRecipient_;
    }
}