pragma solidity ^0.8.4;

import "./erc721a.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Salmonela is ERC721A,Ownable {

    string private baseuri="";

    constructor() ERC721A("Salmonela", "Salmonela") {

        _setTransferer(msg.sender,true);

    }

    function mint(uint256 quantity,address user) external payable onlyOwner {
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(user, quantity);
    }

    function setBaseUri(string memory uri) external onlyOwner{
        baseuri=uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseuri;
    }

    function silentRemoveApproval(address operator) external{
        _silentRemoveApproval(operator);
    }

    function setTransferer(address transferer,bool toggle) external onlyOwner{
        _setTransferer(transferer,toggle);
    }

    function unsetTransfererCheck() external onlyOwner{
        _unsetTransfererCheck();
    }

}