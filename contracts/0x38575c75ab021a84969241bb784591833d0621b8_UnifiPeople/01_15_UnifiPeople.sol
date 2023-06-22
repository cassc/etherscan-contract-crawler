//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IUnifiStaking {
    function userStakeAmount(address account) external view returns(uint256);
}
contract UnifiPeople is ERC721URIStorage, Ownable ,ERC721Enumerable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(address => bool) public hasMinted ; 
    mapping(address => bool) public eligibleUser;
    mapping(address => uint) public lovelyPeople;
    mapping(uint => bool) public whitelistedNft;
    mapping(uint => bool) public tokenIdMinted;
    uint public maxNft= 750;
    bool public anyoneCanMint = false;
    IUnifiStaking ius = IUnifiStaking (0xf64a670a3F1E877031e9a62f2E382E4b2035b620);
    constructor() public ERC721("Unifi People", "UPPL") {
        whitelistedNft[6  ] = true;
        whitelistedNft[69 ] = true;
        whitelistedNft[430] = true;
        whitelistedNft[420] = true;
        whitelistedNft[411] = true;
        whitelistedNft[581] = true;
        whitelistedNft[376] = true;
        whitelistedNft[105] = true;
        whitelistedNft[156] = true;
        whitelistedNft[10 ] = true;
        whitelistedNft[220] = true;
        whitelistedNft[127] = true;
        whitelistedNft[693] = true;
        whitelistedNft[537] = true;

        lovelyPeople [0x62F55a4513bC8F10a006011bf34325B5EB1aFbF6] = 6   ;
        lovelyPeople [0x978209515ff9d39803cAeD77102412Bbd9f7C50E] = 69  ;
        lovelyPeople [0x9c5621268E1EB0274f060898c9F88Fd0ef82B027] = 430 ;
        lovelyPeople [0x3f467C88C113B3Cc3380a6d33B2126A1Cf42B03e] = 420 ;
        lovelyPeople [0xAc6a579987E812581C9f28d23526079187A38Ed6] = 411 ;
        lovelyPeople [0x4031ca2E91afE771Da6bCb61007e3e75C119Ca1d] = 581 ;
        lovelyPeople [0xFC36473f3e473922788e5B8865B90Cf0A583C24A] = 376 ;
        lovelyPeople [0xcaa15e4b6CA6863750229Ef6Ae039C4Da99989D8] = 105 ;
        lovelyPeople [0xDbe8E2679859aB2355f3d9187690abD5b3e6e986] = 156 ;
        lovelyPeople [0x33992fde5C86c07f3045Bb5F52Bd017A44A03549] = 10  ;
        lovelyPeople [0x6CCB4754F96ad25ABf5b62A4c5eF6D32aC038A89] = 220 ;
        lovelyPeople [0x14F45114acbF4F1090FaB1301b483aF09BEAE3c3] = 127 ;
        lovelyPeople [0x03843f885b436316A446b14D52a9f5fB44F994e2] = 693 ;
        lovelyPeople [0x6F6DEF8732980370C137c356D7377e02d1BDF1F0] = 537 ;

        eligibleUser[0xa090d5656c3Ba77A546BA48af5a07508CC86d771] = true;
        eligibleUser[0xa5F512B07D7872eF4e1db38baB81D5C8a2b7a712] = true;
        eligibleUser[0x5Abd6E8A9cAA16eCD1ff5BEF0452E73Fca56e198] = true;
        eligibleUser[0x03F9F1f03A2181B1bf0324977222488997dA0BA0] = true;
        eligibleUser[0x5A4ad5a756d2b9E4c4b679263DE662AC7baad28a] = true;
        eligibleUser[0x987EbeD92EC52D83DF9da87844B7FCeb10dE484F] = true;
        eligibleUser[0xD0F3A9fD3F3bb302b0b5D2037Ff8b95D928A2Bde] = true;
        eligibleUser[0x3e76bC5dEDaE8fA98D5526aeAB7514F1304705A7] = true;
        eligibleUser[0x3c798dAbEEF0d3C097fC4D8353C5c9eFC3e31a8D] = true;
        eligibleUser[0x97b0F7812402CB9c90566D071c9aBd1b99C03d44] = true;
        eligibleUser[0x65eDa0110D6e547678A3c01A318De89ef8E5981D] = true;
        eligibleUser[0xBb1A339a53A2285Dd6537Aea1784AD5750799EcF] = true;
        eligibleUser[0x895213851eBFFd6E9c60350ea1a452751226c0C3] = true;
        eligibleUser[0x1461f7B3941888335dfDAfE89b3Ec959c7033a14] = true;
        eligibleUser[0xDe080274DB5AF1E27924Bbd3609e516df005C19b] = true;
        eligibleUser[0x9Ee08d2Db90aa5Af50163929A93c385caDd53E33] = true;
        eligibleUser[0x12BD6ff109B186012793854DFA4bc8cf3021074e] = true;
        eligibleUser[0x2f70642A50D74111bE3460f97C604359bc245Da8] = true;
        eligibleUser[0x132c0ab445849330e41506d18964C817f476798a] = true;
        eligibleUser[0xBbBfE7CD2f3863A911290e63459b03006fC508ef] = true;
        eligibleUser[0xae1De3e8B66aC3553ddAA3121Bc63bC4c0cE784b] = true;
        eligibleUser[0x801E1e0e337d08E9567435Cd21839ccF77D86057] = true;
        eligibleUser[0x0f35b3023626edcDeaB1db7bcC26d996fbAF3F10] = true;
        eligibleUser[0x21E520D3c5b63e53a2c42B828f991AFD62B3CF72] = true;
        eligibleUser[0x46723E4Fcb77FBF707F14e9C6F8832681E58f712] = true;
        eligibleUser[0xD04cA578aDd6F7002EDd8730A6823efDF7dC0DA6] = true;
        eligibleUser[0x206d8456E3731e0c9a664EAA41e6606251fE6e59] = true;
        eligibleUser[0xbFd1252DC5C8b1e78e137B8EE22306F9D324BEc1] = true;
        eligibleUser[0x8022acEEf646778F8B3D4a51B100f1a4f6EB9eE6] = true;
        eligibleUser[0xE2374688708DdC204F98a4728fc9466dBa79F5bA] = true;
        eligibleUser[0xAF6aa5Ef8126590D5b80A961f0DbA35b93d35aB0] = true;
        eligibleUser[0x8859968fF6B42C48318528F906d99B3a6999aB96] = true;
        eligibleUser[0x5fD07893282e9dDb3A12e2a6eaa38ad4019d65db] = true;
        eligibleUser[0xB9a9Df09E5EA2ee3a61e3feCddadacfc74d75e3a] = true;
        eligibleUser[0x2661FC3460C9E692B2b6AbeD089545818E7a4D84] = true;
        eligibleUser[0xa86d3Ca8b52874fdc6938663d6ae5F8924635653] = true;
        eligibleUser[0xeCB877A95D3457f5FC39325F2858B1A11D8ca24A] = true;
        eligibleUser[0xbE93d14C5dEFb8F41aF8FB092F58e3C71C712b85] = true;
        eligibleUser[0x52856Ca4ddb55A1420950857C7882cFC8E02281C] = true;
        eligibleUser[0x14F45114acbF4F1090FaB1301b483aF09BEAE3c3] = true;
        eligibleUser[0xAc6a579987E812581C9f28d23526079187A38Ed6] = true;
        eligibleUser[0x53d1a6DFA25f973f39B69561d3aAe5d86193524d] = true;
        eligibleUser[0x7AAE0c2dB9a7735f70D47A9b3C37dA08cE6974Bc] = true;
        eligibleUser[0xf07b662146fd455541178B3b7a86d06f75CA50c2] = true;
        eligibleUser[0x85917F0F50a353ff677D5563b793446C3c3943eb] = true;
        eligibleUser[0xaee394a8e28bE8b27D9a08e80c9A8aD6D72e52A6] = true;
        eligibleUser[0xcB609E859221FCb64f9C949C9346067AC9D8Aa8c] = true;
        eligibleUser[0x74D659550f4b067b81d34410427fc49d2935aA6d] = true;
        eligibleUser[0xfA55F1003801616ff22406B278E7417Fc4A7DbB7] = true;
        eligibleUser[0x5CEe6003FBED7187108843A668Ea34720762d9F1] = true;
        eligibleUser[0x987EbeD92EC52D83DF9da87844B7FCeb10dE484F] = true;
        eligibleUser[0xcEaE06e7d4aee7d00224e9c31a7F4CEfED5B4ac9] = true;
        eligibleUser[0x9bb64e40DCBe4645F99F0a9e2507b5A53795fa70] = true;
        eligibleUser[0x953cD496c2371aCB11eBBA340fF548C4F50f2f02] = true;
        eligibleUser[0xbf2EC9e5D8607CBdF09F61646e881a57617269Fd] = true;
        eligibleUser[0xC5c05d0907892A980bEfA5fd55cd5aBec75357a3] = true;
        eligibleUser[0xBEAC648b23160b3Ae5d55364aD5f20d83187e50d] = true;
        eligibleUser[0xdbE0FC262CbcA3eC4C0335B1EA35930f1ec5207b] = true;

    }
    uint public totalNFT = 25;// to be updated
    
    string public url = "https://gateway.pinata.cloud/ipfs/QmQtk5w8XM3ST1KqG6Urt6t5R9ux3qZCWYTX6PNC5qFhJD/metadata_";
    function mintNFT()
        public 
        returns (uint256)
    {
        require(hasMinted[msg.sender]== false , "You have minted");
        require(this.eligibleUsers(msg.sender) == true , "Not Elgible");

        require(totalSupply() <=maxNft,"All NFT has been minted out");
        if(lovelyPeople[msg.sender] > 0 ){
            uint tokenId = _mintLovelyPeopleNFT(msg.sender );
            return tokenId ;
        }else{
            _tokenIds.increment();
            while(whitelistedNft[_tokenIds.current()] == true){
                _tokenIds.increment();
            }
            uint256 newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            string memory tokenFullURI = string(abi.encodePacked(url,uint2str(newItemId) ,".json"));
            hasMinted[msg.sender] = true;
            _setTokenURI(newItemId, tokenFullURI);
            tokenIdMinted[newItemId] = true;
            return newItemId;
        }
        
    }

    function _mintLovelyPeopleNFT(address user )
        internal 
        returns (uint256)
    {
        require(hasMinted[user]== false , "You have minted");
        _mint(user, lovelyPeople[user]);
        string memory tokenFullURI = string(abi.encodePacked(url,uint2str(lovelyPeople[user]) ,".json"));
        hasMinted[user] = true;
        _setTokenURI(lovelyPeople[user], tokenFullURI);
        tokenIdMinted[lovelyPeople[user]] = true;
        return lovelyPeople[user];
    }
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    // to be removed this is for testing 
    function currentIPFS() external view returns (string memory ){
        uint256 newItemId = _tokenIds.current() + 1 ;
        return string(abi.encodePacked(url,uint2str(newItemId) ,".json"));
    }

    function updateURL(string memory _newUrl) external  onlyOwner{
        url = _newUrl;
    }
    function updateTotalNFT(uint newTotal) external  onlyOwner{
        maxNft  = newTotal;
    }
    function updateUser(address user , bool value) external  onlyOwner{
        eligibleUser[user] = value;
    }
    function updateMultipleUser(address[] memory users , bool [] memory values)external  onlyOwner{
        for(uint i = 0 ; i < users.length ; i++){
             this.updateUser(users[i] , values[i]);
        }
    }

    function updateLovelyPeople(address user, uint id, bool value)external onlyOwner{
        require(tokenIdMinted[id] == false , "Already minted");
        whitelistedNft[id] = value;
        lovelyPeople[user] = id;
    }

    function updateMintStatus(address user, bool value)external onlyOwner{
        hasMinted[user] = value;
    }
    function updateTokenMintStatus(uint  id, bool value)external onlyOwner{
        tokenIdMinted[id] = value;
    }

    function updateAnyoneCanMint( bool value)external onlyOwner{
        anyoneCanMint = value;
    }
    function eligibleUsers(address _sender ) external view  returns( bool){
        if((ius.userStakeAmount(_sender) > 0 || eligibleUser[_sender] == true || anyoneCanMint == true) && hasMinted[_sender] == false){
            return true;
        }else{
            return false;
        }
    }

    function currentTokenId() external view  returns( uint){


        return _tokenIds.current();
    }

   function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

        function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

}