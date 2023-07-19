//SPDX-License-Identifier: MIT

/////////////////////////////////RYOKO.CLUB///////////////////////////////////
//                                                                   ,,     //
//                                                             ,, ╔▓▓▓▓▓▓▄  //
//          ,                          ,▄                    ▀╙└ j▓▓▓▓▓▓▓▓  //
//    █╓▄▓▓▓██▌   ╓▓█µ     ▄▌`  ╓▓▓▓██████╙   █    ▓██¬   ,▄█▓▓██████▓▓▓▓▀  //
//  ▀▀█▌╙└─  ██    ▀██▄  ╓█▀   ███▀└   ╙██▌   █   ╫██    ╫██▀╙    ███╨╨╙    //
//   ,██ ╓   ██▌    └▓█▌▓█╙    ]█▌      ██▓  ▐█µ▀▓█▀      ██      ╟██       //
//  ╫██████▓▓██▓⌐     └██▌     ╞██      ╟█▌  ║█▌▓██▓┐     ██       ██       //
//    ██▌ └██▌└       ▐██▀m    ▐██▄     ▐█⌐  ╟██╙  ▓█▌    ██▓      █▌       //
//   ▐██▌   ▀██▓▄     ███─     ,███████████  ▓██b   ███⌐  ▓██████████▌      //
//   ╙▀▀     └▀╙      ▀╙╙      └╙▀╙     ▀└`  "▀╙     ▀╙└ └ ▀╙└    ╙└╙       //
//////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Options.sol";

contract Ryoko is ERC721ABurnable, Ownable, ReentrancyGuard, Options{

    string private baseURI;

    constructor(
        string memory _initBaseURI,
        uint256 _initCost
    ) ERC721A("Ryoko", "RYOKO"){
        setBaseURI(_initBaseURI);
        setCost(_initCost);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _quantity) external payable callerIsUser{
        require(!paused);
        require(_quantity > 0);
        require(_quantity <= maxMintAmount);
        require(totalSupply() + _quantity <= maxSupply, "Not enough tokens left");

        uint256 cost = mintCost;
        uint256 balance = balanceOf(msg.sender);
        bool zeroCost = ((totalSupply() + _quantity < freeAmount + 1) && (balance + _quantity <= maxFreePerWallet));

        if (zeroCost) {
            cost = 0;
        }

        require(msg.value >= cost * _quantity, "Not enough ether sent");
        require(
            numberMinted(msg.sender) + _quantity <= maxMintAmount, "You have reached the mint limit."
        );
        _safeMint(msg.sender, _quantity);
    }

    function ownerMint(uint256 _quantity) external onlyOwner{
        _safeMint(msg.sender, _quantity);
    }

    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function numberBurned(address _owner) public view returns (uint256) {
        return _numberBurned(_owner);
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), baseExtension))
            : "";
    }

    //Only Owner
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setFreeAmount(uint256 _amount) external onlyOwner {
        freeAmount = _amount;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        mintCost = _newCost;
    }

    function withdraw() public payable onlyOwner {
        (bool wd, ) = payable(owner()).call{value: address(this).balance}("");
        require(wd);
    }
}