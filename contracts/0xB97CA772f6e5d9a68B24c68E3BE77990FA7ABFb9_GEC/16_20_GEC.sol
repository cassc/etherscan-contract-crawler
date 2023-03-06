// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract GEC is DefaultOperatorFilterer, Ownable, ERC721Royalty {
    using Strings for uint256;
    using SafeMath for uint256;
    uint256 public constant ITEM_MAX = 1111; // total amount

    uint256 public lastTokenId; // last token id

    // ECDSA verification recover key
    address public signingKey;

    // @notice company wallet address which accept all payments
    address payable public companyAddress;

    // @notice base token uri for metadata uri
    string public publicBaseURI = "";
    string public hiddenBaseURI = "";
    uint256 public highRevealPointer;
    uint256 public lowRevealPointer;
    uint32  public maxAddressPurchase;
    uint public sellToId;

    mapping(address => uint256) private purchaseCounter;

    event PublicSale(uint256 tokenId, address sender, uint256 mintId);

    constructor(
        address _signingKey,
        address _companyAddress,
        address _feeReceiver,
        uint96 _feeNumerator
    )
        ERC721("GEC", "GEC")
    {
        signingKey = _signingKey;
        lastTokenId = 1;
        highRevealPointer = 0;
        lowRevealPointer = 0;
        maxAddressPurchase = 5;
        sellToId = 1111;
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
    function buy(uint256 tokenQuantity,  uint256 valueSent, uint256 mintId, uint256 expireAt, bytes memory signature) external payable {
        require(expireAt >= block.timestamp, "signature expired");
        require(purchaseCounter[msg.sender] + tokenQuantity <= maxAddressPurchase, "Not allowed to purchase that many in total.");

        // validate the transaction with the backend
        address recovered = verify(tokenQuantity, valueSent, mintId, expireAt, msg.sender, signature);
        require(recovered == signingKey, "buy: Verification Failed");

        require(
                lastTokenId.add(tokenQuantity) <= sellToId && lastTokenId.add(tokenQuantity) <= ITEM_MAX,
            "Sorry, there's not that many NFT left in stage."
        );
        
        require(valueSent <= msg.value, "Not Enough payments included" );

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
        require(msg.sender == signingKey, "AdminMint: only the signer can use adminMint");

        require(
            lastTokenId.add(tokenQuantity) <= ITEM_MAX,
            "Sorry, there's not that many NFTs left."
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

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice update royalty info
     * @param receiver royalty receiver address
     * @param feeNumerator royalty fee numerator
     */
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function getRoyaltyInfo() public view returns (address royaltyAddress) {
        royaltyAddress = _getDefaultRoyaltyAddress();
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

    /**
    * @dev Should return a wallet address.
    * @param _tokenQuantity quantity of tokens.
    * @param _valueSent value sent for purchase.
    * @param _mintId mint id submitted by the user.
    * @param _expireAt expiration timestamp.
    * @param _sender wallet address which requested.
    * @param signature This is generated by our server to check the above inputs are valid
    */
    function verify(
        uint256 _tokenQuantity,
        uint256 _valueSent,
        uint256 _mintId,
        uint256 _expireAt,
        address _sender,
        bytes memory signature
    ) internal pure returns (address) {
        // building the message
        bytes32 messageHash = getMessageHash(_tokenQuantity, _valueSent, _mintId, _expireAt, _sender);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    // creating a hash which will be used to verify
    function getMessageHash(
        uint256 _tokenQuantity,
        uint256 _valueSent,
        uint256 _mintId,
        uint256 _expireAt,
        address _sender
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_tokenQuantity, _valueSent, _mintId, _expireAt, _sender));
    }

    // Signing the message
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    /**
    * @dev Should return a wallet address.
    * @param _ethSignedMessageHash message generated by user's input
    * @param _signature generated by our backend server
    */
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        // we are splitting the _signature for verification.
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        // utility function is solidity to return the address that signed it.
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // function to split the signature for verification
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}