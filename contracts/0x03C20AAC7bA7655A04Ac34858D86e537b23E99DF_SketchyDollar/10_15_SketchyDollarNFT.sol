// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/*
███████╗██╗  ██╗███████╗████████╗ ██████╗██╗  ██╗██╗   ██╗    ██████╗  ██████╗ ██╗     ██╗      █████╗ ██████╗ 
██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝██╔════╝██║  ██║╚██╗ ██╔╝    ██╔══██╗██╔═══██╗██║     ██║     ██╔══██╗██╔══██╗
███████╗█████╔╝ █████╗     ██║   ██║     ███████║ ╚████╔╝     ██║  ██║██║   ██║██║     ██║     ███████║██████╔╝
╚════██║██╔═██╗ ██╔══╝     ██║   ██║     ██╔══██║  ╚██╔╝      ██║  ██║██║   ██║██║     ██║     ██╔══██║██╔══██╗
███████║██║  ██╗███████╗   ██║   ╚██████╗██║  ██║   ██║       ██████╔╝╚██████╔╝███████╗███████╗██║  ██║██║  ██║
╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝   ╚═╝       ╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";

contract SketchyDollar is ERC721A, Ownable, ReentrancyGuard, OperatorFilterer, CantBeEvil(LicenseVersion.COMMERCIAL_NO_HATE) {
    
    struct ConfigStateData {
        uint8 maxTokensPerTxn;
        uint8 maxTokensForCreator;
        uint16 maxTokens;
        saleState salestate;
        string baseUri;
        uint256 publicMintPrice;
        address projectWallet;
        bool creatorAllowedMint;
    }

    enum saleState { paused, publicsale }
    ConfigStateData public myContractStateData;

    constructor(address _project_wallet) ERC721A("Sketchy Dollar","SKTCHY") OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false){

            myContractStateData.maxTokens =  9999;
            myContractStateData.publicMintPrice =  0.01 ether;
            myContractStateData.projectWallet =  _project_wallet;
            myContractStateData.maxTokensPerTxn =  25;
            myContractStateData.maxTokensForCreator = 100;
            myContractStateData.salestate = saleState(0);
            myContractStateData.creatorAllowedMint = true;
    }

    function setDevWalletAddress(address _project_wallet) public onlyOwner {
        myContractStateData.projectWallet = _project_wallet;
    }

    function setSaleState(uint _statusId) public onlyOwner {
        myContractStateData.salestate = saleState(_statusId);
    }

    modifier mintCheck(uint256 _mintAmount) {
        uint256 activeSaleStateInt = uint(myContractStateData.salestate);
        require(activeSaleStateInt >0, 'Mint not open');
        require(totalSupply() + _mintAmount <= myContractStateData.maxTokens, 'Max supply exceeded!');
        require(tx.origin == msg.sender);
        _;
    }

    function publicMint(uint256 _mintAmount) public payable mintCheck(_mintAmount) {
        uint256 activeSaleStateInt = uint(myContractStateData.salestate);
        require(_mintAmount > 0 && _mintAmount <= myContractStateData.maxTokensPerTxn, 'Invalid mint amount!');
        require(activeSaleStateInt == 1, 'Mint not open');
        require(msg.value >= myContractStateData.publicMintPrice * _mintAmount, 'Insufficient funds!');
        _mint(msg.sender, _mintAmount);
    }

    function creatorMint(uint256 _mintAmount) public payable onlyOwner {
        require(totalSupply() + _mintAmount <= myContractStateData.maxTokens, 'Max supply exceeded!');
        require(myContractStateData.creatorAllowedMint, "Creator already minted");
        require(_mintAmount > 0 && _mintAmount <= myContractStateData.maxTokensForCreator, 'Invalid mint amount');

        myContractStateData.creatorAllowedMint = false;
        _mint(msg.sender, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function burnNFT(uint256 tokenID) external {
        _burn(tokenID,false);
    }

    function ownerOfNFT(uint256 tokenID) external view returns (address owner) {
        return ownerOf(tokenID);
    }

    function isApprovedForAllNFT(address owner, address operator) external view returns (bool)  {
        return isApprovedForAll(owner, operator);
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        myContractStateData.baseUri = _baseUri;
    }
    
    function withdraw() public onlyOwner nonReentrant {
        address payable _project_devs = payable(myContractStateData.projectWallet);
        _project_devs.transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return myContractStateData.baseUri;
    }

    function getTokenMinted() external view returns (uint256) {
        return totalSupply();
    }

    function getSaleState() external view returns (saleState) {
        return myContractStateData.salestate;
    }

    function getMaxTokenPerMint() external view returns (uint8) {
        return myContractStateData.maxTokensPerTxn;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(CantBeEvil, ERC721A) returns (bool) {
        return
            super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from){
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from){
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}