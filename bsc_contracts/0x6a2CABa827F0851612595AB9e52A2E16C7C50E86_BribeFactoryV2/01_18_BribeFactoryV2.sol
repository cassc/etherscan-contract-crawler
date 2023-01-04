// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../Bribes.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IBribe {
    function addReward(address) external;
}

contract BribeFactoryV2 is OwnableUpgradeable {
    address public last_bribe;
    address public voter;

    constructor() {}
    function initialize(address _voter) initializer  public {
        __Ownable_init();
        voter = _voter;
    }

    function createBribe(address _owner,address _token0,address _token1, string memory _type) external returns (address) {
        require(msg.sender == voter, 'only voter');
        Bribe lastBribe = new Bribe(_owner,voter,address(this), _type);
        lastBribe.addReward(_token0);
        lastBribe.addReward(_token1);
        last_bribe = address(lastBribe);
        return last_bribe;
    }

    function setVoter(address _Voter) external {
        require(owner() == msg.sender, 'not owner');
        require(_Voter != address(0));
        voter = _Voter;
    }

     function addReward(address _token, address[] memory _bribes) external {
        require(owner() == msg.sender, 'not owner');
        uint i = 0;
        for ( i ; i < _bribes.length; i++){
            IBribe(_bribes[i]).addReward(_token);
        }

    }

    function addRewards(address[][] memory _token, address[] memory _bribes) external {
        require(owner() == msg.sender, 'not owner');
        uint i = 0;
        uint k;
        for ( i ; i < _bribes.length; i++){
            address _bribe = _bribes[i];
            for(k = 0; k < _token.length; k++){
                IBribe(_bribe).addReward(_token[i][k]);
            }
        }

    }

}