// SPDX-License-Identifier: MIT
/*
 ██████ ██   ██  █████  ██ ███    ██ ██   ██  ██████  ██    ██ ███    ██ ██████  ███████ 
██      ██   ██ ██   ██ ██ ████   ██ ██   ██ ██    ██ ██    ██ ████   ██ ██   ██ ██      
██      ███████ ███████ ██ ██ ██  ██ ███████ ██    ██ ██    ██ ██ ██  ██ ██   ██ ███████ 
██      ██   ██ ██   ██ ██ ██  ██ ██ ██   ██ ██    ██ ██    ██ ██  ██ ██ ██   ██      ██ 
 ██████ ██   ██ ██   ██ ██ ██   ████ ██   ██  ██████   ██████  ██   ████ ██████  ███████ 
*/

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainHoundsOGPass is ERC1155Supply, Ownable {
    string public constant name = "ChainHounds OG Pass";
    bool public saleIsActive = true;
    uint public CARD_ID = 1;
    uint public MAX_MINT = 1;
    uint public MAX_SUPPLY = 250;
    uint public constant TEAM_RESERVED = 50;
    uint public teamMinted = 0;
    string public baseUri = "https://ipfs.io/ipfs/Qma9SvfwzX3jKDfPPZ7tM2SdzfurBV1MRhAFHec9FnxqNF/{id}.json";
    address private immutable _adminSigner;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    constructor(address adminSigner) ERC1155(baseUri) {
        _adminSigner = adminSigner;
    }

    function setURI(string memory _newUri) external onlyOwner {
        baseUri=_newUri;
        _setURI(_newUri);
    }
    
    function verifyCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), 'ECDSA: invalid signature');
        return signer == _adminSigner;
    }
    
    function mint(uint256 _quantity, Coupon memory coupon) external payable {
        bytes32 digest = keccak256(abi.encode(1, msg.sender));

        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint");
        require(balanceOf(msg.sender, CARD_ID) + _quantity <= MAX_MINT, "Purchase not allowed, only 1 token per wallet");
        require(totalSupply(CARD_ID) + _quantity <= MAX_SUPPLY - (TEAM_RESERVED - teamMinted), "Purchase would exceed max supply");
        require(verifyCoupon(digest, coupon),"Invalid coupon");

        _mint(msg.sender, CARD_ID, _quantity, "");
    }
    
    function teamMint(address to, uint256 _quantity) external onlyOwner {
        require(teamMinted + _quantity <= TEAM_RESERVED, "This amount is more than max allowed");

        _mint(to, CARD_ID, _quantity, "");
        teamMinted = teamMinted + _quantity;
    }
    
    function contractURI() public view returns (string memory) {
        return baseUri;
    }

    function toggleActiveSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function changeSaleDetails(uint _activeCardId, uint _maxMint, uint _maxSupply) external onlyOwner {
        CARD_ID = _activeCardId;
        MAX_MINT = _maxMint;
        MAX_SUPPLY = _maxSupply;
        saleIsActive = false;
    }
}