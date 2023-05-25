/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;
import "../general/Governable.sol";

/**
 * @title Governable
 * @dev Pretty default ownable but with variable names changed to better convey owner.
 */
contract RcaGovernable is Governable {
    address public guardian;
    address public priceOracle;
    address public capOracle;

    event NewGuardian(address indexed oldGuardian, address indexed newGuardian);
    event NewPriceOracle(address indexed oldOracle, address indexed newOracle);
    event NewCapOracle(address indexed oldOracle, address indexed newOracle);

    /**
     * @dev The Ownable constructor sets the original s of the contract to the sender
     * account.
     */
    function initRcaGovernable(
        address _governor,
        address _guardian,
        address _capOracle,
        address _priceOracle
    ) internal {
        require(governor() == address(0), "already initialized");
        initializeGovernable(_governor);

        guardian = _guardian;
        capOracle = _capOracle;
        priceOracle = _priceOracle;

        emit NewGuardian(address(0), _guardian);
        emit NewCapOracle(address(0), _capOracle);
        emit NewPriceOracle(address(0), _priceOracle);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGuardian() {
        require(msg.sender == guardian, "msg.sender is not Guardian.");
        _;
    }

    modifier onlyPriceOracle() {
        require(msg.sender == priceOracle, "msg.sender is not price oracle.");
        _;
    }

    modifier onlyCapOracle() {
        require(msg.sender == capOracle, "msg.sender is not capacity oracle.");
        _;
    }

    /**
     * @notice Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newGuardian The address to transfer ownership to.
     */
    function setGuardian(address _newGuardian) public onlyGov {
        guardian = _newGuardian;
    }

    function setPriceOracle(address _newPriceOracle) public onlyGov {
        priceOracle = _newPriceOracle;
    }

    function setCapOracle(address _newCapOracle) public onlyGov {
        capOracle = _newCapOracle;
    }

    uint256[50] private __gap;
}