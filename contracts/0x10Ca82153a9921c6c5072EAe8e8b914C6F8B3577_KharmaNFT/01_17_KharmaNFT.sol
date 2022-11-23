// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract KharmaNFT is Ownable, ERC721Royalty {
    using Strings for uint256;
    using ECDSA for bytes32;
    using SafeMath for uint256;
    uint256 public constant KHARMA_MAX = 3333; // total amount

    uint256 public lastTokenId; // last token id

    // ECDSA verification recover key
    address private signingKey;

    // @notice company wallet address which accept all payments
    address payable public companyAddress;
    
    // @notice base token uri for metadata uri
    string public publicBaseURI = "";
    string public hiddenBaseURI = "";
    uint256 public highRevealPointer;
    uint256 public lowRevealPointer;
    uint32  public maxAddressPurchase;
    uint public sellToId;
    
    mapping(address => uint32) private purchaseCounter;

    event PublicSale(uint256 tokenId, address sender, uint256 mintId);

    constructor(
        string memory _publicBaseURI,
        string memory _hiddenBaseURI,
        address _signingKey,
        address _companyAddress,
        address _feeReceiver,
        uint96 _feeNumerator
    )
        ERC721("KHARMA", "KHARMA")
    {
        publicBaseURI = _publicBaseURI;
        hiddenBaseURI = _hiddenBaseURI;
        signingKey = _signingKey;
        lastTokenId = 1;
        highRevealPointer = 0;
        lowRevealPointer = 31;
        maxAddressPurchase = 7;
        sellToId = 2577;
        companyAddress = payable(_companyAddress);
        _setDefaultRoyalty(_feeReceiver, _feeNumerator);
    }

    /**
     * @notice buy nfts
     * @param tokenQuantity total amount of nft to be minted
     * @param valueSent minimum value of the contract sent
     * @param mintId user id to verify off-chain
     * @param expireAt  signature expiration time
     * @param signature verification signature from backend
     */
    function buy(uint32 tokenQuantity,  uint256 valueSent, uint256 mintId, uint256 expireAt, bytes memory signature) external payable {
        require(expireAt >= block.timestamp, "signature expired");
        require(purchaseCounter[msg.sender] + tokenQuantity <= maxAddressPurchase, "Not allowed to purchase that many in total.");

        // validate the transaction with the backend
        address recovered = ECDSA.recover(keccak256(abi.encodePacked(tokenQuantity, valueSent, mintId, expireAt, msg.sender)), signature);
        require(recovered == signingKey, "Haculla.buy: Verification Failed");

        require(
                lastTokenId.add(tokenQuantity) <= sellToId && lastTokenId.add(tokenQuantity) <= KHARMA_MAX,
            "Sorry, there's not that many Haculla NFT left in stage."
        );
        
        require( valueSent <= msg.value, "Not Enough payments included" );

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, lastTokenId);
            emit PublicSale(lastTokenId++, msg.sender, mintId);
        }

        purchaseCounter[msg.sender] = purchaseCounter[msg.sender] + tokenQuantity;
        
        // drain message
        companyAddress.transfer(msg.value);
    }

       /**
     * @notice mint NFT from admin
     * @param tokenQuantity total amount of nft to be minted
     * @param to wallet address which nft to be minted
     * @param mintId user id to verify off-chain
     */
    function adminMint(uint32 tokenQuantity, address to, uint256 mintId) external {
        require(msg.sender == signingKey, "Haculla.adminMint: only the signer can use adminMint");

        require(
            lastTokenId.add(tokenQuantity) <= KHARMA_MAX,
            "Sorry, there's not that many Hacullas left."
        );

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(to, lastTokenId);
            emit PublicSale(lastTokenId++, to, mintId);
        }
    }

    /**
     * @notice Results a metadata URI
     * @param tokenId token URI per token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");
        if( lowRevealPointer <= tokenId && highRevealPointer >= tokenId ){
            return
                string( abi.encodePacked(
                                         publicBaseURI,
                                         tokenId.toString()
                                         ) );
        }
        return hiddenBaseURI;
    }
    /**
     * @notice Results a metadata uri
     * @param _tokenHiddenBaseURI token ID which need to be finished
     */
    function setTokenHiddenBaseUri(string memory _tokenHiddenBaseURI)
        public
        onlyOwner
    {
        hiddenBaseURI = _tokenHiddenBaseURI;
    }
    /**
     * @notice Results a metadata uri
     * @param _tokenPublicBaseURI token ID which need to be finished
     */
    function setTokenPublicBaseUri(string memory _tokenPublicBaseURI)
        public
        onlyOwner
    {
        publicBaseURI = _tokenPublicBaseURI;
    }

    function setHighRevealPointer(uint256 _highRevealPointer) public onlyOwner {
        highRevealPointer = _highRevealPointer;
    }

    function setLowRevealPointer(uint256 _lowRevealPointer) public onlyOwner {
        lowRevealPointer = _lowRevealPointer;
    }

    function setSellToId(uint256 _sellToId) public onlyOwner {
        sellToId = _sellToId;
    }

    function setMaxAddressPurchase(uint32 _maxAddressPurchase) public onlyOwner {
        maxAddressPurchase = _maxAddressPurchase;
    }


    /**
     * @notice update royalty info
     * @param receiver royalty receiver address
     * @param feeNumerator royalty fee numerator
     */
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Results a company wallet address
     * @param addr change another wallet address from wallet address
     */
    function setCompanyAddress(address payable addr) public onlyOwner {
        companyAddress = addr;
    }

    function setSigningKey(address addr) public onlyOwner {
        signingKey = addr;
    }
}