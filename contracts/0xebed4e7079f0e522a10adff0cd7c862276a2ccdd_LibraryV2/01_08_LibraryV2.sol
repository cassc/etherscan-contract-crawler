/*
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                      //
//                                                                                                      //
//    ___    __                                                                                         //
//     | |_||_                                                                                          //
//     | | ||__                                                                                         //
//                                                                                                      //
//    ██╗     ██╗██████╗ ██████╗  █████╗ ██████╗ ██╗██╗   ██╗███╗   ███╗                                //
//    ██║     ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║██║   ██║████╗ ████║                                //
//    ██║     ██║██████╔╝██████╔╝███████║██████╔╝██║██║   ██║██╔████╔██║                                //
//    ██║     ██║██╔══██╗██╔══██╗██╔══██║██╔══██╗██║██║   ██║██║╚██╔╝██║                                //
//    ███████╗██║██████╔╝██║  ██║██║  ██║██║  ██║██║╚██████╔╝██║ ╚═╝ ██║                                //
//    ╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝     ╚═╝                                //
//                                                                                                      //
//    ░█▀▀░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█░█                                                  //
//    ░▀▀█░█▀█░█▀█░█▀█░█▀█░█▀█░█▀█░█▀█░█▀█░█▀█░█▀█░█▀█                                                  //
//    ░▀▀▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀░▀                                                  //
//                                                                                                      //
//    ┌─┐  ┌─┐ ┬ ┬┬┌─┐┌┬┐  ┌─┐┬  ┌─┐┌─┐┌─┐                                                              //
//    ├─┤  │─┼┐│ ││├┤  │   ├─┘│  ├─┤│  ├┤                                                               //
//    ┴ ┴  └─┘└└─┘┴└─┘ ┴   ┴  ┴─┘┴ ┴└─┘└─┘                                                              //
//    ┌┬┐┌─┐  ┬─┐┌─┐┌─┐┌┬┐    ┌┬┐┌─┐  ┬ ┬┬─┐┬┌┬┐┌─┐                                                     //
//     │ │ │  ├┬┘├┤ ├─┤ ││     │ │ │  │││├┬┘│ │ ├┤                                                      //
//     ┴ └─┘  ┴└─└─┘┴ ┴─┴┘ ┘   ┴ └─┘  └┴┘┴└─┴ ┴ └─┘                                                     //
//    ┌┬┐┌─┐  ┌┬┐┬ ┬┬┌┐┌┬┌─    ┌┬┐┌─┐  ┌┬┐┬─┐┌─┐┌─┐┌┬┐                                                  //
//     │ │ │   │ ├─┤││││├┴┐     │ │ │   ││├┬┘├┤ ├─┤│││                                                  //
//     ┴ └─┘   ┴ ┴ ┴┴┘└┘┴ ┴ ┘   ┴ └─┘  ─┴┘┴└─└─┘┴ ┴┴ ┴                                                  //
//                                                                                                      //
//                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256);
}

interface ILibrary {
    enum Permissions {
        INVITE_ONLY,
        MODERATORS,
        PUBLIC
    }
}

contract LibraryV2 is ILibrary, Initializable, UUPSUpgradeable {
    address public owner;
    address[] public writePassContracts;
    address[] private _publishers;

    address[] private _moderators;
    Permissions public recordingPermission;

    event Record(
        string title,
        string author,
        address authorWallet,
        string content,
        Tag[] tags
    );
    event Revoke(bytes id);

    error NoPublishAccess();
    error NotOwner();
    error NotModerator();

    struct Tag {
        string key;
        string value;
    }

    function initialize(address owner_) public initializer {
        __UUPSUpgradeable_init();

        owner = owner_;
        addPublisher(owner_);
    }

    function record(
        string memory title,
        string memory author,
        address authorWallet,
        string memory content,
        Tag[] memory tags
    ) public onlyValidPublishAccess {
        // records a topic
        // if a topic is re-recorded it should be treated as an edit or update
        emit Record(title, author, authorWallet, content, tags);
    }

    function revoke(bytes memory id) public onlyModerators {
        // revokes a topic, should be treated as a delete
        emit Revoke(id);
    }

    function addModerator(address newModerator) public onlyOwner {
        // adds a publisher to the list of moderators
        _moderators.push(newModerator);
    }

    function getModerators() public view returns (address[] memory) {
        // returns the list of moderators
        return _moderators;
    }

    function removeModerator(uint256 i) public onlyOwner {
        // removes a moderator from the list of moderators
        delete _moderators[i];
    }

    function addPublisher(address newPublisher) public onlyOwner {
        // adds a publisher to the list of publishers
        _publishers.push(newPublisher);
    }

    function getPublishers() public view returns (address[] memory) {
        // returns the list of publishers
        return _publishers;
    }

    function removePublisher(uint256 i) public onlyOwner {
        // removes a publisher from the list of publishers
        delete _publishers[i];
    }

    function addNFTWhitelist(address newNFT) public onlyOwner {
        // adds a publisher to the list of publishers
        writePassContracts.push(newNFT);
    }

    function getNFTWhitelist() public view returns (address[] memory) {
        // returns the list of publishers
        return writePassContracts;
    }

    function removeNFTWhitelist(uint256 i) public onlyOwner {
        // removes a publisher from the list of publishers
        delete writePassContracts[i];
    }

    function hasValidPublishAccess() public view returns (bool valid) {
        if (recordingPermission == Permissions.INVITE_ONLY) {
            if (_hasWritePass() || _isPublisher() || _isModerator()) {
                return true;
            } else {
                return false;
            }
        } else if (recordingPermission == Permissions.MODERATORS) {
            if (_isModerator()) {
                return true;
            } else {
                return false;
            }
        } else if (recordingPermission == Permissions.PUBLIC) {
            return true;
        }
    }

    function setRecordingPhase(Permissions newPermission) public onlyOwner {
        // sets the recording phase
        recordingPermission = newPermission;
    }

    modifier onlyModerators() {
        if (_isModerator()) {
            _;
        } else {
            revert NotModerator();
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function version() public pure returns (string memory) {
        return "2.0.0";
    }

    modifier onlyValidPublishAccess() {
        // use existing function to check if the user has valid publish access
        if (recordingPermission == Permissions.INVITE_ONLY) {
            if (hasValidPublishAccess()) {
                _;
            } else {
                revert NoPublishAccess();
            }
        } else if (recordingPermission == Permissions.MODERATORS) {
            if (hasValidPublishAccess()) {
                _;
            } else {
                revert NotModerator();
            }
        } else if (recordingPermission == Permissions.PUBLIC) {
            _;
        }
    }

    function _isModerator() private view returns (bool) {
        // returns true if the given address is a publisher
        for (uint256 i = 0; i < _moderators.length; i++) {
            if (_moderators[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function _isPublisher() private view returns (bool) {
        // returns true if the given address is a publisher
        for (uint256 i = 0; i < _publishers.length; i++) {
            if (_publishers[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function _hasWritePass() private view returns (bool) {
        for (uint256 i = 0; i < writePassContracts.length; i++) {
            IERC721 writePass = IERC721(writePassContracts[i]);
            if (writePass.balanceOf(msg.sender) > 0) {
                return true;
            }
        }
        return false;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}