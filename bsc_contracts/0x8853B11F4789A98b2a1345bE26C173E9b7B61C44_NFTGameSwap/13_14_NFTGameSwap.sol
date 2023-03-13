// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol" ;
import "@openzeppelin/contracts/security/Pausable.sol" ;
import "../MITNFT/IMITNft.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol" ;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol" ;
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol" ;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol" ;

contract NFTGameSwap is AccessControl, Pausable, ReentrancyGuard, EIP712, IERC721Receiver {
    enum KIND { NONE, SPACESHIP, HERO, DEFENSIVEFACILITY }

    IMITNft public immutable spaceship ;
    IMITNft public immutable hero ;
    IMITNft public immutable defensiveFacility ;

    // hero => (tokenId => owner)
    mapping(KIND => mapping(uint256 => address)) public nftToAccount;
    mapping(uint256 => KIND) public nftKinds ;

    // struct
    struct Nft {
        KIND kind;
        uint256 tokenId ;
    }

    bool public openTest = false ;
    address public signAddr ;

    /////////////////////////////////////////////////
    //                  events
    /////////////////////////////////////////////////
    event NftGameSwapInEvent(address account, Nft [] nfts) ;
    event NftGameSwapOutEvent(address account, uint256 orderNum, Nft [] nfts) ;

    constructor(address spaceshipAddr, address heroAddr, address defensiveFacilityAddr, address sign) EIP712("NFTGameSwap", "v1.0.0") {
        spaceship = IMITNft(spaceshipAddr) ;
        hero = IMITNft(heroAddr) ;
        defensiveFacility = IMITNft(defensiveFacilityAddr) ;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        signAddr = sign ;
    }

    // chain => game
    function nftSwapIn(Nft [] memory nfts, bytes memory signature) external nonReentrant whenNotPaused {
        require(nfts.length > 0, "The number of swapIn NFTs cannot be empty") ;
        checkNftSwapInSign(nfts, signature) ;
        for(uint256 i = 0 ; i < nfts.length; i++) {
            transferNft(nfts[i].kind, _msgSender(), address (this), nfts[i].tokenId) ;
            nftToAccount[nfts[i].kind][nfts[i].tokenId] = _msgSender() ;
            nftKinds[nfts[i].tokenId] = nfts[i].kind ;
        }
        emit NftGameSwapInEvent(_msgSender(), nfts) ;
    }

    function nftSwapOutBatch(uint256[] memory orderNum, uint256[][] memory tokenIds, bytes memory signature) external nonReentrant whenNotPaused {
        require(tokenIds.length == orderNum.length && orderNum.length > 0, "Parameter error") ;
        checkNftSwapOutSign(orderNum, tokenIds, signature) ;

        for(uint256 i = 0; i < orderNum.length; i++) {
            require(tokenIds[i].length > 0 && orderNum[i] > 0, "Parameter error") ;
            _swapOut(orderNum[i], tokenIds[i]) ;
        }
    }

    // game => chain
    function nftSwapOut2(uint256[] memory tokenIds) external nonReentrant whenNotPaused {
        require(openTest, "test not started") ;
        require(tokenIds.length > 0, "The number of swapOut NFTs cannot be empty") ;
        _swapOut(0, tokenIds) ;
    }

    function _swapOut(uint256 orderNum, uint256[] memory tokenIds) private {
        Nft [] memory nfts = new Nft[](tokenIds.length) ;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            KIND kind = nftKinds[tokenIds[i]] ;
            require(nftToAccount[kind][tokenIds[i]] == _msgSender(), "There is an error in your permutation of the NFT") ;
            transferNft(kind, address (this), _msgSender(), tokenIds[i]) ;
            nfts[i] = Nft({ kind: kind, tokenId: tokenIds[i] }) ;
            delete nftToAccount[kind][tokenIds[i]];
            delete nftKinds[tokenIds[i]];
        }
        emit NftGameSwapOutEvent(_msgSender(), orderNum, nfts) ;
    }

    // transfer
    function transferNft(KIND kind, address from, address to, uint256 tId) private {
        if(kind == KIND.SPACESHIP) {
            spaceship.safeTransferFrom(from, to, tId) ;
        } else if(kind == KIND.HERO) {
            hero.safeTransferFrom(from, to, tId) ;
        } else if(kind == KIND.DEFENSIVEFACILITY) {
            defensiveFacility.safeTransferFrom(from, to, tId) ;
        } else {
            require(false, "Wrong type of replacement NFT") ;
        }
    }

    // check nft swap out sign
    function checkNftSwapOutSign(uint256[] memory orderNum, uint256[][] memory tokenIds, bytes memory signature) private view {
        bytes memory tokenIdEncode ;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            tokenIdEncode = abi.encodePacked(tokenIdEncode,keccak256(abi.encodePacked(tokenIds[i]))) ;
        }
        // cal hash
        bytes memory encodeData = abi.encode(
            keccak256(abi.encodePacked("nftSwapOutBatch(uint256[] orderNum,uint256[][] tokenIds,address owner)")),
            keccak256(abi.encodePacked(orderNum)),
            keccak256(tokenIdEncode),
            _msgSender()
        ) ;
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(_hashTypedDataV4(keccak256(encodeData)), signature);
        require(error == ECDSA.RecoverError.NoError && recovered == signAddr, "Incorrect request signature") ;
    }

    function checkNftSwapInSign(Nft[] memory nfts, bytes memory signature) private view {
        bytes memory allNftEncode ;
        for(uint256 i = 0; i < nfts.length; i++) {
            bytes memory nftEncode = abi.encode(
                keccak256(abi.encodePacked("Nft(uint8 kind,uint256 tokenId)")),
                nfts[i].kind,
                nfts[i].tokenId
            ) ;
            allNftEncode = abi.encodePacked(allNftEncode, keccak256(nftEncode)) ;
        }
        // cal hash
        bytes memory encodeData = abi.encode(
            keccak256(abi.encodePacked("nftSwapInBatch(Nft[] nfts,address owner)Nft(uint8 kind,uint256 tokenId)")),
            keccak256(allNftEncode),
            _msgSender()
        ) ;

        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(_hashTypedDataV4(keccak256(encodeData)), signature);
        require(error == ECDSA.RecoverError.NoError && recovered == signAddr, "Incorrect request signature") ;
    }

    function setOpenTest(bool open) external onlyRole(DEFAULT_ADMIN_ROLE) {
        openTest = open ;
    }

    function setSign(address sign) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signAddr = sign ;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause() ;
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause() ;
    }

    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
        require(from != address(0x0));
        return IERC721Receiver.onERC721Received.selector;
    }
}