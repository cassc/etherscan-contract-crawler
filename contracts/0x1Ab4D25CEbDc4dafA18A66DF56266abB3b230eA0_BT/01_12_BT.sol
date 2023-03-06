// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IPair.sol";

contract BT is Ownable {
    using SafeERC20 for IERC20;

    struct NFTinfo {
        address nftAddress;
        uint256[] ids;
    }

    struct TestamentTokens {
        IERC20[] erc20Tokens;
        NFTinfo[] erc721Tokens;
        NFTinfo[] erc1155Tokens;
    }

    struct Successors {
        address nft721successor; // nft721 tokens receiver
        address nft1155successor; // nft1155 tokens receiver
        address[] erc20successors; // array of erc20 tokens receivers
        uint256[] erc20shares; //array of erc20 tokens shares corresponding to erc20successors
    }

    struct Subscription {
        bool active;
        uint256 priceInQuoteToken;
        address paymentToken;
        address exchangePair;
        uint256 erc20SuccessorsLimit;
    }

    struct DeathConfirmation {
        uint256 confirmed;
        uint256 quorum;
        uint256 confirmationTime;
        address[] validators;
    }

    struct Testament {
        uint256 subscriptionID;
        uint256 expirationTime;
        Successors successors;
        DeathConfirmation voting;
    }

    enum DeathConfirmationState {
        NotExist,
        StillAlive,
        TestamentCanceled,
        Active,
        ConfirmationWaiting,
        Confirmed
    }

    uint256 public constant CONFIRMATION_LOCK = 180 days;
    uint256 public constant CONFIRMATION_PERIOD = 360 days;
    uint256 public constant BASE_POINT = 10000;
    uint256 public constant MAX_VALIDATORS = 30;
    uint256 public constant DISCOUNT_BP = 5000; // 50%
    uint256 public constant FREEMIUM_ID = 0;
    uint256 public constant FREEMIUM_FEE_BP = 300; // 3%

    address public feeAddress;
    address public immutable quoteTokenAddress;
    mapping(address => Testament) public testaments;
    mapping(address => bool) public firstPayment;

    // testamentOwner  => token   =>  amountPerShare
    mapping(address => mapping(address => uint256)) private amountsPerShare;
    // testamentOwner   =>  successor   =>  token  => already withdrawn
    mapping(address => mapping(address => mapping(address => bool)))
        private alreadyWithdrawn;

    Subscription[] public subscriptions;

    modifier validSubscriptionID(uint256 _sid) {
        require(
            _sid < subscriptions.length && subscriptions[_sid].active,
            "subscription is not valid"
        );
        _;
    }

    modifier correctStatus(
        DeathConfirmationState _state,
        address _testamentOwner,
        string memory _error
    ) {
        require(getDeathConfirmationState(_testamentOwner) == _state, _error);
        _;
    }

    event SubscriptionsAdded(Subscription _subscription);
    event SubscriptionStateChanged(uint256 subscriptionID, bool active);
    event TestamentDeleted(address testamentOwner);
    event SuccessorsChanged(address testamentOwner, Successors newSuccessors);
    event ValidatorsChanged(
        address user,
        uint256 newVoteQuorum,
        address[] newValidators
    );

    event CreateTestament(
        address user,
        uint256 priceInPaymentToken,
        Testament newTestament
    );
    event UpgradeTestamentPlan(
        address user,
        uint256 newSubscriptionId,
        uint256 expirationTime,
        uint256 priceInPaymentToken
    );

    event BillPayment(
        address testamentOwner,
        uint256 amountInPaymentToken,
        uint256 newexpirationTime
    );

    event DeathConfirmed(address testamentOwner, uint256 deathConfirmationTime);

    event GetTestament(address testamentOwner, address successor);

    constructor(address _feeAddress, address _quoteTokenAddress) {
        feeAddress = _feeAddress;
        quoteTokenAddress = _quoteTokenAddress;
        // FREEMIUM
        subscriptions.push(
            Subscription(
                true, // active
                0, 
                address(0), 
                address(0), 
                1 // erc20SuccessorsLimit
            )
        ); 
    }

    /**
     * @param _feeAddress: new feeAddress
     */
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    /**
     * @notice add new payment plan
     * @param _subscription: {bool active;uint256 priceInQuoteToken;address paymentToken;address exchangePair;uint256 erc20SuccessorsLimit;}
     */
    function addSubscription(
        Subscription calldata _subscription
    ) external onlyOwner {
        require(
            _subscription.paymentToken !=address(0) 
            || _subscription.priceInQuoteToken == 0, 
            "paymentToken cannot be zero address"
        );
        if (_subscription.exchangePair != address(0)) {
            require(
                _subscription.priceInQuoteToken > 0,
                "priceInQuoteToken cannot be zero"
            );
            //not free
            IPair pair = IPair(_subscription.exchangePair);
            address token0 = pair.token0();
            address token1 = pair.token1();
            require(
                (token0 == quoteTokenAddress &&
                    token1 == _subscription.paymentToken) ||
                    (token0 == _subscription.paymentToken &&
                        token1 == quoteTokenAddress),
                "bad exchangePair address"
            );
        }
        subscriptions.push(_subscription);
        emit SubscriptionsAdded(_subscription);
    }

    /**
     * @notice activate-deactivate a subscription
     */
    function subscriptionStateChange(
        uint256 _sId,
        bool _active
    ) external onlyOwner {
        subscriptions[_sId].active = _active;
        emit SubscriptionStateChanged(_sId, _active);
    }

    function getPriceInPaymentToken(
        address _pair,
        uint256 _priceInQuoteToken
    ) public view returns (uint256) {
        if (_priceInQuoteToken > 0) {
            if (_pair == address(0)) {
                return (_priceInQuoteToken);
            }
            IPair pair = IPair(_pair);
            (uint112 reserves0, uint112 reserves1, ) = pair.getReserves();
            (uint112 reserveQuote, uint112 reserveBase) = pair.token0() ==
                quoteTokenAddress
                ? (reserves0, reserves1)
                : (reserves1, reserves0);

            if (reserveQuote > 0 && reserveBase > 0) {
                return (_priceInQuoteToken * reserveBase) / reserveQuote + 1;
            } else {
                revert("can't determine price");
            }
        } else {
            return 0;
        }
    }

    function checkSharesSUM(uint256[] memory _erc20shares) private pure {
        uint256 sharesSum;
        for (uint256 i = 0; i < _erc20shares.length; i++) {
            sharesSum += _erc20shares[i];
        }
        require(sharesSum == BASE_POINT, "incorrect shares sum");
    }

    /**
     * @notice assignment of successors
     */
    function setSuccessors(
        Successors calldata _newSuccessors
    )
        external
        correctStatus(
            DeathConfirmationState.StillAlive,
            msg.sender,
            "first confirm that you are still alive"
        )
    {
        Testament storage userTestament = testaments[msg.sender];
        Subscription memory userPaymentPlan = subscriptions[
            userTestament.subscriptionID
        ];
        require(
            _newSuccessors.erc20shares.length ==
                _newSuccessors.erc20successors.length,
            "erc20 successors and shares must be the same length"
        );
        require(
            userPaymentPlan.erc20SuccessorsLimit == 0 ||
                userPaymentPlan.erc20SuccessorsLimit >=
                _newSuccessors.erc20successors.length,
            "erc20 successors limit exceeded"
        );

        checkSharesSUM(_newSuccessors.erc20shares);

        userTestament.successors = _newSuccessors;

        emit SuccessorsChanged(msg.sender, _newSuccessors);
    }

    /**
     * @notice check validator's and quorum
     */
    function checkVoteParam(uint256 _quorum,uint256 _validatorsLength) private pure{
        require(_quorum >0 , "_quorum value must be greater than null");
        require(_validatorsLength <= MAX_VALIDATORS, "too many validators");
        require(_validatorsLength >= _quorum, "_quorum should be equal to number of validators");
    }

    /**
     * @notice the weight of the validator's vote in case of repetition of the address in _validators increases
     */
    function setValidators(
        uint256 _quorum,
        address[] calldata _validators
    )
        external 
        correctStatus(
            DeathConfirmationState.StillAlive,
            msg.sender,
            "first confirm that you are still alive"
        )
    {
        checkVoteParam(_quorum,_validators.length);

        Testament storage userTestament = testaments[msg.sender];
        // reset current voting state
        userTestament.voting.confirmed = 0;
        userTestament.voting.validators = _validators;
        userTestament.voting.quorum = _quorum;
        emit ValidatorsChanged(msg.sender, _quorum, _validators);
    }

    function deleteTestament() external {
        require(
            getDeathConfirmationState(msg.sender) <
                DeathConfirmationState.Confirmed,
            "alive only"
        );
        delete testaments[msg.sender];
        emit TestamentDeleted(msg.sender);
    }

    /**
     * @notice create testament 
     * @param _subscriptionId: ID of payment plan
     * @param _quorum: voting quorum
     * @param _validators: array of validators
     * @param _successors: array of successors
     */
    function createTestament(
        uint256 _subscriptionId,
        uint256 _quorum,
        address[] calldata _validators,
        Successors calldata _successors
    )
        external 
        correctStatus(
            DeathConfirmationState.NotExist,
            msg.sender,
            "already exist"
        )
        validSubscriptionID(_subscriptionId)
    {
        
        Subscription memory paymentPlan = subscriptions[_subscriptionId];

        require(
            _successors.erc20shares.length ==
                _successors.erc20successors.length,
            "erc20 successors and shares must be the same length"
        );
        require(
            paymentPlan.erc20SuccessorsLimit == 0 ||
                paymentPlan.erc20SuccessorsLimit >=
                _successors.erc20successors.length,
            "erc20 successors limit exceeded"
        );

        checkVoteParam(_quorum,_validators.length);
        checkSharesSUM(_successors.erc20shares);

        uint256 priceInPaymentToken = getPriceInPaymentToken(
                    paymentPlan.exchangePair,
                    paymentPlan.priceInQuoteToken
                );

        if (priceInPaymentToken > 0) {
            IERC20(paymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                priceInPaymentToken
            );
            // subscription is not free
            firstPayment[msg.sender]=true;
        }

        Testament memory newTestament = Testament(
            _subscriptionId,
            block.timestamp + CONFIRMATION_PERIOD,
            _successors,
            DeathConfirmation(0, _quorum, 0, _validators)
        );

        testaments[msg.sender] = newTestament;

        emit CreateTestament(msg.sender, priceInPaymentToken, newTestament);
    }

    function upgradeTestamentPlan(
        uint256 _subscriptionId
    )
        external
        correctStatus(
            DeathConfirmationState.StillAlive,
            msg.sender,
            "first confirm that you are still alive"
        )
        validSubscriptionID(_subscriptionId)
    {
        Testament memory userTestament = testaments[msg.sender];

        require(
            userTestament.subscriptionID != _subscriptionId,
            "already done"
        );
        Subscription memory paymentPlan = subscriptions[_subscriptionId];

        require(
            paymentPlan.erc20SuccessorsLimit == 0 ||
                paymentPlan.erc20SuccessorsLimit >=
                userTestament.successors.erc20successors.length,
            "the number of successors exceeds the limit for this subscription"
        );

        userTestament.expirationTime = block.timestamp + CONFIRMATION_PERIOD;
        
        bool _firstPayment=firstPayment[msg.sender];
        uint256 priceInPaymentToken = getPriceInPaymentToken(
                    paymentPlan.exchangePair,
                    (_firstPayment ? 
                    paymentPlan.priceInQuoteToken * DISCOUNT_BP / BASE_POINT 
                    : 
                    paymentPlan.priceInQuoteToken)
                );
        

        if (priceInPaymentToken > 0) {
            IERC20(paymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                priceInPaymentToken
            );

            if(!_firstPayment){
                firstPayment[msg.sender]=true;
            }
        }
        userTestament.subscriptionID = _subscriptionId;
        testaments[msg.sender] = userTestament;

        emit UpgradeTestamentPlan(
            msg.sender,
            _subscriptionId,
            userTestament.expirationTime,
            priceInPaymentToken
        );
    }

    /**
     * @notice confirm that you are still alive
     */
    function billPayment() external {
        DeathConfirmationState currentState = getDeathConfirmationState(
            msg.sender
        );
        require(
            currentState == DeathConfirmationState.StillAlive ||
                currentState == DeathConfirmationState.Active,
            "state should be StillAlive or Active or you can try to delete the testament while it not Confirmed"
        );
        Testament memory userTestament = testaments[msg.sender];
        Subscription memory userpaymentPlan = subscriptions[
            userTestament.subscriptionID
        ];

        require(
            block.timestamp >
                (userTestament.expirationTime - CONFIRMATION_PERIOD),
            "no more than two periods"
        );
        userTestament.voting.confirmed = 0;
        userTestament.expirationTime += CONFIRMATION_PERIOD;

        uint256 amountInPaymentToken = getPriceInPaymentToken(
                    userpaymentPlan.exchangePair,
                    userpaymentPlan.priceInQuoteToken * DISCOUNT_BP / BASE_POINT
                );
        if (amountInPaymentToken > 0) {
            IERC20(userpaymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                amountInPaymentToken
            );
        }

        testaments[msg.sender] = userTestament;

        emit BillPayment(
            msg.sender,
            amountInPaymentToken,
            userTestament.expirationTime
        );
    }

    function _getVotersCount(
        uint256 confirmed
    ) private pure returns (uint256 voiceCount) {
        while (confirmed > 0) {
            voiceCount += confirmed & 1;
            confirmed >>= 1;
        }
    }

    function getVotersCount(
        address testamentOwner
    ) external view returns (uint256 voiceCount) {
        DeathConfirmation memory voting = testaments[testamentOwner].voting;
        voiceCount = _getVotersCount(voting.confirmed);
    }

    function getVoters(
        address testamentOwner
    ) external view returns (address[] memory) {
        DeathConfirmation memory voting = testaments[testamentOwner].voting;
        address[] memory voters = new address[](voting.validators.length);
        if (voters.length > 0 && voting.confirmed > 0) {
            uint256 count;
            for (uint256 i = 0; i < voting.validators.length; i++) {
                if (voting.confirmed & (1 << i) != 0) {
                    voters[count] = voting.validators[i];
                    count++;
                }
            }

            assembly {
                mstore(voters, count)
            }
        }
        return voters;
    }

    function confirmDeath(
        address testamentOwner
    )
        external
        correctStatus(
            DeathConfirmationState.Active,
            testamentOwner,
            "voting is not active"
        )
    {
        Testament storage userTestament = testaments[testamentOwner];
        DeathConfirmation memory voting = userTestament.voting;

        for (uint256 i = 0; i < voting.validators.length; i++) {
            if (
                msg.sender == voting.validators[i] &&
                voting.confirmed & (1 << i) == 0
            ) {
                voting.confirmed |= (1 << i);
            }
        }
        userTestament.voting.confirmed = voting.confirmed;

        if (_getVotersCount(voting.confirmed) >= voting.quorum) {
            userTestament.voting.confirmationTime =
                block.timestamp +
                CONFIRMATION_LOCK;
            emit DeathConfirmed(
                testamentOwner,
                userTestament.voting.confirmationTime
            );
        }
    }

    /**
     * @notice get testament after death confirmation
     * call from successors
     * @param testamentOwner: testament creator
     * withdrawal info:
     * @param tokens: {IERC20[] erc20Tokens;NFTinfo[] erc721Tokens;NFTinfo[] erc1155Tokens;}
     * erc20Tokens: array of erc20 tokens
     * erc721Tokens: array of {address nftAddress;uint256[] ids;} objects
     * erc1155Tokens: array of {address nftAddress;uint256[] ids;} objects
     */

    function getTestament(
        address testamentOwner,
        TestamentTokens calldata tokens
    )
        external
        correctStatus(
            DeathConfirmationState.Confirmed,
            testamentOwner,
            "death must be confirmed"
        )
    {
        Testament memory userTestament = testaments[testamentOwner];
        Successors memory userSuccessors = userTestament.successors;

        if (userTestament.subscriptionID == FREEMIUM_ID) {
            require(
                tokens.erc20Tokens.length == 1 &&
                    address(tokens.erc20Tokens[0]) == quoteTokenAddress &&
                    tokens.erc721Tokens.length == 0 &&
                    tokens.erc1155Tokens.length == 0,
                "invalid tokens, the current subscription does not allow receiving these tokens"
            );
        }
        {
            uint256 userERC20Shares;

            for (
                uint256 i = 0;
                i < userSuccessors.erc20successors.length;
                i++
            ) {
                if (msg.sender == userSuccessors.erc20successors[i]) {
                    userERC20Shares += userSuccessors.erc20shares[i];
                }
            }

            if (userERC20Shares > 0) {
                // ERC20
                for (uint256 i = 0; i < tokens.erc20Tokens.length; i++) {
                    mapping(address => bool)
                        storage alreadyDone = alreadyWithdrawn[testamentOwner][
                            msg.sender
                        ];
                    if (alreadyDone[address(tokens.erc20Tokens[i])] == false) {
                        alreadyDone[address(tokens.erc20Tokens[i])] = true;
                        mapping(address => uint256)
                            storage amountPerShare = amountsPerShare[
                                testamentOwner
                            ];
                        uint256 perShare = amountPerShare[
                            address(tokens.erc20Tokens[i])
                        ];
                        
                        if (perShare == 0) {
                            
                            uint256 testamentOwnerBalance = tokens
                                .erc20Tokens[i]
                                .balanceOf(testamentOwner);
                            
                            if (userTestament.subscriptionID == FREEMIUM_ID) {
                                uint256 feeAmount =
                                    (testamentOwnerBalance * FREEMIUM_FEE_BP) /
                                    BASE_POINT;
                                if (feeAmount > 0) {
                                    IERC20(quoteTokenAddress).safeTransferFrom(
                                        testamentOwner,
                                        feeAddress,
                                        feeAmount
                                    );
                                    testamentOwnerBalance-=feeAmount;
                                }
                            }
                            
                            if(testamentOwnerBalance>0){
                                perShare = testamentOwnerBalance / BASE_POINT;
                                amountPerShare[
                                    address(tokens.erc20Tokens[i])
                                ] = perShare;
                                
                                tokens.erc20Tokens[i].safeTransferFrom(
                                    testamentOwner,
                                    address(this),
                                    testamentOwnerBalance
                                );
                            }
                        }
                        uint256 erc20Amount = userERC20Shares * perShare;
                        if (erc20Amount > 0) {
                            tokens.erc20Tokens[i].safeTransfer(
                                msg.sender,
                                erc20Amount
                            );
                        }
                    }
                }
            }
        }

        if (msg.sender == userSuccessors.nft721successor) {
            // ERC721
            for (uint256 i = 0; i < tokens.erc721Tokens.length; i++) {
                for (
                    uint256 x = 0;
                    x < tokens.erc721Tokens[i].ids.length;
                    x++
                ) {
                    IERC721(tokens.erc721Tokens[i].nftAddress).safeTransferFrom(
                            testamentOwner,
                            msg.sender,
                            tokens.erc721Tokens[i].ids[x]
                        );
                }
            }
        }

        if (msg.sender == userSuccessors.nft1155successor) {
            // ERC1155
            for (uint256 i = 0; i < tokens.erc1155Tokens.length; i++) {
                uint256[] memory batchBalances = new uint256[](
                    tokens.erc1155Tokens[i].ids.length
                );
                for (
                    uint256 x = 0;
                    x < tokens.erc1155Tokens[i].ids.length;
                    ++x
                ) {
                    batchBalances[x] = IERC1155(
                        tokens.erc1155Tokens[i].nftAddress
                    ).balanceOf(testamentOwner, tokens.erc1155Tokens[i].ids[x]);
                }
                IERC1155(tokens.erc1155Tokens[i].nftAddress)
                    .safeBatchTransferFrom(
                        testamentOwner,
                        msg.sender,
                        tokens.erc1155Tokens[i].ids,
                        batchBalances,
                        ""
                    );
            }
        }

        emit GetTestament(testamentOwner, msg.sender);
    }

    function getDeathConfirmationState(
        address testamentOwner
    ) public view returns (DeathConfirmationState) {
        Testament memory userTestament = testaments[testamentOwner];
        DeathConfirmation memory voting = userTestament.voting;

        if (userTestament.expirationTime > 0) {
            // voting started
            if (block.timestamp > userTestament.expirationTime) {
                if (_getVotersCount(voting.confirmed) >= voting.quorum) {
                    if (block.timestamp < voting.confirmationTime) {
                        return DeathConfirmationState.ConfirmationWaiting;
                    }

                    return DeathConfirmationState.Confirmed;
                }

                if (
                    block.timestamp <
                    (userTestament.expirationTime + CONFIRMATION_PERIOD)
                ) {
                    return DeathConfirmationState.Active;
                }

                return DeathConfirmationState.TestamentCanceled;
            } else {
                return DeathConfirmationState.StillAlive;
            }
        }

        return DeathConfirmationState.NotExist;
    }
}