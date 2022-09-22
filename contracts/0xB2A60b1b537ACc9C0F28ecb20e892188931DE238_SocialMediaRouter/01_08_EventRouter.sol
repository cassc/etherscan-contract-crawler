pragma solidity ^0.8.4;

import "./SocialMediaRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EventRouter is Ownable, ReentrancyGuard {
    SocialMediaRouter SOCIAL_MEDIA_ROUTER;
    uint256 public fee = 5; // percentage
    uint256 public erc20Fee = 5; // percentage
    uint256 public flatTokenFee = 0.0006 ether;
    bool public isFlatFeeActive = false;
    address payable public milianBank;

    constructor() {
        milianBank = payable(owner());
    }

    event Payment(uint256 indexed paymentId);

    event PendingPayment(
        address indexed sender,
        string serviceId,
        string userId,
        string ruleId
    );

    struct OwedPayment {
        address tokenAddress;
        uint256 amount;
        uint256 paymentId;
    }

    struct Pay {
        address tokenAddress;
        uint256 amount;
        address from;
        address to;
        string serviceId;
        string userId;
        string ruleId;
    }

    // pending payments
    mapping(string => mapping(string => mapping(address => uint256)))
        public owedAmounts;
    mapping(string => mapping(string => mapping(uint256 => OwedPayment)))
        public owedPayments;
    mapping(string => mapping(string => uint256)) public owedPaymentCounts;

    mapping(uint256 => Pay) public payments;
    uint256 public paymentCount = 0;

    /** @dev Withdrawls all tokens in a list for a specific user if the user exists.
     * @param tokenAddresses token addresses the user wishes to withdrawl.
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @notice This function does not withdrawl all pending tokens to ensure no errors occur running out of gas.
     * @notice address(0) represents ETH
     * @notice nonReentrant to prevent reentrancy attack once the tokens/ETH have been transfered
     */
    function withdrawlTokenList(
        address[] memory tokenAddresses,
        string memory serviceId,
        string memory userId
    ) public nonReentrant {
        address toAddress = SOCIAL_MEDIA_ROUTER.getAddress(serviceId, userId);
        require(toAddress != address(0), "User does not exist");
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            uint256 a = owedAmounts[serviceId][userId][tokenAddresses[i]];
            if (a > 0) {
                owedAmounts[serviceId][userId][tokenAddresses[i]] = 0;
                // if token address is ETH
                if (tokenAddresses[i] == address(0)) {
                    payable(toAddress).transfer(a);
                } else {
                    IERC20 token = IERC20(tokenAddresses[i]);
                    token.transfer(toAddress, a);
                }
            }
        }
    }

    /** @dev Creates a new Pay struct in the payments mapping and emits a payment event
     * @param tokenAddress token addresses the user wishes to withdrawl.
     * @param amount amount of the payment.
     * @param from address of whos sending the payment
     * @param to address of whos receiving the payment
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @param ruleId Id of the offchain rule corresponding to the payment.
     * @notice This is an internal function that creates a new payment, an on chain record for the off chain listeners to access
     */
    function createNewPayment(
        address tokenAddress,
        uint256 amount,
        address from,
        address to,
        string memory serviceId,
        string memory userId,
        string memory ruleId
    ) private {
        paymentCount = paymentCount + 1;
        payments[paymentCount] = Pay(
            tokenAddress,
            amount,
            from,
            to,
            serviceId,
            userId,
            ruleId
        );
        emit Payment(paymentCount);
    }

    /** @dev Creates a new Owed Payment struct in the payments mapping and emits a payment event
     * @param tokenAddress token addresses the user wishes to withdrawl.
     * @param amount amount of the payment.
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @notice This is an internal function that creates a new owed payment, an on chain record for the off chain listeners to access
     */

    function createOwedPayment(
        address tokenAddress,
        uint256 amount,
        string memory serviceId,
        string memory userId
    ) private {
        owedPaymentCounts[serviceId][userId] =
            owedPaymentCounts[serviceId][userId] +
            1;
        owedPayments[serviceId][userId][
            owedPaymentCounts[serviceId][userId]
        ] = OwedPayment({
            tokenAddress: tokenAddress,
            amount: amount,
            paymentId: paymentCount
        });
        owedAmounts[serviceId][userId][tokenAddress] =
            owedAmounts[serviceId][userId][tokenAddress] +
            amount;
    }

    /** @dev Pays ETH regarding a specific ruleId
     * @param toAddress address of receiver.
     * @param ruleId Id of the off chain rule
     * @notice Public function allowing users to pay ETH
     */
    function payEth(address toAddress, string memory ruleId) public payable {
        uint256 ownerCut = (fee * msg.value) / 100;
        payable(toAddress).transfer(msg.value - ownerCut);
        milianBank.transfer(ownerCut);
        createNewPayment(
            address(0),
            msg.value,
            msg.sender,
            toAddress,
            "",
            "",
            ruleId
        );
    }

    /** @dev pays ETH through service
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @param ruleId Id of the off chain rule for offchain listeners to process
     * @notice This function allows one to pay users through accounts on other platforms
     * @notice If the receiving user has not yet added their account to the Social media router, the funds will be saved for them until they do
     */
    function payEthThroughService(
        string calldata serviceId,
        string calldata userId,
        string memory ruleId
    ) public payable nonReentrant {
        address toAddress = SOCIAL_MEDIA_ROUTER.getAddress(serviceId, userId);
        uint256 ownerCut = (fee * msg.value) / 100;
        milianBank.transfer(ownerCut);
        // social media router found a match
        if (toAddress != address(0)) {
            payable(toAddress).transfer(msg.value - ownerCut);
            createNewPayment(
                address(0),
                msg.value,
                msg.sender,
                toAddress,
                serviceId,
                userId,
                ruleId
            );
        } else {
            createNewPayment(
                address(0),
                msg.value,
                msg.sender,
                toAddress,
                serviceId,
                userId,
                ruleId
            );
            createOwedPayment(
                address(0),
                msg.value - ownerCut,
                serviceId,
                userId
            );
        }
    }

    /** @dev pays ERC20
     * @param tokenAddress Address of the ERC20 token.
     * @param amount Amount of the ERC20 token.
     * @param toAddress Address whos receiving the funds
     * @param ruleId Id of the off chain rule for offchain listeners to process
     * @notice This function allows one to pay users through accounts on other platforms
     * @notice If the receiving user has not yet added their account to the Social media router, the funds will be saved for them until they do
     */
    function payERC20(
        address tokenAddress,
        uint256 amount,
        address toAddress,
        string memory ruleId
    ) public payable nonReentrant {
        require(
            tokenAddress != address(0),
            "Token address cannot be zero address"
        );
        require(amount > 0, "Amount is zero");

        IERC20 token = IERC20(tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Allowance is too low");

        if (isFlatFeeActive) {
            require(msg.value >= flatTokenFee, "Flat fee not met");
            milianBank.transfer(msg.value);
        }

        uint256 ownerCut = (erc20Fee * amount) / 100;
        if (ownerCut > 0) {
            token.transferFrom(msg.sender, milianBank, ownerCut);
        }
        token.transferFrom(msg.sender, toAddress, amount - ownerCut);

        createNewPayment(
            tokenAddress,
            msg.value,
            msg.sender,
            toAddress,
            "",
            "",
            ruleId
        );
    }

    /** @dev pays ERC20 through service
     * @param tokenAddress Address of the ERC20 token.
     * @param amount Amount of the ERC20 token.
     * @param serviceId Id of the service the token was sent through (ex. twitter).
     * @param userId Id of the user the token was sent to through the service (ex. abc123)
     * @param ruleId Id of the off chain rule for offchain listeners to process
     * @notice This function allows one to pay users through accounts on other platforms
     * @notice If the receiving user has not yet added their account to the Social media router, the funds will be saved for them until they do
     */
    function payERC20ThroughService(
        address tokenAddress,
        uint256 amount,
        string calldata serviceId,
        string calldata userId,
        string memory ruleId
    ) public payable nonReentrant {
        require(amount > 0, "Amount is zero");

        IERC20 token = IERC20(tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Allowance is too low");

        if (isFlatFeeActive) {
            require(msg.value >= flatTokenFee, "Flat fee not met");
            milianBank.transfer(msg.value);
        }

        uint256 ownerCut = (erc20Fee * amount) / 100;
        if (ownerCut > 0) {
            token.transferFrom(msg.sender, milianBank, ownerCut);
        }

        address toAddress = SOCIAL_MEDIA_ROUTER.getAddress(serviceId, userId);

        // social media router found a match
        if (toAddress != address(0)) {
            token.transferFrom(msg.sender, toAddress, amount - ownerCut);
            createNewPayment(
                tokenAddress,
                amount,
                msg.sender,
                toAddress,
                serviceId,
                userId,
                ruleId
            );
        } else {
            token.transferFrom(msg.sender, address(this), amount - ownerCut);
            createNewPayment(
                tokenAddress,
                amount,
                msg.sender,
                toAddress,
                serviceId,
                userId,
                ruleId
            );
            createOwedPayment(
                tokenAddress,
                amount - ownerCut,
                serviceId,
                userId
            );
        }
    }

    /** @dev Adds account to social media router and withdrawls tokens
     * @param signature Signature from bond signer
     * @param accountAddress Address to route payments to
     * @param serviceId Id of the service to link (ex. twitter).
     * @param userId Id of the user to link (ex. abc123)
     * @param nonce nonce to ensure past signatures cannot be used
     * @notice This function allows one to pay users through accounts on other platforms
     * @notice If the receiving user has not yet added their account to the Social media router, the funds will be saved for them until they do
     */
    function addAccountAndWithdrawl(
        bytes memory signature,
        address accountAddress,
        string memory serviceId,
        string memory userId,
        uint256 nonce,
        address[] memory tokenAddresses
    ) public {
        // non reentrant?
        SOCIAL_MEDIA_ROUTER.addAccount(
            signature,
            accountAddress,
            serviceId,
            userId,
            nonce
        );
        withdrawlTokenList(tokenAddresses, serviceId, userId);
    }

    function setSMR(address _a) public onlyOwner {
        SOCIAL_MEDIA_ROUTER = SocialMediaRouter(_a);
    }

    function setFee(uint256 _f) public onlyOwner {
        require(_f <= 100, "Fee is not valid");
        fee = _f;
    }

    function setErc20Fee(uint256 _f) public onlyOwner {
        require(_f <= 100, "ERC20 Fee is not valid");
        erc20Fee = _f;
    }

    function setFlatTokenFee(uint256 _f) public onlyOwner {
        flatTokenFee = _f;
    }

    function setIsFlatFeeActive(bool _a) public onlyOwner {
        isFlatFeeActive = _a;
    }

    function setBank(address payable _bank) public onlyOwner {
        milianBank = _bank;
    }
}