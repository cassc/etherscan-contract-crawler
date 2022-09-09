// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IBotWorker.sol";
import "./IBCertToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FarmCertTokenModule is IBCertToken { 

    constructor(IConfigurator config) IBCertToken(config) {

    }

    function moduleInfo() external pure override
        returns(string memory name, string memory version, bytes32 moduleId)
    {
        name = "FarmCertTokenHandler";
        version = "v0.1.20220501";
        moduleId = CertTokenHandlerID;
    }

    function deposit(address worker, address platformToken, uint amount) external ownedBotOrOwner {
        if (isNativeAsset()) {
            // TODO handle native asset
        } else {
            uint balance = _asset.balanceOf(address(this));
            require(amount <= balance && balance - amount >= totalLiquid(), 
                    Errors.FTM_INSUFFICICIENT_AMOUNT_TO_DEPOSIT);
            _asset.approve(worker, amount);
            IBotWorker(worker).deposit(platformToken, amount);
        }
    }

    function widthdraw(address worker, address platformToken, uint amount) external ownedBotOrOwner {
        if (isNativeAsset()) {
            // TODO handle native asset
        } else {
            IBotWorker(worker).withdraw(platformToken, amount);
        }
    }
}