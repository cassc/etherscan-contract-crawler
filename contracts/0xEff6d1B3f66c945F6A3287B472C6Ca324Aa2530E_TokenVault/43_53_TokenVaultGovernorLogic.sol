pragma solidity ^0.8.0;

import {Address} from "../openzeppelin/utils/Address.sol";
import {ClonesUpgradeable} from "../openzeppelin/upgradeable/proxy/ClonesUpgradeable.sol";
import {ISettings} from "../../interfaces/ISettings.sol";
import {IVault} from "../../interfaces/IVault.sol";

library TokenVaultGovernorLogic {
    //
    bytes4 public constant VOTE_TARGET_CALL_FUNCTION = 0xcc043ed6; //bytes4(keccak256(bytes('proposalTargetCall(address,uint256,bytes)'))) =>0xcc043ed6
    bytes4 public constant CAST_VOTE_CALL_FUNCTION = 0x56781388; //bytes4(keccak256(bytes('castVote(uint256,uint8)'))) ==> 0x56781388

    function newGovernorInstance(
        address settings,
        address vaultToken,
        address veToken,
        uint256 supply,
        uint256 delayBlock,
        uint256 periodBlock
    ) external returns (address) {
        ISettings _settings = ISettings(settings);
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address,address,uint256,uint256,uint256,uint256)",
            vaultToken,
            veToken,
            _settings.votingQuorumPercent(),
            delayBlock,
            periodBlock,
            ((supply * _settings.votingMinTokenPercent()) / 10000)
        );
        address government = ClonesUpgradeable.clone(
            ISettings(settings).governmentTpl()
        );
        Address.functionCall(government, _initializationCalldata);
        return government;
    }

    function validTargetCallFunction(bytes calldata _data)
        internal
        pure
        returns (bool)
    {
        if (VOTE_TARGET_CALL_FUNCTION == bytes4(bytes(_data[:4]))) {
            return true;
        }
        return false;
    }

    function decodeTargetCallParams(bytes calldata _data)
        internal
        pure
        returns (
            address target,
            uint256 value,
            bytes memory data
        )
    {
        (target, value, data) = abi.decode(
            _data[4:],
            (address, uint256, bytes)
        );
        return (target, value, data);
    }

    function decodeCastVoteData(bytes calldata _data)
        public
        pure
        returns (uint256, uint8)
    {
        bytes4 funcName = bytes4(bytes(_data[:4]));
        if (CAST_VOTE_CALL_FUNCTION == funcName) {
            (uint256 proposalId, uint8 value) = abi.decode(
                _data[4:],
                (uint256, uint8)
            );
            return (proposalId, value);
        }
        return (0, 0);
    }
}