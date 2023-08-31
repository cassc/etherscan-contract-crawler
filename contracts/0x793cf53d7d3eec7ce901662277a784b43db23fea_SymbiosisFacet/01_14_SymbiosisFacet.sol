pragma solidity 0.8.17;

import "../libraries/LibDiamond.sol";
import "../libraries/LibData.sol";
import "../libraries/LibPlexusUtil.sol";
import "../libraries/SafeERC20.sol";
import "../interfaces/IBridge.sol";
import "../interfaces/ISymbiosis.sol";
import "../Helpers/ReentrancyGuard.sol";

contract SymbiosisFacet is ReentrancyGuard, IBridge, ISymbiosis {
    using SafeERC20 for IERC20;

    bytes32 internal constant NAMESPACE = keccak256("com.plexus.facets.symbiosis");

    struct Biosis {
        address symbiosis;
        address approveAddress;
    }

    function setBiosis(address _biosis, address _approveAddress) external {
        Biosis storage s = getStorage();
        require(msg.sender == LibDiamond.contractOwner());
        s.symbiosis = _biosis;
        s.approveAddress = _approveAddress;
    }

    function getBiosis() public view returns (address) {
        Biosis storage s = getStorage();
        return s.symbiosis;
    }

    function getApproveAddress() public view returns (address) {
        Biosis storage s = getStorage();
        return s.approveAddress;
    }

    function bridgeToSymbiosis(BridgeData memory _bridgeData, bytes memory _symbiosis) external payable {
        LibPlexusUtil._isTokenDeposit(_bridgeData.srcToken, _bridgeData.amount);
        address router = getBiosis();
        address approveAddress = getApproveAddress();
        bool isNotNative = !LibPlexusUtil._isNative(_bridgeData.srcToken);
        if (isNotNative) {
            IERC20(_bridgeData.srcToken).safeApprove(approveAddress, _bridgeData.amount);
        }
        (bool succ, ) = router.call{value: msg.value}(_symbiosis);
        if (succ) {
            if (isNotNative) {
                IERC20(_bridgeData.srcToken).safeApprove(approveAddress, 0);
            }
            emit LibData.Bridge(msg.sender, _bridgeData.dstChainId, _bridgeData.srcToken, _bridgeData.amount, _bridgeData.plexusData);
        } else revert();
    }

    function swapAndBridgeToSymbiosis(SwapData calldata _swap, BridgeData memory _bridgeData, bytes calldata _symBiosisData) external payable {
        _bridgeData.amount = LibPlexusUtil._tokenDepositAndSwap(_swap);
        bytes memory data = encodeCalldataWithOverride(_symBiosisData, _bridgeData.amount);
        bool isNotNative = !LibPlexusUtil._isNative(_bridgeData.srcToken);
        address router = getBiosis();
        address approveAddress = getApproveAddress();
        if (isNotNative) {
            IERC20(_bridgeData.srcToken).safeApprove(approveAddress, _bridgeData.amount);
        }
        (bool succ, ) = router.call{value: isNotNative ? 0 : _bridgeData.amount}(data);

        if (succ) {
            if (isNotNative) {
                IERC20(_bridgeData.srcToken).safeApprove(approveAddress, 0);
            }
            emit LibData.Bridge(msg.sender, _bridgeData.dstChainId, _bridgeData.srcToken, _bridgeData.amount, _bridgeData.plexusData);
        } else revert();
    }

    function encodeCalldataWithOverride(bytes calldata beforeSymData, uint256 amount) internal view returns (bytes memory afterSymData) {
        bytes4 selector = bytes4(beforeSymData);
        if (selector == 0xa11b1198) {
            SymbiosisDescription memory _symData = abi.decode((beforeSymData[4:]), (SymbiosisDescription));
            _symData.amount = amount;
            return abi.encodeWithSelector(selector, _symData);
        } else {
            revert("Unknown selector");
        }
    }

    /// @dev fetch local storage
    function getStorage() private pure returns (Biosis storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}