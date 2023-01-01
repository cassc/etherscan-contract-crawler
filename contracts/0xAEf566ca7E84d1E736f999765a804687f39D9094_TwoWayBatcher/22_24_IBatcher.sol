//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/token/types/Token6.sol";
import "../interfaces/IEmptySetReserve.sol";

interface IBatcher {
    event Wrap(address indexed to, UFixed18 amount);
    event Unwrap(address indexed to, UFixed18 amount);
    event Rebalance(UFixed18 newMinted, UFixed18 newRedeemed);
    event Close(UFixed18 amount);

    error BatcherNotImplementedError();
    error BatcherBalanceMismatchError(UFixed18 oldBalance, UFixed18 newBalance);

    function RESERVE() external view returns (IEmptySetReserve); // solhint-disable-line func-name-mixedcase
    function USDC() external view returns (Token6); // solhint-disable-line func-name-mixedcase
    function DSU() external view returns (Token18); // solhint-disable-line func-name-mixedcase
    function totalBalance() external view returns (UFixed18);
    function wrap(UFixed18 amount, address to) external;
    function unwrap(UFixed18 amount, address to) external;
    function rebalance() external;
}