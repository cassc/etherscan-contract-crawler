// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TheLostWalletToken is
    ERC1155,
    ERC1155Supply,
    Ownable,
    ReentrancyGuard
{

    string public name = "TheLostWallet Token";
    string public symbol = "LostWallet";

    uint256 public constant EARLY = 0;
    uint256 public constant STANDARD = 1;
    uint256 public constant maxEarlySupply = 1000;

    // Mapping each tokenTypeId with
    mapping(uint256 => bool) _tokenActivated;

    // Admin wallets : Allowed to sign for WL :
    mapping(address => bool) _admins;

    constructor() ERC1155("ipfs://QmQGMXdX1tjupU3yAdBXsyrnwV1hEjHhDiCzruVgHfFduc/{id}.json") {
        // Init admins :
        _admins[msg.sender] = true;

        // TokenId 0 = OG special
        _tokenActivated[0] = true;

        // TokenId % 2 == 1 (odd) : Early ones
        // TokenId % 2 == 0 (even) : Standard ones
    }

    ////////////////////////////
    // Admin functions :

    function addAdmin(address a) public onlyAdmin {
        _admins[a] = true;
    }

    function removeAdmin(address a) public onlyAdmin {
        _admins[a] = false;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender], "User should be admin");
        if (_admins[msg.sender]) {
            _;
        }
    }

    function activateWeek(uint256 weekId) public onlyAdmin {
        _tokenActivated[(2 * weekId) - 1] = true;
        _tokenActivated[(2 * weekId)] = true;
    }

    function deactivateWeek(uint256 weekId) public onlyAdmin {
        _tokenActivated[(2 * weekId) - 1] = false;
        _tokenActivated[(2 * weekId)] = false;
    }

    // Let's do a withdraw ...
    // Just in case somebody wants to put some ETH on this contract, don't want to block that here :'(
    function withdrawMoney() external onlyAdmin nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setURI(string memory newuri) public onlyAdmin {
        _setURI(newuri);
    }

    //
    ////////////////////////////

    ////////////////////////////
    // Mint functions :

    function mint(
        uint256 weekId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(weekId >= 0 && weekId < 25, "Incorrect weekId ;)");

        uint256 earlyTokenId = (weekId == 0) ? 0 : (2 * weekId) - 1;
        uint256 earlySupply = totalSupply(earlyTokenId);

        // Check sign :
        require(
            checkSign(weekId, v, r, s),
            "This early token can only be minted by whitelisted users ;)"
        );

        // 1 token max / wallet
        require(
            this.balanceOf(msg.sender, earlyTokenId) == 0,
            "You cannot mint more than one token of each week."
        );
        require(
            weekId == 0 || this.balanceOf(msg.sender, earlyTokenId + 1) == 0,
            "You cannot mint more than one token of each week."
        );
        require(
            _tokenActivated[earlyTokenId],
            "This token must activated first ..."
        );

        if (weekId == 0 || earlySupply < maxEarlySupply) {
            // Mint early token :
            _mint(msg.sender, earlyTokenId, 1, "");
        } else {
            // Mint std token :
            _mint(msg.sender, earlyTokenId + 1, 1, "");
        }
    }

    //
    ////////////////////////////

    ////////////////////////////
    // Making this tokens SBTs : Non transferable
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        require(from == address(0), "Token is not transferable");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //
    ////////////////////////////

    ////////////////////////////
    // SECURITY

    // Will be used to sign early : Only if on WL :
    function checkSign(
        uint256 weekId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(weekId, msg.sender))
            )
        );
        address recovered = ecrecover(digest, v, r, s);
        return _admins[recovered];
    }
    //
    ////////////////////////////
}