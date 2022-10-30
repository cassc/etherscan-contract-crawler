// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import { DSMath } from "../../../utils/dsmath.sol";
import "./interface.sol";

contract EulerHelper is DSMath {
    address internal constant EUL = 0xd9Fcd98c322942075A5C3860693e9f4f03AAE07b;

    address internal constant EULER_MAINNET = 0x27182842E098f60e3D576794A5bFFb0777E025d3;

    IEulerMarkets internal constant markets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    IEulerGeneralView internal constant eulerView = IEulerGeneralView(0xACC25c4d40651676FEEd43a3467F3169e3E68e42);

    IEulerExecute internal constant eulerExec = IEulerExecute(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);

    IEulerDistributor internal constant eulerDistribute = IEulerDistributor(0xd524E29E3BAF5BB085403Ca5665301E94387A7e2);

    struct SubAccount {
        uint256 id;
        address subAccountAddress;
    }

    struct Position {
        SubAccount subAccountInfo;
        AccountStatus accountStatus;
        ResponseMarket[] marketsInfoSubAcc;
    }

    struct AccountStatus {
        uint256 totalCollateral;
        uint256 totalBorrowed;
        uint256 riskAdjustedTotalCollateral;
        uint256 riskAdjustedTotalBorrow;
        uint256 healthScore;
    }

    struct AccountStatusHelper {
        uint256 collateralValue;
        uint256 liabilityValue;
        uint256 healthScore;
    }

    /**
     * @dev Return ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Weth address
     */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Kovan WETH Address
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }

    /**
     * @dev Get all sub-accounts of a user.
     * @notice Get all sub-accounts of a user.
     * @param end End sub-account.
     * @param user Address of user.
     * @param user Address of user.
     */
    function getSubAccountInRange(
        uint256 start,
        uint256 end,
        address user
    ) public pure returns (SubAccount[] memory subAccounts) {
        uint256 _length = sub(end, start);
        subAccounts = new SubAccount[](_length);

        for (uint256 i = 0; i < _length; i++) {
            address subAccount = getSubAccountAddress(user, start + i);
            subAccounts[i] = SubAccount({ id: i, subAccountAddress: subAccount });
        }
    }

    /**
     * @dev Get all sub-accounts of a user.
     * @notice Get all sub-accounts of a user.
     * @param user Address of user
     */
    function getAllSubAccounts(address user) public pure returns (SubAccount[] memory subAccounts) {
        uint256 length = 256;
        subAccounts = new SubAccount[](length);

        for (uint256 i = 0; i < length; i++) {
            address subAccount = getSubAccountAddress(user, i);
            subAccounts[i] = SubAccount({ id: i, subAccountAddress: subAccount });
        }
    }

    /**
     * @dev Get all sub-accounts of a user.
     * @notice Get all sub-accounts of a user.
     * @param primary Address of user
     * @param subAccountId sub-account Id(0 for primary and 1 - 255 for sub-account)
     */
    function getSubAccountAddress(address primary, uint256 subAccountId) public pure returns (address) {
        require(subAccountId < 256, "sub-account-id-too-big");
        return address(uint160(primary) ^ uint160(subAccountId));
    }

    /**
     * @dev Get active sub-accounts.
     * @notice Get active sub-accounts.
     * @param subAccounts Array of SubAccount struct(id and address)
     * @param tokens Array of the tokens
     */
    function getActiveSubAccounts(SubAccount[] memory subAccounts, address[] memory tokens)
        public
        view
        returns (bool[] memory activeSubAcc, uint256 count)
    {
        uint256 tokenLength = tokens.length;
        activeSubAcc = new bool[](subAccounts.length);

        for (uint256 i = 0; i < subAccounts.length; i++) {
            for (uint256 j = 0; j < tokenLength; j++) {
                address eToken = markets.underlyingToEToken(tokens[j]);

                if ((IEToken(eToken).balanceOfUnderlying(subAccounts[i].subAccountAddress)) > 0) {
                    activeSubAcc[i] = true;
                    count++;
                    break;
                }
            }
        }
    }

    /**
     * @dev Get detailed sub-account info.
     * @notice Get detailed sub-account info.
     * @param response Response of a sub-account. 
        (ResponseMarket include enteredMarkets followed by queried token response).
     * @param tokens Array of the tokens(Use WETH address for ETH token)
     */
    function getSubAccountInfo(
        address subAccount,
        Response memory response,
        address[] memory tokens
    ) public view returns (ResponseMarket[] memory marketsInfo, AccountStatus memory accountStatus) {
        uint256 totalLend;
        uint256 totalBorrow;
        uint256 k;

        marketsInfo = new ResponseMarket[](tokens.length);

        for (uint256 i = response.enteredMarkets.length; i < response.markets.length; i++) {
            totalLend += convertTo18(response.markets[i].decimals, response.markets[i].eTokenBalanceUnderlying);
            totalBorrow += convertTo18(response.markets[i].decimals, response.markets[i].dTokenBalance);

            marketsInfo[k] = response.markets[i];
            k++;
        }

        AccountStatusHelper memory accHelper;

        (accHelper.collateralValue, accHelper.liabilityValue, accHelper.healthScore) = getAccountStatus(subAccount);

        accountStatus = AccountStatus({
            totalCollateral: totalLend,
            totalBorrowed: totalBorrow,
            riskAdjustedTotalCollateral: accHelper.collateralValue,
            riskAdjustedTotalBorrow: accHelper.liabilityValue,
            healthScore: accHelper.healthScore //based on risk adjusted values
        });
    }

    function getAccountStatus(address account)
        public
        view
        returns (
            uint256 collateralValue,
            uint256 liabilityValue,
            uint256 healthScore
        )
    {
        LiquidityStatus memory status = eulerExec.liquidity(account);

        collateralValue = status.collateralValue;
        liabilityValue = status.liabilityValue;

        if (liabilityValue == 0) {
            healthScore = type(uint256).max;
        } else {
            healthScore = (collateralValue * 1e18) / liabilityValue;
        }
    }

    function getClaimedAmount(address user) public view returns (uint256 claimedAmount) {
        claimedAmount = eulerDistribute.claimed(user, address(EUL));
    }
}