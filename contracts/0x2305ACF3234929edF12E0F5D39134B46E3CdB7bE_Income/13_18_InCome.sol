// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./RootDB.sol";

contract Income {

    /// the address of  torn ROOT_DB contract
    address immutable public ROOT_DB;
    /// the address of  torn token contract
    address immutable  public TORN_CONTRACT;


    /// @notice An event emitted when operator distribute torn
    /// @param torn: the amount of the TORN distributed
    event DistributeTorn(uint256 torn);


    constructor(
        address tornContract,
        address rootDb
    ) {
        TORN_CONTRACT = tornContract;
        ROOT_DB = rootDb;
    }
    /**
      * @notice distributeTorn used to distribute TORN to deposit contract which belong to stakes
      * @param tornQty the amount of TORN
   **/
    function distributeTorn(uint256 tornQty) external {
        address deposit_address = RootDB(ROOT_DB).depositContract();
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(TORN_CONTRACT), deposit_address, tornQty);
        emit DistributeTorn(tornQty);
    }

    receive() external payable {

    }

}