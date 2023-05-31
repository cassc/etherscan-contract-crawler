// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRainCollateral.sol";

/**
 *  @title RainCollateralController contract
 *  @notice Used to manage RainCollateral contracts.
 *          Most operational logics are implemented here
 *          while RainCollateral is mainly used to keep collateral.
 *          This contract will be owned by Rain company.
 */
contract RainCollateralController is Ownable {
    /// @notice Elliptic Curve Digital Signature Algorithm Used to validate signature
    using ECDSA for bytes32;

    // Struct of required fields for EIP-712 domain separator
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
    }

    // Struct of required fields for Pay signature
    struct Pay {
        address user;
        address collateral;
        address[] assets;
        uint256[] amounts;
        uint256 nonce;
        uint256 expiresAt;
    }

    // Struct of required fields for Withdraw signature
    struct Withdraw {
        address user;
        address collateral;
        address asset;
        uint256 amount;
        address recipient;
        uint256 nonce;
        uint256 expiresAt;
    }

    // User readable name of signing domain
    string public constant EIP712_DOMAIN_NAME = "Rain Collateral";

    // Current major version of signing domain
    string public constant EIP712_DOMAIN_VERSION = "1";

    // Type hash to check EIP712 domain separator validity in signature
    bytes32 public constant EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    // Type hash to check pay signature validity
    bytes32 public constant PAY_TYPE_HASH =
        keccak256(
            "Pay(address user,address collateral,address[] assets,uint[] amounts,uint nonce,uint expiresAt)"
        );

    // Type hash to check withdraw signature validity
    bytes32 public constant WITHDRAW_TYPE_HASH =
        keccak256(
            "Withdraw(address user,address collateral,address asset,uint amount,address recipient,uint nonce,uint expiresAt)"
        );

    /// @notice Address that runs admin functions.
    ///         Signature should be created by this address.
    address public controllerAdmin;

    /// @notice Treasury contract address where Rain Company keeps its treasury.
    ///         Payment and liqudation moves assets to treasury.
    address public treasury;

    /// @notice A counter to prevent duplicate transaction with same signature
    /// @dev using single nonce for all type of transactions
    ///      to ensure their order.
    /// key: address of RainCollateral
    /// value: counter of past transactions
    mapping(address => uint256) public nonce;

    /**
     * @notice Emitted when withdrawAsset is called
     * @param _collateralProxy RainCollateral proxy contract address
     * @param _asset Asset contract address
     * @param _amount Amount of assets withdrawn
     */
    event Withdrawal(
        address indexed _collateralProxy,
        address _asset,
        uint256 _amount
    );

    /**
     * @notice Emitted when makePayment is called
     * @param _collateralProxy RainCollateral proxy contract address
     * @param _assets Array of asset contract addresses paid from.
     *                Must be the same length with _amounts.
     * @param _amounts Array of amount of assets paid.
     *                 Must be the same length with _assets.
     */
    event Payment(
        address indexed _collateralProxy,
        address[] _assets,
        uint256[] _amounts
    );

    /**
     * @notice Emitted when liquidateAsset is called
     * @param _collateralProxy RainCollateral proxy contract address
     * @param _assets Array of asset contract addresses liquidated from.
     *                Must be the same length with _amounts.
     * @param _amounts Array of amount of assets liquidated.
     *                 Must be the same length with _assets.
     */
    event Liquidation(
        address indexed _collateralProxy,
        address[] _assets,
        uint256[] _amounts
    );

    /**
     * @notice Used to authorize only RainCollateral admin
     * @dev Throws if called by any account other than RainCollateral admin.
     */
    modifier isCollateralAdmin(address _collateralProxy) {
        require(
            IRainCollateral(_collateralProxy).isAdmin(address(msg.sender)),
            "Unauthorized"
        );
        _;
    }

    /**
     * @notice Check if the signature is expired
     * @param _expiresAt timestamp when the signature expires
     */
    modifier activeSignature(uint256 _expiresAt) {
        // _expiresAt will be within 30 minutes to an hour since the signature was issued.
        require(block.timestamp < _expiresAt, "Expired signature");
        _;
    }

    /**
     * @notice Used to initialize
     * @dev Called only once and sets admin and treasury addresses
     * @param _controllerAdmin controller admin address to operate collateralProxies
     * @param _treasury Rain Company's treasury contract address
     */
    constructor(address _controllerAdmin, address _treasury) {
        controllerAdmin = _controllerAdmin;
        treasury = _treasury;
    }

    /**
     * @notice Used to withdraw assets owned by RainCollateral contract
     * @dev Checks {isCollateralAdmin} first
     * @param _collateralProxy targeting RainCollateral proxy address
     * @param _asset asset's contract address
     * @param _amount amount to withdraw
     * @param _recipient address to receive assets
     * @param _expiresAt timestamp when signature expires, in unix seconds
     * @param _salt disambiguating salt for signature
     * @param _signature controllerAdmin's signature for this action (generated by ECDSA)
     * NOTE: `_asset` can be only ERC20 token. ETHER is not supported in V1.
     *       see {ERC20-allowance} and {ERC20-transferFrom}
     *       see {_verifyWithdrawalSignature} function
     * Requirements:
     * - `_expiresAt` should be less than block timestamp.
     * - `_signature` should be valid.
     * - RainCollateral must have balance of asset >= `_amount`.
     */
    function withdrawAsset(
        address _collateralProxy,
        address _asset,
        uint256 _amount,
        address _recipient,
        uint256 _expiresAt,
        bytes32 _salt,
        bytes memory _signature
    ) external isCollateralAdmin(_collateralProxy) activeSignature(_expiresAt) {
        bytes32 messageHash = _hash(
            Withdraw({
                user: msg.sender,
                collateral: _collateralProxy,
                asset: _asset,
                amount: _amount,
                recipient: _recipient,
                nonce: nonce[_collateralProxy],
                expiresAt: _expiresAt
            })
        );
        _verifySignature(_collateralProxy, messageHash, _salt, _signature);

        IRainCollateral(_collateralProxy).withdrawAsset(
            _asset,
            _recipient,
            _amount
        );

        emit Withdrawal(_collateralProxy, _asset, _amount);
    }

    /**
     * @notice Used to make payment with  collateral assets owned by RainCollateral contract
     * @dev Use {_verifyPaymentSignature} to verify signature
     * @param _collateralProxy targeting RainCollateral proxy address
     * @param _assets array of asset's contract addresses
     * @param _amounts array of amounts corresponding to _assets
     * @param _expiresAt timestamp when signature expires as unix seconds
     * @param _salt disambiguating salt for signature
     * @param _signature controllerAdmin's signature for this action (generated by ECDSA)
     * Requirements:
     *
     * - `_expiresAt` should be less than block timestamp.
     * - `_signature` should be valid .
     */
    function makePayment(
        address _collateralProxy,
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256 _expiresAt,
        bytes32 _salt,
        bytes memory _signature
    ) external activeSignature(_expiresAt) {
        require(_assets.length == _amounts.length, "Invalid Params");

        bytes32 messageHash = _hash(
            Pay({
                user: msg.sender,
                collateral: _collateralProxy,
                assets: _assets,
                amounts: _amounts,
                nonce: nonce[_collateralProxy],
                expiresAt: _expiresAt
            })
        );
        _verifySignature(_collateralProxy, messageHash, _salt, _signature);

        for (uint256 i = 0; i < _assets.length; i++) {
            _transferToTreasury(_collateralProxy, _assets[i], _amounts[i]);
        }

        emit Payment(_collateralProxy, _assets, _amounts);
    }

    /**
     * @notice Used to transfer an amount of asset from RainCollateral contract to treasury contract
     * @param _collateralProxy targeting RainCollateral proxy address
     * @param _asset asset's contract address
     * @param _amount asset amount to transfer
     */

    function _transferToTreasury(
        address _collateralProxy,
        address _asset,
        uint256 _amount
    ) internal {
        IRainCollateral(_collateralProxy).withdrawAsset(
            _asset,
            treasury,
            _amount
        );
    }

    /**
     * @notice Sub function of _verifyPaymentSignature and _verifyWithdrawal
     *         used to verify signature is from controller admin
     * @dev increment nonce when signature is valid
     * @param _collateralProxy targeting RainCollateral proxy address
     * @param _messageHash keccak256 hashed message
     * @param _salt disambiguating salt for signature
     * @param _signature signature generated by controllerAdmin
     */
    function _verifySignature(
        address _collateralProxy,
        bytes32 _messageHash,
        bytes32 _salt,
        bytes memory _signature
    ) internal {
        bytes32 domainSeparator = _hash(
            EIP712Domain({
                name: EIP712_DOMAIN_NAME,
                version: EIP712_DOMAIN_VERSION,
                chainId: block.chainid,
                verifyingContract: address(this),
                salt: _salt
            })
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, _messageHash)
        );

        // verify that the signature was generated by controllerAdmin
        require(
            digest.recover(_signature) == controllerAdmin,
            "Invalid signature"
        );

        // update nonce
        nonce[_collateralProxy] += 1;
    }

    /**
     * @notice Build hash of EIP712 domain separator
     * @return bytes32 hash value
     */
    function _hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPE_HASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract,
                    eip712Domain.salt
                )
            );
    }

    /**
     * @notice Build hash of withdraw signature fields
     * @return bytes32 hash value
     */
    function _hash(Withdraw memory withdraw) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        WITHDRAW_TYPE_HASH,
                        withdraw.user,
                        withdraw.collateral,
                        withdraw.asset,
                        withdraw.amount
                    ),
                    abi.encode(
                        withdraw.recipient,
                        withdraw.nonce,
                        withdraw.expiresAt
                    )
                )
            );
    }

    /**
     * @notice Build hash of pay signature fields
     * @return bytes32 hash value
     */
    function _hash(Pay memory pay) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        PAY_TYPE_HASH,
                        pay.user,
                        pay.collateral,
                        keccak256(abi.encodePacked(pay.assets)),
                        keccak256(abi.encodePacked(pay.amounts))
                    ),
                    abi.encode(pay.nonce, pay.expiresAt)
                )
            );
    }

    /**
     * @notice Used to liquidate assets owned by RainCollateral contract
     * @dev loop to the assets and transfer them to treasury
     * Requirements:
     * - only controllerAdmin can call this function.
     * @param _collateralProxy targeting RainCollateral contract address
     * @param _assets array of asset's contract addresses
     * @param _amounts array of amounts corresponding to _assets
     */
    function liquidateAsset(
        address _collateralProxy,
        address[] calldata _assets,
        uint256[] calldata _amounts
    ) external {
        require(msg.sender == controllerAdmin, "Not controller admin");
        require(_assets.length == _amounts.length, "Invalid Params");
        for (uint256 i = 0; i < _assets.length; i++) {
            _transferToTreasury(_collateralProxy, _assets[i], _amounts[i]);
        }

        emit Liquidation(_collateralProxy, _assets, _amounts);
    }

    /**
     * @notice Used to update controller admin address
     * @dev only owner can call this function
     * @param _controllerAdmin new controller admin address
     * Requirements:
     * - `_controllerAdmin` should not be NullAddress.
     */
    function updateControllerAdmin(address _controllerAdmin)
        external
        onlyOwner
    {
        require(_controllerAdmin != address(0), "Zero Address");
        controllerAdmin = _controllerAdmin;
    }

    /**
     * @notice Used to update treasury contract address
     * @dev only owner can call this function
     * @param _treasury new treasury contract address
     * Requirements:
     * - `_newAddress` should not be NullAddress.
     */
    function updateTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Zero Address");
        treasury = _treasury;
    }

    /**
     * @notice Increase nonce of a collateral proxy by onwer
     * @dev can be used to invalidate a signature
     */
    function increaseNonce(address _collateralProxy) external onlyOwner {
        nonce[_collateralProxy]++;
    }
}