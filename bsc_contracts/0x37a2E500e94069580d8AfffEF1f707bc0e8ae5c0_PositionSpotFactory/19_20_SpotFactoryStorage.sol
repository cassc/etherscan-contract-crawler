// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ISpotFactory.sol";

abstract contract SpotFactoryStorage is ISpotFactory {
    address public spotHouse;

    address public positionLiquidity;

    //  baseAsset address => quoteAsset address => spotManager address
    mapping(address => mapping(address => address)) internal pathPairManagers;

    mapping(address => Pair) internal allPairManager;

    mapping(address => bool) public allowedAddressAddPair;

    // pair manager => owner
    mapping(address => address) public override ownerPairManager;

    // owner => pair manager => staking manager
    mapping(address => mapping(address => address))
        public
        override stakingManagerOfPair;

    uint32 public feeShareAmm;
    address public positionRouter;

    mapping(uint32 => address) public mappingVersionTemplate;
    uint32 public latestVersion;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}