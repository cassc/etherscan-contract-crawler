// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./StringUpper.sol";

abstract contract DenyList is StringUpper {
    mapping (string => bool) denyList;

    function addDenyList (string[] memory _words) public virtual {
        for(uint index = 0; index < _words.length; index+=1) {
            denyList[upper(_words[index])] = true;
            emit AddedDenyList(_words[index]);
        }
    }

    function removeDenyList (string[] memory _words) public virtual {
        for(uint index = 0; index < _words.length; index+=1) {
            denyList[upper(_words[index])] = false;
            emit RemovedDenyList(_words[index]);
        }
    }

    function inDenyList(string memory _word) public view virtual returns (bool) {
        return bool(denyList[upper(_word)]);
    }

    event AddedDenyList(string _word);
    event RemovedDenyList(string _word);
}