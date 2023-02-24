pragma solidity ^0.8.1;

import "./Administrable.sol";
import "./interfaces/IAnycallV6Proxy.sol";
import "./interfaces/IExecutor.sol";

abstract contract AnyCallApp is Administrable {
    uint256 public flag; // 0: pay on dest chain, 2: pay on source chain
    address public immutable anyCallProxy;

    mapping(uint256 => address) internal peer;

    event SetPeers(uint256[] chainIDs, address[] peers);
    event SetAnyCallProxy(address proxy);

    modifier onlyExecutor() {
        require(msg.sender == IAnycallV6Proxy(anyCallProxy).executor());
        _;
    }

    constructor (address anyCallProxy_, uint256 flag_) {
        anyCallProxy = anyCallProxy_;
        flag = flag_;
    }

    function setPeers(uint256[] memory chainIDs, address[] memory  peers) public onlyAdmin {
        for (uint i = 0; i < chainIDs.length; i++) {
            peer[chainIDs[i]] = peers[i];
            emit SetPeers(chainIDs, peers);
        }
    }

    function getPeer(uint256 foreignChainID) external view returns (address) {
        return peer[foreignChainID];
    }

    /**
     * @dev Uncomment this function if the app owner wants full control of the contract.
     */
    //function setAnyCallProxy(address proxy) public onlyAdmin {
    //    anyCallProxy = proxy;
    //    emit SetAnyCallProxy(proxy);
    //}

    function _anyExecute(uint256 fromChainID, bytes calldata data) internal virtual returns (bool success, bytes memory result);

    function _anyCall(address _to, bytes memory _data, address _fallback, uint256 _toChainID) internal {
        if (flag == 2) {
            IAnycallV6Proxy(anyCallProxy).anyCall{value: msg.value}(_to, _data, _fallback, _toChainID, flag);
        } else {
            IAnycallV6Proxy(anyCallProxy).anyCall(_to, _data, _fallback, _toChainID, flag);
        }
    }

    function anyExecute(bytes calldata data) external onlyExecutor returns (bool success, bytes memory result) {
        (address callFrom, uint256 fromChainID,) = IExecutor(IAnycallV6Proxy(anyCallProxy).executor()).context();
        require(peer[fromChainID] == callFrom, "call not allowed");
        _anyExecute(fromChainID, data);
    }

}