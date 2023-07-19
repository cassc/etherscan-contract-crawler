// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";//Imported for balanceOf function to check tokenBalance of msg.sender

contract Island is ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 tokenID);
    event Paid (address indexed influencer, uint _amount);

    uint256 public burnCount;
    uint256 constant public TOTALCOUNT = 10000;
    uint256 constant public MAXBATCH = 10;
    string public baseURI = "https://islandboys.wtf/";
    bool private _started = false;
    string constant _NAME = "ISLAND BOYS";
    string constant _SYMBOL = "BOY";
    address constant _RUGS = 0x6C94954D0b265F657A4A1B35dfAA8B73D1A3f199;
    address constant _DRAPES = 0x9aF0e1748fF32f698847CfAB5013469a37dCdb17;
    address constant _BLAZED = 0x8584e7A1817C795f74Ce985a1d13b962758FE3CA;
    address constant _HEADS = 0xC6904FB685b4DFbDb98a5B70E40863Cd9AEF33DC;
    address constant _DOJI = 0x5e9dC633830Af18AA43dDB7B042646AADEDCCe81;
    address constant _RECORDS = 0x153C5091580cB9c3f12F7C1e170743a9af7B774a;
    address constant _INFLUENZAS = 0xaf76c7B002a3b7F062E1a19248B0579C52EeBE4A;
    address constant _ZINGOT = 0x8dEeFeBd24EF87e3F7aEf2057a002a8E91837801;

    constructor()
    ERC721(_NAME, _SYMBOL) {
        setStart(true);
        safeMint(0x86a8A293fB94048189F76552eba5EC47bc272223, 1);
        transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
    }
    receive() external payable {

    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        _started = _start;
    }

    function claimIsland(uint256 _batchCount) public {
        require(_started);
        require(_batchCount > 0 && _batchCount <= MAXBATCH);
        require(totalSupply() + _batchCount + burnCount <= TOTALCOUNT);
        require(hasRugToken(), "You must own at least one Rug project to mint.");
        for(uint256 i = 0; i < _batchCount; i++) {
            uint mintID = totalSupply() + 1;
            emit Claim(_msgSender(), mintID);
            _mint(_msgSender(), mintID);
        }
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function hasRugToken() public view returns (bool) {
        address sender = _msgSender();
        if(
            IERC721(_RUGS).balanceOf(sender) > 0 ||
            IERC721(_DRAPES).balanceOf(sender) > 0 ||
            IERC721(_BLAZED).balanceOf(sender) > 0 ||
            IERC721(_HEADS).balanceOf(sender) > 0 ||
            IERC721(_DOJI).balanceOf(sender) > 0 ||
            IERC721(_RECORDS).balanceOf(sender) > 0 ||
            IERC721(_ZINGOT).balanceOf(sender) > 0 ||
            IERC721(_INFLUENZAS).balanceOf(sender) > 0
        ) {
            return true;
        }
        return false;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < TOTALCOUNT);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        burnCount++;
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}