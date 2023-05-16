/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// File: @chainlink/contracts/src/v0.8/AutomationBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol

pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/AutomationCompatible.sol

pragma solidity ^0.8.0;


abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// File: Mint.sol

pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
interface IReadProxyAddressResolver {
    function target() external view returns (address);
}

interface IAddressResolver {
    function requireAndGetAddress(bytes32 name, string calldata reason)
        external
        view
        returns (address);
}

interface ISupplySchedule {
    // Views
    function mintableSupply() external view returns (uint);

    function isMintable() external view returns (bool);
}

interface ISynthetix {
    function mint() external returns (bool);
}

contract HorizonMint is AutomationCompatibleInterface {
    bytes32 internal constant CONTRACT_SUPPLYSCHEDULE = "SupplySchedule";
    bytes32 internal constant CONTRACT_SYNTHETIX = "Synthetix";

    IReadProxyAddressResolver public readProxyAddressResolver;

    constructor(address _readProxyAddressResolver) {
        readProxyAddressResolver = IReadProxyAddressResolver(
            _readProxyAddressResolver
        );
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;

        bool isMintable = supplySchedule().isMintable();

        if (isMintable) {
            upkeepNeeded = true;
            performData = checkData;
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        bool isMintable = supplySchedule().isMintable();

        if (isMintable) {
            synthetix().mint();
        }
    }

    function addressResolver() public view returns (IAddressResolver) {
        return IAddressResolver(readProxyAddressResolver.target());
    }

    function supplySchedule() public view returns (ISupplySchedule) {
        return
            ISupplySchedule(
                addressResolver().requireAndGetAddress(
                    CONTRACT_SUPPLYSCHEDULE,
                    "Missing SupplySchedule contract"
                )
            );
    }

    function synthetix() public view returns (ISynthetix) {
        return
            ISynthetix(
                addressResolver().requireAndGetAddress(
                    CONTRACT_SYNTHETIX,
                    "Missing Synthetix contract"
                )
            );
    }
}