// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Keisuke OHNO

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.7.0 <0.9.0;
import { Base64 } from 'base64-sol/base64.sol';
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


//tokenURI interface
interface iTokenURI {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract QNCreatorSBT is Ownable, ERC721A{

    constructor(
    ) ERC721A("QNCreatorSBT", "QNCSBT") {
        setIsSBT(true);
        setUseSingleMetadata(true);
        setBaseURI("https://data.zqn.wtf/qncreator/images/");
        setPhaseData(
            1,
            "202210.png",
            "QN Creator SBT, September 2022",
            "Thanks for joining ZQN-DAO.  \nIllustration by https://twitter.com/totomidesign",
            "September 2022", 
            0x11dd935d65dbc8425e8BA1d9cE4d85E8E6000737,
            false,
            ""
            );
        adminMint();
    }


    //
    //withdraw section
    //

    address public constant withdrawAddress = 0xdEcf4B112d4120B6998e5020a6B4819E490F7db6;
    function withdraw() public onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }


    //
    //mint section
    //

    uint256 public cost = 1000000000000000;//0.001 ether
    bool public paused = true;
    uint256 public phaseId = 1;

    mapping(uint256 => uint256) public phaseIdByTokenId;
    mapping(uint256 => phaseStrct) public phaseData;

    struct phaseStrct {
        //input
        string fileName;
        string metadataTitle;
        string metadataDescription;
        string metadataAttributes;
        address withdrawAddress;
        bool useAnimationUrl;
        string animationFileName;

        //internal variable
        mapping(address => uint256) userMintedAmount;
    }

    function setPhaseData( 
            uint256 _id , 
            string memory _fileName , 
            string memory _metadataTitle , 
            string memory _metadataDescription ,
            string memory _metadataAttributes ,
            address _withdrawAddress,
            bool _useAnimationUrl,
            string memory _animationFileName 
        ) public onlyOwner {
        phaseData[_id].fileName = _fileName;
        phaseData[_id].metadataTitle = _metadataTitle;
        phaseData[_id].metadataDescription = _metadataDescription;
        phaseData[_id].metadataAttributes = _metadataAttributes;
        phaseData[_id].withdrawAddress = _withdrawAddress;
        phaseData[_id].animationFileName = _animationFileName;
        phaseData[_id].useAnimationUrl = _useAnimationUrl;
    }

    function setPhaseId(uint256 _id) external onlyOwner {
        phaseId = _id;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    //mint
    function mint() public payable callerIsUser{
        require( !paused , "the contract is paused");
        require( cost <= msg.value , "insufficient funds");
        require( phaseData[phaseId].userMintedAmount[msg.sender] == 0 , "You already have a SBT" );

        phaseData[phaseId].userMintedAmount[msg.sender]++;
        phaseIdByTokenId[_nextTokenId()] = phaseId;
        _safeMint(msg.sender, 1);

        (bool os, ) = payable( phaseData[phaseId].withdrawAddress ).call{value: address(this).balance}('');
        require(os);        
    }

    function adminMint() public onlyOwner{
        phaseIdByTokenId[_nextTokenId()] = phaseId;
        _safeMint(msg.sender, 1);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
  
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function getUserMintedAmount(address _address) public view returns (uint256){
        return phaseData[phaseId].userMintedAmount[_address];
    }
    function getUserMintedAmountByPhaseId(uint256 _phaseId , address _address) public view returns (uint256){
        return phaseData[_phaseId].userMintedAmount[_address];
    }
 


    //
    //URI section
    //

    string public baseURI;
    string public baseExtension = ".json";

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;        
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }



    //
    //interface metadata
    //

    iTokenURI public interfaceOfTokenURI;
    bool public useInterfaceMetadata = false;

    function setInterfaceOfTokenURI(address _address) public onlyOwner() {
        interfaceOfTokenURI = iTokenURI(_address);
    }

    function setUseInterfaceMetadata(bool _useInterfaceMetadata) public onlyOwner() {
        useInterfaceMetadata = _useInterfaceMetadata;
    }


    //
    //single metadata
    //

    bool public useSingleMetadata = false;

    //single image metadata
    function setUseSingleMetadata(bool _useSingleMetadata) public onlyOwner() {
        useSingleMetadata = _useSingleMetadata;
    }


    //
    //token URI
    //

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (useInterfaceMetadata == true) {
            return interfaceOfTokenURI.tokenURI(tokenId);
        } else if (useSingleMetadata == true){
            return string( abi.encodePacked( 'data:application/json;base64,' , Base64.encode(bytes(encodePackedJson(tokenId))) ) );
        } else {
            return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
        }
    }

    function encodePackedJson(uint256 _tokenId) public view returns (bytes memory) {
        return abi.encodePacked(
            '{'
                '"name":"' , phaseData[ phaseIdByTokenId[ _tokenId ] ].metadataTitle ,'",' ,
                '"description":"' , phaseData[ phaseIdByTokenId[ _tokenId ] ].metadataDescription ,  '",' ,
                '"image": "' , _baseURI() , phaseData[ phaseIdByTokenId[ _tokenId ] ].fileName , '",' ,
                phaseData[phaseId].useAnimationUrl==true ? string(abi.encodePacked('"animation_url": "' , _baseURI() , phaseData[ phaseIdByTokenId[ _tokenId ] ].animationFileName , '",')) :"" ,
                '"attributes":[{"trait_type":"type","value":"' , phaseData[ phaseIdByTokenId[ _tokenId ] ].metadataAttributes , '"}]',
            '}'
        );
    }




    //
    //viewer section
    //

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }



    //
    //sbt section
    //

    bool public isSBT = false;

    function setIsSBT(bool _state) public onlyOwner {
        isSBT = _state;
    }

    function _sbt() internal view returns (bool) {
        return isSBT;
    }    

    function _beforeTokenTransfers( address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override{
        require( _sbt() == false || from == address(0), "transfer is prohibited");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require( _sbt() == false , "setApprovalForAll is prohibited");
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public payable virtual override {
        require( _sbt() == false , "approve is prohibited");
        super.approve(to, tokenId);
    }



    //
    //override
    //

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


}