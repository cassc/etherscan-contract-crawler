//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();
error ArraysDontMatch();
//@0xSimon
contract PuffPuffPandas is ERC721AQueryable, ERC2981,Ownable,DefaultOperatorFilterer {
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint constant public MAX_SUPPLY = 6666;
    uint public publicPrice = .099 ether;
    uint public presalePrice = .09 ether;
    uint public maxPublicMints = 3;
    string public baseURI;
    string public notRevealedUri = "ipfs://QmexJhweLAquZANgwhR4d3EpKbSciKUwfgNieSwjYazerU";
    string public uriSuffix = ".json";

    address private signer = 0x6884efd53b2650679996D3Ea206D116356dA08a9;
    bool public revealed;
    enum SaleStatus  {INACTIVE,PRESALE,PUBLIC}
    SaleStatus public saleStatus = SaleStatus.INACTIVE;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor()
        ERC721A("Puff Puff Pandas", "PUFF")
    {
        //Fee Denominator is 10000 -> 5% = 50/10000
        _setDefaultRoyalty(_msgSender(),50);
    }

    function airdrop(address[] calldata accounts,uint[] calldata amounts) external onlyOwner {
        if(accounts.length != amounts.length) revert ArraysDontMatch();
        uint supply = totalSupply();
        for(uint i; i<accounts.length;){
            if(supply + amounts[i] > MAX_SUPPLY) revert SoldOut();
            unchecked{
                supply += amounts[i];
            }
            _mint(accounts[i],amounts[i]);
            unchecked{
                ++i;
            }
        }     
    }

    /*///////////////////////////////////////////////////////////////
                          MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function presaleMint(uint amount,uint max, bytes memory signature) external payable {
        if(saleStatus != SaleStatus.PRESALE) revert SaleNotStarted();
        if(totalSupply() + amount > MAX_SUPPLY) revert SoldOut();
        bytes32 hash = keccak256(abi.encodePacked("PRESALE",max,_msgSender()));
        if(hash.toEthSignedMessageHash().recover(signature)!=signer) revert NotWhitelisted();
        if(_numberMinted(_msgSender()) + amount > max) revert MaxMints();
        if(msg.value < presalePrice * amount) revert Underpriced();
        _mint(_msgSender(),amount);
    }

  
    function publicMint(uint amount) external payable {
        if(saleStatus != SaleStatus.PUBLIC) revert SaleNotStarted();
        if(totalSupply() + amount > MAX_SUPPLY) revert SoldOut();
        uint numMinted = uint(_getAux(_msgSender()));
        if(numMinted + amount > maxPublicMints) revert MaxMints();
        //Impossible To Overflow Since Supply < type(uint64).max
        _setAux(_msgSender(),uint64(numMinted+amount));
        if(msg.value < amount * publicPrice) revert Underpriced();
        _mint(_msgSender(),amount);
    }
    function getNumMintedPresale(address account) public view returns(uint){
        return _numberMinted(account);
    }
    function getNumMintedPublic(address account) public view returns(uint){
        return uint(_getAux(account));
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

    function setPresaleOn() external onlyOwner {
        saleStatus = SaleStatus.PRESALE;
    }
    function setPublicOn() external onlyOwner {
        saleStatus = SaleStatus.PUBLIC;
    }
    function turnSalesOff() external onlyOwner{
        saleStatus = SaleStatus.INACTIVE;
    }
    function setPublicPrice(uint newPrice) external onlyOwner{
        publicPrice = newPrice;
    }
    function setPresalePrice(uint newPrice) external onlyOwner {
        presalePrice = newPrice;
    }
 
    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }
    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }
    function setMaxPublicMints(uint newMax) external onlyOwner{
        maxPublicMints = newMax;
    }

    /*///////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721A,ERC721A)
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

/*
                    Puff Puff Pandas Payouts
    84.70%	0xe9DCE9808E65F0821d22EDa8d0b449Cf7Cc187b7
	2.80%	0x88eC23121FaE1fbC00e7f4ae8Afe578aA2e9625b
	5.00%	0x30C53d45ca0cf73a7DC17CEa4Fa535937cf09980
	2.50%	0x6d10aB9b038122124de213a2BA8C9E6234fF3D4c
	1.00%	0x585aad11F01665782cda10bE30B3604CE8320C74
	1.00%	0xecCb0F9F5C4b74568301900b2f312181d5F3d0dB
	2.00%	0xA70988Ca797Ec4943BE0366323b2D8613b757d9d FullyPickled. eth
    1.00%   0xB168E15AB01F90E7A0d6454493983c25F0c33003
    
*/
      function withdraw() public  onlyOwner {
        uint balance = address(this).balance;
        payable(0xe9DCE9808E65F0821d22EDa8d0b449Cf7Cc187b7).transfer(balance * 8470/10000); //84.70%
        payable(0x88eC23121FaE1fbC00e7f4ae8Afe578aA2e9625b).transfer(balance * 280/10000);  //2.80%
        payable(0x30C53d45ca0cf73a7DC17CEa4Fa535937cf09980).transfer(balance * 500/10000);  //5.00%
        payable(0x6d10aB9b038122124de213a2BA8C9E6234fF3D4c).transfer(balance * 250/10000);  //2.50%
        payable(0x585aad11F01665782cda10bE30B3604CE8320C74).transfer(balance * 100/10000);  //1.00%
        payable(0xecCb0F9F5C4b74568301900b2f312181d5F3d0dB).transfer(balance * 100/10000);  //1.00%
        payable(0xA70988Ca797Ec4943BE0366323b2D8613b757d9d).transfer(balance * 200/10000);  //2.00%
        payable(0xB168E15AB01F90E7A0d6454493983c25F0c33003).transfer(balance * 100/10000);  //1.00%

    }

    /*
    --Overrides and Opensea Filterer--
    */

    //Start Token ID at 1 To Align With JSONs and PNGs
    function _startTokenId() internal view override(ERC721A) virtual returns (uint256) {
        return 1;
    }


    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A,ERC721A, ERC2981) returns (bool) {

        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }
    function transferFrom(address from, address to, uint256 tokenId) public  payable override (IERC721A,ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable  override (IERC721A,ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public  payable 
        override (IERC721A,ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


   

}