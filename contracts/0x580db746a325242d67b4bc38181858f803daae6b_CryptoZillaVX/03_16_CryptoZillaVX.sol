// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ZillaToken.sol";
import "./ERC721Namable.sol";
import "./Ownable.sol";
import "./ERC721.sol";


contract CryptoZillaVX is ERC721Namable, Ownable {
    address withdrawAddress = 0x382A2754e8a19924760D6Ca55D8b8d39F5De5bCF;
    address constant public ZILLACONTRACT = address(0x5a7869dB28Eb513945167293638D59A336A89190);

    uint256 constant public BUYABLE = 1000;
    uint256 constant public TOKEN_BUYABLE = 10000;
    uint256 constant public PRICE = 1 ether / 100;
    uint256 constant public VX_CLAIM_BY_TOKEN_PRICE = 950 ether;

    string public _baseTokenURI;
    bool public publicSaleOpen = false;

    // Variables for counting etc
    uint256 public totalSupply;
    uint256 public tokenSold;
    uint256 public publicSold;

    ZillaToken public zillaToken;

    mapping(address => mapping(uint256 => uint256)) public utility;

    constructor(string[] memory _names, uint256[] memory _ids) ERC721Namable("CryptoZilla VX", "ZILLA VX", _names, _ids) {}

    // Claim the VX models for Genesis holders
    function claim(uint256[] memory _tokenIds) external {
        require(publicSaleOpen, "Claiming not started yet");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(IERC721(ZILLACONTRACT).ownerOf(_tokenIds[i]) == msg.sender, "Not the token owner!");
            require(!_exists(_tokenIds[i]), "Token already exists!");
            _mint(msg.sender, _tokenIds[i]);
            totalSupply++;
        }
    }

    // Mint up to 5 VX models, for the public starting at tokenId 1001
    function mint(uint256 _amount) external payable {
        require(publicSaleOpen, "Public sale has not started yet");
        require(_amount < 6, "You can at most mint 5 VX Zillas at a time!");
        require(publicSold + _amount <= BUYABLE, "Minting would exceed total buyable!");
        require(msg.value == PRICE * _amount, "Incorrect price!");

        for (uint256 i = 0; i < _amount; i++) {
            _mint(msg.sender, 1001 + publicSold);
            publicSold++;
        }
        totalSupply += _amount;
    }

    function claimByToken(uint256 _amount) external {
        require(publicSaleOpen, "Claiming not started yet");
        require(tokenSold + _amount <= TOKEN_BUYABLE, "Not enough VX Zillas left!");
        require(zillaToken.balanceOf(msg.sender) >= VX_CLAIM_BY_TOKEN_PRICE * _amount, "Not enough Zilla tokens!");

        for (uint256 i = 0; i < _amount; i++) {
            zillaToken.burn(msg.sender, VX_CLAIM_BY_TOKEN_PRICE);
            _mint(msg.sender, 2001 + tokenSold);
            tokenSold++;
        }
        totalSupply += _amount;
    }

    function addUtility(address user, uint identifier, uint amount) public onlyOwner {
        utility[user][identifier] = amount;
    }

    // The existing _exists function is private, but we need to access it from outside
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    // Returns the URI of the specified tokenID
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    // Sets the API endpoint
    function setBaseURI(string memory _baseURI) public onlyOwner {
        _baseTokenURI = _baseURI;
    }

    // Sets the ZillaToken contract address
    function setZillaToken(address _address) external onlyOwner {
        zillaToken = ZillaToken(_address);
    }

    function setPublicSaleOpen(bool val) public onlyOwner {
        publicSaleOpen = val;
    }

    // Change the naming price of the VX model
    function changeNamePrice(uint256 _price) external onlyOwner {
        nameChangePrice = _price;
    }

    // Change the name of the VX model, note set the CryptoZilla VX contract to the granted contracts in ZillaToken
    function changeName(uint256 tokenId, string memory newName) public override {
        zillaToken.burn(msg.sender, nameChangePrice);
        super.changeName(tokenId, newName);
    }

    function withdrawFunds() external payable onlyOwner{
        uint256 _balance = address(this).balance;
        require(payable(withdrawAddress).send(_balance));
    }
}
