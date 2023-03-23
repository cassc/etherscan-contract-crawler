// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../../utils.sol";
import "../caller/IWavesCaller.sol";
import "../Adapter.sol";
import "./IMint.sol";

contract WavesMintAdapter is Adapter, IMint {
    IWavesCaller public protocolCaller;
    string public executionContract;

    function init(
        address admin_,
        address protocolCaller_,
        address rootAdapter_,
        string calldata executionContract_
    ) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        require(protocolCaller_ != address(0), "zero address");
        require(rootAdapter_ != address(0), "zero address");
        admin = admin_;
        pauser = admin_;
        protocolCaller = IWavesCaller(protocolCaller_);
        rootAdapter = rootAdapter_;
        executionContract = executionContract_;
        isInited = true;
    }

    function mintTokens(
        uint16 executionChainId_,
        string calldata token_,
        uint256 amount_,
        string calldata recipient_,
        uint256 gaslessReward_,
        string calldata referrer_,
        uint256 referrerFee_
    ) external override whenInitialized whenNotPaused onlyRootAdapter {
        string[] memory args = new string[](7);
        args[0] = ""; // require empty string (see WavesCaller CIP)
        args[1] = token_;
        args[2] = Utils.U256ToHex(amount_);
        args[3] = recipient_;
        args[4] = Utils.U256ToHex(gaslessReward_);
        args[5] = referrer_;
        args[6] = Utils.U256ToHex(referrerFee_);
        protocolCaller.call(
            executionChainId_,
            executionContract,
            "mintTokens",
            args
        );
    }
}