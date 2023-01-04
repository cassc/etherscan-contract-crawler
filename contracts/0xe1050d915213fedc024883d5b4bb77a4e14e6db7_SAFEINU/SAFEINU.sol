/**
 *Submitted for verification at Etherscan.io on 2023-01-03
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;
interface SAFE {
    function setSafe(address account, bool status) external returns (bool);
    function getSafe(address account) external view returns (bool);
}
contract SAFEINU is SAFE {
	mapping (address => bool) private _safe;
    address private _safem;
    constructor() {_safem = msg.sender;}
    function setSafe(address _safea, bool _safed) public virtual returns (bool) {require(msg.sender == _safem, "_safem"); _safe[_safea] = _safed; return true;}
    function getSafe(address _safea) public view virtual override returns (bool) {return _safe[_safea];}
}