// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interface/ITokenURI.sol";
import "./interface/IChimneyTownLandscape.sol";
import "./ERC721AntiScam/extensions/ERC721AntiScamControl.sol";

contract ChimneyTownLandscape is ERC721AntiScamControl, IChimneyTownLandscape, ReentrancyGuard {

    using Strings for uint256;
    uint256 public constant maxSupply = 10000;
    string public baseExtension = '.json';
    string public baseURI = 'https://metadata.ctdao.io/ctl/';
    ITokenURI public tokenuri;

    constructor() ERC721A("CHIMNEY TOWN Landscape", "CTL") {
        _grantLockerRole(msg.sender);
        contractLockStatus = LockStatus.UnLock;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override (ERC721A)
        returns (string memory)
    {
        if(address(tokenuri) == address(0))
        {
            return string(abi.encodePacked(ERC721A.tokenURI(_tokenId), baseExtension));
        }else{
            // Full-on chain support
            return tokenuri.tokenURI_future(_tokenId);
        }
    }

    //
    // onlyOwner functions
    //

    function mint(address _to, uint256 _quantity)
        external
        onlyOwner
        nonReentrant
    {
        require(totalSupply() + _quantity <= maxSupply  , 'can not mint, over max size');
        _safeMint(_to, _quantity);
    }

    function setBaseURI(string memory _URI)
        external
        onlyOwner
    {
        baseURI = _URI;
    }

    function setBaseExtension(string memory _extension)
        external
        onlyOwner
    {
        baseExtension = _extension;
    }

    function setTokenURI(ITokenURI _tokenuri)
        external
        onlyOwner
    {
        tokenuri = _tokenuri;
    }

    //
    // internal functions
    //
    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }
    
    function _startTokenId()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return 1;
    }

    //
    // for ERC721AntiScam
    //
    function setTokenLockOfTokenOwner(uint256[] calldata tokenIds, LockStatus[] calldata status) external {
        require(tokenIds.length == status.length, 'invalid value');
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address tokenOwner = ownerOf(tokenIds[i]);
            require( tokenOwner == msg.sender);
            _lock(status[i],tokenIds[i]);
        }
    }

    function setWalletLockOfWalletOwner(LockStatus status) external {
        _setWalletLock(msg.sender, status);
        emit WalletLock(msg.sender, msg.sender, uint(status));
    }

    function setWalletCALLevelOfWalletOwner(uint256 level) external {
        _setWalletCALLevel(msg.sender, level);
    }

    // return value: tokenid * 100 + tokenLockStatus * 10 + walletLockStatus;
    // example: tokenId=5678, tokenLockStatus=UnLock(1), walletLockStatus=UnSet(0), return=567810
    // maxSupply=10k,so it's not a problem.
    function tokensAndLocksOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256 walletLockStatus = uint256(_walletLockStatus[owner]);
            uint256[] memory returnValues = new uint256[](tokenIdsLength);
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
                    returnValues[tokenIdsIdx++] = i * 100 + uint256(_tokenLockStatus[i]) * 10 + walletLockStatus;
                }
            }
            return returnValues;
        }
    }

    //
    // LockerRole for ERC721AntiScamControl
    //
    function grantLockerRole(address _candidate) external onlyOwner {
        _grantLockerRole(_candidate);
    }

    function revokeLockerRole(address _candidate) external onlyOwner {
        _revokeLockerRole(_candidate);
    }
}