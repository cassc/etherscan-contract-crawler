// SPDX-License-Identifier: MIT

/* 

██████╗ ███████╗ ██████╗ 
╚════██╗██╔════╝██╔════╝ 
 █████╔╝███████╗███████╗ 
██╔═══╝ ╚════██║██╔═══██╗
███████╗███████║╚██████╔╝
╚══════╝╚══════╝ ╚═════╝ 

Using this contract? 
A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.19;

import "./helpers/SSTORE2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TwoFiveSixFactorySeededV1 is Ownable {
    address payable private _twoFiveSixAddress;

    address public masterProject;

    address[] public projects;

    /* Percentage multiplied by 100 */
    uint256 public twoFiveSixSharePrimary;

    uint256 public biddingDelay;
    uint256 public allowListDelay;

    event Deployed(address a);

    /**
     * @notice Launches a new TwoFiveSixProjectSeeded with the provided project, traits, libraries, and seed.
     * @dev The `masterProjectSeeded` is used as the contract implementation.
     * @param _project A struct containing details about the project being launched.
     * @param _traits An array of structs containing details about the traits associated with the project.
     * @param _libraries An array of structs containing details about the libraries used by the project.
     */
    function launchProject(
        ITwoFiveSixProject.Project memory _project,
        ITwoFiveSixProject.Trait[] calldata _traits,
        ITwoFiveSixProject.LibraryScript[] calldata _libraries
    ) public {
        require(
            _project.biddingStartTimeStamp > block.timestamp + biddingDelay,
            "Before minimum bidding delay"
        );
        require(
            _project.allowListStartTimeStamp > block.timestamp + allowListDelay,
            "Before allow list delay"
        );
        require(
            _project.twoFiveSix == _twoFiveSixAddress,
            "Incorrect 256ART address"
        );
        require(
            _project.twoFiveSixShare == uint24(twoFiveSixSharePrimary),
            "Incorrect 256ART share"
        );
        require(
            twoFiveSixSharePrimary + _project.thirdPartyShare <= 10000,
            "Third party share too high"
        );

        address a = clone(masterProject);

        address traits;

        address libraryScripts;

        if (_traits.length > 0) {
            traits = SSTORE2.write(abi.encode(_traits));
        }

        if (_libraries.length > 0) {
            libraryScripts = SSTORE2.write(abi.encode(_libraries));
        }

        ITwoFiveSixProject p = ITwoFiveSixProject(a);

        p.initProject(_project, traits, libraryScripts);
        projects.push(a);
        emit Deployed(a);
    }

    /**
     * @notice Clones a contract using the provided implementation address
     * @param implementation The address of the contract implementation
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Set the master project address
     * @notice Only the contract owner can call this function
     * @param _masterProject Address of the new master project contract
     */
    function setMasterProject(address _masterProject) public onlyOwner {
        masterProject = _masterProject;
    }

    /**
     * @dev Set the 256 address
     * @notice Only the contract owner can call this function
     * @param newAddress The new 256 contract address
     */
    function setTwoFiveSixAddress(address payable newAddress) public onlyOwner {
        _twoFiveSixAddress = newAddress;
    }

    /**
     * @dev Set the primary 256 share
     * @notice Only the contract owner can call this function
     * @param newShare The new primary 256 share
     */
    function setTwoFiveSixSharePrimary(uint256 newShare) public onlyOwner {
        twoFiveSixSharePrimary = newShare;
    }

    /**
     * @dev Set the bidding delay
     * @notice Only the contract owner can call this function
     * @param delay The new bidding delay
     */
    function setBiddingDelay(uint256 delay) public onlyOwner {
        biddingDelay = delay;
    }

    /**
     * @dev Set the allow list delay
     * @notice Only the contract owner can call this function
     * @param delay The new allow list delay
     */
    function setAllowListDelay(uint256 delay) public onlyOwner {
        allowListDelay = delay;
    }
}

interface ITwoFiveSixProject {
    struct Project {
        string name; //unknown
        string imageBase; //unkown
        address[] artScripts; //unknown
        bytes32 merkleRoot; //32
        address artInfo; //20
        uint56 biddingStartTimeStamp; //8
        uint32 maxSupply; //4
        address payable artistAddress; //20
        uint56 allowListStartTimeStamp; //8
        uint32 totalAllowListMints; //4
        address payable twoFiveSix; //20
        uint24 artistAuctionWithdrawalsClaimed; //3
        uint24 artistAllowListWithdrawalsClaimed; //3
        uint24 twoFiveSixShare; //3
        uint24 royalty; //3
        address traits; //20
        uint96 reservePrice; //12
        address payable royaltyAddress; //20
        uint96 lastSalePrice; //12
        address libraryScripts; //20
        uint56 endingTimeStamp; //8
        uint24 thirdPartyShare; //3
        bool fixedPrice; //1
        address payable thirdPartyAddress; //20
    }
    struct Trait {
        string name;
        string[] values;
        string[] descriptions;
        uint256[] weights;
    }

    struct TotalAndCount {
        uint128 total;
        uint128 count;
    }
    struct LibraryScript {
        address fileStoreFrontEnd;
        address fileStore;
        string fileName;
    }

    function initProject(
        Project calldata _p,
        address _traits,
        address _libraryScripts
    ) external;
}