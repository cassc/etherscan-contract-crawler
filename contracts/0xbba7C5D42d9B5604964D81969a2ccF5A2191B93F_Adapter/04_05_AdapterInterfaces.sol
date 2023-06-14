// SPDX-License-Identifier: --DAO--

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 */

pragma solidity =0.8.19;

import "./IERC20.sol";

interface IChainLink {

    function decimals()
        external
        view
        returns (uint8);

    function latestAnswer()
        external
        view
        returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answerdInRound
        );

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function phaseId()
        external
        view
        returns(
            uint16 phaseId
        );

    function aggregator()
        external
        view
        returns (address);

    function description()
        external
        view
        returns (string memory);
}

interface ITokenProfit {

    function getAvailableMint()
        external
        view
        returns (uint256);

    function executeAdapterRequest(
        address _contractToCall,
        bytes memory _callBytes
    )
        external
        returns (bytes memory);

    function executeAdapterRequestWithValue(
        address _contractToCall,
        bytes memory _callBytes,
        uint256 _value
    )
        external
        returns (bytes memory);

    function totalSupply()
        external
        view
        returns (uint256);
}

interface ILiquidNFTsRouter {

    function depositFunds(
        uint256 _amount,
        address _pool
    )
        external;

    function withdrawFunds(
        uint256 _amount,
        address _pool
    )
        external;
}

interface ILiquidNFTsPool {

    function pseudoTotalTokensHeld()
        external
        view
        returns (uint256);

    function totalInternalShares()
        external
        view
        returns (uint256);

    function manualSyncPool()
        external;

    function internalShares(
        address _user
    )
        external
        view
        returns (uint256);

    function poolToken()
        external
        view
        returns (address);

    function chainLinkETH()
        external
        view
        returns (address);
}

interface IUniswapV2 {

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
      external
      payable
      returns (uint256[] memory amounts);

    function swapExactTokensForETH(
       uint256 amountIn,
       uint256 amountOutMin,
       address[] calldata path,
       address to,
       uint256 deadline
   )
       external
       returns (uint256[] memory amounts);
}

interface IWETH is IERC20 {

    function deposit()
        payable
        external;

    function withdraw(
        uint256 _amount
    )
        external;
}