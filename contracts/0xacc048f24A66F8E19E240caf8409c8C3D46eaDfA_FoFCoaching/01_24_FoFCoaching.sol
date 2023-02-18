//
//
//
///////////////////////////////////////////////////
//   __  __ _ _         _  _                     //
//  |  \/  (_) |_____  | || |__ _ __ _ ___ _ _   //
//  | |\/| | | / / -_) | __ / _` / _` / -_) '_|  //
//  |_|  |_|_|_\_\___| |_||_\__,_\__, \___|_|    //
//                               |___/           //
///////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FoFCoaching is
    ERC1155Burnable,
    DefaultOperatorFilterer,
    AccessControl
{
    string public name = "FoF Coaching";
    string public symbol = "FoFCNFT";

    string public contractUri =
        "https://metadata.mikehager.de/FoFCoachingContract.json";

    bytes32 public constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN");

    uint256 public mintLimit = 1;
    mapping(address => uint256) private _mintCount;

    mapping(address => bool) private _whitelist;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    constructor()
        ERC1155("https://metadata.mikehager.de/coaching.json")
    {
        _grantRole(WHITELIST_ADMIN_ROLE, 0x28dFA69eaf27cfC08CbA2013d014b16B862eB9Bd);
        _grantRole(WHITELIST_ADMIN_ROLE, 0x2b195ff2DFcCcBc7962a871Cde6e45c078b1D7Cf);
        _idTracker.increment();
    }

    function setUri(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function setContractURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractUri = newuri;
    }

    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setWhitelist(
        address[] memory _addresses,
        bool _isWhitelisted
    ) public onlyRole(WHITELIST_ADMIN_ROLE){
        for (uint256 i = 0; i < _addresses.length; i++) {
            _whitelist[_addresses[i]] = _isWhitelisted;
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return _whitelist[_address];
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,
        uint256[] memory amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < to.length; i++)
            _mint(to[i], id[i], amount[i], "");
    }

    function setMintLimit(uint256 _mintLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintLimit = _mintLimit;
    }

    function getMintLimitByAddress(
        address _address
    ) public view returns (uint256) {
        return mintLimit - _mintCount[_address];
    }

    function mint() public {
        require(_mintCount[msg.sender] < mintLimit, "Mint limit reached");
        require(_whitelist[msg.sender] == true, "Not whitelisted");

        _mint(msg.sender, _idTracker.current(), 1, "");
        _mintCount[msg.sender] += 1;
        _idTracker.increment();
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, ERC1155) returns (bool) {}
}