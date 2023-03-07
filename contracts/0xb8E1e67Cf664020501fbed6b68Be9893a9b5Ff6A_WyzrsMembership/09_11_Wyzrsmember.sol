// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
/**
 WyzrsMemberOnly
*/

contract WyzrsMembership is ERC721A, Ownable,  IERC2981,ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter; 
    //NFT가 특정지갑주소에 쏠리는것을 방지하는 변수
    uint256 public royalty = 75; 
    // 75 is divided by 10 in the royalty info function to make 7.5%
    uint256 public maxSupply;
    //총 공급량
    uint256 _totalSupply = totalSupply();
    string public baseURI = "ipfs://QmUNXHD5yj7DfnKtuu9i3xL2nxfMATVUuk76gj5NWf6tq5/";
    //민팅되는 Json URI 설정
    string public baseExtension = ".json";  
    Counters.Counter private _tokenIds;

    // constructor(bytes32 merkleroot)
    constructor() ERC721A("WyzrsMembership", "Wyzrs") ReentrancyGuard() {
        maxSupply = 100;
    }  
    //사용자가 사고싶은 가격과과 현재 민트량이 일치하는지 재검증하는 modifier
       modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    } 
    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return baseURI;
    }
     function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }
      function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    } 
     function mintInternal(address _to) internal onlyOwner {
        _tokenIds.increment();
        _safeMint(_to, 1);
    }
     function airdrop(uint256 _mintAmount, address _to) public onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "airdrop amount exceeds max supply"
        );
        _safeMint(_to, _mintAmount);
    }
     function airdrop2(address [] calldata _to) external onlyOwner {
         uint _size = _to.length;
          require(
            totalSupply() + _size <= maxSupply,
            "airdrop amount exceeds max supply"
        );
        for(uint i; i < _size; ++i){       
           mintInternal(_to[i]);
        }
     }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    )
        external
        view
        override(IERC2981)
        returns (address Receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * royalty) / 1000); //100*10 = 1000
    }
     function isApprovedForAll(
        address _owner,
        address _operator
    ) 
        public 
        override 
        view 
        returns 
        (bool isOperator) 
    {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721A.isApprovedForAll(_owner, _operator);
    }
    
     /// @dev === Support Functions ==
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
    

    /// @dev === MODIFIERS ===
 
      function withdraw() external onlyOwner{
       (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }
}