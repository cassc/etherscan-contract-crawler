// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**  
 * ██████  ██  ██████ ██   ██ ██      ███████                
 * ██   ██ ██ ██      ██  ██  ██      ██                     
 * ██████  ██ ██      █████   ██      █████                  
 * ██      ██ ██      ██  ██  ██      ██                     
 * ██      ██  ██████ ██   ██ ███████ ███████                
 *                                                           
 *                                                           
 * ███████ ██████  ██ ████████ ██  ██████  ███    ██ ███████ 
 * ██      ██   ██ ██    ██    ██ ██    ██ ████   ██ ██      
 * █████   ██   ██ ██    ██    ██ ██    ██ ██ ██  ██ ███████ 
 * ██      ██   ██ ██    ██    ██ ██    ██ ██  ██ ██      ██ 
 * ███████ ██████  ██    ██    ██  ██████  ██   ████ ███████            
 * 
 * by @wij_not + @p0pps for Mustard Labs Novemeber 2022                 
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/interfaces/IERC1363.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PickleEditions is AccessControl, ERC1155, ERC1155Supply, IERC1363Receiver {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public beneficiary;
    address public ml_beneficiary;
    uint public split;
    IERC1363 public immutable token;
    mapping(uint256 => uint256) public prices;
    mapping(uint256 => uint256) public minted;
    mapping(uint256 => uint256) public available;
    mapping(uint256 => uint256) private limits;
    mapping(uint256 => string) private customURIs;
    string private suffix = ".json";
    string public name = "Pickle Editions";
    string public symbol = "PCKLEDNS";

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        // token = IERC1363(0xf46AbB1865Fbef39c2a02B33C0EBAE2Fb9E897AB);   // REG on goerli
        token = IERC1363(0x78b5C6149C87c82EDCffC73C230395abbc56DdD5);   // REG on mainnet
        setURI("https://static.mustardlabs.io/pickles/editions/data/"); // default base URI
        prices[1] = 69 * 10 ** 18;
        available[1] = 64;
        split = 50;
        beneficiary = msg.sender;
        ml_beneficiary = 0xb4005DB54aDecf669BaBC3efb19B9B7E3978ebc2;
    }

// view

    function limit(uint _tokenId) public view returns (uint) {
        return limits[_tokenId] + 1;
    }

    function intToBytes(uint _itemId) public pure returns (bytes memory) {
        return abi.encode(_itemId);
    }

// mint

    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) public override returns (bytes4) {
        require(msg.sender == address(token));
        uint256 itemId = abi.decode(data, (uint256));
        uint256 itemPrice = prices[itemId];
        require(itemPrice > 0, "Item price not set");
        require(value >= itemPrice, "invalid payment value");
        require(minted[itemId] <= available[itemId], "None left to mint");
        require(balanceOf(operator, itemId) <= limits[itemId], "Already minted limit");
        uint _splitAmount = (itemPrice * split) / 100;
        token.transfer(beneficiary, _splitAmount);
        token.transfer(ml_beneficiary, itemPrice - _splitAmount);
        minted[itemId]++;
        _mint(operator, itemId, 1, bytes(""));
        if (value > itemPrice) {
            token.transfer(from, value - itemPrice);
        }
        return IERC1363Receiver.onTransferReceived.selector;
    }

// admin

    function setURI(string memory newuri) public onlyRole(MINTER_ROLE) {
        _setURI(newuri);
    }

    function mint(address _to, uint _itemId, uint _count) public onlyRole(MINTER_ROLE) {
        _mint(_to, _itemId, _count, bytes(""));
    }

    function setPrice(uint256 itemId, uint256 newprice) public onlyRole(MINTER_ROLE) {
        prices[itemId] = newprice;
    }

    function setLimits(uint256 itemId, uint256 _limit) public onlyRole(MINTER_ROLE) {
        limits[itemId] = _limit;
    }

    function setNumAvailable(uint256 itemId, uint256 _limit) public onlyRole(MINTER_ROLE) {
        available[itemId] = _limit;
    }

    function increaseNumAvailable(uint itemId, uint _value) public onlyRole(MINTER_ROLE) {
        available[itemId] += _value;
    }

    function setURISuffix(string memory _suffix) public onlyRole(MINTER_ROLE) {
        suffix = _suffix;
    }

    function setName(string memory _name) public onlyRole(MINTER_ROLE) {
        name = _name;
    }

    function setSplit(uint _val) public {
        require(msg.sender == ml_beneficiary, "Not ml admin");
        split = _val;
    }

    function setMLBenefiary(address _addr) public {
        require(msg.sender == ml_beneficiary, "Not ml admin");
        ml_beneficiary = _addr;
    }

    function setCustomBaseURI(uint itemId, string memory _uri) public onlyRole(MINTER_ROLE) {
        // ex. "ipfs://QmWnXeqt4goxe7FiUaBsRrg4C75byJLSixzYKPZyD77Wm1/"
        customURIs[itemId] = _uri;
    }

// overrides

    function uri(uint256 id) public view override returns (string memory) {
        string memory _filename = string.concat(id.toString(), suffix);
        return bytes(customURIs[id]).length > 0 ? string.concat(customURIs[id], _filename) : string.concat(super.uri(id), _filename);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}