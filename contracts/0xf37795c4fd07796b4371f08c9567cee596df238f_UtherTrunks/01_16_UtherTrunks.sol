// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MRC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract UtherTrunks is MRC1155, Ownable {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public constant MALE = 1;
    uint256 public constant FEMALE = 2;

    uint256 public MAX_SUPPLY = 3333;

    // total number of NFTs that could be minted
    // in public sale
    uint256 public maxCap = 3333;

    uint256 public unitPrice = 0.35 ether;
    
    uint8 public maxPerUser = 20;
    
    bool public paused = true;
    bool public pausedPrivate = true;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), 'Only Admin');
        _;
    }


    constructor(
    ) MRC1155(
        "The Uther Trunks",
        "TUT",
        "https://uther-trunks.communitynftproject.io/"
    )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    	_setupRole(ADMIN_ROLE, msg.sender);
    	_setupRole(MINTER_ROLE, msg.sender);
    }

    function price(uint _count) public view returns (uint256) {
        return _count * unitPrice;
    }


    // allows everyone to mint on public sale
    function publicMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) virtual payable external {
        require(!paused, 'paused');
        require(amount <= maxPerUser, '> maxPerUser');
        require(amount + totalSupply(MALE) + totalSupply(FEMALE) <= maxCap, '> maxcap');
        require(msg.value >= price(amount));
        super.mint(to, id, amount, data);
    }

    /** 
     Admin can grant MINTER_ROLE
     to another minter contract and let it mint.
     We need it for private sale. The minter contract can 
     check the whitelist and then mint.
    */
    function privateMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE){
        require(!pausedPrivate, 'paused');
        require(amount <= maxPerUser, '> maxPerUser');
        require(amount + totalSupply(MALE) + totalSupply(FEMALE) <= maxCap, '> maxcap');
        super.mint(to, id, amount, data);
    }

    function _beforeMint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        require(totalSupply(MALE) + totalSupply(FEMALE) + amount <= MAX_SUPPLY, "> maxSupply");
    }

    function uri(uint256 _id) override view public returns(string memory){
        return string(abi.encodePacked(
            super.uri(_id),
            Strings.toString(_id)
        ));
    }

    function setMaxCap(uint256 _cap) public onlyAdmin {
        maxCap = _cap;
    }

    function setPaused(bool _pause) public onlyAdmin {
        paused = _pause;
    }

    function setPausedPrivate(bool _pause) public onlyAdmin {
        pausedPrivate = _pause;
    }

    function setUnitPrice(uint256 _price) public onlyAdmin {
        unitPrice = _price;
    }

    function setMaxPerUser(uint8 _maxPerUser) public onlyAdmin {
        maxPerUser = _maxPerUser;
    }

    // lets the owner withdraw ETH and ERC20 tokens
    function ownerWT(uint256 amount, address _to,
            address _tokenAddr) public onlyOwner{
        require(_to != address(0));
        if(_tokenAddr == address(0)){
            payable(_to).transfer(amount);
        }else{
            IERC20(_tokenAddr).transfer(_to, amount);
        }
    }
}