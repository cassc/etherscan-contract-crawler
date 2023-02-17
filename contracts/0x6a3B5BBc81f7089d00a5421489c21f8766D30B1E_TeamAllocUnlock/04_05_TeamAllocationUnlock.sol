// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// Chainlink Automation
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

// Local
import { IVestedAlloc } from "../interfaces/IVestedAlloc.sol";

/**************************************

    Team Allocation Unlock contract

    ------------------------------

    This contract is deployed and prepared for Chainlink Automation (https://automation.chain.link)
    to track Vested Allocation smart contract and trigger unlocking Team Reserve when Tholos will reach 1 USDT price.

**************************************/

contract TeamAllocUnlock is AutomationCompatibleInterface {

    // constants
    uint8 constant public TEAM_PRICE_RELEASE_NO = 0;
    uint32 constant public ONE_USDT = 1000000;

    // contracts
    IVestedAlloc public vestedAlloc;

    // storage
    bool public allocUnlocked = false;

    /**************************************

        Constructor

    **************************************/

    constructor (address _vestedAllocAddress) {

        // storage
        vestedAlloc = IVestedAlloc(_vestedAllocAddress);

    }

    /**************************************

        Check upkeep

    **************************************/

    function checkUpkeep(bytes calldata _bytes) public view
    returns (bool, bytes memory) {

        // exit if already unlocked
        if (allocUnlocked == true) {
            return (false, _bytes);
        }

        // return
        return (isTholToUsdtOne(), _bytes);

    }

    /**************************************

        Perform upkeep

    **************************************/

    function performUpkeep(bytes calldata) external override {

        // revalidate check upkeep
        if (allocUnlocked == false && isTholToUsdtOne()) {

            // unlock
            vestedAlloc.unlockReserve(IVestedAlloc.ReserveType.TEAM, TEAM_PRICE_RELEASE_NO);

            // set storage
            allocUnlocked = true;

        }

    }

    /**************************************

        Is price equal 1 USDT

    **************************************/

    function isTholToUsdtOne() public view
    returns (bool) {

        // return
        return vestedAlloc.tholToUsdt() >= ONE_USDT;

    }

}