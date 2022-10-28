// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./IReceiverVerifier.sol";
import "./Structs.sol";

/// @title ERC1155Invoke contract
/// @notice ERC1155 contract that supports the echelon protocol
contract ERC1155Invoke is
    Context,
    AccessControlEnumerable,
    ERC1155Burnable,
    ReentrancyGuard
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Address of PRIME contract.
    IERC20 public PRIME = IERC20(0xb23d80f5FefcDDaa212212F028021B41DEd428CF);

    /// @notice Router mapping
    mapping(uint256 => RouterEndpoint) public routerEndpoints;

    /// @notice Token id to uri mapping
    mapping(uint256 => string) public tokenSuffix;

    /// @notice Indicated if invoke is disabled
    bool public disabled;

    /// @notice Indicated if base uri is updatable
    bool public isBaseUriLocked = false;

    /// @notice A descriptive name for a collection of NFTs in this contract
    string public name;

    /// @notice An abbreviated name for NFTs in this contract
    string public symbol;

    /// @notice Modifier used to check if sender is minter
    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC1155Invoke: must have minter role"
        );
        _;
    }

    /// @param _uri Metadata url.
    /// @param _name Name of collection.
    /// @param _symbol Symbol for collection.
    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
    }

    /// @notice Sets invoke to enabled/disabled.
    /// @param _disabled New state of the invoke.
    function setDisabled(bool _disabled) external onlyMinter {
        disabled = _disabled;
    }

    /// @notice Updated PRIME contract address.
    /// @param _prime New PRIME contract address.
    function setPrime(address _prime) external onlyMinter {
        PRIME = IERC20(_prime);
    }

    /// @notice Set new metadata uri.
    /// @param _uri New metadata uri.
    function setUri(string calldata _uri) external onlyMinter {
        require(!isBaseUriLocked, "ERC1155Invoke: base uri is locked");
        _setURI(_uri);
    }

    /// @notice Locks base uri update.
    function lockBaseUri() external onlyMinter {
        isBaseUriLocked = true;
    }

    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(super.uri(tokenId), tokenSuffix[tokenId]));
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string memory tokenUri,
        bytes memory data
    ) external onlyMinter {
        require(
            bytes(tokenUri).length != 0,
            "ERC1155Invoke: token uri cannot be empty"
        );
        require(
            bytes(tokenSuffix[id]).length == 0,
            "ERC1155Invoke: token already minted"
        );

        tokenSuffix[id] = tokenUri;

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] memory tokenUris,
        bytes memory data
    ) external onlyMinter {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                bytes(tokenUris[i]).length != 0,
                "ERC1155Invoke: token uri cannot be empty"
            );
            require(
                bytes(tokenSuffix[ids[i]]).length == 0,
                "ERC1155Invoke: token already minted"
            );

            tokenSuffix[ids[i]] = tokenUris[i];
        }

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Allow the caller to send PRIME and/or ETH to the Echelon Ecosystem of smart contracts
     *         PRIME and ETH are collected to the destination address, handler is invoked to trigger downstream logic and events
     * @param _id - The id of the deployed and registered InvokeEchelonHandler contract
     * @param _primeValue - The amount of PRIME that was sent to the invokeEchelon function (and was collected to _destination)
     * @param _data - Catch-all param to allow the caller to pass additional data to the handler
     */
    function invoke(
        uint256 _id,
        uint256[] calldata _tokenIds,
        uint256[] calldata _tokenQuantities,
        uint256 _primeValue,
        bytes calldata _data
    ) external payable nonReentrant {
        require(!disabled, "ERC1155Invoke: disabled");

        // Require type to be setup
        RouterEndpoint memory routerEndpoint = routerEndpoints[_id];
        require(
            routerEndpoint.verifier != address(0),
            "ERC1155Invoke: routerEndpoint must be initialized"
        );

        // pull the eth to ethReceiverAddress
        if (msg.value != 0) {
            (bool success, ) = payable(routerEndpoint.ethReceiver).call{
                value: msg.value
            }("");
            require(success, "ERC1155Invoke: Failed to receive Ether");
        }

        // pull the PRIME to primeReceiverAddress
        if (_primeValue != 0) {
            bool primeSent = PRIME.transferFrom(
                msg.sender,
                routerEndpoint.primeReceiver,
                _primeValue
            );
            require(primeSent, "ERC1155Invoke: Failed to send PRIME");
        }

        // pull the Nfts to nftReceiverAddress
        if (_tokenIds.length != 0) {
            _safeBatchTransferFrom(
                msg.sender,
                routerEndpoint.nftReceiver,
                _tokenIds,
                _tokenQuantities,
                ""
            );
        }

        // Invoke handler
        IReceiverVerifier(routerEndpoint.verifier).handleInvoke(
            msg.sender,
            routerEndpoint,
            msg.value,
            _primeValue,
            _tokenIds,
            _tokenQuantities,
            _data
        );
    }

    /**
     * @notice Allow an address with minter role to add a handler contract for invoke
     * @param _id - The id of the newly added handler contracts
     * @param _nftReceiver - The address to which the nfts are collected
     * @param _ethReceiver - The address to which ETH is collected
     * @param _primeReceiver - The address to which PRIME is collected
     * @param _verifier - The address of the new invoke handler contract to be registered
     */
    function setReceiver(
        uint256 _id,
        address _nftReceiver,
        address _ethReceiver,
        address _primeReceiver,
        address _verifier
    ) public onlyMinter {
        require(
            _nftReceiver != address(0),
            "ERC1155Invoke: _nftReceiver cannot be 0 address"
        );
        require(
            _ethReceiver != address(0),
            "ERC1155Invoke: _ethReceiver cannot be 0 address"
        );
        require(
            _primeReceiver != address(0),
            "ERC1155Invoke: _primeReceiver cannot be 0 address"
        );
        require(
            _verifier != address(0),
            "ERC1155Invoke: _verifier cannot be 0 address"
        );

        RouterEndpoint memory receiverInfo;
        receiverInfo.nftReceiver = _nftReceiver;
        receiverInfo.ethReceiver = _ethReceiver;
        receiverInfo.primeReceiver = _primeReceiver;
        receiverInfo.verifier = _verifier;

        // Effect
        routerEndpoints[_id] = receiverInfo;
    }
}