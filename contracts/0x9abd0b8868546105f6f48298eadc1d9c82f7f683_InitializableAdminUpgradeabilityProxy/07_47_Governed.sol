pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "../interface/IEscrowCallable.sol";
import "../interface/IPortfoliosCallable.sol";

import "../upgradeable/Ownable.sol";
import "../upgradeable/Initializable.sol";

import "./Directory.sol";

/**
 * @title Governed
 * A base contract to set the contract references on each contract.
 */
contract Governed is OpenZeppelinUpgradesOwnable, Initializable {
    address public DIRECTORY;
    mapping(uint256 => address) private contracts;

    function initialize(address directory, address owner) public initializer {
        _owner = owner;
        DIRECTORY = directory;
    }

    enum CoreContracts {
        Escrow,
        Portfolios,
        ERC1155Token,
        ERC1155Trade
    }

    function setContract(CoreContracts name, address contractAddress) public {
        require(msg.sender == DIRECTORY, "20");
        contracts[uint256(name)] = contractAddress;
    }

    function _setDependencies(CoreContracts[] memory dependencies) internal {
        address[] memory _contracts = Directory(DIRECTORY).getContracts(dependencies);
        for (uint256 i; i < _contracts.length; i++) {
            contracts[uint256(dependencies[i])] = _contracts[i];
        }
    }

    function Escrow() internal view returns (IEscrowCallable) {
        return IEscrowCallable(contracts[uint256(CoreContracts.Escrow)]);
    }

    function Portfolios() internal view returns (IPortfoliosCallable) {
        return IPortfoliosCallable(contracts[uint256(CoreContracts.Portfolios)]);
    }

    function calledByEscrow() internal view returns (bool) {
        return msg.sender == contracts[(uint256(CoreContracts.Escrow))];
    }

    function calledByPortfolios() internal view returns (bool) {
        return msg.sender == contracts[(uint256(CoreContracts.Portfolios))];
    }

    function calledByERC1155Token() internal view returns (bool) {
        return msg.sender == contracts[(uint256(CoreContracts.ERC1155Token))];
    }

    function calledByERC1155Trade() internal view returns (bool) {
        return msg.sender == contracts[(uint256(CoreContracts.ERC1155Trade))];
    }
}