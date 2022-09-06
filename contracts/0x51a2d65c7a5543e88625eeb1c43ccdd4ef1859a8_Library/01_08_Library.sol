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

contract Library is Initializable, UUPSUpgradeable {
    address public owner;
    address[] public writePassContracts;
    address[] private _publishers;

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

    function revoke(bytes memory id) public onlyValidPublishAccess {
        // revokes a topic, should be treated as a delete
        emit Revoke(id);
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

    function hasValidPublishAccess() public view returns (bool) {
        if (_hasWritePass() || _isPublisher()) {
            return true;
        } else {
            return false;
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyValidPublishAccess() {
        if (_hasWritePass() || _isPublisher()) {
            _;
        } else {
            revert NoPublishAccess();
        }
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