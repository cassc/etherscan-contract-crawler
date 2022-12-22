// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./ITGE.sol";
import "./IDispatcher.sol";
import "./IToken.sol";

interface IService {
    function initialize(
        IDispatcher dispatcher_,
        address poolBeacon_,
        address tokenBeacon_,
        address tgeBeacon_,
        address proposalGateway_,
        uint256[13] calldata ballotParams,
        ISwapRouter uniswapRouter_,
        IQuoter uniswapQuoter_,
        uint256 protocolTokenFee_
    ) external;

    function createSecondaryTGE(
        ITGE.TGEInfo calldata tgeInfo, 
        string memory metadataURI, 
        IToken.TokenType tokenType, 
        string memory tokenDescription,
        uint256 preferenceTokenCap
    ) external;

    function addProposal(uint256 proposalId) external;

    function addEvent(IDispatcher.EventType eventType, uint256 proposalId, string calldata metaHash)
        external;

    function isManagerWhitelisted(address account) external view returns (bool);

    function isExecutorWhitelisted(address account) external view returns (bool);

    function owner() external view returns (address);

    function uniswapRouter() external view returns (ISwapRouter);

    function uniswapQuoter() external view returns (IQuoter);

    function dispatcher() external view returns (IDispatcher);

    function proposalGateway() external view returns (address);

    function protocolTreasury() external view returns (address);

    function protocolTokenFee() external view returns (uint256);

    function getMinSoftCap() external view returns (uint256);

    function getProtocolTokenFee(uint256 amount)
        external
        view
        returns (uint256);

    function ballotExecDelay(uint256 _index) external view returns (uint256);

    function primaryAsset() external view returns (address);

    function secondaryAsset() external view returns (address);

    function poolBeacon() external view returns (address);

    function tgeBeacon() external view returns (address);
}