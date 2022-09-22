// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....  
//                'dXMMWNO;                ....... 
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//               
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.16;

import "./ICloneforceClaimable.sol";
import "./Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nexus is ERC1155Supply, Ownable, ICloneforceClaimable {
    address private _airdropManagerContract;
    string private _baseTokenURI;
    address private _admin;
    mapping(address => bool) private _burnAuthorizedContracts;

    bool public contractPaused;

    constructor(
        string memory baseTokenURI,
        address admin,
        address airdropManagerContract)
    ERC1155("") {
        _admin = admin;
        _baseTokenURI = baseTokenURI;
        _airdropManagerContract = airdropManagerContract;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    function mintClaim(address to, uint256 tokenId, uint256 count) external override {
        require(msg.sender == _airdropManagerContract, "You cannot call this function");
        _mint(to, tokenId, count, "");
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string.concat(_baseTokenURI, Strings.toString(_id));
    }

    function setAirdropManagerContract(address airdropManagerContract) external onlyOwnerOrAdmin {
        _airdropManagerContract = airdropManagerContract;
    }

    function mint(address to, uint256 tokenId, uint256 count) external onlyOwnerOrAdmin {
        _mint(to, tokenId, count, "");
    }

    function mintBatch(address[] calldata to, uint256 tokenId, uint256[] calldata counts) external onlyOwnerOrAdmin {
        unchecked {
            for (uint256 i = 0; i < to.length; i++) {
                _mint(to[i], tokenId, counts[i], "");
            }
        }
    }

    function pauseContract(bool paused) external onlyOwnerOrAdmin {
        contractPaused = paused;
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require(!contractPaused, "Contract is paused");
    }

    // Burn functions

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public virtual {
        require(
            _burnAuthorizedContracts[msg.sender] || from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(from, id, amount);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual {
        require(
            _burnAuthorizedContracts[msg.sender] || from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(from, ids, amounts);
    }

    function setBurnAuthorizedContract(address authorizedContract, bool isAuthorized) external onlyOwnerOrAdmin {
        _burnAuthorizedContracts[authorizedContract] = isAuthorized;
    }

    // Marketplace blocklist functions

    mapping(address => bool) private _marketplaceBlocklist;

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_marketplaceBlocklist[operator] == false, "Marketplace is blocked");
        super.setApprovalForAll(operator, approved);
    }

    function blockMarketplace(address addr, bool blocked) public onlyOwnerOrAdmin {
        _marketplaceBlocklist[addr] = blocked;
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://cloneforce.xyz/api/nexus/marketplace-metadata";
    }
}