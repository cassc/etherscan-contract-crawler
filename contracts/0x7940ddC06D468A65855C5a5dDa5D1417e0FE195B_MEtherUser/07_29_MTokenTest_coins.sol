pragma solidity ^0.5.16;

import "./open-zeppelin/token/ERC721/ERC721.sol";
import "./open-zeppelin/token/ERC721/IERC721Metadata.sol";
import "./open-zeppelin/token/ERC20/ERC20.sol";

contract TestNFT is ERC721, IERC721Metadata {

    string internal constant _name = "Glasses";
    string internal constant _symbol = "GLSS";
    uint256 public constant price = 0.1e18;
    uint256 public constant maxSupply = 1000;
    uint256 public nextTokenID;
    address payable public admin;
    string internal _baseURI;
    uint internal _digits;
    string internal _suffix;

    constructor(address payable _admin) ERC721(_name, _symbol) public {
        admin = msg.sender;
        _setMetadata("ipfs://QmWNi2ByeUbY1fWbMq841nvNW2tDTpNzyGAhxWDqoXTAEr", 0, "");
        admin = _admin;
    }
    
    function mint() public payable returns (uint256 newTokenID) {
        require(nextTokenID < maxSupply, "all Glasses sold out");
        require(msg.value >= price, "payment too low");
        newTokenID = nextTokenID;
        nextTokenID++;
        _safeMint(msg.sender, newTokenID);
    }

    function () external payable {
        mint();
    }

//***** below this is just for trying out NFTX market functionality */
    function buyAndRedeem(uint256 vaultId, uint256 amount, uint256[] calldata specificIds, address[] calldata path, address to) external payable {
        path;
        require(vaultId == 2, "wrong vault");
        require(amount == 1, "wrong amount");
        require(specificIds[0] == nextTokenID, "wrong ID");
        require(to == msg.sender, "wrong to");
        mint();
    }
//***** above this is just for trying out NFTX market functionality */

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (_digits == 0) {
            return string(abi.encodePacked(_baseURI, _suffix));
        }
        else {
            bytes memory _tokenID = new bytes(_digits);
            uint _i = _digits;
            while (_i != 0) {
                _i--;
                _tokenID[_i] = bytes1(48 + uint8(tokenId % 10));
                tokenId /= 10;
            }
            return string(abi.encodePacked(_baseURI, string(_tokenID), _suffix));
        }
    }

    /*** Admin functions ***/

    function _setMetadata(string memory newBaseURI, uint newDigits, string memory newSuffix) public {
        require(msg.sender == admin, "only admin");
        require(newDigits < 10, "newDigits too big");
        _baseURI = newBaseURI;
        _digits = newDigits;
        _suffix = newSuffix;
    }

    function _setAdmin(address payable newAdmin) public {
        require(msg.sender == admin, "only admin");
        admin = newAdmin;
    }

    function _withdraw() external {
        require(msg.sender == admin, "only admin");
        admin.transfer(address(this).balance);
    }
}

contract TestERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) public {
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}