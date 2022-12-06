// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/*


 #####  #     #    #    #######  #####                ###   #     # ######  
#     # #     #   # #   #     # #     #              #   #   #   #  #     # 
#       #     #  #   #  #     # #                   #     #   # #   #     # 
#       ####### #     # #     #  #####     #####    #     #    #    #     # 
#       #     # ####### #     #       #             #     #   # #   #     # 
#     # #     # #     # #     # #     #              #   #   #   #  #     # 
 #####  #     # #     # #######  #####                ###   #     # ######  
                                                                            


*/

/*

max-supply : 113
maximum mint per wallet : 10
mint price : 0.02 eth
It will be revealed after all the nfts are minted

*/

contract Chaos is ERC721ABurnable, Ownable {

    error MintAmountExceeded();
    error InsufficientAmount();

    uint8 constant public MAXIMUM_MINT_PER_USER = 10;
    uint8 constant MAX_SUPPLY = 113;
    string constant HIDDEN_IPFS = "ipfs://bafkreibqmnw6fnlhwsyprfakcxwqozjcownrzrn3r57anue7xwmtnck3sq";
    string public baseURI;
    uint64 public price = 0.02 ether;
    bool public isRevealed;

    constructor() ERC721A("Chaos","Chaos") {
        _safeMint(msg.sender,1);
    }

    function mint(uint8 _amount) external payable {
        if(balanceOf(msg.sender)+_amount > MAXIMUM_MINT_PER_USER) revert MintAmountExceeded();
        if(price*_amount != msg.value) revert InsufficientAmount();
        _safeMint(msg.sender,_amount);
    }

    function onwerMint(uint8 _amount) external onlyOwner {
        _safeMint(msg.sender,_amount);
    }

    function tokenURI(uint256 tokenId) public view  override(ERC721A,IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if(!isRevealed){
            return HIDDEN_IPFS;
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
   function setRevealed(bool  _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }
    function withdraw() external onlyOwner {
        (bool _res, ) = msg.sender.call{value:address(this).balance}('');
        require(_res, "FAIL");
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}