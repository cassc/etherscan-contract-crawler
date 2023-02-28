// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWormholeCore.sol";
import "./lib/LibBytes.sol";

contract Phoenix is Ownable {
    using LibBytes for bytes;

    mapping(uint256 => mapping(address => string)) public mappedList;
    mapping(address => bool) public isTokenListed;
    mapping(address => mapping(bytes32 => uint256)) public internalBalances;

    address public coreAddress;
    uint8 public consistencyLevel;

    constructor(address _coreAddress, uint8 _consistencyLevel) {
        coreAddress = _coreAddress;
        consistencyLevel = _consistencyLevel;
    }

    function listedToken(address tokenAddress) external view returns (bool) {
        if (isTokenListed[tokenAddress]) {
            return true;
        } else {
            return false;
        }
    }

    // To-Do: create an array input for listing tokens

    function listTokens(
        uint256 chainId,
        address tokenAddress,
        string memory symbol
    ) public onlyOwner {
        require(!isTokenListed[tokenAddress], "Phoenix: token already listed");

        mappedList[chainId][tokenAddress] = symbol;
        // example: there is USDC on matic and eth, mappedList[5][0x..]="USDC", mappedlist[1][0x..]="USDC"
        isTokenListed[tokenAddress] = true;
    }

    function getVM(bytes memory encodedVm)
        private
        view
        returns (IWormholeCore.VM memory)
    {
        (
            IWormholeCore.VM memory vm,
            bool valid,
            string memory reason
        ) = IWormholeCore(coreAddress).parseAndVerifyVM(encodedVm);
        require(valid, reason);

        return vm;
    }

    function getDepositPayload(bytes memory encodedVm)
        public
        view
        returns (
            address senderAddress,
            uint256 chainId,
            uint256 amount,
            string memory symbol,
            uint64 sequence
        )
    {
        IWormholeCore.VM memory vm = getVM(encodedVm);

        sequence = vm.sequence;
        (senderAddress, chainId, amount, symbol) = vm
            .payload
            .parseDepositInfo();
    }

    function updateDepositBalance(bytes memory data)
        external
        returns (address, bytes32)
    {
        (
            address senderAddress,
            uint256 chainId,
            uint256 amount,
            string memory symbolStr,
            uint64 sequence
        ) = getDepositPayload(data);
        bytes32 symbol = bytes32(bytes(symbolStr));
        internalBalances[senderAddress][symbol] += amount;
        return (senderAddress, symbol);
    }

    function swapInfo(
        string memory symbolStr,
        address destinationAssetAddress,
        uint256 swappingChain,
        uint256 amountIn,
        uint256 amountOutMin
    ) internal returns (uint64 coreSequence) {
        bytes32 symbol = bytes32(bytes(symbolStr));
        require(
            internalBalances[msg.sender][symbol] <= amountIn,
            "Phoenix: insufficient swapping amount"
        );

        require(
            isTokenListed[destinationAssetAddress],
            "Phoenix: destination asset not listed"
        );

        bytes memory payload = abi.encodePacked(
            address(this),
            bytes32(uint256(uint160(address(destinationAssetAddress)))),
            swappingChain,
            amountIn,
            amountOutMin,
            bytes32(bytes(symbolStr))
        );

        coreSequence = IWormholeCore(coreAddress).publishMessage(
            uint32(block.timestamp % 2**32),
            payload,
            consistencyLevel
        );
    }

    function parseSwappedInfo(bytes memory data) external {
        (
            address senderAddress,
            uint256 swappingChain,
            uint256 amountIn,
            address destinationAssetAddress,
            uint256 amountOut,
            string memory sourceSymbolStr
        ) = LibBytes.parseSwappedInfo(data);

        string memory destinationSymbolStr = mappedList[swappingChain][
            destinationAssetAddress
        ];
        bytes32 sourceSymbol = bytes32(bytes(sourceSymbolStr));
        bytes32 destinationSymbol = bytes32(bytes(destinationSymbolStr));

        internalBalances[senderAddress][sourceSymbol] -= amountIn;
        internalBalances[senderAddress][destinationSymbol] += amountOut;
    }
}