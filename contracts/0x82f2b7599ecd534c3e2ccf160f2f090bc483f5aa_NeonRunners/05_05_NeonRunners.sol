/**
 *
 *
 *         _ __   ___  ___  _ __    _ __ _   _ _ __  _ __   ___ _ __ ___       
 *        | '_ \ / _ \/ _ \| '_ \  | '__| | | | '_ \| '_ \ / _ \ '__/ __|   
 *        | | | |  __/ (_) | | | | | |  | |_| | | | | | | |  __/ |  \__ \  
 *        |_| |_|\___|\___/|_| |_| |_|   \__,_|_| |_|_| |_|\___|_|  |___/ 
 *
 *
 * 
 *                    art by: fumeiji.eth | contract by: ens0.eth
 */

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

error MaxQuantityExceeded();
error InsufficientEther();
error ExceedsMaximumSupply();

contract NeonRunners is ERC721A, Ownable {
    uint256 public constant MINT_PRICE = 0.005 ether;
    uint16 public constant MAX_TOKENS = 345;

    string public baseURI = "";

    constructor() ERC721A("neon runners", "CYBERDORK") {
        _mintERC2309(msg.sender, 10);
    }

    function runRunRun(uint256 qty) external payable {
        if(qty > 5) revert MaxQuantityExceeded();

        unchecked {
            if(MINT_PRICE * qty > msg.value) revert InsufficientEther();
            if(totalSupply() + qty > MAX_TOKENS) revert ExceedsMaximumSupply();

            _mint(msg.sender, qty);
        }
    }

    function effUPayMe() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function installChooms(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}