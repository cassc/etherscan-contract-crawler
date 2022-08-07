// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./helpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EulerResolver is EulerHelper {
    /**
     * @dev Get all active sub-account Ids and addresses of a user.
     * @notice Get all sub-account of a user that has some token liquidity in it.
     * @param user Address of user
     * @param tokens Array of the tokens(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getAllActiveSubAccounts(address user, address[] memory tokens)
        public
        view
        returns (SubAccount[] memory activeSubAccounts)
    {
        address[] memory _tokens = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        SubAccount[] memory subAccounts = getAllSubAccounts(user);

        bool[] memory activeSubAccBool = new bool[](256);
        uint256 count;
        (activeSubAccBool, count) = getActiveSubAccounts(subAccounts, _tokens);

        activeSubAccounts = new SubAccount[](count);
        uint256 k = 0;

        for (uint256 j = 0; j < subAccounts.length; j++) {
            if (activeSubAccBool[j]) {
                activeSubAccounts[k].id = j;
                activeSubAccounts[k].subAccountAddress = subAccounts[j].subAccountAddress;
                k++;
            }
        }
    }

    /**
     * @dev Get position details of all active sub-accounts.
     * @notice Get position details of all active sub-accounts.
     * @param user Address of user
     * @param activeSubAccountIds Array of active sub-account Ids(0 for primary and 1 - 255 for sub-account)
     * @param tokens Array of the tokens(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getPositionOfActiveSubAccounts(
        address user,
        uint256[] memory activeSubAccountIds,
        address[] memory tokens
    ) public view returns (uint256 claimedAmount, Position[] memory positions) {
        address[] memory _tokens = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        uint256 length = activeSubAccountIds.length;
        address[] memory subAccountAddresses = new address[](length);
        positions = new Position[](length);

        Query[] memory qs = new Query[](length);

        for (uint256 i = 0; i < length; i++) {
            subAccountAddresses[i] = getSubAccountAddress(user, activeSubAccountIds[i]);
            qs[i] = Query({ eulerContract: EULER_MAINNET, account: subAccountAddresses[i], markets: _tokens });
        }

        Response[] memory response = new Response[](length);
        response = eulerView.doQueryBatch(qs);

        claimedAmount = getClaimedAmount(user);

        for (uint256 j = 0; j < length; j++) {
            (ResponseMarket[] memory marketsInfo, AccountStatus memory accountStatus) = getSubAccountInfo(
                subAccountAddresses[j],
                response[j],
                _tokens
            );

            positions[j] = Position({
                subAccountInfo: SubAccount({ id: activeSubAccountIds[j], subAccountAddress: subAccountAddresses[j] }),
                accountStatus: accountStatus,
                marketsInfoSubAcc: marketsInfo
            });
        }
    }

    /**
     * @dev Get position details of all active sub-accounts of a user.
     * @notice Get position details of all active sub-accounts.
     * @param user Address of user
     * @param tokens Array of the tokens(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
     */
    function getAllPositionsOfUser(address user, address[] memory tokens)
        public
        view
        returns (uint256 claimedAmount, Position[] memory activePositions)
    {
        address[] memory _tokens = new address[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        uint256 length = 256;

        SubAccount[] memory subAccounts = getAllSubAccounts(user);
        (bool[] memory activeSubAcc, uint256 count) = getActiveSubAccounts(subAccounts, _tokens);

        Query[] memory qs = new Query[](count);
        Response[] memory response = new Response[](count);

        SubAccount[] memory activeSubAccounts = new SubAccount[](count);
        uint256 k;

        for (uint256 i = 0; i < length; i++) {
            if (activeSubAcc[i]) {
                qs[i] = Query({
                    eulerContract: EULER_MAINNET,
                    account: subAccounts[i].subAccountAddress,
                    markets: _tokens
                });

                activeSubAccounts[k] = SubAccount({
                    id: subAccounts[i].id,
                    subAccountAddress: subAccounts[i].subAccountAddress
                });

                k++;
            }
        }

        response = eulerView.doQueryBatch(qs);

        claimedAmount = getClaimedAmount(user);

        activePositions = new Position[](count);

        for (uint256 j = 0; j < count; j++) {
            (ResponseMarket[] memory marketsInfo, AccountStatus memory accountStatus) = getSubAccountInfo(
                activeSubAccounts[j].subAccountAddress,
                response[j],
                _tokens
            );

            activePositions[j] = Position({
                subAccountInfo: SubAccount({
                    id: activeSubAccounts[j].id,
                    subAccountAddress: activeSubAccounts[j].subAccountAddress
                }),
                accountStatus: accountStatus,
                marketsInfoSubAcc: marketsInfo
            });
        }
    }
}

contract InstaEulerResolver is EulerResolver {
    string public constant name = "Euler-Resolver-v1.0";
}