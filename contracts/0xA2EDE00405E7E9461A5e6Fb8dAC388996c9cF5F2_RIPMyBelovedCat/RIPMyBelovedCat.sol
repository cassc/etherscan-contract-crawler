/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RIPMyBelovedCat {
    bool private _revealed;
    address private _humanFriendAddr;
    bytes32 private constant _HASHED_T3 = 0x400c9a9706bf7cae2a1d6c5f61e7ad0c6c20be5c7ef185f9bd6a268f3c3b9575;
    IReverseResolver private ReverseResolver = IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    string private constant _LIVED = 'Spring 2005 -  Sep 12, 2022';
    string private constant _EPITAPH = 'You strayed into my heart, and you stayed forever. Thank you for being with me for the past 17 years. I miss your purrs, your meows, your naughtiness, and everything you were. Do not worry my furriend, I will always love you and be near, you will never feel lonely. Be brave my little angel, leave earth with your wings, fly high, and explore heaven. You are loved by many people, forever they will remember you and love you wherever you are. If you see some familiar faces in the future, be their guide to the new world. ^^meow~';
    string public constant ABOUT = unicode'🪦 this contract is used to commemorate my beloved cat 🐱.';
    string public catNameAndText = '(the cat name is hidden)';

    constructor() {
        _humanFriendAddr = msg.sender;
    }

    function read(string memory _catNameAndText) external view returns (string memory) {
        return _revealed
        ? assembleText(catNameAndText, true)
        : check(_catNameAndText)
        ? assembleText(_catNameAndText, true)
        : assembleText(catNameAndText, false)
        ;
    }

    function assembleText(string memory _text, bool _type) internal pure returns (string memory) {
        return _type
        ? string(abi.encodePacked(unicode'R.I.P. ', _text, unicode' 🐱 ', _LIVED, unicode' 🐱 ', _EPITAPH))
        : string(abi.encodePacked(unicode'R.I.P. My Beloved Cat 🐱 ', _LIVED, unicode' 🐱 ', _EPITAPH, ' ', _text))
        ;
    }

    function check(string memory _text) internal pure returns (bool) {
        return keccak256(abi.encodePacked("R.I.P.",keccak256(abi.encodePacked(_text,keccak256(abi.encodePacked(_LIVED)))))) == _HASHED_T3;
    }

    function reveal(string memory _catNameAndText) external {
        require(!_revealed && isHumanFriend() && check(_catNameAndText));
        catNameAndText = _catNameAndText;
        _revealed = !_revealed;
    }

    function seeHumanFriendAddr() external view returns (address) {
        return _humanFriendAddr;
    }
  
    function isHumanFriend() internal view returns (bool) {
        return msg.sender == _humanFriendAddr;
    }

    function updateHumanFriendAddr(address _to) external  {
        require(isHumanFriend());
        _humanFriendAddr = _to;
    }

    function setContractName(string calldata _name) external {
        require(isHumanFriend());
        ReverseResolver.setName(_name);
    }

}

interface IReverseResolver {
    function setName(string memory name) external;
}