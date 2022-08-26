// SPDX-License-Identifier: MIT

/* 

 222222222222222    555555555555555555         66666666   
2:::::::::::::::22  5::::::::::::::::5        6::::::6    
2::::::222222:::::2 5::::::::::::::::5       6::::::6     
2222222     2:::::2 5:::::555555555555      6::::::6      
            2:::::2 5:::::5                6::::::6       
            2:::::2 5:::::5               6::::::6        
         2222::::2  5:::::5555555555     6::::::6         
    22222::::::22   5:::::::::::::::5   6::::::::66666    
  22::::::::222     555555555555:::::5 6::::::::::::::66  
 2:::::22222                    5:::::56::::::66666:::::6 
2:::::2                         5:::::56:::::6     6:::::6
2:::::2             5555555     5:::::56:::::6     6:::::6
2:::::2       2222225::::::55555::::::56::::::66666::::::6
2::::::2222222:::::2 55:::::::::::::55  66:::::::::::::66 
2::::::::::::::::::2   55:::::::::55      66:::::::::66   
22222222222222222222     555555555          666666666    

Using this contract? A shout out to @Mint256Art is appreciated!
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./TwoFiveSixProject.sol";
import "./RoyaltySplitter.sol";

contract TwoFiveSixFactory is Ownable {
    address public masterProject;
    address payable public masterRoyaltySplitter;

    address[] public projects;
    address payable[] public royaltySplitters;

    uint256 public twoFiveSixShare = 1500;
    uint256 public maxPerTx = 9;

    function _getProjectInfo(
        string[2] calldata _strings,
        address[8] calldata _addresses,
        uint256[5] calldata _uints
    ) private pure returns (TwoFiveSixProject.Project memory) {
        return
            TwoFiveSixProject.Project(
                _strings[0],
                _strings[1],
                payable(_addresses[0]),
                payable(_addresses[1]),
                _addresses[2],
                _addresses[3],
                _addresses[4],
                _addresses[5],
                _addresses[6],
                _addresses[7],
                _uints[0],
                _uints[1],
                _uints[2],
                _uints[3],
                _uints[4]
            );
    }

    /* ARTIST SHARE SHOULD BE PERCENTAGE * 100 */
    function createRoyaltySplitter(
        address payable _artist,
        address payable _twoFiveSix,
        uint256 _artistShare
    ) public onlyOwner {
        address payable a = clonePayable(masterRoyaltySplitter);
        RoyaltySplitter r = RoyaltySplitter(a);
        r.initRoyaltySplitter(_artist, _twoFiveSix, _artistShare);
        royaltySplitters.push(a);
    }

    function launchProject(
        string[2] calldata _strings,
        address[8] calldata _addresses,
        uint256[5] calldata _uints
    ) public onlyOwner {
        address a = clone(masterProject);
        TwoFiveSixProject.Project memory projectInfo = _getProjectInfo(
            _strings,
            _addresses,
            _uints
        );

        TwoFiveSixProject p = TwoFiveSixProject(a);
        p.initProject(projectInfo, twoFiveSixShare, maxPerTx);
        projects.push(a);
    }

    function setMasterProject(address _masterProject) public onlyOwner {
        masterProject = _masterProject;
    }

    function setMasterRoyaltySplitter(address payable _masterRoyaltySplitter)
        public
        onlyOwner
    {
        masterRoyaltySplitter = _masterRoyaltySplitter;
    }

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

    function clonePayable(address payable implementation)
        internal
        returns (address payable instance)
    {
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

    function getLastProject() public view returns (address) {
        return projects[projects.length - 1];
    }

    function getLastRoyaltySplitter() public view returns (address) {
        return royaltySplitters[royaltySplitters.length - 1];
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setTwoFiveSixShare(uint256 _twoFiveSixShare) external onlyOwner {
        twoFiveSixShare = _twoFiveSixShare;
    }
}