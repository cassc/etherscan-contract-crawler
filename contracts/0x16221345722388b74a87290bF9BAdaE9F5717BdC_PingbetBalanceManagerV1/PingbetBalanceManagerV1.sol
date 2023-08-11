/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

//        |-----------------------------------------------------------------------------------------------------------|
//        |                                                                        %################.                 |
//        |                                                                       #####################@              |
//        |                                                         |           ######    @#####    &####             |
//        |                                                         |           ###%        ,         ###%            |
//        |                                                         |          &###,  /&@@     @(@@   ####            |
//        |                                                         |           ###@       &..%      *####            |
//        |  $$$$$$$\  $$$$$$$$\ $$\   $$\  $$$$$$\ $$\     $$\     |           @####     .,,,,@    #####             |
//        |  $$  __$$\ $$  _____|$$$\  $$ |$$  __$$\\$$\   $$  |    |            %##(       ,*      @##(@             |
//        |  $$ |  $$ |$$ |      $$$$\ $$ |$$ /  \__|\$$\ $$  /     |        /#&##@                    ##&#&          |
//        |  $$$$$$$  |$$$$$\    $$ $$\$$ |$$ |$$$$\  \$$$$  /      |       ######                        #(###       |
//        |  $$  ____/ $$  __|   $$ \$$$$ |$$ |\_$$ |  \$$  /       |    #######                          ######.     |
//        |  $$ |      $$ |      $$ |\$$$ |$$ |  $$ |   $$ |        |  &#######@                          ##(#####    |
//        |  $$ |      $$$$$$$$\ $$ | \$$ |\$$$$$$  |   $$ |        |        ###                           &##        |
//        |  \__|      \________|\__|  \__| \______/    \__|        |        &##%                          ###        |
//        |                                                         |         %###                        @##@        |
//        |                                                         |           %###@                  &###&          |
//        |                                                                    &,,,,,&################@,,,,,%         |
//        |                                                                  ,.,,,.*%@               /(.,,,,/@        |
//        |-----------------------------------------------------------------------------------------------------------|
//                                -----> Ken and the community makes penguins fly! 🚀  <-----     */

interface IUSDT {
    function transfer(address to, uint value) external;

    function transferFrom(address from, address to, uint value) external;

