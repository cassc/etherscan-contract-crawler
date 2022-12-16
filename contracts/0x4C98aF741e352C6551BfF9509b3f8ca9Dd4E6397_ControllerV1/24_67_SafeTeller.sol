pragma solidity ^0.8.7;

import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "./interfaces/IGnosisSafe.sol";
import "./interfaces/IGnosisSafeProxyFactory.sol";

contract SafeTeller {
    using Address for address;

    // mainnet: 0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B;
    address public immutable proxyFactoryAddress;

    // mainnet: 0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F;
    address public immutable gnosisMasterAddress;
    address public immutable fallbackHandlerAddress;

    string public constant FUNCTION_SIG_SETUP =
        "setup(address[],uint256,address,bytes,address,address,uint256,address)";
    string public constant FUNCTION_SIG_EXEC =
        "execTransaction(address,uint256,bytes,uint8,uint256,uint256,uint256,address,address,bytes)";

    string public constant FUNCTION_SIG_ENABLE = "delegateSetup(address)";

    bytes4 public constant ENCODED_SIG_ENABLE_MOD =
        bytes4(keccak256("enableModule(address)"));
    bytes4 public constant ENCODED_SIG_DISABLE_MOD =
        bytes4(keccak256("disableModule(address,address)"));
    bytes4 public constant ENCODED_SIG_SET_GUARD =
        bytes4(keccak256("setGuard(address)"));

    address internal constant SENTINEL = address(0x1);

    // pods with admin have modules locked by default
    mapping(address => bool) public areModulesLocked;

    /**
     * @param _proxyFactoryAddress The proxy factory address
     * @param _gnosisMasterAddress The gnosis master address
     */
    constructor(
        address _proxyFactoryAddress,
        address _gnosisMasterAddress,
        address _fallbackHanderAddress
    ) {
        proxyFactoryAddress = _proxyFactoryAddress;
        gnosisMasterAddress = _gnosisMasterAddress;
        fallbackHandlerAddress = _fallbackHanderAddress;
    }

    /**
     * @param _safe The address of the safe
     * @param _newSafeTeller The address of the new safe teller contract
     */
    function migrateSafeTeller(
        address _safe,
        address _newSafeTeller,
        address _prevModule
    ) internal {
        // add new safeTeller
        bytes memory enableData = abi.encodeWithSignature(
            "enableModule(address)",
            _newSafeTeller
        );

        bool enableSuccess = IGnosisSafe(_safe).execTransactionFromModule(
            _safe,
            0,
            enableData,
            IGnosisSafe.Operation.Call
        );
        require(enableSuccess, "Migration failed on enable");

        // validate prevModule of current safe teller
        (address[] memory moduleBuffer, ) = IGnosisSafe(_safe)
            .getModulesPaginated(_prevModule, 1);
        require(moduleBuffer[0] == address(this), "incorrect prevModule");

        // disable current safeTeller
        bytes memory disableData = abi.encodeWithSignature(
            "disableModule(address,address)",
            _prevModule,
            address(this)
        );

        bool disableSuccess = IGnosisSafe(_safe).execTransactionFromModule(
            _safe,
            0,
            disableData,
            IGnosisSafe.Operation.Call
        );
        require(disableSuccess, "Migration failed on disable");
    }

    /**
     * @dev sets the safeteller as safe guard, called after migration
     * @param _safe The address of the safe
     */
    function setSafeGuard(address _safe, address guard) internal {
        bytes memory transferData = abi.encodeWithSignature(
            "setGuard(address)",
            guard
        );

        bool guardSuccess = IGnosisSafe(_safe).execTransactionFromModule(
            _safe,
            0,
            transferData,
            IGnosisSafe.Operation.Call
        );
        require(guardSuccess, "Could not set guard");
    }

    function getSafeMembers(address safe)
        public
        view
        returns (address[] memory)
    {
        return IGnosisSafe(safe).getOwners();
    }

    function isSafeModuleEnabled(address safe) public view returns (bool) {
        return IGnosisSafe(safe).isModuleEnabled(address(this));
    }

    function isSafeMember(address safe, address member)
        public
        view
        returns (bool)
    {
        return IGnosisSafe(safe).isOwner(member);
    }

    /**
     * @param _owners The  addresses to be owners of the safe
     * @param _threshold The number of owners that are required to sign a transaciton
     * @return safeAddress The address of the new safe
     */
    function createSafe(
        address[] memory _owners,
        uint256 _threshold,
        uint256 _salt
    ) internal returns (address safeAddress) {
        bytes memory data = abi.encodeWithSignature(
            FUNCTION_SIG_ENABLE,
            address(this)
        );

        // encode the setup call that will be called on the new proxy safe
        // from the proxy factory
        bytes memory setupData = abi.encodeWithSignature(
            FUNCTION_SIG_SETUP,
            _owners,
            _threshold,
            this,
            data,
            fallbackHandlerAddress,
            address(0),
            uint256(0),
            address(0)
        );

        try
            IGnosisSafeProxyFactory(proxyFactoryAddress).createProxyWithNonce(
                gnosisMasterAddress,
                setupData,
                _salt
            )
        returns (address newSafeAddress) {
            return newSafeAddress;
        } catch (bytes memory) {
            revert("Create Proxy With Data Failed");
        }
    }

    /**
     * Uses CREATE2 to replicate a given safe on a new network.
     * @param members The addresses of the members of the pod as it was originally created.
     * @param threshold The number of members that are required to sign a transaction
     * @param podId - Pod ID of safe you are trying to recreate
     */
    function recoverSafe(
        address[] calldata members,
        uint256 threshold,
        uint256 podId
    ) external returns (address) {
        return createSafe(members, threshold, podId);
    }

    /**
     * @param to The account address to add as an owner
     * @param safe The address of the safe
     */
    function onMint(address to, address safe) internal {
        uint256 threshold = IGnosisSafe(safe).getThreshold();

        bytes memory data = abi.encodeWithSignature(
            "addOwnerWithThreshold(address,uint256)",
            to,
            threshold
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            data,
            IGnosisSafe.Operation.Call
        );

        require(success, "Module Transaction Failed");
    }

    /**
     * @param from The address to be removed as an owner
     * @param safe The address of the safe
     */
    function onBurn(address from, address safe) internal {
        uint256 threshold = IGnosisSafe(safe).getThreshold();
        address[] memory owners = IGnosisSafe(safe).getOwners();

        //look for the address pointing to address from
        address prevFrom = address(0);
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == from) {
                if (i == 0) {
                    prevFrom = SENTINEL;
                } else {
                    prevFrom = owners[i - 1];
                }
            }
        }
        if (owners.length - 1 < threshold) threshold -= 1;
        bytes memory data = abi.encodeWithSignature(
            "removeOwner(address,address,uint256)",
            prevFrom,
            from,
            threshold
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            data,
            IGnosisSafe.Operation.Call
        );
        require(success, "Module Transaction Failed");
    }

    /**
     * @param from The address being removed as an owner
     * @param to The address being added as an owner
     * @param safe The address of the safe
     */
    function onTransfer(
        address from,
        address to,
        address safe
    ) internal {
        address[] memory owners = IGnosisSafe(safe).getOwners();

        //look for the address pointing to address from
        address prevFrom;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == from) {
                if (i == 0) {
                    prevFrom = SENTINEL;
                } else {
                    prevFrom = owners[i - 1];
                }
            }
        }

        bytes memory data = abi.encodeWithSignature(
            "swapOwner(address,address,address)",
            prevFrom,
            from,
            to
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            safe,
            0,
            data,
            IGnosisSafe.Operation.Call
        );
        require(success, "Module Transaction Failed");
    }

    /**
     * @dev This will execute a tx from the safe that will update the safe's ENS in the reverse resolver
     * @param safe safe address
     * @param reverseRegistrar The ENS default reverseRegistar
     * @param _ensString string of pod ens name (i.e.'mypod.pod.xyz')
     */
    function setupSafeReverseResolver(
        address safe,
        address reverseRegistrar,
        string memory _ensString
    ) internal virtual {
        bytes memory data = abi.encodeWithSignature(
            "setName(string)",
            _ensString
        );

        bool success = IGnosisSafe(safe).execTransactionFromModule(
            reverseRegistrar,
            0,
            data,
            IGnosisSafe.Operation.Call
        );
        require(success, "Module Transaction Failed");
    }

    /**
     * @dev This will be called by the safe at tx time and prevent module disable on pods with admins
     * @param safe safe address
     * @param isLocked safe address
     */
    function setModuleLock(address safe, bool isLocked) internal {
        areModulesLocked[safe] = isLocked;
    }

    function safeTellerCheck(bytes memory data) internal pure {
        require(
            bytes4(data) != ENCODED_SIG_ENABLE_MOD,
            "Cannot Enable Modules"
        );
        require(
            bytes4(data) != ENCODED_SIG_DISABLE_MOD,
            "Cannot Disable Modules"
        );
        require(bytes4(data) != ENCODED_SIG_SET_GUARD, "Cannot Change Guard");
    }

    /**
     * Removes the reverse registrar entry and disables module.
     * Intended as clean up during the safe ejection process.
     * Note that an already ejected safe cannot clear the reverse registry entry.
     */
    function disableModule(
        address safe,
        address reverseRegistrar,
        address previousModule
    ) internal {
        IGnosisSafe safeContract = IGnosisSafe(safe);

        // Note that you cannot clear the reverse registry entry of an already ejected safe.
        bytes memory nameData = abi.encodeWithSignature("setName(string)", "");
        safeContract.execTransactionFromModule(
            reverseRegistrar,
            0,
            nameData,
            IGnosisSafe.Operation.Call
        );

        // remove controller as guard
        bytes memory guardData = abi.encodeWithSignature(
            "setGuard(address)",
            address(0)
        );

        safeContract.execTransactionFromModule(
            safe,
            0,
            guardData,
            IGnosisSafe.Operation.Call
        );

        // disable module
        bytes memory moduleData = abi.encodeWithSignature(
            "disableModule(address,address)",
            previousModule,
            address(this)
        );

        safeContract.execTransactionFromModule(
            safe,
            0,
            moduleData,
            IGnosisSafe.Operation.Call
        );
    }

    // TODO: move to library
    // Used in a delegate call to enable module add on setup
    function enableModule(address module) external {
        require(module == address(0));
    }

    function delegateSetup(address _context) external {
        this.enableModule(_context);
    }
}