// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Payload is Ownable {
    error ContractDisabled();
    error InvalidSig();
    error InvalidNonce();
    error InvalidCaller();
    error InvalidOperator();
    error NullOperatorSet();
    error InvalidPayment();
    error InvalidTimestamp();
    error InvalidCardCount();
    error ParamLengthMissMatch();

    using SafeERC20 for IERC20;

    IERC20 public prime = IERC20(0xb23d80f5FefcDDaa212212F028021B41DEd428CF);
    IERC1155 public parallelAlpha =
        IERC1155(0x76BE3b62873462d2142405439777e971754E8E77);
    address public pullParallelAlphaFromAddress;
    address public trustedSigner;
    address public cardCountOperator;
    uint256 public cardPrice = 1.5 ether;
    uint256 public totalCardCount = 0;
    uint256 public signatureWindow = 180; // 3 mins
    uint256 public maxCardsPerTrx = 999;
    bool public disabled = false;

    mapping(address => uint256) public nonces;
    mapping(address => uint256) public redeemableCardCount;

    event PrimePayment(
        address indexed paymentAddress,
        uint256 indexed id,
        uint256 cardCount,
        uint256 timestamp,
        uint256 primeAmount,
        uint256 totalCardCount
    );
    event CardsClaimed(
        address indexed paymentAddress,
        uint256[] cardIds,
        uint256[] cardQuantities,
        uint256 nonce,
        uint256 timestamp,
        bytes signature
    );
    event SetCardPrice(uint256 indexed price);
    event SetPaymentDisabled(bool indexed val);
    event SetTrustedSigner(address indexed trustedSigner);
    event SetParallelAlphaContract(address indexed parallelAlpha);
    event SetPullFromAddress(address indexed pullFromAddress);
    event SetCardCountOperatorAddress(address indexed cardCountOperatorAddress);
    event SetPrimeAddress(address indexed primeAddress);
    event SetSignatureWindow(uint256 indexed signatureWindow);
    event SetRedeemableCardCount(address indexed account, uint256 indexed cardCount);

    constructor () Ownable() {
        cardCountOperator = msg.sender;
    }

    modifier onlyCardCountOperator() {
        if (msg.sender != cardCountOperator) {
            revert InvalidOperator();
        }
        _;
    }

    /**
     * @notice Function invoked by the prime token contract to handle totalCardCount increase and emit payment event
     * @param _from The address of the original msg.sender
     * @param _id An id passed by the caller to represent any arbitrary and potentially off-chain event id
     * @param _primeValue The amount of prime that was sent from the prime token contract
     * @param _data Catch-all param to allow the caller to pass additional data to the handler, includes the amount of cards they want to purchase
     */
    function handleInvokeEchelon(
        address _from,
        address,
        address,
        uint256 _id,
        uint256,
        uint256 _primeValue,
        bytes memory _data
    ) public payable {
        if (disabled) {
            revert ContractDisabled();
        }
        if (msg.sender != address(prime)) {
            revert InvalidCaller();
        }
        uint256 cardCount = abi.decode(_data, (uint256));
        if (cardPrice * cardCount != _primeValue) {
            revert InvalidPayment();
        }
        if (cardCount > maxCardsPerTrx) {
            revert InvalidCardCount();
        }
        totalCardCount += cardCount;
        redeemableCardCount[_from] += cardCount;
        emit PrimePayment(
            _from,
            _id,
            cardCount,
            block.timestamp,
            _primeValue,
            totalCardCount
        );
    }

    /**
     * @notice Used for redeeming all cards within the given signature.
     * @param _cardIds An array of ERC1155 token ids to be redeemed
     * @param _cardQuantities The amount of cards to redeem in _cardIds
     * @param _timestamp The timestamp at which _signature was created. After a certain window, the _cardIds in the _signature can no longer be redeemed
     * @param _signature Signature from the trustedSigner used for redeeming cards
     */
    function redeem(
        uint256[] calldata _cardIds,
        uint256[] calldata _cardQuantities,
        uint256 _nonceId,
        uint256 _timestamp,
        bytes memory _signature
    ) external {
        if (disabled) {
            revert ContractDisabled();
        }
        if (_nonceId - nonces[msg.sender] != 1) {
            revert InvalidNonce();
        }
        if (block.timestamp > _timestamp + signatureWindow) {
            revert InvalidTimestamp();
        }
        if (
            !verify(
                trustedSigner,
                msg.sender,
                _cardIds,
                _cardQuantities,
                _nonceId,
                _timestamp,
                block.chainid,
                _signature
            )
        ) {
            revert InvalidSig();
        }

        nonces[msg.sender] = _nonceId;
        uint256 addressCardCount;
        for (uint256 i = 0; i < _cardQuantities.length; i++) {
            addressCardCount += _cardQuantities[i];
        }
        if (addressCardCount > redeemableCardCount[msg.sender]) {
            revert InvalidCardCount();
        }
        unchecked {
            redeemableCardCount[msg.sender] -= addressCardCount;
        }

        parallelAlpha.safeBatchTransferFrom(
            pullParallelAlphaFromAddress,
            msg.sender,
            _cardIds,
            _cardQuantities,
            bytes("")
        );
        emit CardsClaimed(
            msg.sender,
            _cardIds,
            _cardQuantities,
            _nonceId,
            _timestamp,
            _signature
        );
    }

    /** @notice Sweep Transfer ERC20 tokens out of contract. Only owner.
     *  @param _token Token to transfer out
     *  @param _to Address to sweep to
     *  @param _amount Amount to sweep
     */
    function sweepERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _token.transfer(_to, _amount);
    }

    /** @notice Set the cardPrice variable
     *  @param _val Card price
     */
    function setCardPrice(uint256 _val) external onlyOwner {
        cardPrice = _val;
        emit SetCardPrice(_val);
    }

    /** @notice Set payment disabled to true/false
     *  @param _val Disabled state
     */
    function setPaymentDisabled(bool _val) external onlyOwner {
        disabled = _val;
        emit SetPaymentDisabled(_val);
    }

    /** @notice Set the address of the trusted signer for signatures
     *  @param _address Trusted signer address
     */
    function setTrustedSigner(address _address) external onlyOwner {
        trustedSigner = _address;
        emit SetTrustedSigner(_address);
    }

    /** @notice Set the address of the Parallel Alpha contract
     *  @param _parallelAlpha Parallel Alpha contract address
     */
    function setParallelAlphaContractAddress(IERC1155 _parallelAlpha)
        external
        onlyOwner
    {
        parallelAlpha = _parallelAlpha;
        emit SetParallelAlphaContract(address(_parallelAlpha));
    }

    /** @notice Set the address to pull Parallel Alpha card from
     *  @param _pullParallelAlphaFromAddress Pull from address
     */
    function setPullFromAddress(address _pullParallelAlphaFromAddress)
        external
        onlyOwner
    {
        pullParallelAlphaFromAddress = _pullParallelAlphaFromAddress;
        emit SetPullFromAddress(address(_pullParallelAlphaFromAddress));
    }

    /** @notice Set the address to set card counts
     *  @param _cardCountOperator card operator address
     */
    function setCardCountOperatorAddress(address _cardCountOperator)
        external
        onlyOwner
    {
        if (cardCountOperator == address(0)) {
            revert NullOperatorSet();
        }

        cardCountOperator = _cardCountOperator;
        emit SetCardCountOperatorAddress(address(_cardCountOperator));
    }

    /** @notice Set the prime token address
     *  @param _prime prime token address
     */
    function setPrimeAddress(IERC20 _prime) external onlyOwner {
        prime = _prime;
        emit SetPrimeAddress(address(_prime));
    }

    /** @notice Set the window in which users can redeem their cards
     *  @param _signatureWindow Window in seconds
     */
    function setSignatureWindow(uint256 _signatureWindow) external onlyOwner {
        signatureWindow = _signatureWindow;
        emit SetSignatureWindow(_signatureWindow);
    }

    /** @notice Set new limit on how many cards a user can purchase at once
     *  @param _maxCardsPerTrx New max cards limit
     */
    function setMaxCardsPerTrx(uint256 _maxCardsPerTrx) external onlyOwner {
        maxCardsPerTrx = _maxCardsPerTrx;
    }

    /** @notice Sets list of card counts for list of accounts.
     *  @param _accounts List of accounts to set
     *  @param _counts List of counts to set
     */
    function setRedeemableCardCount(
        address[] calldata _accounts,
        uint256[] calldata _counts
    ) external onlyCardCountOperator {
        if (_accounts.length != _counts.length) {
            revert ParamLengthMissMatch();
        }

        for (uint256 i = 0; i < _accounts.length; i++) {
            redeemableCardCount[_accounts[i]] = _counts[i];
            emit SetRedeemableCardCount(_accounts[i], _counts[i]);
        }
    }

    /** @notice Verify signature is valid
     *  @param _signer Trusted signer
     *  @param _to Address that receives the redeemed cards
     *  @param _cardIds An array of ERC1155 token ids to be redeemed
     *  @param _cardQuantities The amount of cards to redeem in _cardIds
     *  @param _timestamp The timestamp at which _signature was created. After a certain window, the _cardIds in the _signature can no longer be redeemed
     *  @param _signature Signature from the trustedSigner used for redeeming cards
     */
    function verify(
        address _signer,
        address _to,
        uint256[] calldata _cardIds,
        uint256[] calldata _cardQuantities,
        uint256 _nonceId,
        uint256 _timestamp,
        uint256 _chainid,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                _to,
                _cardIds,
                _cardQuantities,
                _nonceId,
                _timestamp,
                _chainid
            )
        );
        bytes32 signableMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        return ECDSA.recover(signableMessageHash, _signature) == _signer;
    }
}