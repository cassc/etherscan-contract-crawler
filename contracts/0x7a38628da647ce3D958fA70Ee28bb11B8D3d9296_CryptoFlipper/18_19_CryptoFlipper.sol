// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "chainlink/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "v3-periphery/interfaces/ISwapRouter.sol";
import "./dependencies/weth/IWETH_C.sol";

contract CryptoFlipper is Initializable, OwnableUpgradeable, UUPSUpgradeable, VRFV2WrapperConsumerBase {
    // **** PROPERTIES ****

    address[] private beneficiaries;

    bool private isLocked;

    mapping(address => uint256) public credits;

    struct WaitingTossBetValue {
        address winner;
        uint256 bet;
        string id;
        bool isSet;
    }

    mapping(uint256 => WaitingTossBetValue) public waitingTossBets;

    address public WNATIVE;

    // SwapRouter02
    address public uniswapRouter;

    // **** CONSTANTS ****

    uint256 internal constant MAX_UINT256 = type(uint256).max;

    // **** TYPE ALIASES ****

    using SafeERC20Upgradeable for IERC20Upgradeable;

    // **** EVENTS ****

    event BeneficiariesChanged(address[] beneficiaries);

    event TossWon(address indexed winner, string indexed id, uint256 bet, uint256 win);
    event TossLost(address indexed loser, string indexed id, uint256 bet);

    // **** MODIFIERS ****

    modifier lock() {
        require(!isLocked);

        isLocked = true;
        _;
        isLocked = false;
    }

    // **** INITIALIZING ****

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _link, address _vrfV2Wrapper) initializer VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper) {}

    /// Fallback receive function to support accepting ETH from WETH unwraps
    receive() external payable {}

    function initialize(address[] memory _beneficiaries, address _wnativeAddress, address _uniswapRouter)
        public
        initializer
    {
        __Ownable_init();
        __UUPSUpgradeable_init();

        isLocked = false;

        setBeneficiaries(_beneficiaries);
        setWNATIVE(_wnativeAddress);
        setUniswapRouter(_uniswapRouter);
    }

    // **** ChainLink VRF ****

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override lock {
        // Toss a coin response

        WaitingTossBetValue memory value = waitingTossBets[_requestId];
        require(value.isSet, "no waiting toss");

        // transform the result to a number between 1 and 20 inclusively
        uint256 d20Value = (_randomWords[0] % 20) + 1;

        uint256 winValue = ((value.bet * 2) * 900) / 1000;
        uint256 contractBalance = IERC20Upgradeable(WNATIVE).balanceOf(address(this));
        if (d20Value <= 8 && contractBalance >= winValue) {
            // won

            // (bool sent,) = payable(value.winner).call{value: winValue}("");
            // require(sent, "send failed fr");
            credits[value.winner] += winValue;

            emit TossWon(value.winner, value.id, value.bet, winValue);
        } else {
            // lost
            emit TossLost(value.winner, value.id, value.bet);
        }

        // reset mapping
        delete waitingTossBets[_requestId];
    }

    // **** PLAYING ****

    function addCredit() public payable lock {
        require(msg.value > 0, "min add");

        _addCredit(msg.sender, msg.value);
    }

    function _addCredit(address who, uint256 amount) internal {
        // convert to weth
        IWETH_C(WNATIVE).deposit{value: amount}();

        credits[who] += amount;
    }

    function getCredit(address spender) public view returns (uint256 credit) {
        return credits[spender];
    }

    function toss(uint256 bet, string memory id) public payable lock {
        if (msg.value > 0) {
            _addCredit(msg.sender, msg.value);
        }

        uint256 maxBet = credits[msg.sender];
        require(bet <= maxBet, "bet compliance");

        // Remove credits
        credits[msg.sender] -= bet;

        // Convert some balance to LINK, trigger VRF.

        uint32 gasLimitForVRFCallback = 100000;
        uint256 linkPrice = VRF_V2_WRAPPER.calculateRequestPrice(gasLimitForVRFCallback);

        // Approve maximum the bet amount.
        IERC20Upgradeable(WNATIVE).approve(uniswapRouter, bet);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: WNATIVE,
            tokenOut: address(LINK),
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp + 1,
            amountOut: linkPrice,
            amountInMaximum: bet,
            sqrtPriceLimitX96: 0
        });
        uint256 lostForLink = ISwapRouter(uniswapRouter).exactOutputSingle(params);

        // Create waiting toss
        uint256 betMinusFees = bet - lostForLink;
        WaitingTossBetValue memory waitingTossBetValue =
            WaitingTossBetValue({winner: msg.sender, bet: betMinusFees, id: id, isSet: true});
        // Request randomness
        uint256 vrfRequestId = requestRandomness(gasLimitForVRFCallback, 3, 1);

        // Set waiting toss
        waitingTossBets[vrfRequestId] = waitingTossBetValue;
    }

    // **** WITHDRAWING ****

    function withdrawCredits() public lock {
        uint256 credit = credits[msg.sender];

        require(credit > 0, "wd compliance");

        credits[msg.sender] = 0;

        // Withdraw from weth
        IWETH_C(WNATIVE).withdraw(credit);

        (bool sent,) = payable(msg.sender).call{value: credit}("");
        require(sent, "send failed");
    }

    // **** OWNER FUNCTIONS ****

    // Distributes funds to the current beneficiaries
    function distributeFunds(address token, uint256 amount) public lock {
        // Owner or beneficiary can trigger
        if (msg.sender != owner()) {
            bool isBeneficiary = false;
            for (uint256 i = 0; i < beneficiaries.length; i++) {
                if (msg.sender == beneficiaries[i]) {
                    isBeneficiary = true;
                    break;
                }
            }

            require(isBeneficiary, "beneficiary or owner only");
        }

        bool isEth = token == address(0);

        if (isEth) {
            require(amount <= address(this).balance, "dist impossible");

            uint256 amountPerBeneficiary = amount / beneficiaries.length;

            for (uint256 _i = 0; _i < beneficiaries.length; _i++) {
                (bool sent,) = payable(beneficiaries[_i]).call{value: amountPerBeneficiary}("");
                // We don't care about beneficiaries not being able to receive their stake. So no need to verify.
                require(sent == true || sent == false, "we dont care");
            }
        } else {
            require(amount <= IERC20Upgradeable(token).balanceOf(address(this)), "dist impossible");

            uint256 amountPerBeneficiary = amount / beneficiaries.length;

            for (uint256 _i = 0; _i < beneficiaries.length; _i++) {
                IERC20Upgradeable(token).safeTransfer(beneficiaries[_i], amountPerBeneficiary);
            }
        }
    }

    function setBeneficiaries(address[] memory _beneficiaries) public onlyOwner {
        require(_beneficiaries.length > 0, "0001");

        beneficiaries = _beneficiaries;

        emit BeneficiariesChanged(_beneficiaries);
    }

    function setWNATIVE(address _newWNATIVE) public onlyOwner {
        WNATIVE = _newWNATIVE;
    }

    function setUniswapRouter(address _newUniswapRouter) public onlyOwner {
        uniswapRouter = _newUniswapRouter;
    }

    function withdrawLockedFunds(address toAccount) public onlyOwner {
        payable(toAccount).transfer(address(this).balance);
    }

    function withdrawLockedFunds(IERC20Upgradeable token, address toAccount) public onlyOwner {
        token.safeTransfer(toAccount, token.balanceOf(address(this)));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}