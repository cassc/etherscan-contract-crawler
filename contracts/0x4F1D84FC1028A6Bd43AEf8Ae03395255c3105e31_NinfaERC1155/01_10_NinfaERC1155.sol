/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./access/AccessControl.sol";
import "./token/common/ERC2981CommunalEditions.sol";
import "./token/ERC1155/extensions/ERC1155Burnable.sol";
import "./token/ERC1155/extensions/ERC1155URIStorage.sol";
import "./token/ERC1155/extensions/ERC1155Supply.sol";

/************************************************************
 * @title NinfaERC1155                                      *
 *                                                          *
 * @notice Communal Ninfa ERC-1155 collection               *
 *                                                          *
 * @dev {ERC1155} token implements lazy minting             *
 *      in order to guarantee primary market fee payments   *
 *                                                          *
 * @custom:security-contact [email protected]                   *
 ***********************************************************/

contract NinfaERC1155 is
    AccessControl,
    ERC2981CommunalEditions,
    ERC1155Burnable,
    ERC1155URIStorage,
    ERC1155Supply
{
    // EIP-712
    bytes32 private immutable DOMAIN_SEPARATOR;
    bytes32 private immutable VOUCHER_TYPEHASH;

    // Acces Control
    bytes32 private constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE"); one or more smart contracts allowed to call the mint function, eg. the Marketplace contract
    bytes32 private constant CURATOR_ROLE =
        0x850d585eb7f024ccee5e68e55f2c26cc72e1e6ee456acf62135757a5eb9d4a10; // keccak256("CURATOR_ROLE")

    // Market fees
    uint24 private _primaryFeeBps;
    address private _marketFeeRecipient;

    // Metadata (OPTIONAL non-standard, see https://eips.ethereum.org/EIPS/eip-1155#metadata-choices)
    string public name = "NINFA";
    string public symbol = "NINFA";

    /**
     * @param totalValue maximum tokenId editions cap, if unlimited supply use `type(uint256).max` i.e. 2**256 - 1
     * @param endTime timestamp for when the signed voucher should expire,
     *      if no expiration is needed, timestamp should be `type(uint256).max` i.e. 2**256 - 1,
     *      or anything above 2^32, i.e. 4294967296, i.e. voucher expires after 2106 (in 83 years time)
     */
    struct Voucher {
        bytes32 tokenUri;
        uint256 unitPrice;
        uint256 totalValue;
        uint256 endTime;
        uint256 saleCommissionBps;
        address saleCommissionRecipient;
    }

    /*----------------------------------------------------------*|
    |*  # MINTER FUNCTIONS                                      *|
    |*----------------------------------------------------------*/

    /**
     * @param _tokenId may correspond to an already existing tokenId, if so, the corresponding tokenUri at `_tokenURIs[_tokenId]` MUST equal `voucher.tokenUri`,
     *      or it may be an inexisting tokenId such as 2^256-1 in which case a new token will be minted, provided that `voucher.tokenUri` has never been minted before.
     * @param _value the amount/supply of `tokenId` to be minted, provided that the total tokenId's circulating supply does not exceed the one (if any) specified in `voucher.totalValue`.
     * @param _to buyer, needed if using a external payment gateway, so that the minted tokenId value is sent to the address specified insead of `msg.sender`
     * @param _data data bytes are passed to `onErc1155Received` function if the `_to` address is a contract, for example a marketplace.
     *      `onErc1155Received` is not being called on the minter's address when a new tokenId is minted however, even if it was contract.
     */
    function lazyMint(
        Voucher calldata _voucher,
        uint256 _tokenId,
        uint256 _value,
        address _to,
        bytes memory _signature,
        bytes calldata _data
    ) external payable {
        /*----------------------------------------------------------*|
        |*  # EIP-712 TYPED DATA SIGNATURE VERIFICATION             *|
        |*----------------------------------------------------------*/

        address signer = _recover(_voucher, _signature);

        uint256 sellerAmount = _voucher.unitPrice * _value;

        require(
            // `msg.value` MUST equal ETH unit price multiplied by token value/amount
            msg.value == sellerAmount &&
                // _voucher MUST not be expired
                block.timestamp < _voucher.endTime
        );

        /*----------------------------------------------------------*|
        |*  # MINT                                                  *|
        |*----------------------------------------------------------*/

        if (exists(_tokenId)) {
            /**
             * @dev since `_tokenId` is a user-supplied parameter it can't be trusted, therefore if increasing supply fot an existing token,
             *      the `tokenUri` contained in the `_voucher` MUST match the one stored at `_tokenURIs[_tokenId]`.
             */
            require(
                _voucher.tokenUri == _tokenURIs[_tokenId] &&
                    (_totalSupply[_tokenId] += _value) <= _voucher.totalValue &&
                    /**
                     * @dev The `_voucher` signer MUST be the original artist or at least a royalty recipient for the user-supplied `_tokenId`,
                     *      otherwise a malicious artist could sign a _voucher with the same URI of another artist's token they want to mint and set price to 0,
                     *      alowing them to mint new tokens for free; although minter's address will result as the malicious signer, it is still a risk as these "fake" tokens may still be traded.
                     *      this check is only needed for communal ERC-1155 editions where there are multiple artists,
                     *      as opposed to self-sovreign ERC-1155 editions where there is a single deployer/artist
                     */
                    (signer == _royaltyRecipients[_tokenId] ||
                        signer == artists[_tokenId])
            );
        } else {
            require(
                _value <= _voucher.totalValue && hasRole(MINTER_ROLE, signer)
            );
            /// @dev since `_tokenId` is user-supplied it MUST be reassigned the correct value for the rest of the function work correctly
            _tokenId = _totalSupply.length;
            _totalSupply.push(_value);
            _tokenURIs[_tokenId] = _voucher.tokenUri;
            _royaltyRecipients[_tokenId] = payable(signer);
        }

        /**
         * @dev the following is the net state change after tokenId `_value` has been minted and transferred to a buyer,
         *      rather than calling the internal `_mint` function which whould increase balance of minter, followed by `safeTransferFrom`, which would decrease it.
         *      I.e. minter balance is not updated as it would cancel out anyway after sending the newly minted tokenId `_value` to buyer.
         *      Additionally `safeTransferFrom` function has been omitted otherwise `msg.sender` would have to be an authorized operator by the seller/minter.
         */
        unchecked {
            _balanceOf[_to][_tokenId] += _value;
        }

        // event is needed in order to signal to DApps that a mint has occurred
        emit TransferSingle(msg.sender, address(0), signer, _tokenId, _value);
        // event is needed in order to signal to DApps that a token transfer has occurred
        emit TransferSingle(msg.sender, signer, _to, _tokenId, _value);

        /*----------------------------------------------------------*|
        |*  # PAY MARKET FEES                                       *|
        |*----------------------------------------------------------*/

        uint256 marketFeeAmount = (msg.value * _primaryFeeBps) / 10000;
        sellerAmount -= marketFeeAmount;
        _sendValue(_marketFeeRecipient, marketFeeAmount);

        /*----------------------------------------------------------*|
        |*  # CHECK-EFFECTS-INTERACTIONS                            *|
        |*----------------------------------------------------------*/
        /// @dev perform external calls to untrusted addresses last

        /*----------------------------------------------------------*|
        |*  # PAY SELLER (AND COMMISSIONS)                          *|
        |*----------------------------------------------------------*/

        if (_voucher.saleCommissionBps > 0) {
            uint256 commissionAmount = (msg.value *
                _voucher.saleCommissionBps) / 10000;
            sellerAmount -= commissionAmount;
            _sendValue(_voucher.saleCommissionRecipient, commissionAmount);
        }

        _sendValue(signer, sellerAmount);

        /*----------------------------------------------------------*|
        |*  # SAFE TRANSFER                                         *|
        |*----------------------------------------------------------*/
        /// @dev onERC1155Received is not called on the minter's account

        if (_to.code.length > 0)
            require(
                IERC1155Receiver(_to).onERC1155Received(
                    msg.sender, // operator
                    signer, // from
                    _tokenId, // token id
                    _value, // value
                    _data
                ) == 0xf23a6e61, // IERC1155Receiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*----------------------------------------------------------*|
    |*  # BURN                                                  *|
    |*----------------------------------------------------------*/

    function burn(address _from, uint256 _id, uint256 _value) public override {
        super.burn(_from, _id, _value);
        /// @dev since balance has already been decremented without underflow,
        // `_totalSupply` may be safely decremented. See {ERC1155-_burn}
        unchecked {
            _totalSupply[_id] -= _value;
        }
        // if all supply has been burned, _tokenURIs[_id] is deleted from storage
        if (_totalSupply[_id] == 0) delete _tokenURIs[_id];
    }

    /*----------------------------------------------------------*|
    |*  # PRIVATE FUNCTIONS                                     *|
    |*----------------------------------------------------------*/

    function _recover(
        Voucher calldata _voucher,
        bytes memory _signature
    ) private view returns (address _signer) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        VOUCHER_TYPEHASH,
                        _voucher.tokenUri,
                        _voucher.unitPrice,
                        _voucher.totalValue,
                        _voucher.endTime,
                        _voucher.saleCommissionBps,
                        _voucher.saleCommissionRecipient
                    )
                )
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        _signer = ecrecover(digest, v, r, s);
        if (_signer == address(0)) revert();
    }

    function _sendValue(address _receiver, uint256 _amount) private {
        (bool success, ) = payable(_receiver).call{value: _amount}("");
        require(success);
    }

    /*----------------------------------------------------------*|
    |*  # ERC-165 LOGIC                                         *|
    |*----------------------------------------------------------*/

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // Interface ID for IERC165
            interfaceId == 0xd9b67a26 || // Interface ID for IERC1155
            interfaceId == 0x0e89341c || // Interface ID for IERC1155MetadataURI
            interfaceId == 0x2a55205a || // Interface ID for IERC2981
            interfaceId == 0x7965db0b; // Interface ID for IAccessControl
    }

    /*----------------------------------------------------------*|
    |*  # ADMIN FUNCTIONS                                       *|
    |*----------------------------------------------------------*/

    function setFeeAccount(
        address feeAccount_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _marketFeeRecipient = feeAccount_;
    }

    function setPrimaryFeeBps(
        uint24 primaryFeeBps_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _primaryFeeBps = primaryFeeBps_;
    }

    /**
     * @notice creates `DOMAIN_SEPARATOR` and `VOUCHER_TYPEHASH`,
     *      Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract,
     *      assigns `CURATOR_ROLE` as the admin role for `MINTER_ROLE`,
     *      sets fee account address and fee BPS to 10% on primary market sales.
     * @param feeAccount_ admin multisig contract for receiving market fees on sales.
     */
    constructor(address feeAccount_) {
        /**
         * @dev The EIP712Domain fields should be the order as above, skipping any absent fields.
         *      Protocol designers only need to include the fields that make sense for their signing domain. Unused fields are left out of the struct type.
         * @param name the user readable name of signing domain, i.e. the name of the DApp or the protocol.
         * @param chainId the EIP-155 chain id. The user-agent should refuse signing if it does not match the currently active chain.
         * @param verifyingContract the address of the contract that will verify the signature. The user-agent may do contract specific phishing prevention.
         *      verifyingContract is the only variable parameter in the DOMAIN_SEPARATOR in order to avoid signature replay across different contracts
         *      therefore the DOMAIN_SEPARATOR MUST be calculated inside of the `initialize` function rather than the constructor.
         */
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866, // hardcoded value for keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"), DOMAIN_TYPEHASH
                0xdb3dd9b854cdb7551722584c7e89b5df9798432c0c9ee9bc6f62a8edfed5dac4, // hardcoded value for keccak256(bytes("ninfa.io")),
                block.chainid,
                address(this)
            )
        );
        VOUCHER_TYPEHASH = keccak256(
            "Voucher(bytes32 tokenUri,uint256 unitPrice,uint256 totalValue,uint256 endTime,uint256 saleCommissionBps,address saleCommissionRecipient)"
        );

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, CURATOR_ROLE);

        _marketFeeRecipient = feeAccount_;
        _primaryFeeBps = 1000; // 10% marketplace fees on primary market sales
    }
}