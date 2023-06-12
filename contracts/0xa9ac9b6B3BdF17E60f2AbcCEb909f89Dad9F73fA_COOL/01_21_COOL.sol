// SPDX-License-Identifier: MIT License
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**

@title Cooling Off Coin
@author Anonymous

Trading coin designed to have cooling off period, which benefit to long holders, and can avoid sandwich attacks.
It should still allow classic arbitrage and only rarely block innocent users from making their trades. And you don't
have to keep making failed transaction and lose gas fees when there are too many transactions in one block.
PLUS: Cooling off period will set to 7200 (which is one day), each transfer will let it minus 1, until 1 to the end for
avoiding sandwich attacks.

Added in votes capability to potentially change admin to a DAO.
**/

contract COOL is ERC20Votes {

    // Only privilege admin has is to add more dexes.
    // The centralization here shouldn't cause any problem.
    address public admin;
    address public pendingAdmin;

    mapping (address => uint256) public lastSwapBlock;
    mapping (address => bool) private _excludeList;
    uint256 public cooling = 7200;

    constructor()
    ERC20("Cooling Off Coin", "COOL")
    ERC20Permit("Cooling Off Coin")
    {
        admin = msg.sender;
        setExclude(msg.sender, true);
        _mint(msg.sender, 8_888_888_888_888 ether);
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only the administrator may call this function.");
        _;
    }

    /**
     * @dev Only thing happening here is checking if the address hold for the minimum cooling-off period.
     * @param _to Address that the funds are being sent to.
     * @param _from Address that the funds are being sent from.
    **/
    function _beforeTokenTransfer(address _from, address _to, uint256)
    internal
    override
    {
        uint256 blockNum = lastSwapBlock[_from];
        if (!getExcluded(_to)) {
            lastSwapBlock[_to] = block.timestamp;
        }
        require(getExcluded(_from) || block.timestamp >= blockNum + cooling, "You should hold for some blocks to transfer!");
        if (cooling > 1) {
            _setCooling(cooling - 1);
        }
    }

    function _setCooling(uint256 _cooling) internal {
        cooling = _cooling;
    }

    function setExclude(address account, bool ifExclude) public onlyAdmin {
        require(getExcluded(account) != ifExclude, "IfExclude already set!");
        _excludeList[account] = ifExclude;
    }

    function getExcluded(address account) public view returns (bool) {
        return _excludeList[account];
    }

    /**
     * @dev Make a new admin pending. I hate 1-step ownership transfers. They terrify me.
     * @param _newAdmin The new address to transfer to.
    **/
    function transferAdmin(address _newAdmin)
    external
    onlyAdmin
    {
        pendingAdmin = _newAdmin;
    }

    /**
     * @dev Renounce admin if no one should have it anymore.
    **/
    function renounceAdmin()
    external
    onlyAdmin
    {
        admin = address(0);
    }

    /**
     * @dev Accept administrator from the pending address.
    **/
    function acceptAdmin()
    external
    {
        require(msg.sender == pendingAdmin, "Only the pending administrator may call this function.");
        admin = pendingAdmin;
        delete pendingAdmin;
    }
}