//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title OracleManaged
contract OracleManaged is Ownable {

    address private _oracle;

    event OracleUpdated(address indexed prev, address indexed next);

    modifier onlyOracle {
        require(_msgSender() == _oracle, "OracleManaged: caller is not the Oracle");
        _;
    }

    modifier onlyOwnerOrOracle() {
        require(_msgSender() == owner() || _msgSender() == _oracle, "OracleManaged: Only the owner or oracle can call this function");
        _;
    }

    /// @notice Get Oracle address
    /// @return address Oracle address
    function oracle() public view returns (address) {
        return _oracle;
    }

    /// @notice Set Oracle address
    /// @param _newOracle New Oracle address
    function setOracle(address _newOracle) external onlyOwner {
        _setOracle(_newOracle);
    }

    /// @dev Set Oracle address and emit event with previous and new address
    /// @param _newOracle New Oracle address
    function _setOracle(address _newOracle) internal {
        require(_newOracle != address(0), "OracleManaged: _newOracle cannot be the zero address");
        address prev = _oracle;
        _oracle = _newOracle;
        emit OracleUpdated(prev, _newOracle);
    }
}