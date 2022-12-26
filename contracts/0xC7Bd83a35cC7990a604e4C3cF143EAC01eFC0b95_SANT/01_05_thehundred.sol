pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";

contract SANT is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 100;

    uint256 public constant MAX_MINT_AMOUNT = 5;

    uint256 public constant MINT_PRICE = 0.01 ether;

    string private constant _PREREVEAL_URI =
        "ipfs://bafybeigrxn5adi6vpz4n2uuwjpi6ezp5vtd5yhsz7nb2nmp75g7pwosctu/santa.json";

    bool public isRevealed = false;

    bool public isMintable = true;

    mapping(address => uint256) private mintedAmountMap;

    string private _postRevealURI = "";

    constructor() ERC721A("The 100 Santas", "SANT") {}

   function withdrawEther(uint amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _postRevealURI;
    }

    function reveal(string memory _uri) external onlyOwner {
        isRevealed = true;
        _postRevealURI = _uri;
    }

    function setMintable(bool _isMintable) external onlyOwner {
        isMintable = _isMintable;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!isRevealed) {
            return _PREREVEAL_URI;
        } else {
            return string(abi.encodePacked(_baseURI(), _toString(tokenId)));
        }
    }

    function mint(uint256 _amount) external payable {
        require(msg.value >= _amount * MINT_PRICE);
        require(isMintable, "Mint disabled");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply reached");
        require(
            mintedAmountMap[msg.sender] + _amount <= MAX_MINT_AMOUNT,
            "Individual cap reached"
        );

        mintedAmountMap[msg.sender] += _amount;
        _mint(msg.sender, _amount);

    }
}