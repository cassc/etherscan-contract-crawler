pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BlockPunks is ERC1155, AccessControl {
    using SafeMath for uint;
    
    uint public constant TOTAL_SUPPLY = 10000;
    uint public constant RESERVED_TOTAL_SUPPLY = 1045;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address constant _devAddress = 0x38c918Db9dfb6Cfc27F462ce1CD5C56072D0A4f1;
    address constant _ownerAddress = 0xfEBACBC8493100F2218940528b76Ffc4B90265CF;
    bool public hasSaleStarted = false;
    bool public hasPreSaleStarted = false;
    uint public price;
    uint public reservedSupply;
    uint public mintedSupply;
    string _contractUri;

    mapping(uint => bool) public tokenIsMinted;
    mapping(address => uint) public preSaleAddressToRemainingTokens;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }
    
    constructor(string memory uri, string memory __contractUri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        price = 0.06 ether;
        _contractUri = __contractUri;
    }
    
    function mint(uint quantity, address receiver) public payable {
        if (hasPreSaleStarted && !hasSaleStarted) 
            require(preSaleAddressToRemainingTokens[receiver] >= quantity, "amount not reserved to this address");
        else 
            require(hasSaleStarted, "sale hasn't started");
        require(quantity > 0, "quantity cannot be zero");
        require(totalSupply().add(quantity) <= TOTAL_SUPPLY, "sold out");
        require(msg.value >= price.mul(quantity) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ether value sent is below the price");
        
        for (uint i = 0; i < quantity; i++) {
            uint mintIndex = RESERVED_TOTAL_SUPPLY + mintedSupply;
            _mint(receiver, mintIndex, 1, "");
            mintedSupply++;
            tokenIsMinted[mintIndex] = true;
        }

        if (hasPreSaleStarted && !hasSaleStarted) preSaleAddressToRemainingTokens[receiver] -= quantity;
    }

    function mintReserved(address receiver, uint tokenId) public onlyAdmin {
        require(!tokenIsMinted[tokenId], "token already minted");
        require(tokenId < RESERVED_TOTAL_SUPPLY, "token is not on reservedSupply");
        _mint(receiver, tokenId, 1, "");
        reservedSupply++;
        tokenIsMinted[tokenId] = true;
    }

    function batchMintReserved(address[] memory receivers, uint[] memory tokenIds) public onlyAdmin {
        require(receivers.length == tokenIds.length, "input length is not equal");
        for (uint i = 0; i < receivers.length; i++) {
            mintReserved(receivers[i], tokenIds[i]);
        }
    }

    function addToPresaleWhitelist(address receiver) public onlyAdmin {
        preSaleAddressToRemainingTokens[receiver] = 10;
    }

    function batchAddToPresaleWhitelist(address[] memory receivers) public onlyAdmin {
        for (uint i = 0; i < receivers.length; i++) {
            addToPresaleWhitelist(receivers[i]);
        }
    }

    function totalSupply() public view returns (uint) {
        return reservedSupply + mintedSupply;
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setURI(string memory newURI) external onlyAdmin {
        super._setURI(newURI);
    }

    function setContractURI(string memory __contractUri) public onlyAdmin {
        _contractUri = __contractUri;
    }
    
    function setPrice(uint _price) public onlyAdmin {
        price = _price;
    }
    
    function toggleSale() public onlyAdmin {
        hasSaleStarted = !hasSaleStarted;
    }

    function togglePreSale() public onlyAdmin {
        hasPreSaleStarted = !hasPreSaleStarted;
    }

    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(ADMIN_ROLE, account);
    }

    function removeAdmin(address account) public virtual onlyAdmin {
        renounceRole(ADMIN_ROLE, account);
    }
    
    function withdrawAll() public onlyAdmin {
        require(payable(_devAddress).send(address(this).balance.mul(2).div(100)));
        require(payable(_ownerAddress).send(address(this).balance));
    }
}