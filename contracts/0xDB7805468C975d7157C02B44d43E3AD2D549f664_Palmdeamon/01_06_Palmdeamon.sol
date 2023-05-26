//SPDX-License-Identifier: Unlicense
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./metadata.sol";

pragma solidity ^0.8.0;

contract Palmdeamon is ERC721, Metadata {
    address public admin;
    address public verificationcontract;

    mapping(uint256 => tdata) public tokendata;

    struct tdata {
        uint256 moisture;
        uint256 temperature;
        uint256 colorandlocation;
        string rtimestamp;
    }

    constructor(address _admin) ERC721("Seed Capital", "SDC") {
        admin = _admin;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            generatemetadata(
                id,
                tokendata[id].moisture,
                tokendata[id].temperature,
                tokendata[id].colorandlocation,
                tokendata[id].rtimestamp
            );
    }

    function setverificationcontract(address _verificationcontract) public {
        require(msg.sender == admin, "only admin can set verificationcontract");
        verificationcontract = _verificationcontract;
    }

    function setadmin(address newadmin) public {
        require(msg.sender == admin, "only admin can set admin");
        admin = newadmin;
    }

    function generatecolorprofile(
        uint256 profile,
        string memory firsthex,
        string memory secondhex,
        string memory venue,
        string memory plant,
        string memory curator 
    ) public {
        require(msg.sender == admin, "only admin can set colorprofile");
        _generatecolorprofile(
            profile,
            firsthex,
            secondhex,
            venue,
            plant,
            curator 
        );
    }

    function mintafterverification(
        uint256 value1,
        uint256 value2,
        uint256 colorpointer,
        uint256 tokenid,
        string memory rtimestamp
    ) public {
        require(
            msg.sender == verificationcontract,
            "minting can only be called from verification contract"
        );
        require(
            verificationcontract != address(0),
            "no verification contract set"
        );
        tokendata[tokenid].moisture = value1;
        tokendata[tokenid].temperature = value2;
        tokendata[tokenid].colorandlocation = colorpointer;
        tokendata[tokenid].rtimestamp = rtimestamp;
        _mint(tx.origin, tokenid);
    }
}