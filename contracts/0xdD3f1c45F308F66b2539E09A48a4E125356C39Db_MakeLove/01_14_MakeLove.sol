// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC1155Base.sol";

contract MakeLove is ERC1155Base{
    bool private _isActive = false;

    uint256 public maxCountPerAccount = 1; 
    
    uint256 public price = 0.42 ether;

    uint8 constant MASTER = 0;
    uint8 constant VIP = 1;

    uint16 constant MAX_SUPPLY_MASTER = 420;
    uint16 constant MAX_SUPPLY_VIP = 42;

    mapping (uint256 => string) internal _tokenURIs;
    mapping (uint256 => string) internal _tokenMeta;

    struct Holder {
      address walletAddress;
      uint256 numMaster;
      uint256 numVip;
    }

    address constant I_am_g13m = 0xfBfF1eBff67093A239bC1343aE6a5e3372A14Ac0;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;
    }

    
    function ownerMint(address to, uint8 _amountMaster, uint8 _amountVip) external onlyOwner {
        uint256 totalAmount = _amountMaster + _amountVip;
        require(totalAmount != 0, "Invalid amount of tokens");
        require(
            totalSupply(VIP) + _amountVip <= MAX_SUPPLY_VIP &&
                totalSupply(MASTER) + _amountMaster <= MAX_SUPPLY_MASTER,
            "Max supply reached"
        );
        if (_amountMaster > 0) {
            _mintToken(to, MASTER, _amountMaster);
        }

        if (_amountVip > 0) {
            _mintToken(to, VIP, _amountVip);
        }
    }

    
    function publicMint(uint8 _amount) external payable {   
        require(_isActive,"Mint not live");
        _mintTokens(msg.sender, _amount);
        uint256 balance = address(this).balance;
        Address.sendValue(payable(I_am_g13m), balance);
    }

    function _mintTokens(address to, uint8 _amount) private {
        require(_amount != 0 && _amount <=maxCountPerAccount, "Invalid amount of tokens");
        require(
                totalSupply(MASTER) + _amount <= MAX_SUPPLY_MASTER,
            "Max supply reached"
        );

       require(
            msg.value >= _amount * price,
            "Invalid amount of funds sent"
        );

        if (_amount > 0) {
            _mintToken(to, MASTER, _amount);
        }
   }
    
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxMintPerAddr(uint256 _count) external onlyOwner {
        maxCountPerAccount = _count;
    }

    function _mintToken(address to, uint8 _tokenId, uint8 _amount) private {
        _mint(to, _tokenId, _amount, "");
    }

    function setTokenURI(uint256 tokenId, string calldata uri_) external onlyOwner {
        _tokenURIs[tokenId] = uri_;
    }
    
    function setTokenMeta(uint256 tokenId, string calldata meta_) external onlyOwner {
        _tokenMeta[tokenId] = meta_;
    }

    function startMint() external onlyOwner{
        _isActive=true;
    }

    function stopMint() external onlyOwner{
        _isActive=false;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(I_am_g13m), balance);
    }
 
    function uri(uint256 _id) public view override returns (string memory) {
       require(exists(_id), "Token does not exist");
       string memory metadata = Base64.encode(bytes(abi.encodePacked('{',_tokenMeta[_id],', "image":"data:image/svg+xml;base64,',Base64.encode(bytes(_tokenURIs[_id])),'"}')));
       return string(abi.encodePacked('data:application/json;base64,', metadata));
    }
}