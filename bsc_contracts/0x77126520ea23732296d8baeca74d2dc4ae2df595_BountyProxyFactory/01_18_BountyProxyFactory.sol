// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";
import "./BountyProxy.sol";
import "./IBountyProxyFactory.sol";
import "./BountyPool.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract BountyProxyFactory is Ownable, Initializable {
    using Clones for address;
    /// PUBLIC STORAGE ///

    address public bountyProxyBase;

    address public manager;

    uint256 public constant VERSION = 1;

    /// INTERNAL STORAGE ///

    /// @dev Internal mapping to track all deployed proxies.
    mapping(address => bool) internal _proxies;

    function initiliaze(address payable _bountyProxyBase, address _manager)
        external
        initializer
        onlyOwner
    {
        bountyProxyBase = _bountyProxyBase;
        manager = _manager;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    function deployBounty(address _beacon, bytes memory _data)
        public
        onlyManager
        returns (BountyPool proxy)
    {
        proxy = BountyPool(bountyProxyBase.clone());

        BountyProxy newBounty = BountyProxy(payable(address(proxy)));
        newBounty.initialize(_beacon, _data, msg.sender);
        // proxy.initializeImplementation(msg.sender);
    }
}