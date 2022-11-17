pragma solidity ^0.8.0;

import {Address} from "../openzeppelin/utils/Address.sol";
import {ClonesUpgradeable} from "../openzeppelin/upgradeable/proxy/ClonesUpgradeable.sol";
import {ITreasury, IERC20} from "../../interfaces/ITreasury.sol";
import {ISettings} from "../../interfaces/ISettings.sol";

library TokenVaultTreasuryLogic {
    //
    function newTreasuryInstance(
        address settings,
        address vaultToken,
        uint256 exitLength
    ) external returns (address) {
        uint256 epochDuration = ISettings(settings).epochDuration();
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address,uint256,uint256)",
            vaultToken,
            epochDuration,
            (exitLength / epochDuration)
        );
        address treasury = ClonesUpgradeable.clone(
            ISettings(settings).treasuryTpl()
        );
        Address.functionCall(treasury, _initializationCalldata);
        return treasury;
    }

    function addRewardToken(address treasury, address token) external {
        ITreasury(treasury).addRewardToken(token);
    }

    function end(address treasury) external {
        ITreasury(treasury).end();
    }

    function getPoolBalanceToken(address treasury, address token)
        external
        view
        returns (uint256)
    {
        return ITreasury(treasury).getPoolBalanceToken(IERC20(token));
    }

    function getBalanceVeToken(address treasury)
        external
        view
        returns (uint256)
    {
        return ITreasury(treasury).getBalanceVeToken();
    }

    function stakingInitialize(address treasury, uint256 _stakingLength)
        external
    {
        uint256 _epochTotal = 0;
        if (_stakingLength > 0) {
            _epochTotal = (_stakingLength /
                ITreasury(treasury).epochDuration());
        }
        ITreasury(treasury).stakingInitialize(_epochTotal);
    }

    function shareTreasuryRewardToken(address treasury) external {
        ITreasury(treasury).shareTreasuryRewardToken();
    }

    function initializeGovernorToken(address treasury) external {
        ITreasury(treasury).initializeGovernorToken();
    }
}