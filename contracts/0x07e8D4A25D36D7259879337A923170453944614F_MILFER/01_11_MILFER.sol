/*
*  _____ ______   ___  ___       ________  ________      ___    ___ 
*  |\   _ \  _   \|\  \|\  \     |\   __  \|\   ___ \    |\  \  /  /|
*  \ \  \\\__\ \  \ \  \ \  \    \ \  \|\  \ \  \_|\ \   \ \  \/  / /
*   \ \  \\|__| \  \ \  \ \  \    \ \   __  \ \  \ \\ \   \ \    / / 
*    \ \  \    \ \  \ \  \ \  \____\ \  \ \  \ \  \_\\ \   \/  /  /  
*     \ \__\    \ \__\ \__\ \_______\ \__\ \__\ \_______\__/  / /    
*      \|__|     \|__|\|__|\|_______|\|__|\|__|\|_______|\___/ /     
*                                                       \|___|/     
*   ███    ███ ███████ ███████ ██████  ███████ 
*   ████  ████ ██      ██      ██   ██ ██      
*   ██ ████ ██ █████   █████   ██████  ███████ 
*   ██  ██  ██ ██      ██      ██   ██      ██ 
*   ██      ██ ██      ███████ ██   ██ ███████ 
*                                     
*   by: hyogohime.eth   
*/
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error MaxQuantityExceeded();
error InsufficientEther();
error ExceedsMaximumSupply();

contract MILFER is ERC721A, Ownable {
    uint256 public constant MINT_PRICE = 0.008 ether;
    uint256 public constant MAX_MILFERS = 10000;
    string public constant BASE_URI = "ipfs://QmV977YVJwmgYzg2tRimTcZDdzWrBoH2uoz7Pzdph7PQB3/";

    constructor() ERC721A("milady mfers", "MILFER") {}

    function mintMiladies(uint256 qty) public payable {
        if(qty > 100) revert MaxQuantityExceeded();

        unchecked {
            if(MINT_PRICE * qty > msg.value) revert InsufficientEther();
            if(totalSupply() + qty > MAX_MILFERS) revert ExceedsMaximumSupply();

            _safeMint(msg.sender, qty);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return BASE_URI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}