// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// Author: Stephen Nelson @st3bas
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/*
      >>       >=>       >======>   >=>    >=>       >>             >=>    >=>     >===>     
     >>=>      >=>       >=>    >=> >=>    >=>      >>=>            >=>    >=>   >=>    >=>  
    >> >=>     >=>       >=>    >=> >=>    >=>     >> >=>           >=>    >=> >=>       >=> 
   >=>  >=>    >=>       >======>   >=====>>=>    >=>  >=>          >=====>>=> >=>       >=> 
  >=====>>=>   >=>       >=>        >=>    >=>   >=====>>=>         >=>    >=> >=>       >=> 
 >=>      >=>  >=>       >=>        >=>    >=>  >=>      >=>        >=>    >=>   >=> >> >=>  
>=>        >=> >=======> >=>        >=>    >=> >=>        >=>       >=>    >=>     >= >>=>   
                                                                                        >>   
*/



contract AlphaHQ is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIds;

    address public ALPHA_SIGNER;
    uint256 public MAX_SUPPLY = 2500;

    uint256 public WHITELIST_SALE_PRICE = 0.20 ether;
    bool public WHITELIST_SALE_ACTIVE = false;
    uint public WHITELIST_MAX_MINTS = 2;

    uint256 public PUBLIC_SALE_PRICE = 0.25 ether;
    bool public PUBLIC_SALE_ACTIVE = false;
    uint public PUBLIC_MAX_MINTS = 3;
    
    string public TOKEN_IMAGE = "https://ipfs.io/ipfs/bafybeibwsruzy3vcgne2yh4rbh6qdwpq5bq32mmsmzhiyicazlyoj33jtq";
    string public TOKEN_EXPIRED = "false";
    string public TOKEN_EXPIRY_TIME = "1682899200";

    event SignerUpdated(address alphaSigner);
    event TokenImageUpdated(string tokenImage);
    event TokenExpiryTimeUpdated(string tokenExpiryTime);
    event TokenExpiredUpdated(string tokenExpired);

    mapping(bytes => uint256) public usedSignatures;

    constructor() ERC721("AlphaHQ Access Pass", "AHQ") {
        _tokenIds.increment();
    }

    function setTokenImage(string memory _url) public onlyOwner {
        TOKEN_IMAGE = _url;
        emit TokenImageUpdated(TOKEN_IMAGE);
    }

    function setTokenExpiryTime(string memory _expiryTime) public onlyOwner {
        TOKEN_EXPIRY_TIME = _expiryTime;
        emit TokenExpiryTimeUpdated(TOKEN_EXPIRY_TIME);
    }

    function setTokenExpired(string memory _expired) public onlyOwner {
        TOKEN_EXPIRED = _expired;
        emit TokenExpiredUpdated(TOKEN_EXPIRED);
    }

    function _alphaHQSigner() internal view virtual returns (address) {
        return ALPHA_SIGNER;
    }

    function setAlphaHQSigner(address _signer) public onlyOwner {
        require(_signer != address(0), "signer cannot be 0x0");
        ALPHA_SIGNER = _signer;
        emit SignerUpdated(ALPHA_SIGNER);
    }

    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    // Only used for alpha hq for giveaways and team access nfts
    function adminReserveNFTs(uint _count) public onlyOwner {
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(_count) < MAX_SUPPLY, "Not enough NFTs left to reserve");
        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function publicMintToken(uint _count) public payable {
        uint totalMinted = _tokenIds.current();
        require(PUBLIC_SALE_ACTIVE, "Public sale is not active.");
        require(totalMinted.add(_count) <= MAX_SUPPLY, "Max token supply has been reached.");
        require(_count > 0 && _count <= PUBLIC_MAX_MINTS, "Cannot mint specified number of NFTs.");
        require(msg.value >= PUBLIC_SALE_PRICE.mul(_count), "Ether value sent is not correct.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function whitelistMintToken(uint8 _count, bytes memory signature) external payable {
        uint totalMinted = _tokenIds.current();
        require(WHITELIST_SALE_ACTIVE, "Whitelist sale is not active.");
        require(totalMinted.add(_count) <= MAX_SUPPLY, "Max token supply has been reached.");
        require(msg.sender == tx.origin, "You have to mint from a wallet.");
        require(_count > 0 && _count <= WHITELIST_MAX_MINTS, "Cannot mint specified number of NFTs.");
        require(msg.value >= WHITELIST_SALE_PRICE.mul(_count), "Ether value sent is not correct.");
		require(usedSignatures[signature] + _count < WHITELIST_MAX_MINTS + 1, "Exceeds whitelist allocation");
        require(_isSignedByAlphaSigner(_getSenderHash(msg.sender), signature), "Invalid signature.");
        usedSignatures[signature] += _count;
        
        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function _getSenderHash(address _address) private pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n40", toAsciiString(_address)));
        return hash;
    }

    function _isSignedByAlphaSigner(bytes32 _hash, bytes memory _signature) private view returns (bool) {
        return ALPHA_SIGNER != address(0) && ALPHA_SIGNER == _recoverSigner(_hash, _signature);
    }

    function _recoverSigner(bytes32 hash, bytes memory signature) private pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                hash
            )
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Alpha HQ Access pass", "description": "Access pass for membership to the Alpha HQ toolset and alpha information channels.", "attributes": [{"trait_type": "Expiration","value": "', TOKEN_EXPIRY_TIME, '"},{"trait_type": "Expired","value": "', TOKEN_EXPIRED,'"}], "image": "', TOKEN_IMAGE, '"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }


    /** AHQ AHQ AHQ AHQ AHQ AHQ AHQ AHQ AHQ AHQ **/
    /** AHQ AHQ AHQ Owner Functions AHQ AHQ AHQ **/
    /** AHQ AHQ AHQ AHQ AHQ AHQ AHQ AHQ AHQ AHQ **/
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function toggleWhitelistSale() public onlyOwner {
        WHITELIST_SALE_ACTIVE = !WHITELIST_SALE_ACTIVE;
    }

    function togglePublicSale() public onlyOwner {
        PUBLIC_SALE_ACTIVE = !PUBLIC_SALE_ACTIVE;
    }

    function setWhitelistSalePrice(uint256 newPrice) public onlyOwner {
        WHITELIST_SALE_PRICE = (1 ether * newPrice) / 100;
    }

    function setPublicSalePrice(uint256 newPrice) public onlyOwner {
        PUBLIC_SALE_PRICE = (1 ether * newPrice) / 100;
    }

    function toAsciiString(address x) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}