    function balanceOf(address owner) external view returns (uint);
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract PingbetBalanceManagerV1 {
    uint256 public constant STABLECOIN_DECIMALS = 6;
    uint256 public serviceFee = 0;

    mapping(address => uint256) public usdtWithdrawAllowance;

    address public immutable usdtAddress;
    address public immutable pengyAddress;

    address public immutable deployer;

    bool public isPaused = false;
    bool public usdtPengyAutoSwapOnWithdraw = false;

    mapping(address => bool) operators;

    event USDTDeposited(address indexed walletAddress, uint256 usdtIn);

    struct WithdrawRequest {
        uint256 uid;
        address user;
        uint256 usdtOut;
        uint256 pengyOut;
        uint256 exchangeRate;
        uint32 timestamp;
        bool isApproved;
        bool isRejected;
    }

    event WithdrawRequestCreated(
        uint256 indexed uid,
        address indexed walletAddress,
        uint256 usdtOut,
        uint256 pengyOut,
        uint256 exchangeRate,
        uint32 timestamp
    );

    event WithdrawRequestAccepted(
        uint256 indexed uid,
        address indexed walletAddress,
        uint256 exchangeRate,
        uint256 usdtIn,
        uint256 pengyOut
    );

    event WithdrawRequestRejected(uint256 indexed uid);

    event SwappedUSDTForPENGY(uint256 usdtIn, uint256 pengyOut);

    event UsdtAllowanceModified(uint256 oldBalance, uint256 newBalance);

    event ServiceFeeChanged(uint256 oldFee, uint256 newFee);

    WithdrawRequest[] public withdrawRequests;

    constructor(address _usdtAddress, address _pengyAddress) {
        usdtAddress = _usdtAddress;
        pengyAddress = _pengyAddress;
        deployer = msg.sender;
        operators[msg.sender] = true;
    }

    modifier notPaused() {
        require(!isPaused, "depositWithdrawIsPaused");
        _;
    }

    modifier onlyOperators() {
        require(operators[msg.sender], "onlyOperators");
        _;
    }

    /**
     * Owner functions
     */

    /**
     * @dev Adjusts the balances for a certain wallet.
     * @notice Is called by the owner of the contract after a game has finished.
     */

    function increaseUsdtWithdrawAllowance(
        address[5] memory accounts,
        uint256 usdtToAdd
    ) external onlyOperators {
        require(usdtToAdd > 0, "usdtToAdd must be greater than 0");

        for (uint256 i = 0; i < accounts.length; i++) {
            usdtWithdrawAllowance[accounts[i]] += usdtToAdd;

            emit UsdtAllowanceModified(
                usdtWithdrawAllowance[accounts[i]] - usdtToAdd,
                usdtWithdrawAllowance[accounts[i]]
            );
        }
    }

    function decreaseUsdtWithdrawAllowance(
        address[] memory accounts,
        uint256 usdtToSub
    ) external onlyOperators {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                usdtWithdrawAllowance[accounts[i]] >= usdtToSub,
                "usdtToSub must be less than or equal to the current allowance"
            );

            usdtWithdrawAllowance[accounts[i]] -= usdtToSub;

            emit UsdtAllowanceModified(
                usdtWithdrawAllowance[accounts[i]] + usdtToSub,
                usdtWithdrawAllowance[accounts[i]]
            );
        }
    }

    function changeServiceFee(uint256 _serviceFee) external onlyOperators {
        emit ServiceFeeChanged(serviceFee, _serviceFee);
        serviceFee = _serviceFee;
    }

    function changeIsPaused(bool _isPaused) external onlyOperators {
        isPaused = _isPaused;
    }

    function changeOperatorAccess(address _wallet, bool _hasAccess) external {
        require(
            msg.sender == deployer,
            "Only deployer can change operator access"
        );

        operators[_wallet] = _hasAccess;
    }

    function distributeTokensForWithdrawRequest(
        uint256 _withdrawRequestId,
        uint256 _pengyOut
    ) internal {
        require(
            _withdrawRequestId < withdrawRequests.length,
            "Invalid withdrawRequestId"
        );

        WithdrawRequest storage withdrawRequest = withdrawRequests[
            _withdrawRequestId
        ];

        require(
            !withdrawRequest.isApproved,
            "Withdraw request already approved"
        );

        withdrawRequest.isApproved = true;

        withdrawRequest.pengyOut = _pengyOut;

        IERC20(pengyAddress).transfer(
            withdrawRequest.user,
            withdrawRequest.pengyOut
        );

        emit WithdrawRequestAccepted(
            _withdrawRequestId,
            withdrawRequest.user,
            withdrawRequest.exchangeRate,
            withdrawRequest.usdtOut,
            withdrawRequest.pengyOut
        );
    }

    function approveWithdrawRequestBatch(
        uint256[] memory _withdrawRequestIds,
        uint256[] memory _pengyOut
    ) external onlyOperators {
        require(
            _withdrawRequestIds.length == _pengyOut.length,
            "withdrawRequestIds and pengyOut must have the same length"
        );

        for (uint256 i = 0; i < _withdrawRequestIds.length; i++) {
            distributeTokensForWithdrawRequest(
                _withdrawRequestIds[i],
                _pengyOut[i]
            );
        }
    }

    function rejectWithdrawRequestBatch(
        uint256[] memory _withdrawRequestIds
    ) external onlyOperators {
        for (uint256 i = 0; i < _withdrawRequestIds.length; i++) {
            require(
                _withdrawRequestIds[i] < withdrawRequests.length,
                "Invalid withdrawRequestId"
            );

            WithdrawRequest storage withdrawRequest = withdrawRequests[
                _withdrawRequestIds[i]
            ];

            require(
                !withdrawRequest.isApproved,
                "Withdraw request already approved"
            );

            withdrawRequest.isApproved = true;

            emit WithdrawRequestRejected(_withdrawRequestIds[i]);
        }
    }

    function emergencyWithdrawUSDT(
        address _to,
        uint256 _amount
    ) external onlyOperators {
        IERC20(usdtAddress).transfer(_to, _amount);
    }

    function emergencyWithdrawPENGY(
        address _to,
        uint256 _amount
    ) external onlyOperators {
        IERC20(pengyAddress).transfer(_to, _amount);
    }

    function emergencyWithdrawETH(
        address payable _to,
        uint256 _amount
    ) external onlyOperators {
        // Using call
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function createWithdrawRequest(uint256 usdtOut) external payable notPaused {
        if (serviceFee > 0) {
            require(
                msg.value >= serviceFee,
                "Not enough ETH sent for service fee"
            );
        }

        require(usdtOut > 0, "usdtOut must be greater than 0");

        require(
            usdtWithdrawAllowance[msg.sender] >= usdtOut,
            "Not enough USDT in balance"
        );

        usdtWithdrawAllowance[msg.sender] -= usdtOut;

        uint256 _uid = withdrawRequests.length;

        if (usdtPengyAutoSwapOnWithdraw) {
            //TODO: implement this
        }

        withdrawRequests.push(
            WithdrawRequest({
                uid: _uid,
                user: msg.sender,
                usdtOut: usdtOut,
                pengyOut: 0,
                exchangeRate: 0,
                timestamp: uint32(block.timestamp),
                isApproved: false,
                isRejected: false
            })
        );

        emit WithdrawRequestCreated(
            _uid,
            msg.sender,
            usdtOut,
            0,
            0,
            uint32(block.timestamp)
        );
    }

    function depositTokens(uint256 usdtIn) external notPaused {
        IUSDT(usdtAddress).transferFrom(msg.sender, address(this), usdtIn);

        usdtWithdrawAllowance[msg.sender] += usdtIn;

        emit USDTDeposited(msg.sender, usdtIn);
    }
}

/*

The topics and opinions discussed by Ken the Crypto and the PENGY community are intended to convey general information only. All opinions expressed by Ken or the community should be treated as such.

This contract does not provide legal, investment, financial, tax, or any other type of similar advice.

As with all alternative currencies, Do Your Own Research (DYOR) before purchasing. Ken and the rest of the PENGY community are working to increase coin adoption, but no individual or community shall be held responsible for any financial losses or gains that may be incurred as a result of trading PENGY.

If you’re with us — Hop In, We’re Going Places 🚀

*/