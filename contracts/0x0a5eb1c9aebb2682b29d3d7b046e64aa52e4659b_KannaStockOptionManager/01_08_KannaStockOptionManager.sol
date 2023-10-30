// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {KannaStockOption} from "./KannaStockOption.sol";
import {IKannaStockOption} from "./interfaces/IKannaStockOption.sol";

/**
 *   __
 *  |  | ___\|/_     ____    ____  _\|/_
 *  |  |/ /\__  \   /    \  /    \ \__  \
 *  |    <  / __ \_|   |  \|   |  \ / __ \_
 *  |__|_ \(____  /|___|  /|___|  /(____  /
 *       \/     \/      \/      \/      \/
 *            __                    __                       __   .__
 *    _______/  |_   ____    ____  |  | __   ____  ______  _/  |_ |__|  ____    ____
 *   /  ___/\   __\ /  _ \ _/ ___\ |  |/ /  /  _ \ \____ \ \   __\|  | /  _ \  /    \
 *   \___ \  |  |  (  <_> )\  \___ |    <  (  <_> )|  |_> > |  |  |  |(  <_> )|   |  \
 *  /____  > |__|   \____/  \___  >|__|_ \  \____/ |   __/  |__|  |__| \____/ |___|  /
 *       \/                     \/      \/         |__|                            \/
 *
 *  @title KNN Stock Option Manager
 *  @author KANNA Team
 *  @custom:github  https://github.com/kanna-coin
 *  @custom:site https://kannacoin.io
 *  @custom:discord https://discord.kannacoin.io
 */
contract KannaStockOptionManager is Ownable {
    uint16 private _nonce;
    mapping(address => bool) private _contractsMap;
    address[] private _contracts;

    address public contractTemplate;

    event ContractTemplateUpdated(
        address contractAddress
    );

    event ContractRegistered(
        address contractAddress,
        uint16 nonce
    );

    event ContractUnregistered(
        address contractAddress
    );

    /**
     * @dev Update StockOptionPool contract template
     */
    function updateTemplate(address _contractTemplate) public onlyOwner {
        require(
            IKannaStockOption(_contractTemplate).supportsInterface(type(IKannaStockOption).interfaceId),
            "`_contractTemplate` needs to implement `IKannaStockOption` interface"
        );

        contractTemplate = _contractTemplate;

        emit ContractTemplateUpdated(contractTemplate);
    }

    /**
     * @dev Deploy a new contract
     */
    function deployContract() public onlyOwner hasTemplateDefined {
        bytes32 _salt = keccak256(abi.encodePacked(_nonce, block.timestamp));

        address newContract = createClone(_salt, contractTemplate);

        _registerContract(newContract);
    }

    /**
     * @dev Register a new contract
     */
    function registerContract(address _contract) public onlyOwner {
        require(
            IKannaStockOption(_contract).supportsInterface(type(IKannaStockOption).interfaceId),
            "`_contract` needs to implement `IKannaStockOption` interface"
        );

        _registerContract(_contract);
    }

    /**
     * @dev Register a new contract
     */
    function registerContractUnsafe(address _contract) public onlyOwner {
        _registerContract(_contract);
    }

    /**
     * @dev Unregister a contract
     */
    function unregisterContract(address _contract) public onlyOwner {
        require(_contractsMap[_contract], "Contract not registered");

        _contractsMap[_contract] = false;

        for (uint256 i; i<_contracts.length; i++) {
            if (_contracts[i] == _contract) {
                _contracts[i] = _contracts[_contracts.length - 1];
                _contracts.pop();
                break;
            }
        }

        emit ContractUnregistered(_contract);
    }

    function contracts() public view returns (address[] memory) {
        return _contracts;
    }

    function hasContract(address _contract) public view returns (bool) {
        return _contractsMap[_contract];
    }

    function totalVested() public view returns (uint256) {
        uint256 _totalVested = 0;

        for (uint i=0; i<_contracts.length; i++) {
            try IKannaStockOption(_contracts[i]).totalVested() returns(uint256 contractTotalVested) {
                _totalVested += contractTotalVested;
            } catch Error(string memory /*reason*/) {
            } catch (bytes memory /*lowLevelData*/) {}
        }

        return _totalVested;
    }

    function vestingForecast(uint256 date) public view returns (uint256) {
        uint256 _vestingForecast = 0;

        for (uint i=0; i<_contracts.length; i++) {
            try IKannaStockOption(_contracts[i]).vestingForecast(date) returns(uint256 contractVestingForecast) {
                _vestingForecast += contractVestingForecast;
            } catch Error(string memory /*reason*/) {
            } catch (bytes memory /*lowLevelData*/) {}
        }

        return _vestingForecast;
    }

    function availableToWithdraw() public view returns (uint256) {
        uint256 _availableToWithdraw = 0;

        for (uint i=0; i<_contracts.length; i++) {
            try IKannaStockOption(_contracts[i]).availableToWithdraw() returns(uint256 contractAvailableToWithdraw) {
                _availableToWithdraw += contractAvailableToWithdraw;
            } catch Error(string memory /*reason*/) {
            } catch (bytes memory /*lowLevelData*/) {}
        }

        return _availableToWithdraw;
    }

    // creates clone using minimal proxy
    function createClone(bytes32 _salt, address _target) internal returns (address _result) {
        bytes20 _targetBytes = bytes20(_target);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), _targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            _result := create2(0, clone, 0x37, _salt)
        }

        require(_result != address(0), "Create2: Failed on minimal deploy");
    }

    /**
     * @dev Register a new contract
     */
    function _registerContract(address _contract) private {
        require(_contractsMap[_contract] == false, "Contract already registered");

        _contracts.push(_contract);
        _contractsMap[_contract] = true;

        emit ContractRegistered(_contract, ++_nonce);
    }

    modifier hasTemplateDefined() {
        require(contractTemplate != address(0), "Contract template not defined");
        _;
    }
}