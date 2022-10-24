// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./library/Initializable.sol";
import "./library/Ownable.sol";

import "./interface/ILSR.sol";

/**
 * @title dForce's Liquid Stability Reserve factory
 * @author dForce
 */
contract LSRFactory is Initializable, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal lsrs_;

    /// @dev Emitted When creating an LSR.
    event CreateLSR(
        address lsr,
        address implementation,
        address proxyAdmin,
        bytes data
    );

    /// @dev Emitted when `lsrs_` has been added.
    event AddLSR(address lsr);

    /// @dev Emitted when `lsrs_` has been removed.
    event RemoveLSR(address lsr);

    /**
     * @notice Only for the implementation contract, as for the proxy pattern,
     *            should call `initialize()` separately.
     */
    constructor() public {
        initialize();
    }

    /**
     * @notice Initialize Liquid Stability Reserve factory data.
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @dev Create a new LSR.
     * @param _implementation LSR's implementation address.
     * @param _proxyAdmin LSR's proxyAdmin address.
     * @param _data LSR's initialization data.
     */
    function _createLSR(
        address _implementation,
        address _proxyAdmin,
        bytes memory _data
    ) external onlyOwner {
        address _lsr = address(
            new TransparentUpgradeableProxy(_implementation, _proxyAdmin, _data)
        );
        emit CreateLSR(_lsr, _implementation, _proxyAdmin, _data);
        _addLSR(_lsr);
    }

    /**
     * @dev Add an LSR.
     * @param _lsr LSR address.
     */
    function _addLSR(address _lsr) public onlyOwner {
        require(ILSR(_lsr).mpr() != address(0), "_addLSR: is LSR contract");
        require(lsrs_.add(_lsr), "it has been sold");
        emit AddLSR(_lsr);
    }

    /**
     * @dev Remove an LSR.
     * @param _lsr LSR address.
     */
    function _removeLSR(address _lsr) public onlyOwner {
        require(lsrs_.remove(_lsr), "_removeLSR: _lsr does not exist");
        emit RemoveLSR(_lsr);
    }

    /**
     * @notice Generic call contract function.
     * @dev Call the asset's priceModel function.
     * @param _target Target contract address (`lsrs_`).
     * @param _signature Function signature.
     * @param _data Param data.
     * @return The return value of calling the target contract function.
     */
    function _execute(
        address _target,
        string memory _signature,
        bytes memory _data
    ) internal returns (bytes memory) {
        require(
            bytes(_signature).length > 0,
            "_execute: Parameter signature can not be empty!"
        );
        bytes memory _callData = abi.encodePacked(
            bytes4(keccak256(bytes(_signature))),
            _data
        );
        return _target.functionCall(_callData);
    }

    function _executeTransaction(
        address _target,
        string memory _signature,
        bytes memory _data
    ) external onlyOwner {
        _execute(_target, _signature, _data);
    }

    /**
     * @dev Get the address list of all LSRs.
     * @return _allLsrs Address list of all LSRs.
     */
    function _getAllLSRs() internal view returns (address[] memory _allLsrs) {
        EnumerableSet.AddressSet storage _lsrs = lsrs_;

        uint256 _len = _lsrs.length();
        _allLsrs = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _allLsrs[i] = _lsrs.at(i);
        }
    }

    /**
     * @dev Get the MSD and MSD peg reserve information of LSR.
     * @param _lsrs LSR address list.
     * @return _msds MSD address list.
     * @return _mprs MSD peg reserve address list.
     */
    function _getLSRInfo(address[] memory _lsrs)
        internal
        view
        returns (address[] memory _msds, address[] memory _mprs)
    {
        uint256 _len = _lsrs.length;
        _msds = new address[](_len);
        _mprs = new address[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _msds[i] = ILSR(_lsrs[i]).msd();
            _mprs[i] = ILSR(_lsrs[i]).mpr();
        }
    }

    function getAllLSRs()
        external
        view
        returns (
            address[] memory _allLsrs,
            address[] memory _msds,
            address[] memory _mprs
        )
    {
        _allLsrs = _getAllLSRs();
        (_msds, _mprs) = _getLSRInfo(_allLsrs);
    }
}