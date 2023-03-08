pragma solidity 0.5.4;

import "./ERC1594.sol";
import "./ERC1644.sol";
import "../interfaces/IModerator.sol";


contract ERC1400 is ERC1594, ERC1644 {
    constructor(IModerator _moderator) public Moderated(_moderator) {}
}