/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../access/AccessControl.sol";
import "../common/ERC2981PersonalEditions.sol";
import "./extensions/ERC1155Burnable.sol";
import "./extensions/ERC1155URIStorage.sol";
import "./extensions/ERC1155Supply.sol";

/*************************************************************
 * @title ERC1155Minter                                      *
 *                                                           *
 * @notice Self-sovreign ERC-1155 minter preset              *
 *                                                           *
 * @dev {ERC1155} token featuring:                           *
 *      + minting and lazy minting                           *
 *      + ERC-2981 royalty standard tracking both royalties  *
 *        and token market (primary and secondary)           *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract ERC1155Minter is
    AccessControl,
    ERC2981PersonalEditions,
    ERC1155Burnable,
    ERC1155URIStorage,
    ERC1155Supply
{
    // EIP-712
    bytes32 private DOMAIN_SEPARATOR;
    bytes32 private immutable VOUCHER_TYPEHASH;

    // Acces Control
    bytes32 internal constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE"); one or more smart contracts allowed to call the mint function, eg. the Marketplace contract
    address private immutable _FACTORY;

    // Metadata (OPTIONAL non-standard, see https://eips.ethereum.org/EIPS/eip-1155#metadata-choices)
    string public name;
    string public symbol;

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
        uint256 marketFeeBps;
        address saleCommissionRecipient;
        address marketFeeRecipient;
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
        Voucher calldata voucher,
        uint256 _tokenId,
        uint256 _value,
        address _to,
        bytes memory _signature,
        bytes calldata _data
    ) external payable {
        /*----------------------------------------------------------*|
        |*  # EIP-712 TYPED DATA SIGNATURE VERIFICATION             *|
        |*----------------------------------------------------------*/

        address signer = _recover(voucher, _signature);

        uint256 sellerAmount = voucher.unitPrice * _value;

        require(
            // `msg.value` MUST equal ETH unit price multiplied by token value/amount
            msg.value == sellerAmount &&
                // voucher MUST not be expired
                block.timestamp < voucher.endTime &&
                // signer MUST have MINTER_ROLE
                hasRole(MINTER_ROLE, signer)
        );

        /*----------------------------------------------------------*|
        |*  # MINT                                                  *|
        |*----------------------------------------------------------*/

        if (exists(_tokenId)) {
            /**
             * @dev since `_tokenId` is a user-supplied parameter it can't be trusted, therefore if increasing supply for an existing token,
             *      the `tokenUri` contained in the `_voucher` MUST match the one stored at `_tokenURIs[_tokenId]`.
             */
            require(
                voucher.tokenUri == _tokenURIs[_tokenId] &&
                    // if the tokenId already exists, increment the array value at _totalSupply[_tokenId]
                    (_totalSupply[_tokenId] += _value) <= voucher.totalValue
            );
        } else {
            require(_value <= voucher.totalValue);
            /// @dev since `_tokenId` is user-supplied it MUST be reassigned the correct value for the rest of the function work correctly
            _tokenId = _totalSupply.length;
            // if the tokenId doesn't exist yet, push a new value to the corresponding array index
            _totalSupply.push(_value);
            _tokenURIs[_tokenId] = voucher.tokenUri;
        }

        /*----------------------------------------------------------*|
        |*  # UPDATE BALANCES                                       *|
        |*----------------------------------------------------------*/

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

        uint256 marketFeeAmount = (msg.value * voucher.marketFeeBps) / 10000;
        sellerAmount -= marketFeeAmount;
        _sendValue(voucher.marketFeeRecipient, marketFeeAmount);

        /*----------------------------------------------------------*|
        |*  # CHECK-EFFECTS-INTERACTIONS                            *|
        |*----------------------------------------------------------*/
        /// @dev perform external calls to untrusted addresses last

        /*----------------------------------------------------------*|
        |*  # PAY SELLER (AND COMMISSIONS)                          *|
        |*----------------------------------------------------------*/

        if (voucher.saleCommissionBps > 0) {
            uint256 commissionAmount = (msg.value * voucher.saleCommissionBps) /
                10000;
            sellerAmount -= commissionAmount;
            _sendValue(voucher.saleCommissionRecipient, commissionAmount);
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

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     * @param _to if different from msg.sender it is considered an airdrop
     * @param _tokenURI the ipfs hash of the token, base58 decoded, then the first two bytes "Qm" removed,  then hex encoded and in order to fit exactly in 32 bytes (uint256 is 32 bytes).
     *
     * const getBytes32FromIpfsHash = hash => {
     *      let bytes = bs58.decode(hash);
     *      bytes = bytes.slice(2, bytes.length);
     *      let hexString = web3.utils.bytesToHex(bytes);
     *      return web3.utils.hexToNumber(hexString);
     *  };
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`, i.e. only the owner of the collection can mint tokens, not just any artist on Ninfa marketplace.
     *
     */
    function mint(
        address _to,
        bytes32 _tokenURI,
        uint256 _amount,
        bytes memory _data
    ) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _totalSupply.length;
        _mint(_to, tokenId, _amount, _data);
        _tokenURIs[tokenId] = _tokenURI;
        _totalSupply.push(_amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
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
                        _voucher.marketFeeBps,
                        _voucher.saleCommissionRecipient,
                        _voucher.marketFeeRecipient
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

    function setRoyaltyInfo(
        address royaltyRecipient_,
        uint24 royaltyBps_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _royaltyRecipient = payable(royaltyRecipient_);
        _royaltyBps = royaltyBps_;
    }

    /**
     * @notice This function is used when the artist decides to set the royalty receiver to an address other than its own.
     * It adds the artist address to the `artists` mapping in {ERC2981Communal}, in order to use it for access control in `setRoyaltyRecipient()`. This removes the burden of setting this mapping in the `mint()` function as it will rarely be needed.
     * @param royaltyRecipient_ (likely a payment splitter contract) may be 0x0 although it is not intended as ETH would be burnt if sent to 0x0. If the user only wants to mint it should call mint() instead, so that the roy
     *
     * Require:
     *
     * - If the `artists` for `_tokenId` mapping is empty, the minter's address is equal to `royaltyRecipients[_tokenId]`. I.e. the caller must correspond to `royaltyRecipients[_tokenId]`, i.e. the token minter/artist
     * - Else, the caller must correspond to the `_tokenId`'s minter address set in `artists[_tokenId]`, i.e. if `artists[_tokenId]` is not 0x0. Note that the artist address cannot be reset.
     *
     * Allow:
     *
     * - the minter may (re)set `royaltyRecipients[_tokenId]` to the same address as `artists[_tokenId]`, i.e. the minter/artist. This would be quite useless, but not dangerous. The frontend should disallow it.
     *
     */
    function setRoyaltyRecipient(
        address royaltyRecipient_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _royaltyRecipient = payable(royaltyRecipient_);
    }

    function setRoyaltyBps(
        uint24 royaltyBps_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _royaltyBps = royaltyBps_;
    }

    /*----------------------------------------------------------*|
    |*  # POST-DEPLOYMENT INITIALIZATION                        *|
    |*----------------------------------------------------------*/

    function initialize(bytes calldata _data) external {
        require(msg.sender == _FACTORY);

        address owner;
        (name, symbol, owner, _royaltyRecipient, _royaltyBps) = abi.decode(
            _data,
            (string, string, address, address, uint24)
        );

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
                0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866, //harcoded value for keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)") DOMAIN_TYPEHASH
                0xdb3dd9b854cdb7551722584c7e89b5df9798432c0c9ee9bc6f62a8edfed5dac4, //harcoded value for keccak256(bytes("ninfa.io")),
                block.chainid,
                address(this)
            )
        );

        _grantRole(DEFAULT_ADMIN_ROLE, owner); // DEFAULT_ADMIN_ROLE is by default admin of all other roles, i.e. MINTER_ROLE, meaning it can assign MINTER_ROLE to other addresses _grantRole(MINTER_ROLE, msg.sender); // grant MINTER_ROLE to factory contract
        _grantRole(MINTER_ROLE, owner); // grant MINTER_ROLE to owner, this way minting requires only checking for MINTER_ROLE rather than also DEFAULT_ADMIN_ROLE.
    }

    /**
     * @notice creates `DOMAIN_SEPARATOR` and `VOUCHER_TYPEHASH` and assigns address to `_FACTORY`
     * @param factory_ is used for access control on self-sovreign ERC-1155 collection rather than using the `initializer` modifier,
     *      this is cheaper because the clones won't need to write `initialized = true;` to storage each time they are initialized
     *      instead `_FACTORY` is only assigned once in the `constructor` of the master copy therefore it can be read by all clones.
     */
    constructor(address factory_) {
        VOUCHER_TYPEHASH = keccak256(
            "Voucher(bytes32 tokenUri,uint256 unitPrice,uint256 totalValue,uint256 endTime,uint256 saleCommissionBps,uint256 marketFeeBps,address saleCommissionRecipient,address marketFeeRecipient)"
        );
        _FACTORY = factory_;
    }
}