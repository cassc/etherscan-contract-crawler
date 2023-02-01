// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                             ]█████▄       ,██████    //
//                                 ,,,,,       ███████▄     ▄██████▌    //
//                                 █████▌      ████████⌐  ▄████████     //
//                                ▐█████      ▐█████████▄██████████     //
//                                ██████▄▄▄▄▄▄█████▌▀███████'▐████      //
//                                █████████████████  ▀████▀  █████      //
//                               ▐█████▀▀▀▀▀▀█████▌         ▐████▌      //
//                               █████▌      █████-         ▀▀▀▀▀       //
//                              ▐█████  ▄██████████████▄   ]█████       //
//                              ▀▀▀▀▀▀ █████████████████▌  ▄▄▄▄▄`       //
//                                    ▐█████`      █████▌  █████        //
//                                    █████▌       █████  ▐████▌        //
//                                    █████       ▐█████  █████`        //
//                                   ▐█████,     ,█████▌  ▀▀▀▀▀         //
//                                   ▐█████████████████                 //
//                                    ▀▀████████████▀▀                  //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

interface AllowList {
    function getCount(address _addr) external view returns (uint);
    function getCountFree(address _addr) external view returns (uint);
    function decrease(address _addr, uint _count) external;
    function decreaseFree(address _addr, uint _count) external;
}

contract OneBitCitizen is ERC721, Pausable, AccessControl, ERC721Royalty, ERC721Burnable {
    using Random for Random.Manifest;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string baseURI;
    AllowList allowList;
    uint public price = 1 ether / 20; // .05 Ether
    uint private limit = 500;
    bool public publicSale = false;

    Random.Manifest private deck;    
    address public beneficiary;     

    event FreeMint(address wallet, uint256 amount);  
    event Sale(address wallet, uint256 amount, uint paymentAmount);  

    constructor() ERC721("One-Bit-Citizens", "1BCTZ"){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        deck.setup(limit);
        beneficiary = msg.sender; 
        baseURI = "ipfs://QmTFXJ9p1TXkwFZMg3VAhyqbjjPBGTuYzs4xxbk9K2xtJv/";
        // allowList = AllowList(0x1Ee575a59106A2561865C7cCCc17f49E13bD84B9); // Goerli
        allowList = AllowList(0xbe6161704f1f5cd89f49F790137F33CEF2bb8554); // Mainnet
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function mint(address to, uint256 numberOfTokens) public payable whenNotPaused {
        require(remaining() >= numberOfTokens);
        if (msg.value == 0) {
            // free mint
            require(allowList.getCountFree(to) >= numberOfTokens,"No free mints for this address");
            allowList.decreaseFree(to,numberOfTokens);
            _mintBatch(to, numberOfTokens);
            emit FreeMint(to, numberOfTokens);
        } else if (publicSale) {
            // public sale
            require(msg.value >= numberOfTokens * price, 'Insufficient payment');
            Address.sendValue(payable(beneficiary), msg.value);
            _mintBatch(to, numberOfTokens);
            emit Sale(to, numberOfTokens,msg.value);
        } else {
            // allowlist only
            require(msg.value >= numberOfTokens * price, 'Insufficient payment');
            require(allowList.getCount(to) >= numberOfTokens, "Not on allowlist");
            Address.sendValue(payable(beneficiary), msg.value);
            allowList.decrease(to,numberOfTokens);
            _mintBatch(to, numberOfTokens);
            emit Sale(to, numberOfTokens,msg.value);
        }
    }

    function mintGift(uint256 numberOfTokens, address recipient) public onlyRole(MINTER_ROLE) whenNotPaused {
        _mintBatch(recipient, numberOfTokens);
    }


// VIEW

    function allowListCount(address _addr) public view returns (uint) {
        return allowList.getCount(_addr);
    }

    function freeListCount(address _addr) public view returns (uint) {
        return allowList.getCountFree(_addr);
    }

  function remaining() public view returns (uint256) {
    return deck.remaining();
  }

  function whitelistAddr() public view returns (address) {
    return address(allowList);
  }

// URI

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getBaseURI() public view returns (string memory){
        return baseURI;
    }

// ADMIN

    function setDefaultRoyalty(address _addr, uint96 _points) public onlyRole(MINTER_ROLE) whenNotPaused {
        _setDefaultRoyalty(_addr, _points);
    }

    function setPublicSale(bool _val) public onlyRole(MINTER_ROLE) {
        publicSale = _val;
    }

    function setBaseURI(string memory _ipfsHash) public onlyRole(MINTER_ROLE)  {
        string memory _pre = "ipfs://";
        string memory _post = "/";
        baseURI = string(abi.encodePacked(_pre, _ipfsHash, _post));
    }

    function setAllowlistContract(address addr) public onlyRole(MINTER_ROLE){
        allowList = AllowList(addr);
    }

    function pause() public onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MINTER_ROLE) {
        _unpause();
    }

    function setBeneficiary(address newBeneficiary) public onlyRole(MINTER_ROLE) {
        beneficiary = newBeneficiary;
    }

    function setPrice(uint _price) public onlyRole(MINTER_ROLE) {
        price = _price;
    }

    function withdraw(address _addr)public onlyRole(MINTER_ROLE) {
        Address.sendValue(payable(_addr), address(this).balance);
    }

// Internal + Overrides

    function _mintBatch(address to, uint256 count) internal {
        for (uint256 i = 0; i < count; ++i) {
            _mint(to, deck.draw());
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }
}

library Random {
    function random() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)) ;
    }

    struct Manifest {
        uint256[] _data;
    }

    function setup(Manifest storage self, uint256 length) internal {
        uint256[] storage data = self._data;

        require(data.length == 0, "cannot-setup-during-active-draw");
        assembly { sstore(data.slot, length) }
    }

    function draw(Manifest storage self) internal returns (uint256) {
        return draw(self, random());
    }

    function draw(Manifest storage self, bytes32 seed) internal returns (uint256) {
        uint256[] storage data = self._data;

        uint256 l = data.length;
        uint256 i = uint256(seed) % l;
        uint256 x = data[i];
        uint256 y = data[--l];
        if (x == 0) { x = i + 1;   }
        if (y == 0) { y = l + 1;   }
        if (i != l) { data[i] = y; }
        data.pop();
        return x - 1;
    }

    function put(Manifest storage self, uint256 i) internal {
        self._data.push(i + 1);
    }

    function remaining(Manifest storage self) internal view returns (uint256) {
        return self._data.length;
    }
}