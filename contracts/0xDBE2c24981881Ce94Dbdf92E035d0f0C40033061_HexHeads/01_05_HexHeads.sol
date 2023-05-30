pragma solidity ^0.8.17;

import "../libs/ERC721.sol";
import "../libs/Owned.sol";
import "./utils/Strings.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//  ██╗  ██╗ ███████╗ ██╗  ██╗ ██╗  ██╗ ███████╗  █████╗  ██████╗  ███████╗  //
//  ██║  ██║ ██╔════╝ ╚██╗██╔╝ ██║  ██║ ██╔════╝ ██╔══██╗ ██╔══██╗ ██╔════╝  //
//  ███████║ █████╗    ╚███╔╝  ███████║ █████╗   ███████║ ██║  ██║ ███████╗  //
//  ██╔══██║ ██╔══╝    ██╔██╗  ██╔══██║ ██╔══╝   ██╔══██║ ██║  ██║ ╚════██║  //
//  ██║  ██║ ███████╗ ██╔╝ ██╗ ██║  ██║ ███████╗ ██║  ██║ ██████╔╝ ███████║  //
//  ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝ ╚═════╝  ╚══════╝  //
//                           The faces of Ethereum                           //
//                                hexheads.io                                //
///////////////////////////////////////////////////////////////////////////////

contract HexHeads is ERC721, Owned {

    //// PUBLIC STORAGE ////

    /// CONSTANTS ///
    uint256 constant public maxSupply = 1461501637330902918203684832716283019655932542975;
    
    /// MUTABLES ///
    mapping(uint256 => bool) public burnt;
    address public operator;

    //// PRIVATE STORAGE ////

    string private _baseURI;

    //// MODIFIERS ////

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can call this function.");
        _;
    }

    //// CONSTRUCTOR ////

    constructor(
        address owner_,
        address operator_,
        string memory baseURI_
    ) ERC721("HexHeads", "HH") Owned(owner_) {
        operator = operator_;
        _baseURI = baseURI_;
    }

    //// PUBLIC FUNCTIONS ////

    function mint() external {
        uint256 id = uint256(uint160(msg.sender));
        require(!burnt[id], "TOKEN_IS_BURNT");

        _mint(msg.sender, id);
    }

    function tokenURI(
        uint256 id
    ) public view override returns (string memory) {
        return string.concat(_baseURI, Strings.toString(id));
    }

    //// ONLY OPERATOR ////

    function burn(
        uint256 id
    ) public onlyOperator {
        burnt[id] = true;
        _burn(id);
    }

    //// ONLY OWNER ////

    function setBaseUri(
        string memory baseURI
    ) public onlyOwner {
        _baseURI = baseURI;
    }

    function setOperator(
        address operator_
    ) public onlyOwner {
        operator = operator_;
    }

}