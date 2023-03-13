// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../Common/BaseNFT.sol";
import "@openzeppelin/contracts/utils/Counters.sol" ;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol" ;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol" ;
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol" ;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol" ;

contract Item is BaseNFT, ReentrancyGuard, EIP712, IERC721Receiver {
    bytes32 public constant SIGN_ROLE = keccak256("SIGN_ROLE");

    //////////////////////////////////
    //          events
    /////////////////////////////////
    event MintNftEvent(uint256 requestId, address [] tos, uint256 [] tokenIds, address operater) ;
    event SynthesisEvent(uint256 requestId, uint256 main, uint256 additional, address owner) ;
    event ClaimSynthesisEvent(uint256 requestId, uint256 [] tokenIds, address owner) ;
    event CSGameSwapInEvent(uint256 requestId, uint256 [] tokenIds, address owner) ;

    modifier onlySign() {
        require(signers[_msgSender()], "You have no permission to operate!") ;
        _;
    }

    // server sign
    mapping(address => bool) public signers;

    // request ids
    mapping(uint256 => bool) public mintRequestIds ;
    mapping(uint256 => bool) public synthesisRequestIds ;

    // synthesis request
    mapping(uint256 => uint256 []) public requestIdNftTokenIds ;

    constructor(string memory baseUri, address managerAddr)
    BaseNFT("Item NFT","Item", baseUri, managerAddr) EIP712("Item",  "v1.0.0") {
        signers[managerAddr] = true ;
        _setupRole(SIGN_ROLE, managerAddr);
        approvalWhite[_msgSender()] = true ;
    }

    function tokenURI(uint256 tokenId) public view virtual override(BaseNFT) returns (string memory) {
        return string(abi.encodePacked(_baseURI(),"/item/", Strings.toString(tokenId)));
    }

    function mintOwner(address [] memory tos, uint256 [] memory tokenIds) onlySign public  {
        _mint(0, tos, tokenIds) ;
    }

    function mintNft(uint256 requestId, uint256 [] memory tokenIds, bytes memory signature) public {
        require(mintRequestIds[requestId] == false, "mint request Expires") ;
        mintRequestIds[requestId] = true ;
        checkMintSign(requestId, tokenIds, signature) ;

        address[] memory tos = new address[](tokenIds.length) ;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            tos[i] = _msgSender() ;
        }
        _mint(requestId, tos, tokenIds) ;
    }

    function _mint(uint256 requestId, address [] memory tos, uint256 [] memory tokenIds) private nonReentrant whenNotPaused {
        require(tos.length == tokenIds.length, "tos tokenIds length has not eq") ;
        require(tos.length > 0, "tos has empty") ;
        for(uint256 i = 0; i < tos.length; i++) {
            _safeMint(tos[i], tokenIds[i]) ;
        }
        emit MintNftEvent(requestId, tos, tokenIds, _msgSender()) ;
    }

    function synthesis(uint256 requestId, uint256 main, uint256 additional, bytes memory signature) public whenNotPaused nonReentrant {
        require(synthesisRequestIds[requestId] == false, "synthesis request Expires") ;
        synthesisRequestIds[requestId] = true ;
        checkSynthesisSign(requestId, main, additional, signature) ;
        uint256 [] memory tokenIds = new uint256[](2) ;
        tokenIds[0] = main ;
        tokenIds[1] = additional ;
        requestIdNftTokenIds[requestId] = tokenIds ;
        batchTransfer(_msgSender(), address(this), tokenIds) ;
        emit SynthesisEvent(requestId, main, additional, _msgSender()) ;
    }

    function claimSynthesis(uint256 requestId, uint256 [] memory tokenIds, bytes memory signature) public whenNotPaused nonReentrant {
        require(tokenIds.length > 0, "claim tokenIds has empty") ;
        require(tokenIds.length < 3, "claim tokenIds length has invalid") ;
        uint256 [] memory synthesisNftTokenIds = requestIdNftTokenIds[requestId] ;
        require(synthesisNftTokenIds.length == 2, "claim synthesis request has Expires") ;
        require(tokenIds[0] == synthesisNftTokenIds[0], "synthesis main NFT has invalid") ;
        if(tokenIds.length > 1) {
            require(tokenIds[1] == synthesisNftTokenIds[1], "synthesis additional NFT has invalid") ;
        }
        delete requestIdNftTokenIds[requestId] ;
        checkClaimSynthesisSign(requestId, tokenIds, signature) ;
        batchTransfer(address(this), _msgSender(), tokenIds) ;
        emit ClaimSynthesisEvent(requestId, tokenIds, _msgSender()) ;
    }

    function gameSwapIn(uint256 requestId, uint256 [] memory tokenIds) public whenNotPaused nonReentrant {
        require(tokenIds.length > 0, "Data cannot be empty") ;
        for(uint256 i = 0 ;i < tokenIds.length ; i++ ){
            burn(tokenIds[i]);
        }
        emit CSGameSwapInEvent(requestId, tokenIds, _msgSender()) ;
    }

    function batchTransfer(address from, address to, uint256[] memory tokenId) private {
        for(uint256 i = 0; i < tokenId.length; i++) {
            _transfer(from, to, tokenId[i]) ;
        }
    }

    // add signer
    function addSigner(address sign) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        signers[sign] = true ;
        _setupRole(SIGN_ROLE, sign);
        return true ;
    }

    // del signer
    function delSigner(address sign) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        signers[sign] = false ;
        _revokeRole(SIGN_ROLE, sign);
        return true ;
    }

    function checkMintSign(uint256 requestId, uint256 [] memory tokenIds, bytes memory signature) private view {
        // cal hash
        bytes memory encodeData = abi.encode(
            keccak256(abi.encodePacked("Mint(uint256 requestId,uint256[] tokenIds,address owner)")),
            requestId,
            keccak256(abi.encodePacked(tokenIds)),
            _msgSender()
        ) ;

        (bool success,) = checkSign(encodeData, signature) ;
        require(success, "mint: The operation of Mint permission is wrong!") ;
    }

    function checkSynthesisSign(uint256 requestId, uint256 main, uint256 additional, bytes memory signature) private view {
        // cal hash
        bytes memory encodeData = abi.encode(
            keccak256(abi.encodePacked("Synthesis(uint256 requestId,uint256 main,uint256 additional,address owner)")),
            requestId,
            main,
            additional,
            _msgSender()
        ) ;

        (bool success,) = checkSign(encodeData, signature) ;
        require(success, "synthesis: The operation of synthesis permission is wrong!") ;
    }

    function checkClaimSynthesisSign(uint256 requestId, uint256 [] memory tokenIds, bytes memory signature) private view {
        // cal hash
        bytes memory encodeData = abi.encode(
            keccak256(abi.encodePacked("ClaimSynthesis(uint256 requestId,uint256[] tokenIds,address owner)")),
            requestId,
            keccak256(abi.encodePacked(tokenIds)),
            _msgSender()
        ) ;

        (bool success,) = checkSign(encodeData, signature) ;
        require(success, "ClaimSynthesis: The operation of claim synthesis permission is wrong!") ;
    }

    // recover pubKey
    function checkSign(bytes memory encodeData, bytes memory signature)
    internal view whenNotPaused returns(bool, address){
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(_hashTypedDataV4(keccak256(encodeData)), signature);
        return (signers[recovered] && error == ECDSA.RecoverError.NoError, recovered) ;
    }

    function _migration(uint256 tokenId, uint256 gene, address owner) internal onlyRole(MANAGER_ROLE) virtual override returns (bool){}

    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
        require(from != address(0x0));
        return IERC721Receiver.onERC721Received.selector;
    }

    // get ed NFT Info By Page, page start zero
    function getAllNftInfoByPage(uint256 page, uint256 limit) external view returns(uint256 [] memory, address [] memory, uint256 ) {
        uint256 startIndex = page * limit ;
        uint256 len = totalSupply() - startIndex ;

        if(len > limit) {
            len = limit ;
        }

        if(startIndex >= totalSupply()) {
            len = 0 ;
        }

        uint256 [] memory nftInfoArr = new uint256[](len) ;
        address [] memory owners = new address[](len) ;
        for(uint256 i = 0 ;i < len; i++) {
            nftInfoArr[i] = tokenByIndex(startIndex + i) ;
            owners[i] = ownerOf(nftInfoArr[i]) ;
        }

        return (nftInfoArr, owners, totalSupply());
    }

    //  get ed NFT Info By Page & owner, page start zero
    function getOwnerNftInfoByPage(uint256 page, uint256 limit, address owner) external view returns(uint256 [] memory, uint256) {
        uint256 startIndex = page * limit ;
        uint256 len = balanceOf(owner) - startIndex ;

        if(len > limit) {
            len = limit ;
        }

        if(startIndex >= balanceOf(owner)) {
            len = 0 ;
        }
        uint256[] memory nftInfoArr = new uint256[] (len) ;
        for(uint256 i = 0 ;i < len; i++) {
            nftInfoArr[i] = tokenOfOwnerByIndex(owner, startIndex + i) ;
        }
        return (nftInfoArr, balanceOf(owner));
    }
}