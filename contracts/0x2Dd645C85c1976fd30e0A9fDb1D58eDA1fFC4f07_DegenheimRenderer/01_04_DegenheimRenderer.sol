// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

DegenheimRenderer.sol

Written by: mousedev.eth

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IDegenheim {
    function totalSupply() external view returns (uint256);
}

contract DegenheimRenderer is Ownable {
    string public unrevealedURI = "ipfs://QmXsR3XvPwUCjbcRHdDtQnnMpM9NswKPxUFXVBdrXY11NK";
    string public baseURI;
    string public baseURIEXT = ".json";

    bool public revealed;

    uint256 public shiftAmount;
    uint256 public commitBlock;

    address public degenheimAddress;

    function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    function setBaseURIEXT(string memory _baseURIEXT) public onlyOwner {
        baseURIEXT = _baseURIEXT;
    }

    function commit(string memory _baseURI) public onlyOwner {
        require(commitBlock == 0, "Commit block already set!");

        commitBlock = block.number + 5;
        baseURI = _baseURI;
    }

    function setDegenheimAddress(address _degenheimAddress) public onlyOwner {
        degenheimAddress = _degenheimAddress;
    }

    function reveal() public onlyOwner {
        require(block.number >= commitBlock, "Hasn't passed commit block!");
        require(commitBlock > 0, "Commit block not set!");
        require(!revealed, "Has already been revealed");

        shiftAmount = uint256(blockhash(commitBlock));
        revealed = true;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        if (revealed) {
            uint256 _newTokenId = (_tokenId + shiftAmount) %
                IDegenheim(degenheimAddress).totalSupply();
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(_newTokenId),
                        baseURIEXT
                    )
                );
        } else {
            return unrevealedURI;
        }
    }
}