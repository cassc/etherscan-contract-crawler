// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

// Interfaces
import "./ILiquidInit.sol";

// Inheritance Contacts
import "./LiquidPool.sol";
import "./LiquidRouter.sol";

/**
 * @author René Hochmuth
 * @author Vitally Marinchenko
 * @author Christoph Krpoun
 */

/**
 * @dev LiquidFactory: Factory is responsible
 * for deploying new LiquidPools.
 */

contract PoolFactory {

    // Instance for router reference
    LiquidRouter immutable liquidRouter;

    // Liquid router that manages pools
    address public routerAddress;

    // Contract that all pools are cloned from
    address public defaultPoolTarget;

    // Address to manage protocol
    address public multisigAddress;

    // Simple useful counter
    uint256 public poolCount;

    /**
     * @dev Revert if msg.sender if not multisig
     */
    modifier onlyMultisig() {
        require(
            msg.sender == multisigAddress,
            "AccessControl: NOT_MULTISIG"
        );
        _;
    }

    /**
     * @dev Creates default pool target and sets router
     */
    constructor(
        address _chainLinkETH
    ) {
        multisigAddress = msg.sender;

        liquidRouter = new LiquidRouter(
            address(this),
            _chainLinkETH
        );

        routerAddress = address(
            liquidRouter
        );

        defaultPoolTarget = address(
            new LiquidPool()
        );
    }

    event PoolCreated(
        address indexed pool,
        address indexed token
    );

    event DefaultPoolTargetUpdate(
        address indexed previousDefaultPoolTarget,
        address indexed newDefaultPoolTarget
    );

    /**
     * @dev Change the default target contract.
     * Only multisig address can do this.
     */
    function updateDefaultPoolTarget(
        address _newDefaultTarget
    )
        external
        onlyMultisig
    {
        address oldDefaultPoolTarget = defaultPoolTarget;

        defaultPoolTarget = _newDefaultTarget;

        emit DefaultPoolTargetUpdate(
            oldDefaultPoolTarget,
            _newDefaultTarget
        );
    }

    /**
     * @dev Creates a copy of bytecode of defaultPoolTarget with CREATE2 opcode
     * also calls initialise to set state variables
     */
    function createLiquidPool(
        address _poolTokenAddress,
        address _chainLinkFeedAddress,
        uint256 _multiplicationFactor,
        uint256 _maxCollateralFactor,
        address[] memory _nftAddresses,
        string memory _tokenName,
        string memory _tokenSymbol
    )
        external
        onlyMultisig
        returns (address poolAddress)
    {
        poolAddress = _generatePool(
            _poolTokenAddress
        );

        require(
            _chainLinkFeedAddress > address(0),
            "PoolFactory: EMPTY_ADDRESS"
        );

        ILiquidInit(poolAddress).initialise(
            _poolTokenAddress,
            _chainLinkFeedAddress,
            _multiplicationFactor,
            _maxCollateralFactor,
            _nftAddresses,
            _tokenName,
            _tokenSymbol
        );

        liquidRouter.addLiquidPool(
            poolAddress
        );

        emit PoolCreated(
            poolAddress,
            _poolTokenAddress
        );
    }

    /**
     * @dev Deploys a pool with bytecode of defaultPoolTarget with CREATE2 opcode
     */
    function _generatePool(
        address _poolAddress
    )
        internal
        returns (address poolAddress)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                poolCount++,
                _poolAddress
            )
        );

        bytes20 targetBytes = bytes20(
            defaultPoolTarget
        );

        assembly {

            let clone := mload(0x40)

            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )

            mstore(
                add(clone, 0x14),
                targetBytes
            )

            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            poolAddress := create2(
                0,
                clone,
                0x37,
                salt
            )
        }
    }

    /**
    * @dev Pre-compute what address a future pool will exist at.
     */
    function predictPoolAddress(
        uint256 _index,
        address _pool,
        address _factory,
        address _implementation
    )
        external
        pure
        returns (address predicted)
    {
        bytes32 salt = keccak256(
            abi.encodePacked(
                _index,
                _pool
            )
        );

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, _factory))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }
}
