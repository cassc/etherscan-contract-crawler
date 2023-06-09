/* solhint-disable avoid-low-level-calls*/
/* solhint-disable no-inline-assembly */
/* solhint-disable no-complex-fallback */
// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./routers/IRouter.sol";
import "./adapters/IAdapter.sol";
import "./TokenTransferProxy.sol";
import "./ITokenTransferProxy.sol";
import "./AugustusStorage.sol";

contract AugustusSwapper is AugustusStorage, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event AdapterInitialized(address indexed adapter);

    event RouterInitialized(address indexed router);

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "caller is not the admin");
        _;
    }

    constructor(address payable _feeWallet) public {
        TokenTransferProxy lTokenTransferProxy = new TokenTransferProxy();
        tokenTransferProxy = ITokenTransferProxy(lTokenTransferProxy);
        feeWallet = _feeWallet;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*solhint-disable no-empty-blocks*/
    receive() external payable {}

    /*solhint-enable no-empty-blocks*/

    fallback() external payable {
        bytes4 selector = msg.sig;
        //Figure out the router contract for the given function
        address implementation = getImplementation(selector);
        if (implementation == address(0)) {
            _revertWithData(abi.encodeWithSelector(bytes4(keccak256("NotImplementedError(bytes4)")), selector));
        }

        //Delegate call to the router
        (bool success, bytes memory resultData) = implementation.delegatecall(msg.data);
        if (!success) {
            _revertWithData(resultData);
        }

        _returnWithData(resultData);
    }

    function initializeAdapter(address adapter, bytes calldata data) external onlyAdmin {
        require(hasRole(WHITELISTED_ROLE, adapter), "Exchange not whitelisted");
        (bool success, ) = adapter.delegatecall(abi.encodeWithSelector(IAdapter.initialize.selector, data));
        require(success, "Failed to initialize adapter");
        emit AdapterInitialized(adapter);
    }

    function initializeRouter(address router, bytes calldata data) external onlyAdmin {
        require(hasRole(ROUTER_ROLE, router), "Router not whitelisted");
        (bool success, ) = router.delegatecall(abi.encodeWithSelector(IRouter.initialize.selector, data));
        require(success, "Failed to initialize router");
        emit RouterInitialized(router);
    }

    function getImplementation(bytes4 selector) public view returns (address) {
        return selectorVsRouter[selector];
    }

    function getVersion() external pure returns (string memory) {
        return "5.0.0";
    }

    function getPartnerFeeStructure(address partner) public view returns (FeeStructure memory) {
        return registeredPartners[partner];
    }

    function getFeeWallet() external view returns (address) {
        return feeWallet;
    }

    function setFeeWallet(address payable _feeWallet) external onlyAdmin {
        require(_feeWallet != address(0), "Invalid address");
        feeWallet = _feeWallet;
    }

    function registerPartner(
        address partner,
        uint256 _partnerShare,
        bool _noPositiveSlippage,
        bool _positiveSlippageToUser,
        uint16 _feePercent,
        string calldata partnerId,
        bytes calldata _data
    ) external onlyAdmin {
        require(partner != address(0), "Invalid partner");
        FeeStructure storage feeStructure = registeredPartners[partner];
        require(feeStructure.partnerShare == 0, "Already registered");
        require(_partnerShare > 0 && _partnerShare < 10000, "Invalid values");
        require(_feePercent <= 10000, "Invalid values");

        feeStructure.partnerShare = _partnerShare;
        feeStructure.noPositiveSlippage = _noPositiveSlippage;
        feeStructure.positiveSlippageToUser = _positiveSlippageToUser;
        feeStructure.partnerId = partnerId;
        feeStructure.feePercent = _feePercent;
        feeStructure.data = _data;
    }

    function setImplementation(bytes4 selector, address implementation) external onlyAdmin {
        require(hasRole(ROUTER_ROLE, implementation), "Router is not whitelisted");
        selectorVsRouter[selector] = implementation;
    }

    /**
     * @dev Allows admin of the contract to transfer any tokens which are assigned to the contract
     * This method is for safety if by any chance tokens or ETHs are assigned to the contract by mistake
     * @dev token Address of the token to be transferred
     * @dev destination Recepient of the token
     * @dev amount Amount of tokens to be transferred
     */
    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) external onlyAdmin {
        if (amount > 0) {
            if (token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
                require(result, "Failed to transfer Ether");
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function isAdapterInitialized(bytes32 key) public view returns (bool) {
        return adapterInitialized[key];
    }

    function getAdapterData(bytes32 key) public view returns (bytes memory) {
        return adapterVsData[key];
    }

    function isRouterInitialized(bytes32 key) public view returns (bool) {
        return routerInitialized[key];
    }

    function getRouterData(bytes32 key) public view returns (bytes memory) {
        return routerData[key];
    }

    function getTokenTransferProxy() public view returns (address) {
        return address(tokenTransferProxy);
    }

    function _revertWithData(bytes memory data) private pure {
        assembly {
            revert(add(data, 32), mload(data))
        }
    }

    function _returnWithData(bytes memory data) private pure {
        assembly {
            return(add(data, 32), mload(data))
        }
    }
}