//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title SixthRéseau Lucidia Dream Cardholder Contract
/// @author SphericonIO
contract SixthReseauLucidiaCardholder is ERC1155Supply, Ownable {
    using SafeMath for uint256;

    uint public maxSupply = 884;

    string public _baseTokenUri;

    string public name = "Sixth Reseau Lucidia Dreams Cardholder";
    string public symbol = "SRLDC";

    address public lucidia;

    mapping(address => bool) private _minted;

    constructor(string memory _uri, address _lucidia) 
    ERC1155(_uri){
        setLucidia(_lucidia);
        setBaseTokenURI(_uri);
    }

    /// @notice Claim Lucidia Dreams Card Holder token, caller must own a Lucidia Dream
    function claim() public {
        require(totalSupply(1).add(1) < maxSupply, "Lucidia Dreams Cardholder: Max supply is reached");
        require(!_minted[msg.sender], "Lucidia Dreams Cardholder: You have already minted your Lucidia Dreams Cardholder token");
        require(IERC1155(lucidia).balanceOf(msg.sender, 1) >= 1, "Lucidia Dreams Cardholder: You are not elgible to claim a Lucidia Dreams Cardholder token");
        _minted[msg.sender] = true;
        _mint(msg.sender, 1, 1, "");
    }

    function hasClaimed(address _owner) public view returns (bool) {
        return _minted[_owner];
    }

    /// @notice Mint Lucidia Dreams Cardholders tokens to an address
    /// @param _to Address tokens get minted to
    /// @param _amount Amount of tokens to mint
    function reserveMint(address _to, uint _amount) external onlyOwner {
        _mint(_to, 1, _amount, "");
    }

    /// @notice Set the URI of the metadata
    /// @param _uri New metadata URI
    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenUri = _uri;
    }

    /// @notice Set the address of the Lucidia Dreams Smart Contract
    /// @param _address New address
    function setLucidia(address _address) public onlyOwner {
        lucidia = _address;
    }

    /// @notice Metadata of each token
    /// @param _tokenId Token id to get metadata of
    /// @return Metadata URI of the token
    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId), "URI: nonexistent token");
        return string(abi.encodePacked(abi.encodePacked(_baseTokenUri, Strings.toString(_tokenId)), ".json"));
    }
}