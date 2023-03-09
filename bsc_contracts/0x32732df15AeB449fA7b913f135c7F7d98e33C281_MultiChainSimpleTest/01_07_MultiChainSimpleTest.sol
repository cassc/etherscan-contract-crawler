// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import "./multichain/IAnyswapV6CallProxy.sol";
import "./multichain/IApp.sol";

interface ICounter {
    function increaseCounter() external;
}

contract MultiChainSimpleTest is Ownable, Pausable, IApp {

    uint256 immutable chainId;
    address public to = address(0x675499339e957Ef0c3baF5F3eB93f6Ab5f650395);

    IAnyswapV6CallProxy public endpoint;
    
    mapping(address => mapping(uint256 => bool)) public isAllowedCaller;

    constructor(IAnyswapV6CallProxy _endpoint,uint256 _chainId) {
        endpoint = _endpoint;
        chainId = _chainId;
    }

    function increaseCounter(uint256 _toChainId,address _toCounter) external payable whenNotPaused {
        require(_toChainId != chainId, "Cannot mirror from/to same chain");
        bytes memory payload = abi.encode();
        endpoint.anyCall{value: msg.value}(_toCounter, payload, address(0), _toChainId, 2);
    }


    function anyFallback(address _to, bytes calldata _data) override external {}

    function anyExecute(bytes calldata _data) override external returns (bool success, bytes memory result) {
        require(_msgSender() == address(endpoint.executor()), "Only multichain endpoint can trigger mirroring");

        (address from, uint256 fromChainId,) = endpoint.executor().context();
        require(isAllowedCaller[from][fromChainId], "Caller is not allowed from source chain");

        ICounter(to).increaseCounter();

        return (true, "");
    }

    function setupAllowedCallers(
        address[] memory _callers,
        uint256[] memory _chainIds,
        bool[] memory _areAllowed
    ) external onlyOwner {
        uint256 nbCallers_ = _callers.length;
        for (uint256 i = 0; i < nbCallers_; i++) {
            isAllowedCaller[_callers[i]][_chainIds[i]] = _areAllowed[i];
        }
    }

    function setEndpoint(IAnyswapV6CallProxy _endpoint) external onlyOwner {
        endpoint = _endpoint;
    }

  
    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

}