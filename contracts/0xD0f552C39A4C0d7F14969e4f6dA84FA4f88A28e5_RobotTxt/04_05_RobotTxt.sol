// SPDX-License-Identifier: MIT
/**
 *  ██████╗  ██████╗ ██████╗  ██████╗ ████████╗███████╗           ████████╗██╗  ██╗████████╗
 *  ██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝           ╚══██╔══╝╚██╗██╔╝╚══██╔══╝
 *  ██████╔╝██║   ██║██████╔╝██║   ██║   ██║   ███████╗              ██║    ╚███╔╝    ██║
 *  ██╔══██╗██║   ██║██╔══██╗██║   ██║   ██║   ╚════██║              ██║    ██╔██╗    ██║
 *  ██║  ██║╚██████╔╝██████╔╝╚██████╔╝   ██║   ███████║    ██╗       ██║   ██╔╝ ██╗   ██║
 *  ╚═╝  ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝    ╚═╝       ╚═╝   ╚═╝  ╚═╝   ╚═╝
 *
 * A robots.txt file tells search engine crawlers which URLs the crawler can access on your site.
 * In web3, we can use this robots-txt registry contract to let aggregators anyone else that scape the the blockchain and IPFs
 * know what default rights we are giving them regarding our content.
 *
 * How this works:
 * -------------------
 * You can set a default license uri and info  for any address
 * of a contract that has an "owner()" function that returns your address.
 * When yo udo this, you get a special ROBOT token that you can use to remove the license later (and then it gets burned)
 *
 * call setDefaultLicense(address _for, string _licenseUri, string info) to set a license _for your address or a contract you own.
 * call licenseOf(address _address) to get the license and info for an address. if none is set, it will return an empty string.
 *
 * by Roy Osherove, Niv Mimran
 */
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts//access/Ownable.sol";
import "./token/IRobot.sol";
import "./IRobotTxt.sol";
// import "forge-std/console.sol";
//forge console

contract RobotTxt is IRobotTxt, Ownable {
    IRobot public robot;
    mapping(address => LicenseData) public licenseOf;
    mapping(address => address[]) public ownerLicenses;
    mapping(address => address) public contractAddressToOwnerAllowList;
    uint256 public totalLicenseCount;

    modifier senderMustBeOwnerOf(address _owned) {
        if (_owned == address(0)) revert ZeroAddress();
        bool isAllowListed = contractAddressToOwnerAllowList[_owned] == msg.sender;
        bool isOwnableOwner; // false by default

        try Ownable(_owned).owner() returns (address contractOwner) {
            if (msg.sender == contractOwner) {
                isOwnableOwner = true;
            }
        } catch { // no error handling in `catch`?
        }
        require(isOwnableOwner || isAllowListed, "Sender must be owner of the address");
        _;
    }

    /// @param robotAddress address of the legato robot token contract
    constructor(address robotAddress) {
        if (robotAddress == address(0)) revert ZeroAddress();
        robot = IRobot(robotAddress);
    }

    /// @notice registers a new license URI _for a license owned by the license owner
    /// @param _for the address of the license to register
    /// @param _licenseUri the URI of the licens10
    /// @param _info the URI of the license info
    function setDefaultLicense(address _for, string memory _licenseUri, string memory _info)
        public
        senderMustBeOwnerOf(_for)
    {
        if (bytes(_licenseUri).length == 0) revert ZeroValue();
        LicenseData memory licenseData = licenseOf[_for];

        if (bytes(licenseData.uri).length == 0) {
            robot.mint(msg.sender);
            ++totalLicenseCount;
            ownerLicenses[msg.sender].push(_for);
        }

        // licenseOf[_for] = LicenseData(_licenseUri, _info);
        licenseOf[_for].uri = _licenseUri;
        licenseOf[_for].info = _info;

        emit LicenseSet(msg.sender, _for, _licenseUri, _info);
    }

    /// @notice returns a license count for a given owner
    /// @param _owner the owner of the licenses
    /// @return licenseCount
    function getOwnerLicenseCount(address _owner) external view returns (uint256) {
        return ownerLicenses[_owner].length;
    }

    /// @notice remove a license URI _for a license owned by the license owner
    /// @param _for the address of the license to register
    function removeDefaultLicense(address _for) public senderMustBeOwnerOf(_for) {
        LicenseData memory licenseData = licenseOf[_for];
        if (bytes(licenseData.uri).length == 0) {
            revert LicenseNotRegistered();
        }

        delete licenseOf[_for];

        address[] memory licenses = ownerLicenses[msg.sender];
        delete ownerLicenses[msg.sender];

        uint256 length = licenses.length;
        for (uint256 i; i < length;) {
            if (licenses[i] != _for) {
                ownerLicenses[msg.sender].push(licenses[i]);
            }
            unchecked {
                ++i;
            }
        }

        robot.burn(msg.sender);
        --totalLicenseCount;

        emit LicenseRemoved(msg.sender, _for);
    }

    function whitelistOwnerContract(address _owner, address _contractAddress) external onlyOwner {
        if (_owner == address(0) || _contractAddress == address(0)) revert ZeroAddress();
        if (contractAddressToOwnerAllowList[_contractAddress] == _owner) revert AlreadyWhitelisted();
        contractAddressToOwnerAllowList[_contractAddress] = _owner;
        emit ContractWhitelisted(_owner, _contractAddress);
    }

    function delistOwnerContract(address _owner, address _contractAddress) external onlyOwner {
        if (_owner == address(0) || _contractAddress == address(0)) revert ZeroAddress();
        if (contractAddressToOwnerAllowList[_contractAddress] != _owner) revert NotWhitelisted();
        delete contractAddressToOwnerAllowList[_contractAddress];
        emit ContractDelisted(_owner, _contractAddress);
    }
}