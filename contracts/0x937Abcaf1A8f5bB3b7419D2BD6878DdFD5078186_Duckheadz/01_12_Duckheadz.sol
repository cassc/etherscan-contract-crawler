// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;



import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Duckheadz is ERC721A, Ownable{
    using Strings for uint256;

    
    uint256 public constant TOTAL_SUPPLY = 3333;
    bool public headzMinted = false;
    uint256 public MINTS_PER_WALLET = 5;
    string private baseURI;

    //toggle paused
    bool public paused = true;

    //Just Mallards Flock Treasury address
    address public mallardAddress = 0x30D7e19e5Fa279907E24E49e3ea9CdD9B521cb9E;

    mapping(address => uint256) public totalMinted;

    constructor() ERC721A("Duckheadz", "QUACKZ") {

    }

    function headHeadMint() external onlyOwner {
        require(!headzMinted, "Only once, sir.");
        _safeMint(msg.sender, 100);
        headzMinted = true;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contract cannot be called from another contract. Quack");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require( paused == false, "Public mint is not yet active.");
        require((totalSupply() + _quantity) <= TOTAL_SUPPLY, "This transaction would exceed the total supply - 3,333");
        require((totalMinted[msg.sender] + _quantity) <= MINTS_PER_WALLET, "Only 20 headz can be minted per wallet.");
        require((msg.value >= 0.000 ether), "It's free, my guy!");

        totalMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // return uri for a token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");

        uint256 trueId = tokenId;

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, trueId.toString(), ".json")) : "";
    }

    //walletOf() function shouldn't be called on-chain due to gas consumption.
    function walletOf() external view returns(uint256[] memory) {
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++) {
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function withdraw() external onlyOwner{
        //7% royalty fee set for this project. 2% will be sent to the JustMallards Flock Treasury automatically.
        uint256 flockPiece = address(this).balance * 2/7;
        payable(mallardAddress).transfer(flockPiece);
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMallardsAddress(address _mallardAddress) public onlyOwner {
        mallardAddress = _mallardAddress;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setMaxPerWallet(uint256 _MINTS_PER_WALLET) public onlyOwner {
        MINTS_PER_WALLET = _MINTS_PER_WALLET;
    }
    
    receive() external payable {}
}