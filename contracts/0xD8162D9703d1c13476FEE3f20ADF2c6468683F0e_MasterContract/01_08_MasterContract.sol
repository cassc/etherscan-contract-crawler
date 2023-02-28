// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./reduced_interfaces/BAPGenesisInterface.sol";
import "./reduced_interfaces/BAPMethaneInterface.sol";
import "./reduced_interfaces/BAPUtilitiesInterface.sol";
import "./reduced_interfaces/BAPTeenBullsInterface.sol";
import "./reduced_interfaces/BAPOrchestratorInterfaceV2.sol";

/// @title Bulls and Apes Project - Master Contract
/// @author BAP Dev Team
/// @notice Handle interactions between several BAP contracts
contract MasterContract is Ownable {
    /// @notice Contract address for BAP METH
    BAPMethaneInterface public bapMeth;
    /// @notice Contract address for BAP Utilities
    BAPUtilitiesInterface public bapUtilities;
    /// @notice Contract address for BAP Teen Bulls
    BAPTeenBullsInterface public bapTeenBulls;

    /// @notice Mapping for contracts allowed to use this contract
    mapping(address => bool) public isAuthorized;

    /// @notice Deploys the contract
    /// @param _bapMethane METH contract address
    /// @param _bapUtilities Utilities contract address
    /// @param _bapTeenBulls Teen Bulls contract address
    constructor(
        address _bapMethane,
        address _bapUtilities,
        address _bapTeenBulls
    ) {
        bapMeth = BAPMethaneInterface(_bapMethane);
        bapUtilities = BAPUtilitiesInterface(_bapUtilities);
        bapTeenBulls = BAPTeenBullsInterface(_bapTeenBulls);
    }

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Not Authorized");
        _;
    }

    // METH functions
    /// @notice Call claim function on METH contract
    /// @param to Address to send METH
    /// @param amount Amount to mint
    function claim(address to, uint256 amount) external onlyAuthorized {
        bapMeth.claim(to, amount);
    }

    /// @notice Call pay function on METH contract
    /// @param payment Amount to charge as payment
    /// @param fee Fee to be sent to treasury
    function pay(uint256 payment, uint256 fee) external onlyAuthorized {
        bapMeth.pay(payment, fee);
    }

    // Teens functions

    /// @notice Call airdrop function on Teen Bulls contract
    /// @param to Address to send the Teens
    /// @param amount Quantity of teens to mint
    function airdrop(address to, uint256 amount) external onlyAuthorized {
        bapTeenBulls.airdrop(to, amount);
    }

    /// @notice Call burnTeenBull function on Teen Bulls contract
    /// @param tokenId Item to be burned
    /// @dev User needs to approve this contract to burn their Teens
    function burnTeenBull(uint256 tokenId) external onlyAuthorized {
        bapTeenBulls.burnTeenBull(tokenId);
    }

    /// @notice Call ownerOf function on Teen Bulls contract
    /// @param tokenId Id to ask owner address
    function ownerOf(uint256 tokenId) external view returns (address) {
        return bapTeenBulls.ownerOf(tokenId);
    }

    // Utilities functions

    /// @notice Call burn function on Utilities contract
    /// @param id Item to be burned
    /// @param amount Quantity to be burned
    /// @dev User needs to approve this contract to burn their Utilities
    function burn(uint256 id, uint256 amount) external onlyAuthorized {
        bapUtilities.burn(id, amount);
    }

    /// @notice Call airdrop function on Utilities contract
    /// @param to Address to send the Utilities
    /// @param amount Quantity of Utilities to mint
    /// @param id Id of the item to be minted
    function airdrop(
        address to,
        uint256 amount,
        uint256 id
    ) external onlyAuthorized {
        bapUtilities.airdrop(to, amount, id);
    }

    // Ownable

    /// @notice authorise a new address to use this contract
    /// @param operator Address to be set
    /// @param status Can use this contract or not
    /// @dev Only contract owner can call this function
    function setAuthorized(address operator, bool status) external onlyOwner {
        isAuthorized[operator] = status;
    }

    /// @notice Transfer ownership from external contracts owned by this contract
    /// @param _contract Address of the external contract
    /// @param _newOwner New owner
    /// @dev Only contract owner can call this function
    function transferOwnershipExternalContract(
        address _contract,
        address _newOwner
    ) external onlyOwner {
        Ownable(_contract).transferOwnership(_newOwner);
    }

    /// @notice Change the address for METH Contract
    /// @param _newAddress New address to be set
    /// @dev Can only be called by the contract owner
    function setMethaneContract(address _newAddress) external onlyOwner {
        bapMeth = BAPMethaneInterface(_newAddress);
    }

    /// @notice Change the address for Utilities Contract
    /// @param _newAddress New address to be set
    /// @dev Can only be called by the contract owner
    function setUtilitiesContract(address _newAddress) external onlyOwner {
        bapUtilities = BAPUtilitiesInterface(_newAddress);
    }

    /// @notice Change the address for Teen Bulls Contract
    /// @param _newAddress New address to be set
    /// @dev Can only be called by the contract owner
    function setTeenBullsContract(address _newAddress) external onlyOwner {
        bapTeenBulls = BAPTeenBullsInterface(_newAddress);
    }
}