//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error WalkThePlank();
error ArraysDontMatch();
error LookAtMeIAmTheCaptainNow();
error iM_a_TrAdEr();
error ExtinctionBaby();
contract LooksChest2 is ERC721AQueryable, Ownable{
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint constant public maxSupply = 1000;
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";


    address private captain = 0xeC19af89f554B66c1FF80D353cdb2919b784Bb41;
    bool public revealed;
    uint private constant chestPrice = .01 ether;

    bool public bootyOpen;

 

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor()
        ERC721A("LooksChest2", "LCHEST2")
    {
        setNotRevealedURI("ipfs://QmTKrCBbJBvH11LZm4aeeJfhrjNJ7Ur7eS96egRETz94Gv");
    }



    /*///////////////////////////////////////////////////////////////
                          MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintThatBooty(uint amount) external payable {
        require(bootyOpen,"booty not open");
        if(_nextTokenId()+ amount > maxSupply) revert ExtinctionBaby();
        if(msg.value < amount * chestPrice) revert iM_a_TrAdEr();
        _mint(_msgSender(),amount);
    }
   

    /*///////////////////////////////////////////////////////////////
                          MINTING UTILITIES
    //////////////////////////////////////////////////////////////*/
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function isOwnerOfBatch(address account,uint[] calldata tokenIds) external view returns(bool) {
        for(uint i; i<tokenIds.length;++i){
            if(account != ownerOf(tokenIds[i])) return false;
        }
        return true;
    }
    function burnChests(uint[] calldata chestIds, bytes[] memory signatures,uint[] calldata values) external {
        uint payout;
        for(uint i; i<chestIds.length;++i){
            uint chest = chestIds[i];
            uint value = values[i];
            bytes memory sig = signatures[i];
            bytes32 hash = keccak256(abi.encodePacked("C2",chest,value));
            require(_msgSender() == ownerOf(chest),"Not Owner"); 
            if(hash.toEthSignedMessageHash().recover(sig) != captain) revert LookAtMeIAmTheCaptainNow();
            payout += value;
            _burn(chest);
            
        }
        (bool r1,) = payable(_msgSender()).call{value:payout}("");
        require(r1);

    }
    function depositMoney() external payable{
        return;
    }
    function emergencyWithdraw() external  onlyOwner{
        (bool r1,) = payable(owner()).call{value:address(this).balance}("");
        require(r1);
    }
    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }
    function setSigner(address _signer) external onlyOwner{
        captain = _signer;
    }

    function toggleBooty() external onlyOwner{
        bootyOpen = !bootyOpen;
    }

    /*///////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _toString(tokenId),uriSuffix))
                : "";
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/
      function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

   

}